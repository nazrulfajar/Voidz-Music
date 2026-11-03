import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/providers/connectivity_provider.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_glass.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../../shared/widgets/app_artwork.dart';
import '../../../../shared/widgets/app_chrome_insets.dart';
import '../../../../shared/widgets/app_empty_state.dart';
import '../../../../shared/widgets/app_section_header.dart';
import '../../../../shared/widgets/glass_surface.dart';
import '../../../../shared/widgets/shimmer_loading.dart';
import '../../../cache/presentation/providers/cache_stats_provider.dart';
import '../../../player/domain/entities/track.dart';
import '../../../player/presentation/providers/device_songs_provider.dart';
import '../../../player/presentation/providers/player_controller.dart';
import '../../domain/entities/playlist.dart';
import '../providers/downloaded_provider.dart';
import '../providers/playlist_provider.dart';

/// True when the library has no user content yet: no user playlist, no liked
/// tracks, no local songs, no cache and no listening history.
///
/// Derived from provider state only. Reading the providers performs the I/O;
/// this provider never touches storage during widget `build()`.
final libraryFirstRunProvider = Provider<bool>((ref) {
  final playlists = ref.watch(allPlaylistsProvider).valueOrNull;
  if (playlists == null) return false;
  final deviceSongs = ref.watch(deviceSongsProvider).valueOrNull;
  final hasUserPlaylist = playlists.any((playlist) => !playlist.isSystem);
  int systemTrackCount(String name) => playlists
      .where((playlist) => playlist.isSystem && playlist.name == name)
      .fold<int>(0, (sum, playlist) => sum + playlist.trackCount);

  return !hasUserPlaylist &&
      (deviceSongs?.isEmpty ?? true) &&
      systemTrackCount('Liked Songs') == 0 &&
      systemTrackCount('Downloaded') == 0 &&
      systemTrackCount('Recently Played') == 0;
});

class LibraryScreen extends ConsumerWidget {
  const LibraryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = AppColors.of(context);
    final playlistsAsync = ref.watch(allPlaylistsProvider);
    final totalTracks = ref.watch(libraryTrackTotalProvider).valueOrNull;
    final isOnline = ref.watch(connectivityProvider).value ?? true;

    return Scaffold(
      backgroundColor: Colors.transparent,
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
            padding: EdgeInsets.only(
              left: AppSpacing.screenInset,
              right: AppSpacing.screenInset,
              top: AppSpacing.space4,
              bottom: AppChromeInsets.bottomOf(context),
            ),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 420),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildHeader(context, t, totalTracks),
                    if (!isOnline) ...[
                      const SizedBox(height: AppSpacing.space4),
                      const AppOfflineBanner(),
                    ],
                    const SizedBox(height: AppSpacing.space6),
                    playlistsAsync.when(
                      data: (playlists) => _buildContent(
                        context,
                        ref,
                        t,
                        playlists,
                      ),
                      loading: () => _buildSkeleton(),
                      error: (e, _) => _buildError(context, ref, e),
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
    final l10n = AppLocalizations.of(context);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Expanded(
          child: Text(
            l10n.libraryTitle,
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.w700,
              color: t.textPrimary,
            ),
          ),
        ),
        Text(
          totalTracks == null || totalTracks == 0
              ? ''
              : l10n.commonTrackCount(totalTracks),
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
    final l10n = AppLocalizations.of(context);
    final firstRun = ref.watch(libraryFirstRunProvider);
    final deviceAsync = ref.watch(deviceSongsProvider);
    if (firstRun && deviceAsync.isLoading) return _buildSkeleton();
    if (firstRun) return _buildFirstRun(context, ref);

    final deviceSongs = deviceAsync.value ?? const <Track>[];
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
          title: l10n.libraryDownloadedCache,
          meta: cacheMeta,
          onTap: () => context.push('/downloaded'),
        ),
        const SizedBox(height: AppSpacing.space2),
        _linkRow(
          context: context,
          t: t,
          icon: Icons.queue_music_rounded,
          title: l10n.libraryCustomPlaylists,
          meta: l10n.commonPlaylistCount(userPlaylists.length),
          onTap: () => context.push('/playlists'),
        ),
        const SizedBox(height: AppSpacing.space2),
        _linkRow(
          context: context,
          t: t,
          icon: Icons.folder_outlined,
          title: l10n.libraryDeviceSongs,
          meta: l10n.commonTrackCount(deviceSongs.length),
          onTap: () => context.push('/device-songs'),
        ),
        if (pinned.isNotEmpty) ...[
          const SizedBox(height: AppSpacing.space6),
          AppSectionHeader(
            title: l10n.libraryPinnedOfflineTracks,
            padding: const EdgeInsets.only(bottom: AppSpacing.space2),
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
          title: l10n.libraryListeningRecap,
          meta: l10n.libraryListeningSummary,
          onTap: () => context.push('/recap'),
        ),
      ],
    );
  }

  Widget _buildFirstRun(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final permission = ref.watch(devicePermissionStatusProvider).valueOrNull;
    final scanUnavailable =
        permission == DevicePermissionStatus.permanentlyDenied;
    return AppEmptyState(
      compact: true,
      glassQuality: GlassQuality.blurred,
      icon: scanUnavailable
          ? Icons.search_rounded
          : Icons.folder_special_outlined,
      title: l10n.libraryEmptyTitle,
      subtitle: scanUnavailable
          ? l10n.libraryEmptyScanUnavailable
          : l10n.libraryEmptySubtitle,
      actionLabel:
          scanUnavailable ? l10n.librarySearchMusic : l10n.libraryScanDevice,
      onAction: scanUnavailable
          ? () => context.go('/search')
          : () => _openDeviceSongs(context, ref),
    );
  }

  Future<void> _openDeviceSongs(BuildContext context, WidgetRef ref) async {
    await context.push('/device-songs');
    if (!context.mounted) return;
    ref.invalidate(devicePermissionStatusProvider);
    ref.invalidate(allPlaylistsProvider);
    ref.invalidate(libraryTrackTotalProvider);
  }

  Widget _likedCard(BuildContext context, Playlist playlist) {
    final t = AppColors.of(context);
    final l10n = AppLocalizations.of(context);
    return GlassSurface.card(
      key: const Key('library-liked-glass'),
      quality: GlassQuality.blurred,
      borderRadius: BorderRadius.circular(22),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(22),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: () => context.push(
            '/playlist-detail/${playlist.id}',
            extra: playlist,
          ),
          borderRadius: BorderRadius.circular(22),
          child: ConstrainedBox(
            constraints: const BoxConstraints(minHeight: 104),
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.space4),
              child: Row(
                children: [
                  Container(
                    width: 72,
                    height: 72,
                    decoration: BoxDecoration(
                      gradient: t.artworkGradient,
                      borderRadius:
                          BorderRadius.circular(AppRadius.artworkSmall),
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
                          l10n.libraryAutoPlaylistLabel,
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w500,
                            letterSpacing: 1.2,
                            color: t.textSecondary,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          l10n.libraryLikedSongs,
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                            color: t.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          l10n.libraryLikedMeta(playlist.trackCount),
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
          ),
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
    return GlassSurface.card(
      quality: GlassQuality.frosted,
      borderRadius: BorderRadius.circular(AppRadius.lg),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(AppRadius.lg),
          child: ConstrainedBox(
            constraints: const BoxConstraints(minHeight: 56),
            child: Padding(
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
          ),
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
    final l10n = AppLocalizations.of(context);
    return GlassSurface.card(
      key: ValueKey('library-pinned-glass-${track.sourceId}'),
      quality: GlassQuality.frosted,
      borderRadius: BorderRadius.circular(AppRadius.xl),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(AppRadius.xl),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: () => ref
              .read(playerControllerProvider.notifier)
              .playTrack(track, queue: queue),
          borderRadius: BorderRadius.circular(AppRadius.xl),
          child: ConstrainedBox(
            constraints: const BoxConstraints(minHeight: 72),
            child: Padding(
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
                              ? l10n.libraryPinnedMeta(track.artist)
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
          ),
        ),
      ),
    );
  }

  Widget _recentRow(BuildContext context, AppColorTokens t) {
    final l10n = AppLocalizations.of(context);
    return GlassSurface.card(
      key: const Key('library-recent-glass'),
      quality: GlassQuality.frosted,
      borderRadius: BorderRadius.circular(AppRadius.lg),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: () => context.push('/recently-played'),
          borderRadius: BorderRadius.circular(AppRadius.lg),
          child: ConstrainedBox(
            constraints: const BoxConstraints(minHeight: 64),
            child: Padding(
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
                          l10n.libraryRecentlyPlayed,
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            color: t.textPrimary,
                          ),
                        ),
                        Text(
                          l10n.libraryListeningHistory,
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
          ),
        ),
      ),
    );
  }

  Widget _buildSkeleton() {
    return const Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ShimmerBox(height: 104, radius: 22),
        SizedBox(height: AppSpacing.space4),
        ShimmerBox(height: 56, radius: AppRadius.lg),
        SizedBox(height: AppSpacing.space2),
        ShimmerBox(height: 56, radius: AppRadius.lg),
        SizedBox(height: AppSpacing.space2),
        ShimmerBox(height: 56, radius: AppRadius.lg),
        SizedBox(height: AppSpacing.space4),
        ShimmerBox(height: 64, radius: AppRadius.lg),
      ],
    );
  }

  Widget _buildError(BuildContext context, WidgetRef ref, Object error) {
    return AppErrorState(
      error: AppLocalizations.of(context).libraryLoadError,
      cause: error,
      onRetry: () => ref.invalidate(allPlaylistsProvider),
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
