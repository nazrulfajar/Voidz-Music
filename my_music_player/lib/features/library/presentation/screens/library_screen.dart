import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../shared/widgets/app_artwork.dart';
import '../../../../shared/widgets/app_section_header.dart';
import '../../../cache/presentation/providers/cache_stats_provider.dart';
import '../../../player/domain/entities/track.dart';
import '../../../player/presentation/providers/device_songs_provider.dart';
import '../../../player/presentation/providers/player_controller.dart';
import '../../domain/entities/playlist.dart';
import '../providers/downloaded_provider.dart';
import '../providers/playlist_provider.dart';

class LibraryScreen extends ConsumerWidget {
  const LibraryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = AppColors.of(context);
    final playlistsAsync = ref.watch(allPlaylistsProvider);
    final totalTracks = ref.watch(libraryTrackTotalProvider).valueOrNull;

    return Scaffold(
      backgroundColor: t.background,
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () async {
            ref.invalidate(allPlaylistsProvider);
            ref.invalidate(cacheStatsProvider);
            ref.invalidate(deviceSongsProvider);
            ref.invalidate(downloadedTracksProvider);
            ref.invalidate(libraryTrackTotalProvider);
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
                    _buildHeader(context, t, totalTracks),
                    const SizedBox(height: AppSpacing.space6),
                    playlistsAsync.when(
                      data: (playlists) => _buildContent(
                        context,
                        ref,
                        t,
                        playlists,
                      ),
                      loading: () => _buildSkeleton(t),
                      error: (e, _) => _buildError(context, ref, t),
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

  Widget _buildHeader(
    BuildContext context,
    AppColorTokens t,
    int? totalTracks,
  ) {
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
          totalTracks == null ? '' : '$totalTracks tracks',
          style: TextStyle(
            fontSize: 11,
            color: t.textSecondary,
          ),
        ),
      ],
    );
  }

  Widget _buildContent(
    BuildContext context,
    WidgetRef ref,
    AppColorTokens t,
    List<Playlist> playlists,
  ) {
    final deviceSongs = ref.watch(deviceSongsProvider).value ?? const <Track>[];
    final cacheStats = ref.watch(cacheStatsProvider).valueOrNull;
    final userPlaylists = playlists.where((p) => !p.isSystem).toList();

    final liked = playlists.where((p) => p.name == 'Liked Songs').firstOrNull;
    final pinned =
        deviceSongs.where((tr) => tr.isPinned || tr.isCached).toList();

    final cacheMeta = cacheStats == null
        ? '—'
        : '${_formatBytes(cacheStats.totalCacheSizeBytes)} / '
            '${_formatBytes(cacheStats.maxCacheSizeBytes)}';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (liked != null) ...[
          _likedCard(context, liked),
          const SizedBox(height: AppSpacing.space4),
        ],
        _linkRow(
          context: context,
          t: t,
          icon: Icons.download_rounded,
          title: 'Downloaded cache',
          meta: cacheMeta,
          onTap: () => context.push('/library/downloaded'),
        ),
        const SizedBox(height: AppSpacing.space2),
        _linkRow(
          context: context,
          t: t,
          icon: Icons.queue_music_rounded,
          title: 'Custom playlists',
          meta: '${userPlaylists.length} playlists',
          onTap: () => context.push('/library/playlists'),
        ),
        const SizedBox(height: AppSpacing.space2),
        _linkRow(
          context: context,
          t: t,
          icon: Icons.folder_outlined,
          title: 'Device songs',
          meta: '${deviceSongs.length} tracks',
          onTap: () => context.push('/library/device-songs'),
        ),
        if (pinned.isNotEmpty) ...[
          const SizedBox(height: AppSpacing.space6),
          const AppSectionHeader(
            title: 'Pinned offline tracks',
            padding: EdgeInsets.only(bottom: AppSpacing.space2),
          ),
          for (final track in pinned.take(2)) ...[
            _pinnedRow(context, ref, t, track, pinned),
            const SizedBox(height: AppSpacing.space2),
          ],
        ],
        const SizedBox(height: AppSpacing.space6),
        _recentRow(context, t),
        const SizedBox(height: AppSpacing.space2),
        _linkRow(
          context: context,
          t: t,
          icon: Icons.auto_awesome,
          title: 'Listening recap',
          meta: 'Your listening summary',
          onTap: () => context.push('/library/recap'),
        ),
      ],
    );
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
        constraints: const BoxConstraints(minHeight: 104),
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
                    'Auto-playlist · ${playlist.trackCount} tracks',
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
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppRadius.lg),
      child: Container(
        constraints: const BoxConstraints(minHeight: 56),
        decoration: BoxDecoration(
          color: t.row,
          borderRadius: BorderRadius.circular(AppRadius.lg),
          border: Border.all(color: t.border),
        ),
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.space4,
          vertical: AppSpacing.space2,
        ),
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
        constraints: const BoxConstraints(minHeight: 72),
        decoration: BoxDecoration(
          color: t.row,
          borderRadius: BorderRadius.circular(AppRadius.xl),
          border: Border.all(color: t.border),
        ),
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.space4,
          vertical: AppSpacing.space2,
        ),
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
                    track.isPinned
                        ? '${track.artist} · Pinned offline'
                        : track.artist,
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
        constraints: const BoxConstraints(minHeight: 64),
        decoration: BoxDecoration(
          color: t.row,
          borderRadius: BorderRadius.circular(AppRadius.lg),
          border: Border.all(color: t.border),
        ),
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.space4,
          vertical: AppSpacing.space2,
        ),
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
        block(64),
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
}

String _formatBytes(int bytes) {
  const kilo = 1024;
  const mega = kilo * 1024;
  const giga = mega * 1024;

  String format(double value, String unit) {
    final text = value == value.roundToDouble()
        ? value.toStringAsFixed(0)
        : value.toStringAsFixed(1);
    return '$text $unit';
  }

  if (bytes >= giga) return format(bytes / giga, 'GB');
  if (bytes >= mega) return format(bytes / mega, 'MB');
  if (bytes >= kilo) return format(bytes / kilo, 'KB');
  return '$bytes B';
}
