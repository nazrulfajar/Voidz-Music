import 'dart:ui';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../shared/widgets/app_empty_state.dart';
import '../../../../shared/widgets/playlist_mosaic_cover.dart';
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
    final t = AppColors.of(context);
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
      return Scaffold(
        backgroundColor: t.background,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          leading: IconButton(
            tooltip: 'Back',
            icon: Icon(Icons.arrow_back, color: t.textPrimary),
            onPressed: () => context.pop(),
          ),
        ),
        body: Center(
          child: Text(
            'Playlist not found',
            style: TextStyle(color: t.textSecondary),
          ),
        ),
      );
    }

    // Virtual playlists have synthetic id -1 and can't be fetched by id alone
    // — try to find them from allPlaylistsProvider via name fallback
    if (id == -1 && hint != null) {
      return _PlaylistDetailBody(playlist: hint);
    }

    final playlistAsync = ref.watch(playlistByIdProvider(id));
    return playlistAsync.when(
      data: (fetched) {
        if (fetched == null) {
          // fallback to hint if fetch misses (e.g. deleted)
          if (hint != null) return _PlaylistDetailBody(playlist: hint);
          return Scaffold(
            backgroundColor: t.background,
            appBar: AppBar(
              backgroundColor: Colors.transparent,
              leading: IconButton(
                tooltip: 'Back',
                icon: Icon(Icons.arrow_back, color: t.textPrimary),
                onPressed: () => context.pop(),
              ),
            ),
            body: Center(
              child: Text(
                'Playlist not found',
                style: TextStyle(color: t.textSecondary),
              ),
            ),
          );
        }
        return _PlaylistDetailBody(playlist: fetched);
      },
      loading: () => Scaffold(
        backgroundColor: t.background,
        body: Center(
          child: CircularProgressIndicator(color: t.accent),
        ),
      ),
      error: (e, st) => Scaffold(
        backgroundColor: t.background,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          leading: IconButton(
            tooltip: 'Back',
            icon: Icon(Icons.arrow_back, color: t.textPrimary),
            onPressed: () => context.pop(),
          ),
        ),
        body: Center(
          child: Text(
            'Error: $e',
            style: TextStyle(color: t.textPrimary),
          ),
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
    final theme = Theme.of(context);
    final t = AppColors.of(context);
    final tracksAsync = ref.watch(playlistTracksProvider(playlist));
    final playerState = ref.watch(playerControllerProvider);

    final currentTrackCount = playlist.isSystem
        ? playlist.trackCount
        : tracksAsync.maybeWhen(
            data: (tracks) => tracks.length,
            orElse: () => playlist.trackCount,
          );

    final cover = Container(
      width: 120,
      height: 120,
      decoration: BoxDecoration(
        color: t.surface,
        borderRadius: BorderRadius.circular(AppRadius.md),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.3),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(AppRadius.md),
        child: PlaylistMosaicCover(
          imageUrls: playlist.thumbnailUrls,
          size: 120,
        ),
      ),
    );

    final info = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          playlist.name,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: theme.textTheme.headlineMedium?.copyWith(
            fontWeight: FontWeight.bold,
            color: t.textPrimary,
          ),
        ),
        const SizedBox(height: AppSpacing.xs),
        Text(
          '$currentTrackCount tracks',
          style: theme.textTheme.titleMedium?.copyWith(
            color: t.textSecondary,
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        Wrap(
          spacing: AppSpacing.sm,
          runSpacing: AppSpacing.sm,
          children: [
            ElevatedButton.icon(
              onPressed: tracksAsync.maybeWhen(
                data: (tracks) => tracks.isNotEmpty
                    ? () => ref
                        .read(playerControllerProvider.notifier)
                        .playTrack(tracks.first, queue: tracks)
                    : null,
                orElse: () => null,
              ),
              icon: const Icon(Icons.play_arrow, size: 18),
              label: const Text(
                'Play All',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: t.accent,
                foregroundColor: t.onAccent,
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppRadius.full),
                ),
              ),
            ),
            OutlinedButton.icon(
              onPressed: tracksAsync.maybeWhen(
                data: (tracks) => tracks.isNotEmpty
                    ? () {
                        final s = List.of(tracks)..shuffle();
                        ref
                            .read(playerControllerProvider.notifier)
                            .playTrack(s.first, queue: s);
                      }
                    : null,
                orElse: () => null,
              ),
              icon: const Icon(Icons.shuffle, size: 16),
              label: const Text(
                'Acak',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              style: OutlinedButton.styleFrom(
                foregroundColor: t.textPrimary,
                side: BorderSide(color: t.border),
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppRadius.full),
                ),
              ),
            ),
          ],
        ),
      ],
    );

    return Scaffold(
      extendBodyBehindAppBar: true,
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          tooltip: 'Back',
          icon: Icon(Icons.arrow_back, color: t.textPrimary),
          onPressed: () => context.pop(),
        ),
        actions: [
          if (!playlist.isSystem)
            IconButton(
              tooltip: 'Delete playlist',
              icon: Icon(Icons.delete, color: t.textSecondary),
              onPressed: () async {
                final confirm = await showDialog<bool>(
                  context: context,
                  builder: (context) => AlertDialog(
                    backgroundColor: t.raised,
                    title: const Text('Delete Playlist?'),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(context, false),
                        child: Text(
                          'Cancel',
                          style: TextStyle(color: t.textSecondary),
                        ),
                      ),
                      TextButton(
                        onPressed: () => Navigator.pop(context, true),
                        child: Text(
                          'Delete',
                          style: TextStyle(color: t.textPrimary),
                        ),
                      ),
                    ],
                  ),
                );

                if (confirm == true) {
                  await ref
                      .read(playlistRepositoryProvider)
                      .deletePlaylist(playlist.id!);
                  ref.invalidate(allPlaylistsProvider);
                  if (context.mounted) context.pop();
                }
              },
            ),
        ],
      ),
      body: Stack(
        children: [
          Positioned.fill(
            child: PlaylistMosaicCover(
              imageUrls: playlist.thumbnailUrls,
              size: 400,
            ),
          ),
          Positioned.fill(
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 80, sigmaY: 80),
              child: Container(
                color: t.background.withValues(alpha: 0.7),
              ),
            ),
          ),
          SafeArea(
            child: Column(
              children: [
                LayoutBuilder(
                  builder: (context, _) {
                    // At 200% text the side-by-side header leaves too little
                    // width for the title, so stack it (a11y §10).
                    final stacked =
                        MediaQuery.textScalerOf(context).scale(1) > 1.4;
                    const padding = EdgeInsets.symmetric(
                      horizontal: AppSpacing.xl,
                      vertical: AppSpacing.lg,
                    );
                    if (stacked) {
                      return Padding(
                        padding: padding,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            cover,
                            const SizedBox(height: AppSpacing.md),
                            info,
                          ],
                        ),
                      );
                    }
                    return Padding(
                      padding: padding,
                      child: Row(
                        children: [
                          cover,
                          const SizedBox(width: AppSpacing.xl),
                          Expanded(child: info),
                        ],
                      ),
                    );
                  },
                ),
                Divider(color: t.border),
                Expanded(
                  child: tracksAsync.when(
                    data: (tracks) {
                      if (tracks.isEmpty) {
                        return const SingleChildScrollView(
                          child: AppEmptyState(
                            icon: Icons.queue_music_rounded,
                            title: 'Playlist is empty',
                          ),
                        );
                      }

                      if (playlist.isSystem) {
                        return ListView.builder(
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
                            return ListTile(
                              leading: ClipRRect(
                                borderRadius:
                                    BorderRadius.circular(AppRadius.sm),
                                child: CachedNetworkImage(
                                  imageUrl: track.thumbnailUrl ?? '',
                                  width: 48,
                                  height: 48,
                                  fit: BoxFit.cover,
                                  errorWidget: (context, url, error) =>
                                      Container(color: t.raised),
                                ),
                              ),
                              title: Text(
                                track.title,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  color: isPlaying ? t.accent : t.textPrimary,
                                ),
                              ),
                              subtitle: Text(
                                track.artist,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(color: t.textSecondary),
                              ),
                              onTap: () {
                                ref
                                    .read(
                                      playerControllerProvider.notifier,
                                    )
                                    .playTrack(track, queue: tracks);
                              },
                            );
                          },
                        );
                      }

                      return ReorderableListView.builder(
                        padding: const EdgeInsets.only(
                          left: AppSpacing.md,
                          right: AppSpacing.md,
                          top: AppSpacing.md,
                          bottom: 160,
                        ),
                        itemCount: tracks.length,
                        onReorder: (oldIndex, newIndex) async {
                          if (oldIndex < newIndex) {
                            newIndex -= 1;
                          }
                          final track = tracks.removeAt(oldIndex);
                          tracks.insert(newIndex, track);

                          await ref
                              .read(playlistRepositoryProvider)
                              .reorderTracks(
                                playlist.id!,
                                oldIndex,
                                newIndex,
                              );
                        },
                        itemBuilder: (context, index) {
                          final track = tracks[index];
                          final isPlaying = track.sourceId ==
                              playerState.currentTrack?.sourceId;
                          return ListTile(
                            key: ValueKey(
                              track.sourceId + index.toString(),
                            ),
                            leading: ClipRRect(
                              borderRadius: BorderRadius.circular(AppRadius.sm),
                              child: CachedNetworkImage(
                                imageUrl: track.thumbnailUrl ?? '',
                                width: 48,
                                height: 48,
                                fit: BoxFit.cover,
                                errorWidget: (context, url, error) =>
                                    Container(color: t.raised),
                              ),
                            ),
                            title: Text(
                              track.title,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                color: isPlaying ? t.accent : t.textPrimary,
                              ),
                            ),
                            subtitle: Text(
                              track.artist,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(color: t.textSecondary),
                            ),
                            trailing: IconButton(
                              tooltip: 'Remove from playlist',
                              icon: Icon(
                                Icons.remove_circle_outline,
                                color: t.textSecondary,
                              ),
                              onPressed: () async {
                                await ref
                                    .read(playlistRepositoryProvider)
                                    .removeTrackFromPlaylist(
                                      playlist.id!,
                                      track.sourceId,
                                    );
                                ref.invalidate(
                                  playlistTracksProvider(playlist),
                                );
                                ref.invalidate(allPlaylistsProvider);
                              },
                            ),
                            onTap: () {
                              ref
                                  .read(playerControllerProvider.notifier)
                                  .playTrack(track, queue: tracks);
                            },
                          );
                        },
                      );
                    },
                    loading: () => const Center(
                      child: CircularProgressIndicator(),
                    ),
                    error: (e, st) => Center(
                      child: Text(
                        'Error: $e',
                        style: TextStyle(color: t.textPrimary),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
