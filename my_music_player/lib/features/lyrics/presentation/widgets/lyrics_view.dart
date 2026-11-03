import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../../shared/widgets/app_artwork.dart';
import '../../../../shared/widgets/app_empty_state.dart';
import '../../../player/domain/entities/track.dart';
import '../../../player/presentation/providers/player_controller.dart';
import '../../domain/entities/lyrics.dart';
import '../providers/lyrics_provider.dart';

class LyricsView extends ConsumerStatefulWidget {
  const LyricsView({super.key});

  @override
  ConsumerState<LyricsView> createState() => _LyricsViewState();
}

class _LyricsViewState extends ConsumerState<LyricsView> {
  static const _manualScrollPause = Duration(seconds: 4);
  static const _scrollDuration = Duration(milliseconds: 300);

  final ScrollController _scrollController = ScrollController();
  final GlobalKey _activeKey = GlobalKey();
  int _lastActiveIndex = -1;
  String? _lastTrackId;
  Lyrics? _lastLyrics;
  bool _manualScrollPaused = false;
  int? _pendingActiveIndex;
  Timer? _resumeAutoScrollTimer;

  @override
  void dispose() {
    _resumeAutoScrollTimer?.cancel();
    _scrollController.dispose();
    super.dispose();
  }

  void _resetForNewTrack() {
    _lastActiveIndex = -1;
    _manualScrollPaused = false;
    _pendingActiveIndex = null;
    _resumeAutoScrollTimer?.cancel();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || !_scrollController.hasClients) return;
      _scrollController.jumpTo(0);
    });
  }

  void _ensureActiveVisible(bool reduceMotion) {
    final activeContext = _activeKey.currentContext;
    if (activeContext == null) return;
    Scrollable.ensureVisible(
      activeContext,
      alignment: 0.4,
      duration: reduceMotion ? Duration.zero : _scrollDuration,
      curve: Curves.easeInOut,
    );
  }

  void _scrollToActiveLine(int index) {
    if (!mounted || !_scrollController.hasClients) return;
    if (_manualScrollPaused) {
      _pendingActiveIndex = index;
      return;
    }
    if (index == _lastActiveIndex) return;

    _lastActiveIndex = index;
    final reduceMotion = MediaQuery.disableAnimationsOf(context);
    if (_activeKey.currentContext != null) {
      _ensureActiveVisible(reduceMotion);
      return;
    }

    // A large seek can jump outside the lazily built window. Jump to an
    // approximate offset first so the active row exists, then align it at 40%.
    final target = (index * 60.0).clamp(
      0.0,
      _scrollController.position.maxScrollExtent,
    );
    _scrollController.jumpTo(target);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || !_scrollController.hasClients) return;
      _ensureActiveVisible(reduceMotion);
    });
  }

  bool _handleScrollNotification(ScrollNotification notification) {
    final isUserDrag = (notification is ScrollStartNotification &&
            notification.dragDetails != null) ||
        (notification is ScrollUpdateNotification &&
            notification.dragDetails != null);
    if (isUserDrag) {
      _manualScrollPaused = true;
      _resumeAutoScrollTimer?.cancel();
      _resumeAutoScrollTimer = Timer(_manualScrollPause, () {
        _manualScrollPaused = false;
        final pending = _pendingActiveIndex;
        _pendingActiveIndex = null;
        if (pending == null) return;
        _lastActiveIndex = -1;
        _scrollToActiveLine(pending);
      });
    }
    return false;
  }

  String _formatTime(Duration time) {
    final minutes = time.inMinutes;
    final seconds = time.inSeconds % 60;
    return '$minutes:${seconds.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final lyricsAsync = ref.watch(currentLyricsProvider);
    final parsedLyrics = ref.watch(parsedLyricsProvider);
    final playerState = ref.watch(playerControllerProvider);
    final theme = Theme.of(context);
    final tokens = AppColors.of(context);
    final l10n = AppLocalizations.of(context);
    final lyrics = lyricsAsync.valueOrNull;
    final lineCount = parsedLyrics?.lines.length ?? 0;
    final isSynced = lyrics?.type == LyricsType.synced && lineCount > 0;

    final trackId = playerState.currentTrack?.sourceId;
    if (trackId != _lastTrackId) {
      _lastTrackId = trackId;
      _resetForNewTrack();
    }
    if (!identical(lyrics, _lastLyrics)) {
      _lastLyrics = lyrics;
      _resetForNewTrack();
    }

    return Column(
      children: [
        const SizedBox(height: AppSpacing.xs),
        Text(
          l10n.lyricsHeader,
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w500,
            letterSpacing: 2,
            color: tokens.textSecondary,
          ),
        ),
        if (playerState.currentTrack != null) ...[
          const SizedBox(height: AppSpacing.md),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
            child: _TrackHeader(
              track: playerState.currentTrack!,
              isSynced: isSynced,
            ),
          ),
        ],
        const SizedBox(height: AppSpacing.xs),
        Expanded(
          child: lyricsAsync.when(
            data: (lyrics) {
              if (lyrics == null || lyrics.type == LyricsType.notFound) {
                return _EmptyLyricsPanel(
                  title: l10n.lyricsNotFoundTitle,
                  message: l10n.lyricsNotFoundMessage,
                  footnote: l10n.lyricsNotFoundFootnote,
                  onRetry: () => ref.invalidate(currentLyricsProvider),
                );
              }

              if (lyrics.type == LyricsType.synced && lineCount == 0) {
                return _EmptyLyricsPanel(
                  title: l10n.lyricsEmpty,
                  message: l10n.lyricsEmptySyncedMessage,
                  footnote: l10n.lyricsNotFoundFootnote,
                  onRetry: () => ref.invalidate(currentLyricsProvider),
                );
              }

              if (!isSynced) {
                return SingleChildScrollView(
                  padding: const EdgeInsets.all(AppSpacing.lg),
                  child: Text(
                    lyrics.plainLyrics ??
                        lyrics.syncedLyrics ??
                        l10n.lyricsEmpty,
                    style: theme.textTheme.headlineSmall?.copyWith(
                      color: tokens.textPrimary,
                      fontWeight: FontWeight.w700,
                      height: 1.6,
                    ),
                    textAlign: TextAlign.left,
                  ),
                );
              }

              final parsed = parsedLyrics!;
              final activeIndex = parsed.getActiveLineIndex(
                playerState.position,
              );

              WidgetsBinding.instance.addPostFrameCallback((_) {
                if (activeIndex != -1) {
                  _scrollToActiveLine(activeIndex);
                }
              });

              final reduceMotion = MediaQuery.disableAnimationsOf(context);
              return NotificationListener<ScrollNotification>(
                onNotification: _handleScrollNotification,
                child: ShaderMask(
                  shaderCallback: (bounds) {
                    return const LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.transparent,
                        Colors.black,
                        Colors.black,
                        Colors.transparent,
                      ],
                      stops: [0.0, 0.15, 0.85, 1.0],
                    ).createShader(bounds);
                  },
                  blendMode: BlendMode.dstIn,
                  child: ListView.builder(
                    controller: _scrollController,
                    physics: const BouncingScrollPhysics(),
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.xl,
                      vertical: 80.0,
                    ),
                    itemCount: parsed.lines.length,
                    itemBuilder: (context, index) {
                      final line = parsed.lines[index];
                      final isActive = index == activeIndex;
                      final isPassed = index < activeIndex;
                      void seek() {
                        ref
                            .read(playerControllerProvider.notifier)
                            .seek(line.time);
                      }

                      return Semantics(
                        button: true,
                        selected: isActive,
                        label: l10n.lyricsLineSemantics(
                          _formatTime(line.time),
                          line.text,
                        ),
                        onTap: seek,
                        child: ExcludeSemantics(
                          child: GestureDetector(
                            key: isActive ? _activeKey : null,
                            onTap: seek,
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                vertical: AppSpacing.md,
                              ),
                              child: AnimatedDefaultTextStyle(
                                duration: reduceMotion
                                    ? Duration.zero
                                    : _scrollDuration,
                                style: theme.textTheme.headlineMedium!.copyWith(
                                  color: isActive
                                      ? tokens.textPrimary
                                      : tokens.textPrimary.withValues(
                                          alpha: isPassed ? 0.3 : 0.5,
                                        ),
                                  fontWeight: isActive
                                      ? FontWeight.w900
                                      : FontWeight.w700,
                                  fontSize: isActive ? 34 : 28,
                                  height: 1.3,
                                  letterSpacing: -0.5,
                                ),
                                textAlign: TextAlign.left,
                                child: Text(line.text),
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              );
            },
            loading: () => Center(
              child: CircularProgressIndicator(color: tokens.accent),
            ),
            error: (err, stack) => AppErrorState(
              error: l10n.lyricsLoadError,
              cause: err,
              onRetry: () => ref.invalidate(currentLyricsProvider),
            ),
          ),
        ),
        if (lyrics != null &&
            lyrics.type != LyricsType.notFound &&
            (lyrics.type == LyricsType.plain || lineCount > 0))
          Padding(
            padding: const EdgeInsets.only(
              top: AppSpacing.sm,
              bottom: AppSpacing.md,
            ),
            child: Text(
              isSynced ? l10n.lyricsFooterSynced : l10n.lyricsFooterPlain,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w500,
                color: tokens.textSecondary,
              ),
            ),
          ),
      ],
    );
  }
}

class _EmptyLyricsPanel extends StatelessWidget {
  const _EmptyLyricsPanel({
    required this.title,
    required this.message,
    required this.footnote,
    required this.onRetry,
  });

  final String title;
  final String message;
  final String footnote;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return AppStatePanel(
      variant: AppStateVariant.empty,
      icon: Icons.lyrics_outlined,
      title: title,
      message: message,
      actionLabel: l10n.lyricsRetry,
      actionIcon: Icons.refresh_rounded,
      onAction: onRetry,
      footnote: footnote,
    );
  }
}

class _TrackHeader extends StatelessWidget {
  const _TrackHeader({required this.track, required this.isSynced});

  final Track track;
  final bool isSynced;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final t = AppColors.of(context);

    return Row(
      children: [
        AppArtwork(
          localPath: track.localThumbnailPath,
          imageUrl: track.thumbnailUrl,
          size: 44,
          radius: AppRadius.md,
        ),
        const SizedBox(width: AppSpacing.md),
        Expanded(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                track.title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.bodyLarge?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: t.textPrimary,
                ),
              ),
              Text(
                track.artist,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: t.textSecondary,
                ),
              ),
            ],
          ),
        ),
        if (isSynced) ...[
          const SizedBox(width: AppSpacing.sm),
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.sm,
              vertical: AppSpacing.xs,
            ),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(AppRadius.full),
              border: Border.all(color: t.border),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.check_rounded,
                  size: 12,
                  color: t.textSecondary,
                ),
                const SizedBox(width: AppSpacing.xxs),
                Text(
                  AppLocalizations.of(context).lyricsSyncedBadge,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                    color: t.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }
}
