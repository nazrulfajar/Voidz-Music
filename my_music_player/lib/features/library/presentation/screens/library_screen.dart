import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../shared/widgets/app_artwork.dart';
import '../../../../shared/widgets/app_section_header.dart';
import '../../../player/domain/entities/track.dart';
import '../../../player/presentation/providers/device_songs_provider.dart';
import '../../../player/presentation/providers/player_controller.dart';
import '../../data/repositories/playlist_repository_impl.dart';
import '../../domain/entities/playlist.dart';
import '../providers/playlist_provider.dart';

class LibraryScreen extends ConsumerStatefulWidget {
  const LibraryScreen({super.key});

  @override
  ConsumerState<LibraryScreen> createState() => _LibraryScreenState();
}

class _LibraryScreenState extends ConsumerState<LibraryScreen> {
  final GlobalKey _playlistsKey = GlobalKey();

  Future<void> _scrollToPlaylists() async {
    final context = _playlistsKey.currentContext;
    if (context != null) {
      await Scrollable.ensureVisible(
        context,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = AppColors.of(context);
    final playlistsAsync = ref.watch(allPlaylistsProvider);

    return Scaffold(
      backgroundColor: t.background,
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () async {
            ref.invalidate(allPlaylistsProvider);
            try {
              await ref.read(allPlaylistsProvider.future);
            } catch (_) {}
          },
          color: t.accent,
          backgroundColor: t.row,
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.only(
              left: AppSpacing.screenInset,
              right: AppSpacing.screenInset,
              top: AppSpacing.space4,
              bottom: AppSpacing.bottomPlayerPadding,
            ),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 420),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    playlistsAsync.when(
                      data: (playlists) {
                        final deviceAsync = ref.watch(deviceSongsProvider);
                        final deviceSongs =
                            deviceAsync.value ?? const <Track>[];
                        final deviceCount = deviceSongs.length;
                        final userPlaylists =
                            playlists.where((p) => !p.isSystem).toList();
                        final totalTracks = userPlaylists.fold<int>(
                          0,
                          (sum, p) => sum + p.trackCount,
                        );
                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildHeader(context, t, totalTracks),
                            const SizedBox(height: AppSpacing.space6),
                            ..._buildContent(
                              context,
                              ref,
                              t,
                              playlists,
                              userPlaylists,
                              deviceSongs,
                              deviceCount,
                            ),
                          ],
                        );
                      },
                      loading: () => Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildHeader(context, t, 0),
                          const SizedBox(height: AppSpacing.space6),
                          _buildSkeleton(t),
                        ],
                      ),
                      error: (e, _) => Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildHeader(context, t, 0),
                          const SizedBox(height: AppSpacing.space6),
                          _buildError(context, ref, t),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context, AppColorTokens t, int totalTracks) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Expanded(
          child: Text(
            'Your Library',
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.w700,
              color: t.textPrimary,
            ),
          ),
        ),
        Text(
          '$totalTracks tracks',
          style: TextStyle(
            fontSize: 11,
            color: t.textSecondary,
          ),
        ),
      ],
    );
  }

  List<Widget> _buildContent(
    BuildContext context,
    WidgetRef ref,
    AppColorTokens t,
    List<Playlist> playlists,
    List<Playlist> userPlaylists,
    List<Track> deviceSongs,
    int deviceCount,
  ) {
    final widgets = <Widget>[];

    final liked = playlists.where((p) => p.name == 'Liked Songs').firstOrNull;
    if (liked != null) {
      widgets.add(_likedCard(context, liked));
      widgets.add(const SizedBox(height: AppSpacing.space4));
    }

    // Three link rows
    widgets.add(
      _linkRow(
        context: context,
        t: t,
        icon: Icons.download_rounded,
        title: 'Downloaded cache',
        meta: 'Manage offline music',
        height: 56,
        onTap: () => context.push('/library/downloaded'),
      ),
    );
    widgets.add(const SizedBox(height: AppSpacing.space2));
    widgets.add(
      _linkRow(
        context: context,
        t: t,
        icon: Icons.queue_music_rounded,
        title: 'Custom playlists',
        meta: '${userPlaylists.length} playlists',
        height: 56,
        onTap: _scrollToPlaylists,
      ),
    );
    widgets.add(const SizedBox(height: AppSpacing.space2));
    widgets.add(
      _linkRow(
        context: context,
        t: t,
        icon: Icons.folder_outlined,
        title: 'Device songs',
        meta: '$deviceCount tracks',
        height: 56,
        onTap: () => context.push('/library/device-songs'),
      ),
    );
    widgets.add(const SizedBox(height: AppSpacing.space6));

    // Pinned offline tracks
    final pinned =
        deviceSongs.where((tr) => tr.isPinned || tr.isCached).toList();
    if (pinned.isNotEmpty) {
      widgets.add(const AppSectionHeader(title: 'PINNED OFFLINE TRACKS'));
      final shown = pinned.take(2).toList();
      for (final track in shown) {
        widgets.add(
          _pinnedRow(context, ref, t, track, pinned),
        );
        widgets.add(const SizedBox(height: AppSpacing.space2));
      }
      widgets.add(const SizedBox(height: AppSpacing.space4));
    }

    // Recently played
    final recent =
        playlists.where((p) => p.name == 'Recently Played').firstOrNull;
    if (recent != null) {
      widgets.add(const AppSectionHeader(title: 'RECENTLY PLAYED'));
      widgets.add(
        _recentRow(context, t),
      );
      widgets.add(const SizedBox(height: AppSpacing.space6));
    }

    // Playlists section
    widgets.add(
      Container(
        key: _playlistsKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const AppSectionHeader(title: 'PLAYLISTS'),
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                childAspectRatio: 0.78,
              ),
              itemCount: userPlaylists.length + 1,
              itemBuilder: (context, index) {
                if (index == userPlaylists.length) {
                  return _newPlaylistTile(context, ref, t);
                }
                final playlist = userPlaylists[index];
                return _playlistCard(context, playlist);
              },
            ),
            const SizedBox(height: AppSpacing.space3),
            _linkRow(
              context: context,
              t: t,
              icon: Icons.auto_awesome,
              title: 'Listening recap',
              meta: 'Your listening summary',
              height: 56,
              onTap: () => context.push('/library/recap'),
            ),
          ],
        ),
      ),
    );

    return widgets;
  }

  Widget _likedCard(BuildContext context, Playlist playlist) {
    final t = AppColors.of(context);
    return InkWell(
      onTap: () => context.push(
        '/library/playlist-detail/${playlist.id}',
        extra: playlist,
      ),
      borderRadius: BorderRadius.circular(22),
      child: Container(
        height: 104,
        decoration: BoxDecoration(
          color: t.row,
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: t.border),
        ),
        padding: const EdgeInsets.all(AppSpacing.space4),
        child: Row(
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                gradient: t.artworkGradient,
                borderRadius: BorderRadius.circular(AppRadius.artworkSmall),
              ),
              child: Icon(
                Icons.favorite,
                size: 32,
                color: t.textPrimary,
              ),
            ),
            const SizedBox(width: AppSpacing.space3),
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'AUTO-PLAYLIST',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                      letterSpacing: 1.2,
                      color: t.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Liked Songs',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: t.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${playlist.trackCount} tracks',
                    style: TextStyle(
                      fontSize: 12,
                      color: t.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.favorite,
              size: 24,
              color: t.textPrimary,
            ),
          ],
        ),
      ),
    );
  }

  Widget _linkRow({
    required BuildContext context,
    required AppColorTokens t,
    required IconData icon,
    required String title,
    required String meta,
    required double height,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppRadius.lg),
      child: Container(
        height: height,
        decoration: BoxDecoration(
          color: t.row,
          borderRadius: BorderRadius.circular(AppRadius.lg),
          border: Border.all(color: t.border),
        ),
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.space4),
        child: Row(
          children: [
            Icon(icon, size: 24, color: t.textPrimary),
            const SizedBox(width: AppSpacing.space2),
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: t.textPrimary,
                    ),
                  ),
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
            Icon(
              Icons.chevron_right_rounded,
              size: 20,
              color: t.textSecondary,
            ),
          ],
        ),
      ),
    );
  }

  Widget _pinnedRow(
    BuildContext context,
    WidgetRef ref,
    AppColorTokens t,
    Track track,
    List<Track> queue,
  ) {
    return InkWell(
      onTap: () => ref
          .read(playerControllerProvider.notifier)
          .playTrack(track, queue: queue),
      borderRadius: BorderRadius.circular(AppRadius.xl),
      child: Container(
        height: 72,
        decoration: BoxDecoration(
          color: t.row,
          borderRadius: BorderRadius.circular(AppRadius.xl),
          border: Border.all(color: t.border),
        ),
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.space4),
        child: Row(
          children: [
            AppArtwork(
              localPath: track.localThumbnailPath,
              imageUrl: track.thumbnailUrl,
              size: 44,
              radius: AppRadius.md,
            ),
            const SizedBox(width: AppSpacing.space3),
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
                    track.isPinned ? 'Pinned offline' : track.artist,
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
            Icon(
              Icons.check_circle,
              size: 24,
              color: t.textPrimary,
            ),
          ],
        ),
      ),
    );
  }

  Widget _recentRow(BuildContext context, AppColorTokens t) {
    return InkWell(
      onTap: () => context.push('/library/recently-played'),
      borderRadius: BorderRadius.circular(AppRadius.lg),
      child: Container(
        height: 64,
        decoration: BoxDecoration(
          color: t.row,
          borderRadius: BorderRadius.circular(AppRadius.lg),
          border: Border.all(color: t.border),
        ),
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.space4),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: t.raised,
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.history,
                size: 20,
                color: t.textPrimary,
              ),
            ),
            const SizedBox(width: AppSpacing.space3),
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Recently played',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: t.textPrimary,
                    ),
                  ),
                  Text(
                    'Your listening history',
                    style: TextStyle(
                      fontSize: 12,
                      color: t.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.chevron_right_rounded,
              size: 20,
              color: t.textSecondary,
            ),
          ],
        ),
      ),
    );
  }

  Widget _playlistCard(BuildContext context, Playlist playlist) {
    final t = AppColors.of(context);
    return InkWell(
      onTap: () => context.push(
        '/library/playlist-detail/${playlist.id}',
        extra: playlist,
      ),
      borderRadius: BorderRadius.circular(AppRadius.xxl),
      child: Container(
        decoration: BoxDecoration(
          color: t.row,
          borderRadius: BorderRadius.circular(AppRadius.xxl),
          border: Border.all(color: t.border),
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              child: Container(
                decoration: BoxDecoration(gradient: t.artworkGradient),
                child: playlist.thumbnailUrls.isNotEmpty
                    ? LayoutBuilder(
                        builder: (context, constraints) {
                          final size = constraints.maxWidth / 2;
                          return GridView.count(
                            crossAxisCount: 2,
                            padding: EdgeInsets.zero,
                            mainAxisSpacing: 2,
                            crossAxisSpacing: 2,
                            physics: const NeverScrollableScrollPhysics(),
                            children: playlist.thumbnailUrls
                                .take(4)
                                .map<Widget>(
                                  (url) => AppArtwork(
                                    imageUrl: url,
                                    size: size,
                                    radius: 0,
                                  ),
                                )
                                .toList(),
                          );
                        },
                      )
                    : Center(
                        child: Icon(
                          Icons.queue_music_rounded,
                          size: 40,
                          color: t.textSecondary,
                        ),
                      ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(AppSpacing.space3),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    playlist.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: t.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${playlist.trackCount} tracks',
                    style: TextStyle(
                      fontSize: 11,
                      color: t.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _newPlaylistTile(
      BuildContext context, WidgetRef ref, AppColorTokens t) {
    return InkWell(
      onTap: () => _showCreatePlaylistDialog(context, ref),
      borderRadius: BorderRadius.circular(AppRadius.xxl),
      child: Container(
        decoration: BoxDecoration(
          color: t.field,
          borderRadius: BorderRadius.circular(AppRadius.xxl),
          border: Border.all(color: t.border),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: t.raised,
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.add,
                size: 20,
                color: t.textPrimary,
              ),
            ),
            const SizedBox(height: AppSpacing.space2),
            Text(
              'New playlist',
              style: TextStyle(
                fontSize: 13,
                color: t.textPrimary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSkeleton(AppColorTokens t) {
    Widget block(double height) => Container(
          height: height,
          margin: const EdgeInsets.only(bottom: AppSpacing.space2),
          decoration: BoxDecoration(
            color: t.textPrimary.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(AppRadius.sm),
          ),
        );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        block(104),
        const SizedBox(height: AppSpacing.space2),
        block(56),
        block(56),
        block(56),
        const SizedBox(height: AppSpacing.space4),
        block(200),
      ],
    );
  }

  Widget _buildError(BuildContext context, WidgetRef ref, AppColorTokens t) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: AppSpacing.space8),
        Text(
          'Failed to load library',
          style: TextStyle(color: t.textSecondary),
        ),
        const SizedBox(height: AppSpacing.space3),
        TextButton(
          onPressed: () => ref.invalidate(allPlaylistsProvider),
          child: Text(
            'Retry',
            style: TextStyle(color: t.textPrimary),
          ),
        ),
      ],
    );
  }

  void _showCreatePlaylistDialog(BuildContext context, WidgetRef ref) {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (dialogContext) {
        final dt = AppColors.of(dialogContext);
        return AlertDialog(
          backgroundColor: dt.row,
          title: Text(
            'New Playlist',
            style: TextStyle(color: dt.textPrimary),
          ),
          content: TextField(
            controller: controller,
            autofocus: true,
            style: TextStyle(color: dt.textPrimary),
            decoration: InputDecoration(
              hintText: 'Playlist name',
              hintStyle: TextStyle(color: dt.textMuted),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: Text(
                'Cancel',
                style: TextStyle(color: dt.textSecondary),
              ),
            ),
            TextButton(
              onPressed: () async {
                final name = controller.text.trim();
                if (name.isNotEmpty) {
                  await ref
                      .read(playlistRepositoryProvider)
                      .createPlaylist(name);
                  ref.invalidate(allPlaylistsProvider);
                }
                if (dialogContext.mounted) Navigator.pop(dialogContext);
              },
              child: Text(
                'Create',
                style: TextStyle(color: dt.textPrimary),
              ),
            ),
          ],
        );
      },
    );
  }
}
