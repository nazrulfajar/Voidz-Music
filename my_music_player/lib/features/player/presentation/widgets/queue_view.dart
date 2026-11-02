import 'dart:io';
import 'dart:ui';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../shared/widgets/add_to_playlist_sheet.dart';
import '../../../../shared/widgets/app_empty_state.dart';
import '../../data/repositories/track_repository_impl.dart';
import '../providers/player_controller.dart';

class QueueView extends ConsumerWidget {
  const QueueView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Ponytail: hanya rebuild saat queue/index berubah, tidak saat
    // position/duration (lag local)
    final queue =
        ref.watch(playerControllerProvider.select((s) => s.currentQueue));
    final currentIndex =
        ref.watch(playerControllerProvider.select((s) => s.currentIndex));
    final theme = Theme.of(context);
    final t = AppColors.of(context);

    if (queue.isEmpty) {
      return const AppEmptyState(
        icon: Icons.queue_music_rounded,
        title: 'Antrean kosong',
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
            horizontal: AppSpacing.sm,
            vertical: AppSpacing.xs,
          ),
          tileColor: Colors.transparent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.md),
          ),
          leading: ClipRRect(
            borderRadius: BorderRadius.circular(AppRadius.sm),
            child: track.localThumbnailPath != null
                ? Image.file(
                    File(track.localThumbnailPath!),
                    width: 48,
                    height: 48,
                    fit: BoxFit.cover,
                    cacheWidth: 100,
                    errorBuilder: (_, __, ___) =>
                        _thumbnailFallback(t, track.thumbnailUrl),
                  )
                : _thumbnailFallback(t, track.thumbnailUrl),
          ),
          title: Text(
            track.title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: theme.textTheme.bodyLarge?.copyWith(
              fontWeight: isPlaying ? FontWeight.bold : FontWeight.normal,
              color: isPlaying ? t.accent : t.textPrimary,
            ),
          ),
          subtitle: Text(
            track.artist,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: t.textSecondary,
            ),
          ),
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (isPlaying)
                Semantics(
                  label: 'Now playing',
                  child: Icon(Icons.equalizer, color: t.accent),
                ),
              MergeSemantics(
                child: Semantics(
                  label: 'Track options',
                  button: true,
                  child: PopupMenuButton<String>(
                    icon: Icon(Icons.more_vert, color: t.textSecondary),
                    color: t.raised,
                    onSelected: (value) {
                      if (value == 'like') {
                        if (isPlaying) {
                          ref
                              .read(playerControllerProvider.notifier)
                              .toggleLike();
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
                              ),
                            ),
                          );
                        }
                      } else if (value == 'add_playlist') {
                        showAddToPlaylistSheet(context, track: track);
                      } else if (value == 'remove') {
                        ref
                            .read(playerControllerProvider.notifier)
                            .removeFromQueue(index);
                      }
                    },
                    itemBuilder: (context) => [
                      PopupMenuItem(
                        value: 'like',
                        child: Text(
                          track.isLiked ? 'Unlike' : 'Like',
                          style: TextStyle(color: t.textPrimary),
                        ),
                      ),
                      PopupMenuItem(
                        value: 'add_playlist',
                        child: Text(
                          'Add to Playlist',
                          style: TextStyle(color: t.textPrimary),
                        ),
                      ),
                      PopupMenuItem(
                        value: 'remove',
                        child: Text(
                          'Remove from queue',
                          style: TextStyle(color: t.textPrimary),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              // Swipe-to-remove has a labelled menu alternative; the handle is
              // announced so reordering is discoverable.
              Semantics(
                label: 'Drag to reorder',
                container: true,
                child: SizedBox(
                  width: 48,
                  height: 48,
                  child: Icon(
                    Icons.drag_handle,
                    color: t.textMuted,
                  ),
                ),
              ),
            ],
          ),
        );

        return Dismissible(
          key: ValueKey('${track.sourceId}_$index'),
          direction: DismissDirection.endToStart,
          background: Container(
            alignment: Alignment.centerRight,
            padding: const EdgeInsets.only(right: AppSpacing.lg),
            color: t.raised,
            child: Icon(Icons.delete, color: t.textPrimary),
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
                      border: Border.all(color: t.border, width: 0.5),
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
                          color: t.background.withValues(alpha: 0.9),
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

  Widget _thumbnailFallback(AppColorTokens t, String? thumbnailUrl) {
    final placeholder = Container(
      width: 48,
      height: 48,
      color: t.raised,
      child: Icon(Icons.music_note, color: t.textMuted),
    );

    if (thumbnailUrl == null) return placeholder;

    return CachedNetworkImage(
      imageUrl: thumbnailUrl,
      width: 48,
      height: 48,
      memCacheWidth: 100,
      fit: BoxFit.cover,
      placeholder: (_, __) => placeholder,
      errorWidget: (_, __, ___) => placeholder,
    );
  }
}
