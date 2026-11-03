import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_glass.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../../shared/widgets/add_to_playlist_sheet.dart';
import '../../../../shared/widgets/app_artwork.dart';
import '../../../../shared/widgets/app_empty_state.dart';
import '../../../../shared/widgets/glass_surface.dart';
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
    final l10n = AppLocalizations.of(context);

    if (queue.isEmpty) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Padding(
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
              title: l10n.queueEmpty,
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
                onClear: current != null && upNext.isNotEmpty
                    ? () => _confirmClearUpNext(context, ref)
                    : null,
              ),
              if (current != null) ...[
                const SizedBox(height: AppSpacing.lg),
                _nowPlayingSectionLabel(l10n, t),
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
                    Expanded(
                      child: _sectionLabel(l10n.queueUpNext, t),
                    ),
                    Text(
                      l10n.commonSongCount(upNext.length),
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
                l10n.queueDragHint,
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

  Future<void> _confirmClearUpNext(
    BuildContext context,
    WidgetRef ref,
  ) async {
    final state = ref.read(playerControllerProvider);
    final currentIndex = state.currentIndex;
    if (currentIndex < 0 || currentIndex >= state.currentQueue.length - 1) {
      return;
    }
    final upNext = state.currentQueue.sublist(currentIndex + 1);
    final tokens = AppColors.of(context);
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context);
    final count = upNext.length;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: tokens.raised,
        title: Text(
          l10n.queueClearTitle,
          style:
              theme.textTheme.titleMedium?.copyWith(color: tokens.textPrimary),
        ),
        content: Text(
          l10n.queueClearBody(count),
          style:
              theme.textTheme.bodyMedium?.copyWith(color: tokens.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(
              l10n.commonCancelAction,
              style: TextStyle(color: tokens.textSecondary),
            ),
          ),
          TextButton.icon(
            onPressed: () => Navigator.pop(ctx, true),
            icon: const Icon(Icons.delete_outline, size: 18),
            label: Text(
              l10n.queueClear,
              style: TextStyle(color: tokens.textPrimary),
            ),
          ),
        ],
      ),
    );

    if (confirmed != true || !context.mounted) return;

    final live = ref.read(playerControllerProvider);
    if (live.currentIndex != currentIndex) return;
    final snapshot = List<Track>.of(upNext);
    final controller = ref.read(playerControllerProvider.notifier);
    final length = live.currentQueue.length;
    for (var index = length - 1; index > currentIndex; index--) {
      await controller.removeFromQueue(index);
    }

    if (!context.mounted) return;
    final messenger = ScaffoldMessenger.of(context);
    messenger.hideCurrentSnackBar();
    messenger.showSnackBar(
      SnackBar(
        content: Text(l10n.queueCleared(count)),
        action: SnackBarAction(
          label: l10n.queueUndo,
          onPressed: () {
            // Re-appends the exact up-next snapshot. Playback is untouched:
            // no play/seek/restart path runs when the queue is non-empty.
            controller.addAllToQueue(snapshot);
          },
        ),
      ),
    );
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

  /// Icon + label so "now playing" is never conveyed by colour alone.
  Widget _nowPlayingSectionLabel(AppLocalizations l10n, AppColorTokens t) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        ExcludeSemantics(
          child: Icon(
            Icons.equalizer,
            size: 14,
            color: t.textSecondary,
          ),
        ),
        const SizedBox(width: AppSpacing.xxs),
        _sectionLabel(l10n.queueNowPlaying, t),
      ],
    );
  }

  static String _formatDuration(Duration d) {
    final minutes = d.inMinutes;
    final seconds = d.inSeconds.remainder(60);
    return '$minutes:${seconds.toString().padLeft(2, '0')}';
  }

  static String _formatTotal(
    AppLocalizations l10n,
    Duration total,
  ) {
    final hours = total.inHours;
    final minutes = total.inMinutes.remainder(60);
    if (hours > 0 && minutes > 0) {
      return l10n.playlistsDurationHoursMinutes(hours, minutes);
    }
    if (hours > 0) return l10n.commonDurationHours(hours);
    return l10n.playlistsDurationMinutes(total.inMinutes);
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
    final l10n = AppLocalizations.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                l10n.queueTitle,
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
                textStyle: theme.textTheme.labelLarge?.copyWith(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
              child: Text(l10n.queueClear),
            ),
          ],
        ),
        Text(
          l10n.queueSummary(
            count,
            QueueView._formatTotal(l10n, total),
          ),
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
    final l10n = AppLocalizations.of(context);

    final row = ConstrainedBox(
      constraints: const BoxConstraints(minHeight: 48),
      child: GlassSurface.chrome(
        key: const Key('queue-now-playing'),
        // Rows stay frosted: the queue scrolls, so it adds no blur layer.
        quality: GlassQuality.frosted,
        borderRadius: BorderRadius.circular(AppRadius.md),
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.sm,
          vertical: AppSpacing.xs,
        ),
        child: Material(
          color: Colors.transparent,
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
                label: l10n.queueDragToReorder,
                container: true,
                child: SizedBox(
                  width: 48,
                  height: 48,
                  child: Icon(Icons.drag_handle, color: t.textMuted),
                ),
              ),
            ],
          ),
        ),
      ),
    );

    return Semantics(
      container: true,
      label: l10n.browseNowPlaying,
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
    final l10n = AppLocalizations.of(context);

    return GlassSurface.card(
      key: Key('queue-up-next-glass-$queueIndex'),
      // Up-next rows scroll; frosted material keeps them blur-free.
      quality: GlassQuality.frosted,
      borderRadius: BorderRadius.circular(AppRadius.md),
      child: ConstrainedBox(
        constraints: const BoxConstraints(minHeight: 64),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(AppRadius.md),
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
                      label: l10n.queueDragToReorder,
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
    final l10n = AppLocalizations.of(context);
    final isPlaying =
        ref.read(playerControllerProvider).currentIndex == queueIndex;

    return MergeSemantics(
      child: Semantics(
        label: l10n.commonTrackOptions,
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
                          ? l10n.playlistAddedTo(l10n.libraryLikedSongs)
                          : l10n.queueRemovedFromPlaylist(
                              l10n.libraryLikedSongs,
                            ),
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
                track.isLiked ? l10n.playerUnlike : l10n.playerLike,
                style: TextStyle(color: t.textPrimary),
              ),
            ),
            PopupMenuItem(
              value: 'add_playlist',
              child: Text(
                l10n.playlistAddSheetTitle,
                style: TextStyle(color: t.textPrimary),
              ),
            ),
            PopupMenuItem(
              value: 'remove',
              child: Text(
                l10n.queueRemoveTrack,
                style: TextStyle(color: t.textPrimary),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
