import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dart:io';
import 'dart:ui';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_radius.dart';
import '../providers/player_controller.dart';
import '../../data/repositories/track_repository_impl.dart';
import '../../../../shared/widgets/add_to_playlist_sheet.dart';

class QueueView extends ConsumerWidget {
  const QueueView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Ponytail: hanya rebuild saat queue/index berubah, tidak saat position/duration (lag local)
    final queue = ref.watch(playerControllerProvider.select((s) => s.currentQueue));
    final currentIndex = ref.watch(playerControllerProvider.select((s) => s.currentIndex));
    final theme = Theme.of(context);

    if (queue.isEmpty) {
      return Center(
        child: Text(
          'Antrean kosong',
          style: theme.textTheme.bodyMedium
              ?.copyWith(color: AppColors.textSecondary),
        ),
      );
    }

    // Show the entire queue
    return ReorderableListView.builder(
      padding: const EdgeInsets.all(AppSpacing.md),
      itemCount: queue.length,
      onReorder: (oldIndex, newIndex) {
        ref
            .read(playerControllerProvider.notifier)
            .reorderQueue(oldIndex, newIndex);
      },
      itemBuilder: (context, index) {
        final track = queue[index];
        final isPlaying = index == currentIndex;

        final tile = ListTile(
          onTap: () {
            ref.read(playerControllerProvider.notifier).skipToQueueItem(index);
          },
          contentPadding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.sm, vertical: AppSpacing.xs),
          tileColor: Colors.transparent,
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppRadius.md)),
          leading: ClipRRect(
            borderRadius: BorderRadius.circular(AppRadius.sm),
            child: track.localThumbnailPath != null
                ? Image.file(
                    File(track.localThumbnailPath!),
                    width: 48,
                    height: 48,
                    fit: BoxFit.cover,
                    cacheWidth: 100,
                    errorBuilder: (_, __, ___) => track.thumbnailUrl != null
                        ? Image(
                            image: CachedNetworkImageProvider(track.thumbnailUrl!),
                            width: 48,
                            height: 48,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => Container(width: 48, height: 48, color: AppColors.surfaceOverlay, child: const Icon(Icons.music_note, color: AppColors.textTertiary)),
                          )
                        : Container(width: 48, height: 48, color: AppColors.surfaceOverlay, child: const Icon(Icons.music_note, color: AppColors.textTertiary)),
                  )
                : track.thumbnailUrl != null
                    ? CachedNetworkImage(
                        imageUrl: track.thumbnailUrl!,
                        width: 48,
                        height: 48,
                        memCacheWidth: 100,
                        fit: BoxFit.cover,
                        placeholder: (_, __) => Container(width: 48, height: 48, color: AppColors.surfaceOverlay),
                        errorWidget: (_, __, ___) => Container(width: 48, height: 48, color: AppColors.surfaceOverlay, child: const Icon(Icons.music_note, color: AppColors.textTertiary)),
                      )
                    : Container(width: 48, height: 48, decoration: BoxDecoration(color: AppColors.surfaceOverlay, borderRadius: BorderRadius.circular(AppRadius.sm)), child: const Icon(Icons.music_note, color: AppColors.textTertiary)),
          ),
          title: Text(
            track.title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: theme.textTheme.bodyLarge?.copyWith(
              fontWeight: isPlaying ? FontWeight.bold : FontWeight.normal,
              color:
                  isPlaying ? AppColors.accentPrimary : AppColors.textPrimary,
            ),
          ),
          subtitle: Text(
            track.artist,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: theme.textTheme.bodyMedium
                ?.copyWith(color: AppColors.textSecondary),
          ),
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (isPlaying)
                const Icon(Icons.equalizer, color: AppColors.accentPrimary),
              PopupMenuButton<String>(
                icon:
                    const Icon(Icons.more_vert, color: AppColors.textSecondary),
                color: AppColors.surfaceElevated,
                onSelected: (value) {
                  if (value == 'like') {
                    if (isPlaying) {
                      ref.read(playerControllerProvider.notifier).toggleLike();
                    } else {
                      final trackRepo = ref.read(trackRepositoryProvider);
                      final updatedTrack =
                          track.copyWith(isLiked: !track.isLiked);
                      trackRepo.updateTrack(updatedTrack);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                            content: Text(
                                updatedTrack.isLiked
                                    ? 'Added to Liked Songs'
                                    : 'Removed from Liked Songs',
                                style: const TextStyle(
                                    color: AppColors.textPrimary)),
                            backgroundColor: AppColors.surfaceOverlay),
                      );
                    }
                  } else if (value == 'add_playlist') {
                    showAddToPlaylistSheet(context, track: track);
                  }
                },
                itemBuilder: (context) => [
                  PopupMenuItem(
                    value: 'like',
                    child: Text(track.isLiked ? 'Unlike' : 'Like',
                        style: const TextStyle(color: AppColors.textPrimary)),
                  ),
                  const PopupMenuItem(
                    value: 'add_playlist',
                    child: Text('Add to Playlist',
                        style: TextStyle(color: AppColors.textPrimary)),
                  ),
                ],
              ),
              const SizedBox(width: AppSpacing.md),
              const Icon(Icons.drag_handle,
                  color: AppColors.textTertiary), // Drag handle icon
            ],
          ),
        );

        return Dismissible(
          key: ValueKey('${track.sourceId}_$index'),
          direction: DismissDirection.endToStart,
          background: Container(
            alignment: Alignment.centerRight,
            padding: const EdgeInsets.only(right: AppSpacing.lg),
            color: AppColors.statusError.withValues(alpha: 0.8),
            child: const Icon(Icons.delete, color: Colors.white),
          ),
          onDismissed: (direction) {
            ref.read(playerControllerProvider.notifier).removeFromQueue(index);
          },
          child: Material(
            color: Colors.transparent,
            child: isPlaying
                ? Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(AppRadius.md),
                      border:
                          Border.all(color: AppColors.glassBorder, width: 0.5),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.3),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(AppRadius.md),
                      child: BackdropFilter(
                        filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
                        child: Material(
                          color: AppColors.blurBackground,
                          child: tile,
                        ),
                      ),
                    ),
                  )
                : tile,
          ),
        );
      },
    );
  }
}
