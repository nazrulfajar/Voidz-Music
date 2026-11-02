import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../shared/widgets/app_empty_state.dart';
import '../../../cache/domain/usecases/cache_manager.dart';
import '../../../player/presentation/providers/player_controller.dart';
import '../providers/downloaded_provider.dart';

class DownloadedScreen extends ConsumerWidget {
  const DownloadedScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final downloadedTracks = ref.watch(downloadedTracksProvider);
    final cacheManager = ref.watch(cacheManagerProvider);
    final playerState = ref.watch(playerControllerProvider);
    final theme = Theme.of(context);
    final t = AppColors.of(context);

    return Scaffold(
      backgroundColor: t.background,
      appBar: AppBar(
        backgroundColor: t.background,
        title: Text(
          'Downloads',
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
            color: t.textPrimary,
          ),
        ),
      ),
      body: Column(
        children: [
          // Storage Indicator and List of tracks
          Expanded(
            child: downloadedTracks.when(
              data: (tracks) {
                int bytes = 0;
                for (var track in tracks) {
                  bytes += (track.fileSizeBytes ?? 0);
                }

                final double progress = cacheManager.maxCacheSizeBytes > 0
                    ? (bytes / cacheManager.maxCacheSizeBytes).clamp(0.0, 1.0)
                    : 0.0;
                final storageLabel = '${_formatBytes(bytes)} / '
                    '${_formatBytes(cacheManager.maxCacheSizeBytes)}';

                return Column(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(AppSpacing.md),
                      margin: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.md,
                        vertical: AppSpacing.sm,
                      ),
                      decoration: BoxDecoration(
                        color: t.surface,
                        borderRadius: BorderRadius.circular(AppRadius.lg),
                        border: Border.all(color: t.border),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(
                                child: Text(
                                  'Storage Used',
                                  style: theme.textTheme.bodyMedium?.copyWith(
                                    color: t.textSecondary,
                                  ),
                                ),
                              ),
                              Flexible(
                                child: Text(
                                  storageLabel,
                                  style: theme.textTheme.bodyMedium?.copyWith(
                                    fontWeight: FontWeight.bold,
                                    color: t.textPrimary,
                                  ),
                                  textAlign: TextAlign.right,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: AppSpacing.sm),
                          LinearProgressIndicator(
                            value: progress,
                            backgroundColor: t.track,
                            color: t.accent,
                            minHeight: 8,
                            borderRadius: BorderRadius.circular(AppRadius.full),
                          ),
                          if (progress > 0.9) ...[
                            const SizedBox(height: AppSpacing.xs),
                            Row(
                              children: [
                                Icon(
                                  Icons.warning_amber_rounded,
                                  size: 16,
                                  color: t.textPrimary,
                                ),
                                const SizedBox(width: AppSpacing.xs),
                                Expanded(
                                  child: Text(
                                    'Storage is almost full. Old unpinned '
                                    'tracks will be removed automatically.',
                                    style: theme.textTheme.bodySmall?.copyWith(
                                      color: t.textPrimary,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ],
                      ),
                    ),
                    Expanded(
                      child: tracks.isEmpty
                          ? const AppEmptyState(
                              icon: Icons.offline_pin_outlined,
                              title: 'No downloaded tracks yet',
                            )
                          : ListView.builder(
                              padding: const EdgeInsets.only(
                                left: AppSpacing.md,
                                right: AppSpacing.md,
                                top: AppSpacing.md,
                                bottom: 160,
                              ),
                              itemCount: tracks.length,
                              itemBuilder: (context, index) {
                                final track = tracks[index];
                                final isPlaying = track.sourceId ==
                                    playerState.currentTrack?.sourceId;
                                return Padding(
                                  padding: const EdgeInsets.only(
                                    bottom: AppSpacing.sm,
                                  ),
                                  child: ListTile(
                                    contentPadding:
                                        const EdgeInsets.all(AppSpacing.xs),
                                    shape: RoundedRectangleBorder(
                                      borderRadius:
                                          BorderRadius.circular(AppRadius.md),
                                    ),
                                    tileColor: Colors.transparent,
                                    hoverColor: t.well,
                                    onTap: () {
                                      ref
                                          .read(
                                            playerControllerProvider.notifier,
                                          )
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
                                                  _buildFallbackThumbnail(t),
                                            )
                                          : _buildFallbackThumbnail(t),
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
                                                  ? t.accent
                                                  : t.textPrimary,
                                            ),
                                          ),
                                        ),
                                        const SizedBox(width: AppSpacing.xs),
                                        Semantics(
                                          label: 'Downloaded',
                                          child: Icon(
                                            Icons.offline_pin,
                                            color: t.textPrimary,
                                            size: 16,
                                          ),
                                        ),
                                      ],
                                    ),
                                    subtitle: Text(
                                      '${track.artist} • '
                                      '${((track.fileSizeBytes ?? 0) / (1024 * 1024)).toStringAsFixed(1)} MB',
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: theme.textTheme.bodyMedium
                                          ?.copyWith(color: t.textSecondary),
                                    ),
                                    trailing: IconButton(
                                      tooltip: 'Remove download',
                                      icon: Icon(
                                        Icons.delete_outline,
                                        color: t.textSecondary,
                                      ),
                                      onPressed: () async {
                                        await cacheManager
                                            .removeTrackFromCache(track);
                                        ref.invalidate(
                                          downloadedTracksProvider,
                                        );
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
              loading: () => Center(
                child: CircularProgressIndicator(color: t.accent),
              ),
              error: (err, stack) => AppErrorState(
                error: 'Failed to load downloads',
                onRetry: () => ref.invalidate(downloadedTracksProvider),
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _formatBytes(int bytes) {
    const gb = 1024 * 1024 * 1024;
    if (bytes >= gb) {
      final value = (bytes / gb).toStringAsFixed(1);
      final trimmed =
          value.endsWith('.0') ? value.substring(0, value.length - 2) : value;
      return '$trimmed GB';
    }
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }

  Widget _buildFallbackThumbnail(AppColorTokens t) {
    return Container(
      width: 56,
      height: 56,
      color: t.raised,
      child: Icon(Icons.music_note, color: t.textMuted),
    );
  }
}
