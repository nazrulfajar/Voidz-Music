import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:just_audio/just_audio.dart' show LoopMode;

import '../../../../core/network/api_service.dart';
import '../../../../core/providers/connectivity_provider.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_glass.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../../shared/widgets/add_to_playlist_sheet.dart';
import '../../../../shared/widgets/app_artwork.dart';
import '../../../../shared/widgets/app_icon_button.dart';
import '../../../../shared/widgets/app_snackbar.dart';
import '../../../../shared/widgets/glass_background.dart';
import '../../../../shared/widgets/glass_surface.dart';
import '../../domain/entities/track.dart';
import '../providers/player_controller.dart';
import '../widgets/queue_view.dart';
import '../widgets/sleep_timer_sheet.dart';

/// Responsive geometry for the player (`docs/DESIGN_SYSTEM.md` §4.4/§6.2).
class _PlayerLayout {
  const _PlayerLayout._();

  /// Landscape width at which artwork and controls sit side by side.
  static const double twoPaneMinWidth = 600.0;

  static const double artworkMin = 160.0;
  static const double artworkMax = 312.0;
  static const double landscapeArtworkMax = 288.0;

  /// Vertical space reserved for header, metadata, seek and transport.
  ///
  /// At 360×640 this leaves 190dp for the artwork, keeping transport above
  /// the fold. Taller viewports grow up to [artworkMax].
  static const double artworkReservedHeight = 450.0;

  static const double contentMaxWidth = 420.0;
  static const double horizontalInset = 16.0;
  static const double metadataInset = 24.0;
  static const double twoPaneInset = 24.0;
  static const double playButtonSize = 76.0;

  /// Decorative glass halo painted outside the 76dp play target. The layout
  /// box stays 76dp so TASK-039 geometry is unchanged.
  static const double playHaloSize = playButtonSize + 8;
  static const double secondaryControlSize = 48.0;

  /// Five transport controls must fit without shrinking a touch target.
  static const double controlsMinWidth =
      playButtonSize + secondaryControlSize * 4;
}

class PlayerScreen extends ConsumerStatefulWidget {
  const PlayerScreen({
    super.key,
    this.glassQuality = GlassQuality.blurred,
  });

  /// Rendering quality for the floating chrome. The header buttons always use
  /// the frosted step unless this is [GlassQuality.opaque], so the screen
  /// stays inside the 2-3 blur-layer cap.
  final GlassQuality glassQuality;

  @override
  ConsumerState<PlayerScreen> createState() => _PlayerScreenState();
}

class _PlayerScreenState extends ConsumerState<PlayerScreen> {
  /// Header controls are frosted even when the screen allows blur; the play
  /// halo and dock are the two blurred layers of the production cap.
  GlassQuality get _headerQuality => widget.glassQuality == GlassQuality.blurred
      ? GlassQuality.frosted
      : widget.glassQuality;

  String _formatDuration(Duration d) {
    final minutes = d.inMinutes;
    final seconds = d.inSeconds % 60;
    return '$minutes:${seconds.toString().padLeft(2, '0')}';
  }

  Duration _motion(BuildContext context, int milliseconds) {
    return MediaQuery.disableAnimationsOf(context)
        ? Duration.zero
        : Duration(milliseconds: milliseconds);
  }

  // Premium: push canonical detail without closing player, no tab-switch hack.
  // Player stays in stack so back returns to Now Playing (Spotify/Apple behavior).
  Future<void> _navigateToArtist(
      BuildContext context, WidgetRef ref, String artistName) async {
    if (artistName == 'Unknown Artist' || artistName.isEmpty) return;

    final l10n = AppLocalizations.of(context);
    final isOnline = ref.read(connectivityProvider).value ?? true;
    if (!isOnline) {
      AppSnackbar.showError(context, l10n.playerOfflineArtist);
      return;
    }

    showDialog(
        context: context,
        barrierDismissible: false,
        builder: (_) => const Center(child: CircularProgressIndicator()));

    try {
      final apiService = ref.read(apiServiceProvider);
      final results = await apiService
          .searchArtistsOrAlbums(artistName, 'artists', limit: 1);

      if (context.mounted) Navigator.pop(context); // close loading

      if (results.isNotEmpty && results.first['browse_id'] != null) {
        final id = results.first['browse_id'];
        if (context.mounted) {
          // Premium: canonical push, player stays — no Navigator.pop(player)
          context.push('/artist/$id');
        }
      } else {
        if (context.mounted) {
          AppSnackbar.showError(context, l10n.playerArtistNotFound);
        }
      }
    } catch (_) {
      if (context.mounted) {
        Navigator.pop(context);
        AppSnackbar.showError(context, l10n.playerArtistLoadError);
      }
    }
  }

  Future<void> _navigateToAlbum(BuildContext context, WidgetRef ref,
      String albumName, String artistName) async {
    if (albumName.isEmpty) return;

    final l10n = AppLocalizations.of(context);
    final isOnline = ref.read(connectivityProvider).value ?? true;
    if (!isOnline) {
      AppSnackbar.showError(context, l10n.playerOfflineAlbum);
      return;
    }

    showDialog(
        context: context,
        barrierDismissible: false,
        builder: (_) => const Center(child: CircularProgressIndicator()));

    try {
      final apiService = ref.read(apiServiceProvider);
      final results = await apiService
          .searchArtistsOrAlbums('$albumName $artistName', 'albums', limit: 1);

      if (context.mounted) Navigator.pop(context); // close loading

      if (results.isNotEmpty && results.first['browse_id'] != null) {
        final id = results.first['browse_id'];
        if (context.mounted) {
          context.push('/album/$id');
        }
      } else {
        if (context.mounted) {
          AppSnackbar.showError(context, l10n.playerAlbumNotFound);
        }
      }
    } catch (_) {
      if (context.mounted) {
        Navigator.pop(context);
        AppSnackbar.showError(context, l10n.playerAlbumLoadError);
      }
    }
  }

  void _openLyrics(BuildContext context) => context.push('/lyrics');

  void _showQueueSheet(BuildContext context) {
    final t = AppColors.of(context);
    final mq = MediaQuery.of(context);
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(AppRadius.xxxl),
        ),
      ),
      builder: (_) {
        return SizedBox(
          height: mq.size.height * 0.8,
          child: GlassSurface.chrome(
            key: const Key('queue-sheet-glass'),
            // Frosted panel: a sheet is a stable surface, so it takes the
            // chrome recipe without a new backdrop blur layer.
            quality: GlassQuality.frosted,
            borderRadius: const BorderRadius.vertical(
              top: Radius.circular(AppRadius.xxxl),
            ),
            child: Material(
              color: Colors.transparent,
              child: Column(
                children: [
                  const SizedBox(height: AppSpacing.sm),
                  Container(
                    width: 32,
                    height: 4,
                    decoration: BoxDecoration(
                      color: t.textPrimary,
                      borderRadius: BorderRadius.circular(AppRadius.handle),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  const Expanded(child: QueueView()),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final playerState = ref.watch(playerControllerProvider);
    final currentTrack = playerState.currentTrack;
    final t = AppColors.of(context);

    if (currentTrack == null) {
      return Scaffold(
        backgroundColor: Colors.transparent,
        body: GlassBackground(
          child: Center(
            child: CircularProgressIndicator(color: t.textPrimary),
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: GlassBackground(
        child: SafeArea(
          child: GestureDetector(
            behavior: HitTestBehavior.translucent,
            onHorizontalDragEnd: (details) {
              if ((details.primaryVelocity ?? 0).abs() > 250) {
                _openLyrics(context);
              }
            },
            child: LayoutBuilder(
              builder: (context, constraints) {
                final useTwoPane =
                    constraints.maxWidth >= _PlayerLayout.twoPaneMinWidth &&
                        constraints.maxWidth > constraints.maxHeight;

                if (useTwoPane) {
                  return _buildTwoPane(
                    context,
                    constraints,
                    playerState,
                    currentTrack,
                    t,
                  );
                }

                return _buildPortrait(
                  context,
                  constraints,
                  playerState,
                  currentTrack,
                  t,
                );
              },
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPortrait(
    BuildContext context,
    BoxConstraints constraints,
    PlayerState playerState,
    Track track,
    AppColorTokens tokens,
  ) {
    final artworkSize = _portraitArtworkSize(constraints);
    final spacious = constraints.maxHeight >= 760;

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(
            _PlayerLayout.horizontalInset,
            AppSpacing.md,
            _PlayerLayout.horizontalInset,
            0,
          ),
          child: _buildHeader(context, track, tokens),
        ),
        Expanded(
          child: LayoutBuilder(
            builder: (context, bodyConstraints) {
              return SingleChildScrollView(
                physics: const ClampingScrollPhysics(),
                padding: const EdgeInsets.symmetric(
                  horizontal: _PlayerLayout.metadataInset,
                ),
                child: Center(
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                      maxWidth: _PlayerLayout.contentMaxWidth,
                      minHeight: bodyConstraints.maxHeight,
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.end,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        const SizedBox(height: AppSpacing.space3),
                        Center(child: _buildArtwork(track, artworkSize)),
                        SizedBox(
                          height:
                              spacious ? AppSpacing.space10 : AppSpacing.space4,
                        ),
                        if (_hasQuality(track)) ...[
                          Center(child: _buildQualityBadge(track, tokens)),
                          const SizedBox(height: AppSpacing.space4),
                        ],
                        _buildTitleRow(context, track, tokens),
                        const SizedBox(height: AppSpacing.space2),
                        _buildSeek(context, playerState, tokens),
                        const SizedBox(height: AppSpacing.space1),
                        _buildTimes(playerState, tokens),
                        if (playerState.errorMessage != null) ...[
                          const SizedBox(height: AppSpacing.space4),
                          _buildErrorCard(playerState, track),
                        ],
                        const SizedBox(height: AppSpacing.space4),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ),
        Padding(
          padding: EdgeInsets.fromLTRB(
            _PlayerLayout.horizontalInset,
            0,
            _PlayerLayout.horizontalInset,
            spacious ? AppSpacing.space3 : AppSpacing.space2,
          ),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(
                maxWidth: _PlayerLayout.contentMaxWidth,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _buildControls(context, playerState, tokens),
                  SizedBox(
                    height: spacious ? AppSpacing.space8 : AppSpacing.space3,
                  ),
                  _buildDock(context, playerState, tokens),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTwoPane(
    BuildContext context,
    BoxConstraints constraints,
    PlayerState playerState,
    Track track,
    AppColorTokens tokens,
  ) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        _PlayerLayout.twoPaneInset,
        AppSpacing.md,
        _PlayerLayout.twoPaneInset,
        AppSpacing.md,
      ),
      child: Column(
        children: [
          _buildHeader(context, track, tokens),
          const SizedBox(height: AppSpacing.md),
          Expanded(
            child: LayoutBuilder(
              builder: (context, bodyConstraints) {
                final widthBudget = bodyConstraints.maxWidth -
                    _PlayerLayout.controlsMinWidth -
                    AppSpacing.space6;
                final artworkSize = math
                    .min(
                      math.min(bodyConstraints.maxHeight, widthBudget),
                      _PlayerLayout.landscapeArtworkMax,
                    )
                    .clamp(
                      _PlayerLayout.artworkMin,
                      _PlayerLayout.landscapeArtworkMax,
                    );

                return Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    SizedBox(
                      width: artworkSize,
                      child: Center(child: _buildArtwork(track, artworkSize)),
                    ),
                    const SizedBox(width: AppSpacing.space6),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Expanded(
                            child: SingleChildScrollView(
                              physics: const ClampingScrollPhysics(),
                              // Keep the edge thumb inside the scroll clip.
                              padding: const EdgeInsets.symmetric(
                                horizontal: AppSpacing.space2,
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  _buildTitleRow(context, track, tokens),
                                  const SizedBox(height: AppSpacing.md),
                                  _buildSeek(context, playerState, tokens),
                                  const SizedBox(height: AppSpacing.xs),
                                  _buildTimes(playerState, tokens),
                                  if (playerState.errorMessage != null) ...[
                                    const SizedBox(height: AppSpacing.md),
                                    _buildErrorCard(playerState, track),
                                  ],
                                  const SizedBox(height: AppSpacing.lg),
                                ],
                              ),
                            ),
                          ),
                          _buildControls(
                            context,
                            playerState,
                            tokens,
                            horizontalPadding: 0,
                          ),
                          const SizedBox(height: AppSpacing.sm),
                          _buildDock(context, playerState, tokens),
                          const SizedBox(height: AppSpacing.xs),
                        ],
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  double _portraitArtworkSize(BoxConstraints constraints) {
    final widthCap = constraints.maxWidth - _PlayerLayout.metadataInset * 2;
    final heightBudget =
        constraints.maxHeight - _PlayerLayout.artworkReservedHeight;
    final size = math.min(widthCap, heightBudget);
    return size.clamp(_PlayerLayout.artworkMin, _PlayerLayout.artworkMax);
  }

  bool _hasQuality(Track track) =>
      (track.audioFormat?.trim().isNotEmpty ?? false) ||
      (track.bitrateKbps ?? 0) > 0;

  /// 48dp chrome button for PlayerBack/PlayerMore/PlayerLike.
  Widget _buildGlassIconButton({
    required Key key,
    required IconData icon,
    required String semanticLabel,
    required VoidCallback onPressed,
    double iconSize = 20,
  }) {
    const size = _PlayerLayout.secondaryControlSize;
    return SizedBox(
      key: key,
      width: size,
      height: size,
      child: GlassSurface.chrome(
        quality: _headerQuality,
        borderRadius: BorderRadius.circular(AppRadius.full),
        child: AppIconButton(
          icon: icon,
          semanticLabel: semanticLabel,
          onPressed: onPressed,
          iconSize: iconSize,
          size: size,
          filled: false,
        ),
      ),
    );
  }

  Widget _buildHeader(
    BuildContext context,
    Track track,
    AppColorTokens tokens,
  ) {
    final l10n = AppLocalizations.of(context);
    return Row(
      children: [
        _buildGlassIconButton(
          key: const Key('player-back-glass'),
          icon: Icons.keyboard_arrow_down_rounded,
          semanticLabel: l10n.playerClose,
          onPressed: () => context.pop(),
          iconSize: 22,
        ),
        Expanded(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                l10n.playerPlayingFrom,
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w500,
                  color: tokens.textSecondary,
                  letterSpacing: 1.2,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                track.source.name.toUpperCase(),
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: tokens.textPrimary,
                ),
              ),
            ],
          ),
        ),
        MenuAnchor(
          style: MenuStyle(
            backgroundColor: WidgetStatePropertyAll(tokens.panel),
            shape: WidgetStatePropertyAll(
              RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppRadius.lg),
              ),
            ),
          ),
          menuChildren: [
            MenuItemButton(
              onPressed: () => showSleepTimerSheet(context),
              child: Text(
                l10n.playerSleepTimer,
                style: TextStyle(color: tokens.textPrimary),
              ),
            ),
            MenuItemButton(
              onPressed: () => showAddToPlaylistSheet(
                context,
                track: track,
              ),
              child: Text(
                l10n.playlistAddSheetTitle,
                style: TextStyle(color: tokens.textPrimary),
              ),
            ),
            if (track.album?.isNotEmpty ?? false)
              MenuItemButton(
                onPressed: () => _navigateToAlbum(
                  context,
                  ref,
                  track.album!,
                  track.artist,
                ),
                child: Text(
                  track.album!,
                  style: TextStyle(color: tokens.textPrimary),
                ),
              ),
          ],
          builder: (context, controller, child) {
            return _buildGlassIconButton(
              key: const Key('player-more-glass'),
              icon: Icons.more_horiz,
              semanticLabel: l10n.commonMoreOptions,
              iconSize: 20,
              onPressed: () {
                if (controller.isOpen) {
                  controller.close();
                } else {
                  controller.open();
                }
              },
            );
          },
        ),
      ],
    );
  }

  Widget _buildArtwork(Track track, double size) {
    return Stack(
      alignment: Alignment.center,
      clipBehavior: Clip.none,
      children: [
        Positioned.fill(
          child: IgnorePointer(
            child: OverflowBox(
              minWidth: size + AppSpacing.space12,
              maxWidth: size + AppSpacing.space12,
              minHeight: size + AppSpacing.space12,
              maxHeight: size + AppSpacing.space12,
              child: Container(
                padding: const EdgeInsets.all(AppSpacing.space2),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: AppGlass.of(context).chrome.border),
                ),
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: AppGlass.of(context).chrome.border,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
        AnimatedSwitcher(
          duration: _motion(context, 300),
          switchInCurve: Curves.easeOut,
          switchOutCurve: Curves.easeIn,
          transitionBuilder: (child, animation) {
            return FadeTransition(
              opacity: animation,
              child: ScaleTransition(
                scale: Tween<double>(begin: 0.96, end: 1).animate(animation),
                child: child,
              ),
            );
          },
          child: DoubleTapArtwork(
            key: ValueKey('player-artwork-${track.sourceId}'),
            track: track,
            size: size,
            onDoubleTap: () {
              ref.read(playerControllerProvider.notifier).toggleLike();
            },
          ),
        ),
      ],
    );
  }

  Widget _buildQualityBadge(Track track, AppColorTokens tokens) {
    return Container(
      constraints: const BoxConstraints(minHeight: 27),
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.space4,
        vertical: AppSpacing.space1,
      ),
      decoration: BoxDecoration(
        color: tokens.background,
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: tokens.qualityOutline),
      ),
      child: Text(
        [
          if ((track.bitrateKbps ?? 0) > 0) '${track.bitrateKbps} kbps',
          if (track.audioFormat?.trim().isNotEmpty ?? false)
            track.audioFormat!.trim().toUpperCase(),
        ].join(' · '),
        style: TextStyle(
          fontSize: 10,
          color: tokens.textPrimary,
        ),
        textAlign: TextAlign.center,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
    );
  }

  Widget _buildTitleRow(
    BuildContext context,
    Track track,
    AppColorTokens tokens,
  ) {
    final l10n = AppLocalizations.of(context);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Expanded(
          child: AnimatedSwitcher(
            duration: _motion(context, 300),
            transitionBuilder: (child, animation) {
              return FadeTransition(
                opacity: animation,
                child: SlideTransition(
                  position: Tween<Offset>(
                    begin: const Offset(0, 0.04),
                    end: Offset.zero,
                  ).animate(animation),
                  child: child,
                ),
              );
            },
            child: Column(
              key: ValueKey('player-meta-${track.sourceId}'),
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  track.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    height: 34 / 28,
                    color: tokens.textPrimary,
                  ),
                ),
                const SizedBox(height: 4),
                GestureDetector(
                  onTap: () => _navigateToArtist(
                    context,
                    ref,
                    track.artist,
                  ),
                  child: Text(
                    track.artist,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 15,
                      height: 21 / 15,
                      color: tokens.textSecondary,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(width: AppSpacing.md),
        _buildGlassIconButton(
          key: const Key('player-like-glass'),
          icon: track.isLiked ? Icons.favorite : Icons.favorite_border,
          semanticLabel: track.isLiked ? l10n.playerUnlike : l10n.playerLike,
          iconSize: 21,
          onPressed: () {
            ref.read(playerControllerProvider.notifier).toggleLike();
          },
        ),
      ],
    );
  }

  Widget _buildSeek(
    BuildContext context,
    PlayerState playerState,
    AppColorTokens tokens,
  ) {
    return SliderTheme(
      data: SliderTheme.of(context).copyWith(
        activeTrackColor: tokens.accent,
        inactiveTrackColor: tokens.track,
        thumbColor: tokens.accent,
        trackHeight: 5,
        thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6.5),
        overlayShape: const RoundSliderOverlayShape(overlayRadius: 12),
      ),
      child: SizedBox(
        height: _PlayerLayout.secondaryControlSize,
        child: Slider(
          padding: EdgeInsets.zero,
          value: playerState.position.inMilliseconds.toDouble().clamp(
                0.0,
                playerState.duration.inMilliseconds > 0
                    ? playerState.duration.inMilliseconds.toDouble()
                    : 1.0,
              ),
          max: playerState.duration.inMilliseconds > 0
              ? playerState.duration.inMilliseconds.toDouble()
              : 1.0,
          onChanged: (value) {
            ref
                .read(playerControllerProvider.notifier)
                .seek(Duration(milliseconds: value.toInt()));
          },
        ),
      ),
    );
  }

  Widget _buildTimes(PlayerState playerState, AppColorTokens tokens) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          _formatDuration(playerState.position),
          style: TextStyle(
            fontSize: 11,
            color: tokens.textSecondary,
          ),
        ),
        Text(
          _formatDuration(playerState.duration),
          style: TextStyle(
            fontSize: 11,
            color: tokens.textSecondary,
          ),
        ),
      ],
    );
  }

  Widget _buildErrorCard(PlayerState playerState, Track track) {
    return _PlaybackErrorCard(
      onRetry: () {
        ref.read(playerControllerProvider.notifier).playTrack(
              track,
              queue: playerState.currentQueue,
            );
      },
    );
  }

  Widget _buildControls(
    BuildContext context,
    PlayerState playerState,
    AppColorTokens tokens, {
    double horizontalPadding = 0,
  }) {
    final l10n = AppLocalizations.of(context);
    final canShuffle = playerState.currentQueue.length > 1;

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton(
            icon: Icon(
              Icons.shuffle,
              size: 21,
              semanticLabel: l10n.commonShuffle,
              color: playerState.isShuffleEnabled
                  ? tokens.textPrimary
                  : tokens.textInactive,
            ),
            onPressed: canShuffle
                ? () {
                    ref.read(playerControllerProvider.notifier).toggleShuffle();
                  }
                : null,
          ),
          AppIconButton(
            icon: Icons.skip_previous_rounded,
            semanticLabel: l10n.playerPrevious,
            iconSize: 28,
            filled: false,
            onPressed: () {
              ref.read(playerControllerProvider.notifier).playPrevious();
            },
          ),
          _buildPlayButton(playerState, tokens, l10n),
          AppIconButton(
            icon: Icons.skip_next_rounded,
            semanticLabel: l10n.playerNext,
            iconSize: 28,
            filled: false,
            onPressed: () {
              ref.read(playerControllerProvider.notifier).playNext();
            },
          ),
          IconButton(
            icon: Icon(
              playerState.loopMode == LoopMode.one
                  ? Icons.repeat_one
                  : Icons.repeat,
              size: 21,
              semanticLabel: playerState.loopMode == LoopMode.one
                  ? l10n.playerRepeatOne
                  : l10n.playerRepeat,
              color: playerState.loopMode != LoopMode.off
                  ? tokens.textPrimary
                  : tokens.textInactive,
            ),
            onPressed: () {
              ref.read(playerControllerProvider.notifier).toggleRepeat();
            },
          ),
        ],
      ),
    );
  }

  /// White Logo_White 76dp play button with a decorative glass halo.
  ///
  /// The halo is 84dp and paints 4dp outside the 76dp semantics box through
  /// [OverflowBox], so TASK-039 geometry and the 48dp target stay unchanged.
  /// The halo is one of the two blurred layers allowed on this screen.
  Widget _buildPlayButton(
    PlayerState playerState,
    AppColorTokens tokens,
    AppLocalizations l10n,
  ) {
    final isPlaying = playerState.isPlaying;
    final label = isPlaying ? l10n.playerPause : l10n.commonPlay;

    void toggle() =>
        ref.read(playerControllerProvider.notifier).togglePlayPause();

    return Semantics(
      button: true,
      label: label,
      onTap: toggle,
      child: ExcludeSemantics(
        child: SizedBox(
          width: _PlayerLayout.playButtonSize,
          height: _PlayerLayout.playButtonSize,
          child: Stack(
            alignment: Alignment.center,
            clipBehavior: Clip.none,
            children: [
              OverflowBox(
                minWidth: _PlayerLayout.playHaloSize,
                maxWidth: _PlayerLayout.playHaloSize,
                minHeight: _PlayerLayout.playHaloSize,
                maxHeight: _PlayerLayout.playHaloSize,
                child: AnimatedScale(
                  scale: isPlaying ? 1 : 0.94,
                  duration: _motion(context, 300),
                  curve: Curves.easeOut,
                  child: GlassSurface.chrome(
                    key: const Key('player-play-halo'),
                    quality: widget.glassQuality,
                    borderRadius: BorderRadius.circular(AppRadius.full),
                  ),
                ),
              ),
              SizedBox(
                width: _PlayerLayout.playButtonSize,
                height: _PlayerLayout.playButtonSize,
                child: IconButton(
                  icon: AnimatedSwitcher(
                    duration: _motion(context, 200),
                    transitionBuilder: (child, animation) {
                      return ScaleTransition(
                        scale: animation,
                        child: FadeTransition(
                          opacity: animation,
                          child: child,
                        ),
                      );
                    },
                    child: Icon(
                      isPlaying
                          ? Icons.pause_rounded
                          : Icons.play_arrow_rounded,
                      key: ValueKey(isPlaying),
                      size: 36,
                      color: tokens.onAccent,
                    ),
                  ),
                  style: IconButton.styleFrom(
                    backgroundColor: tokens.accent,
                    foregroundColor: tokens.onAccent,
                    fixedSize: const Size.square(
                      _PlayerLayout.playButtonSize,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(
                        AppRadius.playButton,
                      ),
                    ),
                  ),
                  onPressed: toggle,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDock(
    BuildContext context,
    PlayerState playerState,
    AppColorTokens tokens,
  ) {
    final l10n = AppLocalizations.of(context);
    return GlassSurface.chrome(
      key: const Key('player-dock-glass'),
      quality: widget.glassQuality,
      borderRadius: BorderRadius.circular(AppRadius.x4xl),
      child: ConstrainedBox(
        constraints: const BoxConstraints(minHeight: 56),
        child: IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                child: _DockItem(
                  icon: Icons.lyrics_outlined,
                  label: l10n.playerDockLyrics,
                  color: tokens.textSecondary,
                  onTap: () => _openLyrics(context),
                ),
              ),
              Expanded(
                child: _DockItem(
                  icon: Icons.queue_music_rounded,
                  label: l10n.playerDockQueue(
                    playerState.currentQueue.length,
                  ),
                  color: tokens.textSecondary,
                  onTap: () => _showQueueSheet(context),
                ),
              ),
              Expanded(
                child: _DockItem(
                  icon: Icons.timer_outlined,
                  label: l10n.playerDockTimer,
                  color: tokens.textSecondary,
                  onTap: () => showSleepTimerSheet(context),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PlaybackErrorCard extends StatelessWidget {
  const _PlaybackErrorCard({required this.onRetry});

  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final t = AppColors.of(context);
    final l10n = AppLocalizations.of(context);
    return Container(
      constraints: const BoxConstraints(minHeight: 88),
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.space4,
        vertical: AppSpacing.space3,
      ),
      decoration: BoxDecoration(
        color: t.raised,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: t.focusedBorder),
      ),
      child: Row(
        children: [
          Icon(
            Icons.error_outline_rounded,
            size: 20,
            color: t.textPrimary,
          ),
          const SizedBox(width: AppSpacing.space3),
          Expanded(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l10n.playerPlaybackFailed,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: t.textPrimary,
                  ),
                ),
                const SizedBox(height: AppSpacing.xxs),
                Text(
                  l10n.playerStreamUnavailable,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: t.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.space2),
          FilledButton(
            onPressed: onRetry,
            style: FilledButton.styleFrom(
              backgroundColor: t.accent,
              foregroundColor: t.onAccent,
              minimumSize: const Size(100, 48),
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.space4,
                vertical: AppSpacing.space2,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(24),
              ),
            ),
            child: Text(
              l10n.playerRetry,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _DockItem extends StatelessWidget {
  const _DockItem({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      enabled: true,
      label: label,
      onTap: onTap,
      child: ExcludeSemantics(
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(AppRadius.x4xl),
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.space2),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(icon, size: 18, color: color),
                const SizedBox(width: AppSpacing.space2),
                Flexible(
                  child: Text(
                    label,
                    maxLines: 1,
                    textAlign: TextAlign.center,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: color,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class DoubleTapArtwork extends StatefulWidget {
  const DoubleTapArtwork({
    super.key,
    required this.track,
    required this.size,
    required this.onDoubleTap,
  });

  final Track track;
  final double size;
  final VoidCallback onDoubleTap;

  @override
  State<DoubleTapArtwork> createState() => _DoubleTapArtworkState();
}

class _DoubleTapArtworkState extends State<DoubleTapArtwork>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late Animation<double> _opacityAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );

    _scaleAnimation = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween(begin: 0.0, end: 1.2)
            .chain(CurveTween(curve: Curves.easeOutBack)),
        weight: 50,
      ),
      TweenSequenceItem(
        tween:
            Tween(begin: 1.2, end: 1.0).chain(CurveTween(curve: Curves.easeIn)),
        weight: 20,
      ),
      TweenSequenceItem(
        tween:
            Tween(begin: 1.0, end: 0.0).chain(CurveTween(curve: Curves.easeIn)),
        weight: 30,
      ),
    ]).animate(_controller);

    _opacityAnimation = TweenSequence<double>([
      TweenSequenceItem(
        tween:
            Tween(begin: 0.0, end: 1.0).chain(CurveTween(curve: Curves.easeIn)),
        weight: 20,
      ),
      TweenSequenceItem(tween: ConstantTween(1.0), weight: 50),
      TweenSequenceItem(
        tween: Tween(begin: 1.0, end: 0.0)
            .chain(CurveTween(curve: Curves.easeOut)),
        weight: 30,
      ),
    ]).animate(_controller);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _handleDoubleTap() {
    widget.onDoubleTap();
    _controller.forward(from: 0.0);
  }

  @override
  Widget build(BuildContext context) {
    final t = AppColors.of(context);
    final l10n = AppLocalizations.of(context);
    return Semantics(
      image: true,
      label: l10n.playerArtworkSemantics(widget.track.title),
      child: ExcludeSemantics(
        child: GestureDetector(
          onDoubleTap: _handleDoubleTap,
          child: Stack(
            alignment: Alignment.center,
            children: [
              AppArtwork(
                localPath: widget.track.localThumbnailPath,
                imageUrl: widget.track.thumbnailUrl,
                size: widget.size,
                radius: AppRadius.x4xl,
                border: true,
              ),
              // Heart Animation Overlay
              AnimatedBuilder(
                animation: _controller,
                builder: (context, child) {
                  if (_controller.isDismissed) return const SizedBox.shrink();
                  return Transform.scale(
                    scale: _scaleAnimation.value,
                    child: Opacity(
                      opacity: _opacityAnimation.value,
                      child: Icon(
                        Icons.favorite,
                        color: t.textPrimary,
                        size: 120,
                      ),
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
