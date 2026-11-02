import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../shared/widgets/app_artwork.dart';
import '../../../../shared/widgets/app_empty_state.dart';
import '../../../player/domain/entities/track.dart';
import '../../../player/presentation/providers/player_controller.dart';
import '../../domain/entities/daily_mix.dart';
import '../providers/mood_mix_provider.dart';
import '../widgets/mix_card.dart';

/// Detail screen for one Daily Mix mood (`/daily-mix/:mood`).
class DailyMixScreen extends ConsumerWidget {
  const DailyMixScreen({super.key, required this.mood});

  final DailyMixMood mood;

  String _formatDuration(int ms) {
    final duration = Duration(milliseconds: ms);
    final minutes = duration.inMinutes;
    final seconds = duration.inSeconds % 60;
    return '$minutes:${seconds.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tokens = AppColors.of(context);
    final theme = Theme.of(context);
    final mixAsync = ref.watch(moodMixProvider(mood));
    final playerState = ref.watch(playerControllerProvider);

    return Scaffold(
      backgroundColor: tokens.background,
      appBar: AppBar(
        backgroundColor: tokens.background,
        surfaceTintColor: tokens.background,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: tokens.textPrimary),
          tooltip: 'Back',
          onPressed: () {
            if (context.canPop()) {
              context.pop();
            } else {
              context.go('/');
            }
          },
        ),
      ),
      body: mixAsync.when(
        data: (mix) {
          if (mix.isEmpty) {
            return SingleChildScrollView(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.screenInset,
                vertical: AppSpacing.space6,
              ),
              child: AppEmptyState(
                icon: Icons.queue_music_rounded,
                title: 'No tracks for ${mood.label}',
                subtitle: 'Search for music or scan your device library.',
                actionLabel: 'Search',
                onAction: () => context.go('/search'),
                secondaryLabel: 'Scan device songs',
                onSecondaryAction: () => context.push('/library/device-songs'),
              ),
            );
          }

          return ListView(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.screenInset,
              AppSpacing.space2,
              AppSpacing.screenInset,
              AppSpacing.bottomPlayerPadding,
            ),
            children: [
              Center(
                child: MixArtwork(
                  mood: mood,
                  artworkUrls: mix.artworkUrls,
                  width: 160,
                  height: 160,
                ),
              ),
              const SizedBox(height: AppSpacing.space4),
              Center(
                child: Text(
                  mood.label,
                  textAlign: TextAlign.center,
                  style: theme.textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: tokens.textPrimary,
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.space1),
              Center(
                child: Text(
                  '${mix.tracks.length} tracks · Daily Mix',
                  textAlign: TextAlign.center,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: tokens.textSecondary,
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.space5),
              Center(
                child: FilledButton.icon(
                  onPressed: () => ref
                      .read(playerControllerProvider.notifier)
                      .playTrack(mix.tracks.first, queue: mix.tracks),
                  style: FilledButton.styleFrom(
                    backgroundColor: tokens.accent,
                    foregroundColor: tokens.onAccent,
                    minimumSize: const Size(0, 48),
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.space6,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppRadius.xxxl),
                    ),
                  ),
                  icon: const Icon(Icons.play_arrow_rounded),
                  label: const Text('Play all'),
                ),
              ),
              const SizedBox(height: AppSpacing.space6),
              for (final track in mix.tracks)
                Padding(
                  padding: const EdgeInsets.only(bottom: AppSpacing.space2),
                  child: _MixTrackTile(
                    track: track,
                    duration: _formatDuration(track.durationMs),
                    isCurrent:
                        playerState.currentTrack?.sourceId == track.sourceId,
                    onTap: () => ref
                        .read(playerControllerProvider.notifier)
                        .playTrack(track, queue: mix.tracks),
                  ),
                ),
            ],
          );
        },
        loading: () => Center(
          child: CircularProgressIndicator(color: tokens.accent),
        ),
        error: (error, stackTrace) => AppErrorState(
          error: error.toString(),
          onRetry: () => ref.invalidate(moodMixProvider(mood)),
        ),
      ),
    );
  }
}

class _MixTrackTile extends StatelessWidget {
  const _MixTrackTile({
    required this.track,
    required this.duration,
    required this.isCurrent,
    required this.onTap,
  });

  final Track track;
  final String duration;
  final bool isCurrent;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final tokens = AppColors.of(context);
    final theme = Theme.of(context);
    final radius = BorderRadius.circular(AppRadius.lg);

    return Container(
      constraints: const BoxConstraints(minHeight: 54),
      decoration: BoxDecoration(
        color: tokens.surface,
        borderRadius: radius,
        border: Border.all(color: tokens.border),
      ),
      child: Material(
        type: MaterialType.transparency,
        borderRadius: radius,
        child: InkWell(
          borderRadius: radius,
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.space3,
              vertical: AppSpacing.space2,
            ),
            child: Row(
              children: [
                AppArtwork(
                  localPath: track.localThumbnailPath,
                  imageUrl: track.thumbnailUrl,
                  size: 34,
                  radius: AppRadius.md,
                ),
                const SizedBox(width: AppSpacing.space3),
                Expanded(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        track.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w500,
                          color: isCurrent ? tokens.accent : tokens.textPrimary,
                        ),
                      ),
                      Text(
                        track.artist,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: tokens.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: AppSpacing.space2),
                Text(
                  duration,
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: tokens.textSecondary,
                    fontSize: 11,
                    letterSpacing: 0,
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
