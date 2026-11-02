import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_spacing.dart';
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
  final ScrollController _scrollController = ScrollController();
  final GlobalKey _activeKey = GlobalKey();
  int _lastActiveIndex = -1;

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToActiveLine(int index) {
    if (!_scrollController.hasClients) return;
    if (index == _lastActiveIndex) return;

    _lastActiveIndex = index;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_activeKey.currentContext != null) {
        Scrollable.ensureVisible(
          _activeKey.currentContext!,
          alignment: 0.35, // Moved from 0.5 to lift it roughly 1 line higher
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
        );
      } else {
        // Fallback for when jumping large distances (scrubbing)
        final double offset = index * 70.0;
        _scrollController.animateTo(
          offset,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final lyricsAsync = ref.watch(currentLyricsProvider);
    final parsedLyrics = ref.watch(parsedLyricsProvider);
    final playerState = ref.watch(playerControllerProvider);
    final theme = Theme.of(context);
    final t = AppColors.of(context);
    final lyrics = lyricsAsync.valueOrNull;
    final isSynced = lyrics?.type == LyricsType.synced && parsedLyrics != null;

    return Column(
      children: [
        const SizedBox(height: AppSpacing.xs),
        Text(
          'LYRICS',
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w500,
            letterSpacing: 2,
            color: t.textSecondary,
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
                return AppStatePanel(
                  variant: AppStateVariant.empty,
                  icon: Icons.lyrics_outlined,
                  title: 'No lyrics found',
                  message: 'LRCLIB has no lyrics for this track. Instrumental '
                      'tracks never show lyrics.',
                  actionLabel: 'Retry',
                  actionIcon: Icons.refresh_rounded,
                  onAction: () => ref.invalidate(currentLyricsProvider),
                  footnote: 'Playback continues without lyrics.',
                );
              }

              if (lyrics.type == LyricsType.plain || parsedLyrics == null) {
                return SingleChildScrollView(
                  padding: const EdgeInsets.all(AppSpacing.lg),
                  child: Text(
                    lyrics.plainLyrics ?? lyrics.syncedLyrics ?? 'Lirik kosong',
                    style: theme.textTheme.headlineSmall?.copyWith(
                      color: t.textPrimary,
                      fontWeight: FontWeight.w700,
                      height: 1.6,
                    ),
                    textAlign: TextAlign.left,
                  ),
                );
              }

              // Synced Lyrics
              final activeIndex =
                  parsedLyrics.getActiveLineIndex(playerState.position);

              // Use a post-frame callback to avoid updating scroll during build
              WidgetsBinding.instance.addPostFrameCallback((_) {
                if (activeIndex != -1) {
                  _scrollToActiveLine(activeIndex);
                }
              });

              return ShaderMask(
                shaderCallback: (Rect bounds) {
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
                  itemCount: parsedLyrics.lines.length,
                  itemBuilder: (context, index) {
                    final line = parsedLyrics.lines[index];
                    final isActive = index == activeIndex;
                    final isPassed = index < activeIndex;

                    return GestureDetector(
                      key: isActive ? _activeKey : null,
                      onTap: () {
                        ref
                            .read(playerControllerProvider.notifier)
                            .seek(line.time);
                      },
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          vertical: AppSpacing.md,
                        ),
                        child: AnimatedDefaultTextStyle(
                          duration: const Duration(milliseconds: 300),
                          style: theme.textTheme.headlineMedium!.copyWith(
                            color: isActive
                                ? t.textPrimary
                                : t.textPrimary.withValues(
                                    alpha: isPassed ? 0.3 : 0.5,
                                  ),
                            fontWeight:
                                isActive ? FontWeight.w900 : FontWeight.w700,
                            fontSize: isActive ? 34 : 28,
                            height: 1.3,
                            letterSpacing: -0.5,
                          ),
                          textAlign: TextAlign.left,
                          child: Text(line.text),
                        ),
                      ),
                    );
                  },
                ),
              );
            },
            loading: () => Center(
              child: CircularProgressIndicator(color: t.accent),
            ),
            error: (err, stack) => AppErrorState(
              error: 'Lyrics are unavailable right now.',
              cause: err,
              onRetry: () => ref.invalidate(currentLyricsProvider),
            ),
          ),
        ),
        if (lyrics != null && lyrics.type != LyricsType.notFound)
          Padding(
            padding: const EdgeInsets.only(
              top: AppSpacing.sm,
              bottom: AppSpacing.md,
            ),
            child: Text(
              isSynced ? 'Synced lyrics · LRCLIB' : 'Lyrics · LRCLIB',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w500,
                color: t.textSecondary,
              ),
            ),
          ),
      ],
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
                  'Synced',
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
