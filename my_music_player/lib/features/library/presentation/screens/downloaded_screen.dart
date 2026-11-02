import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dart:io';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_radius.dart';
import '../providers/downloaded_provider.dart';
import '../../../player/presentation/providers/player_controller.dart';
import '../../../cache/domain/usecases/cache_manager.dart';

class DownloadedScreen extends ConsumerWidget {
  const DownloadedScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final downloadedTracks = ref.watch(downloadedTracksProvider);
    final cacheManager = ref.watch(cacheManagerProvider);
    final playerState = ref.watch(playerControllerProvider);
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: AppColors.surfaceBase,
      appBar: AppBar(
        backgroundColor: AppColors.surfaceBase,
        title: Text('Downloaded',
            style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
      ),
      body: Column(
        children: [
          // Storage Indicator and List of tracks
          Expanded(
            child: downloadedTracks.when(
              data: (tracks) {
                int bytes = 0;
                for (var t in tracks) {
                  bytes += (t.fileSizeBytes ?? 0);
                }

                final double mbUsed = bytes / (1024 * 1024);
                final double maxMb = (cacheManager.maxCacheSizeBytes > 0
                        ? cacheManager.maxCacheSizeBytes
                        : 1) /
                    (1024 * 1024);
                final double progress = cacheManager.maxCacheSizeBytes > 0
                    ? (bytes / cacheManager.maxCacheSizeBytes).clamp(0.0, 1.0)
                    : 0.0;

                return Column(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(AppSpacing.md),
                      margin: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.md, vertical: AppSpacing.sm),
                      decoration: BoxDecoration(
                        color: AppColors.surfaceElevated,
                        borderRadius: BorderRadius.circular(AppRadius.lg),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text('Storage Used',
                                  style: theme.textTheme.bodyMedium?.copyWith(
                                      color: AppColors.textSecondary)),
                              Flexible(
                                child: Text(
                                    '${mbUsed.toStringAsFixed(1)} MB / ${maxMb.toStringAsFixed(0)} MB',
                                    style: theme.textTheme.bodyMedium?.copyWith(
                                        fontWeight: FontWeight.bold,
                                        color: AppColors.textPrimary),
                                    textAlign: TextAlign.right),
                              ),
                            ],
                          ),
                          const SizedBox(height: AppSpacing.sm),
                          LinearProgressIndicator(
                            value: progress,
                            backgroundColor: AppColors.surfaceOverlay,
                            color: progress > 0.9
                                ? AppColors.statusError
                                : AppColors.accentPrimary,
                            minHeight: 8,
                            borderRadius: BorderRadius.circular(AppRadius.full),
                          ),
                          if (progress > 0.9) ...[
                            const SizedBox(height: AppSpacing.xs),
                            Text(
                                'Storage is almost full. Old unpinned tracks will be removed automatically.',
                                style: theme.textTheme.bodySmall
                                    ?.copyWith(color: AppColors.statusWarning)),
                          ]
                        ],
                      ),
                    ),
                    Expanded(
                      child: tracks.isEmpty
                          ? Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.offline_pin_outlined,
                                      size: 64,
                                      color: AppColors.textTertiary
                                          .withValues(alpha: 0.5)),
                                  const SizedBox(height: AppSpacing.md),
                                  Text(
                                    'No downloaded tracks yet',
                                    style: theme.textTheme.titleMedium
                                        ?.copyWith(
                                            color: AppColors.textSecondary),
                                  ),
                                ],
                              ),
                            )
                          : ListView.builder(
                              padding: const EdgeInsets.only(
                                  left: AppSpacing.md,
                                  right: AppSpacing.md,
                                  top: AppSpacing.md,
                                  bottom: 160),
                              itemCount: tracks.length,
                              itemBuilder: (context, index) {
                                final track = tracks[index];
                                final isPlaying = track.sourceId ==
                                    playerState.currentTrack?.sourceId;
                                return Padding(
                                  padding: const EdgeInsets.only(
                                      bottom: AppSpacing.sm),
                                  child: ListTile(
                                    contentPadding:
                                        const EdgeInsets.all(AppSpacing.xs),
                                    shape: RoundedRectangleBorder(
                                      borderRadius:
                                          BorderRadius.circular(AppRadius.md),
                                    ),
                                    tileColor: AppColors.transparent,
                                    hoverColor: AppColors.surfaceHover,
                                    onTap: () {
                                      ref
                                          .read(
                                              playerControllerProvider.notifier)
                                          .playTrack(track, queue: tracks);
                                    },
                                    leading: ClipRRect(
                                      borderRadius:
                                          BorderRadius.circular(AppRadius.sm),
                                      child: track.localThumbnailPath != null
                                          ? Image.file(
                                              File(track.localThumbnailPath!),
                                              width: 56,
                                              height: 56,
                                              fit: BoxFit.cover,
                                              errorBuilder: (context, error,
                                                      stackTrace) =>
                                                  _buildFallbackThumbnail(),
                                            )
                                          : _buildFallbackThumbnail(),
                                    ),
                                    title: Row(
                                      children: [
                                        Expanded(
                                          child: Text(
                                            track.title,
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                            style: theme.textTheme.bodyLarge
                                                ?.copyWith(
                                                    fontWeight: FontWeight.w500,
                                                    color: isPlaying
                                                        ? AppColors
                                                            .accentPrimary
                                                        : AppColors
                                                            .textPrimary),
                                          ),
                                        ),
                                        const SizedBox(width: AppSpacing.xs),
                                        const Icon(Icons.offline_pin,
                                            color: AppColors.statusSuccess,
                                            size: 16),
                                      ],
                                    ),
                                    subtitle: Text(
                                      '${track.artist} • ${((track.fileSizeBytes ?? 0) / (1024 * 1024)).toStringAsFixed(1)} MB',
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: theme.textTheme.bodyMedium
                                          ?.copyWith(
                                              color: AppColors.textSecondary),
                                    ),
                                    trailing: IconButton(
                                      icon: const Icon(Icons.delete_outline,
                                          color: AppColors.textTertiary),
                                      onPressed: () async {
                                        await cacheManager
                                            .removeTrackFromCache(track);
                                        ref.invalidate(
                                            downloadedTracksProvider);
                                      },
                                    ),
                                  ),
                                );
                              },
                            ),
                    ),
                  ],
                );
              },
              loading: () => const Center(
                  child: CircularProgressIndicator(
                      color: AppColors.accentPrimary)),
              error: (err, stack) => Center(
                child: Text('Error: $err',
                    style: const TextStyle(color: AppColors.statusError)),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFallbackThumbnail() {
    return Container(
      width: 56,
      height: 56,
      color: AppColors.surfaceOverlay,
      child: const Icon(Icons.music_note, color: AppColors.textTertiary),
    );
  }
}
