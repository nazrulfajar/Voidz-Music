import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:go_router/go_router.dart';
import 'package:marquee/marquee.dart';
import 'dart:io';
import 'dart:ui';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_radius.dart';
import '../providers/player_controller.dart';

class MiniPlayer extends ConsumerWidget {
  const MiniPlayer({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final playerState = ref.watch(playerControllerProvider);
    final currentTrack = playerState.currentTrack;

    if (currentTrack == null) return const SizedBox.shrink();

    final theme = Theme.of(context);
    final progress = playerState.duration.inMilliseconds > 0
        ? playerState.position.inMilliseconds /
            playerState.duration.inMilliseconds
        : 0.0;

    return GestureDetector(
      onTap: () => context.push('/player'),
      onVerticalDragEnd: (details) {
        if (details.primaryVelocity! < 0) {
          // Swipe up
          context.push('/player');
        }
      },
      child: Container(
        height: 64,
        margin: const EdgeInsets.symmetric(
            horizontal: AppSpacing.sm, vertical: AppSpacing.xs),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(AppRadius.md),
          border: Border.all(color: AppColors.glassBorder, width: 0.5),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.5),
              blurRadius: 15,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(AppRadius.md),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
            child: Container(
              color: AppColors.blurBackground,
              child: Stack(
                children: [
                  Row(
                    children: [
                      // Artwork
                      Container(
                        margin: const EdgeInsets.all(AppSpacing.xs),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(AppRadius.sm),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.3),
                              blurRadius: 4,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(AppRadius.sm),
                          child: currentTrack.localThumbnailPath != null
                              ? Image.file(
                                  File(currentTrack.localThumbnailPath!),
                                  width: 56,
                                  height: 56,
                                  fit: BoxFit.cover,
                                  errorBuilder: (context, error, stackTrace) =>
                                      _buildPlaceholder(),
                                )
                              : CachedNetworkImage(
                                  imageUrl: currentTrack.thumbnailUrl ?? '',
                                  width: 56,
                                  height: 56,
                                  fit: BoxFit.cover,
                                  errorWidget: (context, url, error) =>
                                      _buildPlaceholder(),
                                ),
                        ),
                      ),
                      const SizedBox(width: AppSpacing.sm),

                      // Info
                      Expanded(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            SizedBox(
                              height: 20,
                              child: currentTrack.title.length > 25
                                  ? Marquee(
                                      text: currentTrack.title,
                                      style: theme.textTheme.bodyLarge
                                          ?.copyWith(
                                              fontWeight: FontWeight.w600,
                                              color: AppColors.textPrimary),
                                      scrollAxis: Axis.horizontal,
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      blankSpace: 20.0,
                                      velocity: 30.0,
                                      startPadding: 0,
                                      accelerationDuration:
                                          const Duration(seconds: 1),
                                      accelerationCurve: Curves.linear,
                                      decelerationDuration:
                                          const Duration(milliseconds: 500),
                                      decelerationCurve: Curves.easeOut,
                                    )
                                  : Text(
                                      currentTrack.title,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: theme.textTheme.bodyLarge
                                          ?.copyWith(
                                              fontWeight: FontWeight.w600,
                                              color: AppColors.textPrimary),
                                    ),
                            ),
                            Text(
                              currentTrack.artist,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: theme.textTheme.bodyMedium
                                  ?.copyWith(color: AppColors.accentSecondary),
                            ),
                          ],
                        ),
                      ),

                      // Previous Button
                      IconButton(
                        icon: const Icon(Icons.skip_previous_rounded,
                            color: AppColors.textPrimary),
                        onPressed: () {
                          ref
                              .read(playerControllerProvider.notifier)
                              .playPrevious();
                        },
                      ),
                      // Play/Pause Button
                      IconButton(
                        icon: Icon(
                          playerState.isPlaying
                              ? Icons.pause_rounded
                              : Icons.play_arrow_rounded,
                          color: AppColors.textPrimary,
                          size: 32,
                        ),
                        onPressed: () {
                          ref
                              .read(playerControllerProvider.notifier)
                              .togglePlayPause();
                        },
                      ),
                      // Next Button
                      IconButton(
                        icon: const Icon(Icons.skip_next_rounded,
                            color: AppColors.textPrimary),
                        onPressed: () {
                          ref
                              .read(playerControllerProvider.notifier)
                              .playNext();
                        },
                      ),
                      const SizedBox(width: AppSpacing.xs),
                    ],
                  ),

                  // Progress Bar
                  Positioned(
                    bottom: 0,
                    left: 0,
                    right: 0,
                    child: Container(
                      height: 2,
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [
                            AppColors.accentPrimary,
                            AppColors.accentPrimaryVariant
                          ],
                        ),
                        borderRadius: BorderRadius.circular(2),
                      ),
                      child: FractionallySizedBox(
                        alignment: Alignment.centerLeft,
                        widthFactor: progress.clamp(0.0, 1.0),
                        child: Container(
                            color: Colors.white.withValues(alpha: 0.8)),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPlaceholder() {
    return Container(
      width: 56,
      height: 56,
      color: AppColors.surfaceOverlay,
      child: const Icon(Icons.music_note, color: AppColors.textTertiary),
    );
  }
}
