import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_glass.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../../shared/widgets/app_artwork.dart';
import '../../../../shared/widgets/app_icon_button.dart';
import '../../../../shared/widgets/glass_surface.dart';
import '../providers/player_controller.dart';

/// Mini-player from `docs/DESIGN_SYSTEM.md` §6.1: 66dp, r20, glass chrome,
/// 1px border, 46dp artwork and 2dp progress. No colour.
class MiniPlayer extends ConsumerWidget {
  const MiniPlayer({
    super.key,
    this.quality = GlassQuality.blurred,
  });

  /// Glass quality. Pass [GlassQuality.opaque] for the lowest-cost fallback.
  final GlassQuality quality;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final playerState = ref.watch(playerControllerProvider);
    final track = playerState.currentTrack;
    if (track == null) return const SizedBox.shrink();

    final tokens = AppColors.of(context);
    final l10n = AppLocalizations.of(context);
    final progress = playerState.duration.inMilliseconds > 0
        ? (playerState.position.inMilliseconds /
                playerState.duration.inMilliseconds)
            .clamp(0.0, 1.0)
        : 0.0;
    final textTheme = Theme.of(context).textTheme;

    void openPlayer() => context.push('/player');
    void previous() =>
        ref.read(playerControllerProvider.notifier).playPrevious();
    void toggle() =>
        ref.read(playerControllerProvider.notifier).togglePlayPause();
    void next() => ref.read(playerControllerProvider.notifier).playNext();

    return Align(
      alignment: Alignment.bottomCenter,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 420),
          child: GestureDetector(
            onTap: openPlayer,
            onVerticalDragEnd: (details) {
              if ((details.primaryVelocity ?? 0) < -100) openPlayer();
            },
            child: ConstrainedBox(
              constraints: const BoxConstraints(minHeight: 66),
              child: GlassSurface.chrome(
                quality: quality,
                borderRadius: BorderRadius.circular(AppRadius.xxl),
                child: Stack(
                  children: [
                    Row(
                      children: [
                        const SizedBox(width: 10),
                        AppArtwork(
                          localPath: track.localThumbnailPath,
                          imageUrl: track.thumbnailUrl,
                          size: 46,
                          radius: AppRadius.md,
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                track.title,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: textTheme.titleSmall?.copyWith(
                                  color: tokens.textPrimary,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                track.artist,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: textTheme.labelSmall?.copyWith(
                                  color: tokens.textSecondary,
                                ),
                              ),
                            ],
                          ),
                        ),
                        AppIconButton(
                          icon: Icons.skip_previous_rounded,
                          semanticLabel: l10n.playerPrevious,
                          iconSize: 18,
                          filled: false,
                          onPressed: previous,
                        ),
                        AppIconButton(
                          icon: playerState.isPlaying
                              ? Icons.pause_rounded
                              : Icons.play_arrow_rounded,
                          semanticLabel: playerState.isPlaying
                              ? l10n.playerPause
                              : l10n.commonPlay,
                          iconSize: 18,
                          filled: false,
                          onPressed: toggle,
                        ),
                        AppIconButton(
                          icon: Icons.skip_next_rounded,
                          semanticLabel: l10n.playerNext,
                          iconSize: 18,
                          filled: false,
                          onPressed: next,
                        ),
                        const SizedBox(width: 6),
                      ],
                    ),
                    Positioned(
                      left: 10,
                      right: 10,
                      bottom: 0,
                      child: Container(
                        height: 2,
                        color: tokens.track,
                        alignment: Alignment.centerLeft,
                        child: FractionallySizedBox(
                          widthFactor: progress,
                          child: Container(color: tokens.accent),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
