import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../shared/widgets/add_to_playlist_sheet.dart';
import '../../../../shared/widgets/app_artwork.dart';
import '../../../../shared/widgets/app_empty_state.dart';
import '../../../../shared/widgets/app_icon_button.dart';
import '../../../../shared/widgets/playlist_mosaic_cover.dart';
import '../../../player/domain/entities/track.dart';
import '../../../player/presentation/providers/player_controller.dart';
import '../../data/repositories/playlist_repository_impl.dart';
import '../../domain/entities/playlist.dart';
import '../providers/playlist_detail_provider.dart';
import '../providers/playlist_provider.dart';

/// Premium: deep-link safe.
/// Accepts `playlistId` (path param) + optional `initialPlaylist` hint from
/// `extra`. Falls back to legacy `playlist` ctor for backward-compat.
/// If no hint or id mismatch, fetches via `playlistByIdProvider`.
class PlaylistDetailScreen extends ConsumerWidget {
  final Playlist? playlist; // legacy — prefer playlistId
  final int? playlistId;
  final String? playlistIdStr;
  final Playlist? initialPlaylist;

  const PlaylistDetailScreen({
    super.key,
    this.playlist,
    this.playlistId,
    this.playlistIdStr,
    this.initialPlaylist,
  });

  /// Legacy convenience: `PlaylistDetailScreen(playlist: p)`
  factory PlaylistDetailScreen.fromPlaylist(Playlist p) =>
      PlaylistDetailScreen(playlist: p);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Resolve effective playlist hint
    final hint = playlist ?? initialPlaylist;
    final id = playlistId ?? hint?.id ?? int.tryParse(playlistIdStr ?? '');

    // If we have a hint and it matches the requested id (or no id requested),
    // use it directly — no fetch
    final bool canUseHint =
        hint != null && (id == null || hint.id == id || hint.isSystem);
    if (canUseHint) {
      return _PlaylistDetailBody(playlist: hint);
    }

    // Need to fetch by id — deep-link / restoration path
    if (id == null) {
      return _messageScaffold(
        context,
        title: 'Playlist not found',
      );
    }

    // Virtual playlists have synthetic id -1 and can't be fetched by id alone
    // — the hint above already resolves them.
    if (id == -1 && hint != null) {
      return _PlaylistDetailBody(playlist: hint);
    }

    final playlistAsync = ref.watch(playlistByIdProvider(id));
    return playlistAsync.when(
      data: (fetched) {
        if (fetched == null) {
          // fallback to hint if fetch misses (e.g. deleted)
          if (hint != null) return _PlaylistDetailBody(playlist: hint);
          return _messageScaffold(context, title: 'Playlist not found');
        }
        return _PlaylistDetailBody(playlist: fetched);
      },
      loading: () {
        final t = AppColors.of(context);
        return Scaffold(
          backgroundColor: t.background,
          body: Center(
            child: CircularProgressIndicator(color: t.accent),
          ),
        );
      },
      error: (e, st) => _messageScaffold(context, title: 'Error: $e'),
    );
  }

  Widget _messageScaffold(
    BuildContext context, {
    required String title,
  }) {
    final t = AppColors.of(context);
    return Scaffold(
      backgroundColor: t.background,
      appBar: AppBar(
        backgroundColor: t.background,
        elevation: 0,
        leading: IconButton(
          tooltip: 'Back',
          icon: Icon(Icons.arrow_back, color: t.textPrimary),
          onPressed: () => context.pop(),
        ),
        title: Text(
          'Playlist',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.w700,
            color: t.textPrimary,
          ),
        ),
      ),
      body: Center(
        child: Text(
          title,
          style: TextStyle(color: t.textSecondary),
        ),
      ),
    );
  }
}

class _PlaylistDetailBody extends ConsumerWidget {
  final Playlist playlist;
  const _PlaylistDetailBody({required this.playlist});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = AppColors.of(context);
    final tracksAsync = ref.watch(playlistTracksProvider(playlist));
    final playingId = ref.watch(
      playerControllerProvider.select((state) => state.currentTrack?.sourceId),
    );

    final loadedTracks = tracksAsync.valueOrNull;
    final count = loadedTracks?.length ?? playlist.trackCount;
    final totalMs = loadedTracks?.fold<int>(
      0,
      (sum, track) => sum + track.durationMs,
    );

    final header = _buildHeaderContent(
      context: context,
      ref: ref,
      t: t,
      tracks: loadedTracks ?? const <Track>[],
      count: count,
      totalMs: totalMs,
    );

    return Scaffold(
      backgroundColor: t.background,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            _buildTopBar(context, ref, t, count: count, totalMs: totalMs),
            Expanded(
              child: tracksAsync.when(
                data: (tracks) {
                  if (tracks.isEmpty) {
                    return ListView(
                      padding: const EdgeInsets.only(
                        bottom: AppSpacing.bottomPlayerPadding,
                      ),
                      children: [
                        header,
                        const SizedBox(height: AppSpacing.space10),
                        AppEmptyState(
                          icon: Icons.queue_music_rounded,
                          title: 'Playlist is empty',
                          subtitle: playlist.isSystem
                              ? 'Tracks will appear here automatically'
                              : 'Add songs to start listening',
                          actionLabel: 'Search music',
                          onAction: () => context.push('/search'),
                        ),
                      ],
                    );
                  }

                  if (playlist.isSystem) {
                    return ListView.builder(
                      padding: const EdgeInsets.only(
                        bottom: AppSpacing.bottomPlayerPadding,
                      ),
                      itemCount: tracks.length + 1,
                      itemBuilder: (context, index) {
                        if (index == 0) return header;
                        final track = tracks[index - 1];
                        return _rowPadding(
                          _PlaylistTrackRow(
                            track: track,
                            isPlaying: track.sourceId == playingId,
                            isSystem: true,
                            onTap: () => ref
                                .read(playerControllerProvider.notifier)
                                .playTrack(track, queue: tracks),
                            onRemove: () {},
                          ),
                        );
                      },
                    );
                  }

                  return ReorderableListView.builder(
                    header: header,
                    padding: const EdgeInsets.only(
                      bottom: AppSpacing.bottomPlayerPadding,
                    ),
                    buildDefaultDragHandles: true,
                    itemCount: tracks.length,
                    onReorder: (oldIndex, newIndex) async {
                      if (oldIndex < newIndex) {
                        newIndex -= 1;
                      }
                      final track = tracks.removeAt(oldIndex);
                      tracks.insert(newIndex, track);

                      final id = playlist.id;
                      if (id == null) return;
                      await ref
                          .read(playlistRepositoryProvider)
                          .reorderTracks(id, oldIndex, newIndex);
                    },
                    itemBuilder: (context, index) {
                      final track = tracks[index];
                      return Padding(
                        key: ValueKey(
                          'playlist-reorder-${track.sourceId}-$index',
                        ),
                        padding: const EdgeInsets.only(
                          bottom: AppSpacing.space2,
                        ),
                        child: _PlaylistTrackRow(
                          track: track,
                          isPlaying: track.sourceId == playingId,
                          isSystem: false,
                          onTap: () => ref
                              .read(playerControllerProvider.notifier)
                              .playTrack(track, queue: tracks),
                          onRemove: () => _removeTrack(ref, track),
                        ),
                      );
                    },
                  );
                },
                loading: () => ListView(
                  padding: const EdgeInsets.only(
                    bottom: AppSpacing.bottomPlayerPadding,
                  ),
                  children: [
                    header,
                    const SizedBox(height: AppSpacing.space10),
                    Center(
                      child: CircularProgressIndicator(color: t.accent),
                    ),
                  ],
                ),
                error: (e, st) => ListView(
                  padding: const EdgeInsets.only(
                    bottom: AppSpacing.bottomPlayerPadding,
                  ),
                  children: [
                    header,
                    const SizedBox(height: AppSpacing.space8),
                    Center(
                      child: Text(
                        'Error: $e',
                        style: TextStyle(color: t.textSecondary),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _rowPadding(Widget child) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.screenInset,
        0,
        AppSpacing.screenInset,
        AppSpacing.space2,
      ),
      child: child,
    );
  }

  Widget _buildTopBar(
    BuildContext context,
    WidgetRef ref,
    AppColorTokens t, {
    required int count,
    required int? totalMs,
  }) {
    final subtitle = playlist.isSystem
        ? '$count songs · ${_formatTotalDuration(totalMs)}'
        : 'Your collection, your soundtrack';

    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.screenInset,
        AppSpacing.space3,
        AppSpacing.screenInset,
        AppSpacing.space4,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _CircleAction(
                icon: Icons.arrow_back,
                tooltip: 'Back',
                onPressed: () => context.pop(),
              ),
              const SizedBox(width: AppSpacing.space3),
              Expanded(
                child: Text(
                  'Playlist',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w700,
                    color: t.textPrimary,
                  ),
                ),
              ),
              _PlaylistOptionsButton(
                key: const Key('playlist-options'),
                tooltip: 'Playlist options',
                isSystem: playlist.isSystem,
                onDelete: () => _confirmDelete(context, ref),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.space2),
          Text(
            subtitle,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(fontSize: 12, color: t.textSecondary),
          ),
        ],
      ),
    );
  }

  Widget _buildHeaderContent({
    required BuildContext context,
    required WidgetRef ref,
    required AppColorTokens t,
    required List<Track> tracks,
    required int count,
    required int? totalMs,
  }) {
    final canPlay = tracks.isNotEmpty;
    final overline = playlist.isSystem ? 'AUTO-PLAYLIST' : 'PLAYLIST';
    final owner = playlist.isSystem ? '$count songs' : 'You · $count songs';
    final updated = playlist.isSystem
        ? ''
        : ' · updated ${_relativeTime(playlist.updatedAt)}';
    final duration = _formatTotalDuration(totalMs);
    final meta =
        (totalMs == null || totalMs <= 0) ? duration : '$duration$updated';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.screenInset,
          ),
          child: Container(
            key: const Key('playlist-summary'),
            padding: const EdgeInsets.all(AppSpacing.space4),
            decoration: BoxDecoration(
              color: t.row,
              borderRadius: BorderRadius.circular(AppRadius.xxxl),
              border: Border.all(color: t.border),
            ),
            child: LayoutBuilder(
              builder: (context, constraints) {
                final stacked =
                    MediaQuery.textScalerOf(context).scale(1) > 1.4 ||
                        constraints.maxWidth < 280;
                final cover = ClipRRect(
                  borderRadius: BorderRadius.circular(AppRadius.xxxl),
                  child: PlaylistMosaicCover(
                    imageUrls: playlist.thumbnailUrls,
                    size: 120,
                    defaultIcon: _defaultIcon,
                    iconColor: t.textSecondary,
                  ),
                );
                final info = Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      overline,
                      style: AppTypography.overline(t),
                    ),
                    const SizedBox(height: AppSpacing.space1),
                    Text(
                      playlist.name,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                        color: t.textPrimary,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.space1),
                    Text(
                      owner,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 12,
                        color: t.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      meta,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 11,
                        color: t.textSecondary,
                      ),
                    ),
                  ],
                );

                if (stacked) {
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      cover,
                      const SizedBox(height: AppSpacing.space4),
                      info,
                    ],
                  );
                }
                return Row(
                  children: [
                    cover,
                    const SizedBox(width: AppSpacing.space3),
                    Expanded(child: info),
                  ],
                );
              },
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.space4),
        Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.screenInset,
          ),
          child: _buildActions(context, ref, t, tracks, canPlay),
        ),
        const SizedBox(height: AppSpacing.space6),
        Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.screenInset,
          ),
          child: Text('TRACKS', style: AppTypography.overline(t)),
        ),
        const SizedBox(height: AppSpacing.space2),
      ],
    );
  }

  Widget _buildActions(
    BuildContext context,
    WidgetRef ref,
    AppColorTokens t,
    List<Track> tracks,
    bool canPlay,
  ) {
    final largeText = MediaQuery.textScalerOf(context).scale(1) > 1.4;

    Widget playAll({bool expanded = false}) {
      final button = FilledButton.icon(
        key: const Key('play-all'),
        onPressed: canPlay
            ? () => ref
                .read(playerControllerProvider.notifier)
                .playTrack(tracks.first, queue: tracks)
            : null,
        icon: const Icon(Icons.play_arrow_rounded, size: 20),
        label: const Text('Play all'),
        style: FilledButton.styleFrom(
          backgroundColor: t.accent,
          foregroundColor: t.onAccent,
          disabledBackgroundColor: t.raised,
          disabledForegroundColor: t.textMuted,
          minimumSize: const Size(0, 48),
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.space5,
          ),
          shape: const StadiumBorder(),
          textStyle: Theme.of(context).textTheme.labelLarge?.copyWith(
                fontWeight: FontWeight.w600,
              ),
        ),
      );
      if (!expanded) return button;
      return SizedBox(width: double.infinity, child: button);
    }

    final shuffle = _CircleAction(
      icon: Icons.shuffle_rounded,
      tooltip: 'Shuffle',
      onPressed: canPlay
          ? () {
              final shuffled = List<Track>.of(tracks)..shuffle();
              ref
                  .read(playerControllerProvider.notifier)
                  .playTrack(shuffled.first, queue: shuffled);
            }
          : null,
    );
    final more = _PlaylistOptionsButton(
      key: const Key('playlist-actions-more'),
      tooltip: 'More options',
      isSystem: playlist.isSystem,
      onDelete: () => _confirmDelete(context, ref),
    );

    if (largeText) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          playAll(expanded: true),
          const SizedBox(height: AppSpacing.space3),
          Row(
            children: [
              shuffle,
              const Spacer(),
              more,
            ],
          ),
        ],
      );
    }

    return Row(
      children: [
        playAll(),
        const SizedBox(width: AppSpacing.space3),
        shuffle,
        const Spacer(),
        more,
      ],
    );
  }

  IconData get _defaultIcon {
    if (!playlist.isSystem) return Icons.queue_music_rounded;
    switch (playlist.name) {
      case 'Liked Songs':
        return Icons.favorite_rounded;
      case 'Recently Played':
        return Icons.history_rounded;
      case 'Downloaded':
        return Icons.download_rounded;
      default:
        return Icons.queue_music_rounded;
    }
  }

  Future<void> _removeTrack(WidgetRef ref, Track track) async {
    final id = playlist.id;
    if (id == null) return;
    await ref
        .read(playlistRepositoryProvider)
        .removeTrackFromPlaylist(id, track.sourceId);
    ref.invalidate(playlistTracksProvider(playlist));
    ref.invalidate(allPlaylistsProvider);
  }

  Future<void> _confirmDelete(BuildContext context, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        final dt = AppColors.of(dialogContext);
        return AlertDialog(
          backgroundColor: dt.row,
          surfaceTintColor: Colors.transparent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.xxl),
          ),
          title: Text(
            'Delete Playlist?',
            style: TextStyle(color: dt.textPrimary),
          ),
          content: Text(
            'This playlist will be permanently deleted.',
            style: TextStyle(color: dt.textSecondary),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: Text(
                'Cancel',
                style: TextStyle(color: dt.textSecondary),
              ),
            ),
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, true),
              child: Text(
                'Delete',
                style: TextStyle(color: dt.textPrimary),
              ),
            ),
          ],
        );
      },
    );

    if (confirmed != true) return;
    final id = playlist.id;
    if (id == null) return;

    await ref.read(playlistRepositoryProvider).deletePlaylist(id);
    ref.invalidate(allPlaylistsProvider);
    if (context.mounted) context.pop();
  }
}

class _PlaylistTrackRow extends StatelessWidget {
  final Track track;
  final bool isPlaying;
  final bool isSystem;
  final VoidCallback onTap;
  final VoidCallback onRemove;

  const _PlaylistTrackRow({
    required this.track,
    required this.isPlaying,
    required this.isSystem,
    required this.onTap,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    final t = AppColors.of(context);
    final meta = '${track.artist} · ${_formatTrackDuration(track.durationMs)}';

    return Material(
      key: ValueKey('playlist-track-${track.sourceId}'),
      color: isPlaying ? t.raised : t.row,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.xl),
        side: BorderSide(color: t.border),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Container(
          constraints: const BoxConstraints(minHeight: 72),
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.space3,
            vertical: AppSpacing.space3,
          ),
          child: Row(
            children: [
              AppArtwork(
                localPath: track.localThumbnailPath,
                imageUrl: track.thumbnailUrl,
                size: 44,
                radius: AppRadius.md,
              ),
              const SizedBox(width: AppSpacing.space4),
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      track.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: t.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      meta,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 12,
                        color: t.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: AppSpacing.space2),
              _TrackOptionsButton(
                track: track,
                isSystem: isSystem,
                onRemove: onRemove,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TrackOptionsButton extends StatelessWidget {
  final Track track;
  final bool isSystem;
  final VoidCallback onRemove;

  const _TrackOptionsButton({
    required this.track,
    required this.isSystem,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    final t = AppColors.of(context);
    return SizedBox(
      width: 48,
      height: 48,
      child: PopupMenuButton<String>(
        key: ValueKey('track-options-${track.sourceId}'),
        tooltip: 'Track options',
        padding: EdgeInsets.zero,
        icon: Icon(
          Icons.more_horiz,
          size: 20,
          color: t.textSecondary,
        ),
        color: t.raised,
        position: PopupMenuPosition.under,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.lg),
        ),
        onSelected: (value) {
          if (value == 'add') {
            showAddToPlaylistSheet(context, track: track);
          } else if (value == 'remove') {
            onRemove();
          }
        },
        itemBuilder: (context) => [
          PopupMenuItem<String>(
            value: 'add',
            child: Text(
              'Add to playlist',
              style: TextStyle(color: t.textPrimary),
            ),
          ),
          if (!isSystem)
            PopupMenuItem<String>(
              value: 'remove',
              child: Text(
                'Remove from playlist',
                style: TextStyle(color: t.textPrimary),
              ),
            ),
        ],
      ),
    );
  }
}

class _PlaylistOptionsButton extends StatelessWidget {
  final String tooltip;
  final bool isSystem;
  final VoidCallback onDelete;

  const _PlaylistOptionsButton({
    super.key,
    required this.tooltip,
    required this.isSystem,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final t = AppColors.of(context);
    return MergeSemantics(
      child: Semantics(
        label: tooltip,
        button: true,
        child: Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: t.row,
            shape: BoxShape.circle,
            border: Border.all(color: t.border),
          ),
          child: PopupMenuButton<String>(
            padding: EdgeInsets.zero,
            icon: Icon(Icons.more_horiz, size: 20, color: t.textSecondary),
            color: t.raised,
            position: PopupMenuPosition.under,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppRadius.lg),
            ),
            onSelected: (value) {
              if (value == 'delete') onDelete();
            },
            itemBuilder: (context) => [
              if (isSystem)
                PopupMenuItem<String>(
                  enabled: false,
                  child: Text(
                    'Read-only auto-playlist',
                    style: TextStyle(color: t.textSecondary),
                  ),
                )
              else
                PopupMenuItem<String>(
                  value: 'delete',
                  child: Text(
                    'Delete playlist',
                    style: TextStyle(color: t.textPrimary),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CircleAction extends StatelessWidget {
  final IconData icon;
  final String tooltip;
  final VoidCallback? onPressed;

  const _CircleAction({
    required this.icon,
    required this.tooltip,
    this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return AppIconButton(
      icon: icon,
      semanticLabel: tooltip,
      tooltip: tooltip,
      onPressed: onPressed,
    );
  }
}

String _formatTrackDuration(int ms) {
  final duration = Duration(milliseconds: ms);
  final minutes = duration.inMinutes;
  final seconds = duration.inSeconds % 60;
  return '$minutes:${seconds.toString().padLeft(2, '0')}';
}

String _formatTotalDuration(int? ms) {
  if (ms == null) return '—';
  if (ms <= 0) return '0 min';
  final duration = Duration(milliseconds: ms);
  final hours = duration.inHours;
  final minutes = duration.inMinutes % 60;
  if (hours == 0) return '$minutes min';
  if (minutes == 0) return '$hours hr';
  return '$hours hr $minutes min';
}

String _relativeTime(DateTime time) {
  final diff = DateTime.now().difference(time);
  if (diff.inMinutes < 1) return 'just now';
  if (diff.inHours < 1) return '${diff.inMinutes}m ago';
  if (diff.inDays < 1) return '${diff.inHours}h ago';
  if (diff.inDays < 7) return '${diff.inDays}d ago';
  if (diff.inDays < 30) return '${diff.inDays ~/ 7}w ago';
  if (diff.inDays < 365) return '${diff.inDays ~/ 30}mo ago';
  return '${diff.inDays ~/ 365}y ago';
}
