import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../shared/widgets/add_to_playlist_sheet.dart';
import '../../../../shared/widgets/app_artwork.dart';
import '../../../../shared/widgets/app_empty_state.dart';
import '../../data/repositories/track_repository_impl.dart';
import '../../domain/entities/track.dart';
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
    final t = AppColors.of(context);

    if (queue.isEmpty) {
      return const Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: EdgeInsets.fromLTRB(
              AppSpacing.lg,
              AppSpacing.md,
              AppSpacing.lg,
              0,
            ),
            child: _QueueHeader(
              count: 0,
              total: Duration.zero,
              onClear: null,
            ),
          ),
          Expanded(
            child: AppEmptyState(
              icon: Icons.queue_music_rounded,
              title: 'Antrean kosong',
            ),
          ),
        ],
      );
    }

    final hasCurrent = currentIndex >= 0 && currentIndex < queue.length;
    final current = hasCurrent ? queue[currentIndex] : null;
    final upNextStart = current != null ? currentIndex + 1 : 0;
    final upNext = queue.sublist(upNextStart);

    return CustomScrollView(
      slivers: [
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.lg,
            AppSpacing.md,
            AppSpacing.lg,
            0,
          ),
          sliver: SliverList(
            delegate: SliverChildListDelegate([
              _QueueHeader(
                count: queue.length,
                total: queue.fold<Duration>(
                  Duration.zero,
                  (sum, track) =>
                      sum + Duration(milliseconds: track.durationMs),
                ),
                onClear: upNext.isEmpty ? null : () => _clearUpNext(ref),
              ),
              if (current != null) ...[
                const SizedBox(height: AppSpacing.lg),
                _sectionLabel('NOW PLAYING', t),
                const SizedBox(height: AppSpacing.sm),
                _NowPlayingRow(
                  track: current,
                  queueIndex: currentIndex,
                ),
              ],
              if (upNext.isNotEmpty) ...[
                const SizedBox(height: AppSpacing.lg),
                Row(
                  children: [
                    Expanded(child: _sectionLabel('UP NEXT', t)),
                    Text(
                      '${upNext.length} songs',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: t.textSecondary,
                      ),
                    ),
                  ],
                ),
              ],
            ]),
          ),
        ),
        SliverPadding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
          sliver: SliverReorderableList(
            itemCount: upNext.length,
            onReorderItem: (oldIndex, newIndex) {
              ref.read(playerControllerProvider.notifier).reorderQueue(
                    upNextStart + oldIndex,
                    upNextStart + newIndex,
                  );
            },
            itemBuilder: (context, index) {
              final queueIndex = upNextStart + index;
              return Dismissible(
                key: ValueKey('${upNext[index].sourceId}_$queueIndex'),
                direction: DismissDirection.endToStart,
                background: Container(
                  alignment: Alignment.centerRight,
                  padding: const EdgeInsets.only(right: AppSpacing.lg),
                  color: t.raised,
                  child: Icon(Icons.delete, color: t.textPrimary),
                ),
                onDismissed: (_) {
                  ref
                      .read(playerControllerProvider.notifier)
                      .removeFromQueue(queueIndex);
                },
                child: _UpNextRow(
                  track: upNext[index],
                  queueIndex: queueIndex,
                  localIndex: index,
                ),
              );
            },
          ),
        ),
        if (upNext.isNotEmpty)
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.lg,
                AppSpacing.xl,
                AppSpacing.lg,
                AppSpacing.lg,
              ),
              child: Text(
                'Drag to reorder · Swipe to remove',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                  color: t.textSecondary,
                ),
              ),
            ),
          ),
      ],
    );
  }

  Future<void> _clearUpNext(WidgetRef ref) async {
    final controller = ref.read(playerControllerProvider.notifier);
    final currentIndex = ref.read(playerControllerProvider).currentIndex;
    final length = ref.read(playerControllerProvider).currentQueue.length;
    for (var index = length - 1; index > currentIndex; index--) {
      await controller.removeFromQueue(index);
    }
  }

  Widget _sectionLabel(String text, AppColorTokens t) {
    return Text(
      text,
      style: TextStyle(
        fontSize: 11,
        fontWeight: FontWeight.w500,
        letterSpacing: 1.1,
        color: t.textSecondary,
      ),
    );
  }

  static String _formatDuration(Duration d) {
    final minutes = d.inMinutes;
    final seconds = d.inSeconds.remainder(60);
    return '$minutes:${seconds.toString().padLeft(2, '0')}';
  }

  static String _formatTotal(Duration total) {
    final hours = total.inHours;
    final minutes = total.inMinutes.remainder(60);
    if (hours > 0 && minutes > 0) return '$hours hr $minutes min';
    if (hours > 0) return '$hours hr';
    return '${total.inMinutes} min';
  }
}

class _QueueHeader extends StatelessWidget {
  const _QueueHeader({
    required this.count,
    required this.total,
    required this.onClear,
  });

  final int count;
  final Duration total;
  final VoidCallback? onClear;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final t = AppColors.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                'Queue',
                style: theme.textTheme.titleLarge?.copyWith(
                  fontSize: 22,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            TextButton(
              onPressed: onClear,
              style: TextButton.styleFrom(
                foregroundColor: t.textPrimary,
                disabledForegroundColor: t.textMuted,
                minimumSize: const Size(48, 48),
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.sm,
                ),
                textStyle: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
              child: const Text('Clear'),
            ),
          ],
        ),
        Text(
          '$count songs · ${QueueView._formatTotal(total)}',
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: t.textSecondary,
          ),
        ),
      ],
    );
  }
}

class _NowPlayingRow extends ConsumerWidget {
  const _NowPlayingRow({
    required this.track,
    required this.queueIndex,
  });

  final Track track;
  final int queueIndex;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final t = AppColors.of(context);

    final row = Container(
      key: const Key('queue-now-playing'),
      constraints: const BoxConstraints(minHeight: 48),
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: AppSpacing.xs,
      ),
      decoration: BoxDecoration(
        color: t.raised,
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: t.border, width: 0.5),
      ),
      child: Row(
        children: [
          AppArtwork(
            key: const Key('queue-now-playing-artwork'),
            localPath: track.localThumbnailPath,
            imageUrl: track.thumbnailUrl,
            size: 48,
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
                    color: t.accent,
                  ),
                ),
                Text(
                  track.artist,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: t.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Text(
            QueueView._formatDuration(
              Duration(milliseconds: track.durationMs),
            ),
            style: TextStyle(
              fontSize: 12,
              color: t.textSecondary,
            ),
          ),
          _TrackOptions(track: track, queueIndex: queueIndex),
          // Decorative handle kept for the queue a11y contract (TASK-019).
          Semantics(
            label: 'Drag to reorder',
            container: true,
            child: SizedBox(
              width: 48,
              height: 48,
              child: Icon(Icons.drag_handle, color: t.textMuted),
            ),
          ),
        ],
      ),
    );

    return Semantics(
      container: true,
      label: 'Now playing',
      child: row,
    );
  }
}

class _UpNextRow extends ConsumerWidget {
  const _UpNextRow({
    required this.track,
    required this.queueIndex,
    required this.localIndex,
  });

  final Track track;
  final int queueIndex;
  final int localIndex;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final t = AppColors.of(context);

    return Material(
      color: Colors.transparent,
      child: ConstrainedBox(
        constraints: const BoxConstraints(minHeight: 64),
        child: InkWell(
          onTap: () {
            ref
                .read(playerControllerProvider.notifier)
                .skipToQueueItem(queueIndex);
          },
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.sm,
              vertical: AppSpacing.xs,
            ),
            child: Row(
              children: [
                AppArtwork(
                  key: Key('queue-up-next-artwork-$queueIndex'),
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
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: t.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                Text(
                  QueueView._formatDuration(
                    Duration(milliseconds: track.durationMs),
                  ),
                  style: TextStyle(
                    fontSize: 12,
                    color: t.textSecondary,
                  ),
                ),
                _TrackOptions(track: track, queueIndex: queueIndex),
                ReorderableDragStartListener(
                  index: localIndex,
                  child: Semantics(
                    label: 'Drag to reorder',
                    container: true,
                    child: SizedBox(
                      width: 48,
                      height: 48,
                      child: Icon(Icons.drag_handle, color: t.textMuted),
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

class _TrackOptions extends ConsumerWidget {
  const _TrackOptions({
    required this.track,
    required this.queueIndex,
  });

  final Track track;
  final int queueIndex;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = AppColors.of(context);
    final isPlaying =
        ref.read(playerControllerProvider).currentIndex == queueIndex;

    return MergeSemantics(
      child: Semantics(
        label: 'Track options',
        button: true,
        child: PopupMenuButton<String>(
          icon: Icon(Icons.more_vert, color: t.textSecondary),
          color: t.raised,
          onSelected: (value) {
            if (value == 'like') {
              if (isPlaying) {
                ref.read(playerControllerProvider.notifier).toggleLike();
              } else {
                final trackRepo = ref.read(trackRepositoryProvider);
                final updatedTrack = track.copyWith(isLiked: !track.isLiked);
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
                  .removeFromQueue(queueIndex);
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
    );
  }
}
