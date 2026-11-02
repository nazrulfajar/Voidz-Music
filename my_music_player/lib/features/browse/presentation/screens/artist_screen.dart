import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_radius.dart';
import '../providers/browse_provider.dart';
import '../../domain/entities/browse_models.dart';
import '../../../player/presentation/providers/player_controller.dart';
import '../../../../shared/providers/palette_provider.dart';

class ArtistScreen extends ConsumerWidget {
  final String artistId;

  const ArtistScreen({super.key, required this.artistId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final artistAsync = ref.watch(artistDetailsProvider(artistId));
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: AppColors.surfaceBase,
      body: artistAsync.when(
        data: (artist) => _buildBody(context, ref, artist, theme),
        loading: () => const Center(
            child: CircularProgressIndicator(color: AppColors.accentPrimary)),
        error: (err, stack) => Center(
            child: Text('Error: $err',
                style: const TextStyle(color: AppColors.statusError))),
      ),
    );
  }

  Widget _buildBody(BuildContext context, WidgetRef ref, ArtistDetails artist,
      ThemeData theme) {
    final palette = ref.watch(paletteProvider(artist.thumbnailUrl ?? ''));
    final dominantColor =
        palette.value?.dominantColor?.color ?? AppColors.surfaceBase;

    return CustomScrollView(
      slivers: [
        SliverAppBar(
          expandedHeight: 300.0,
          pinned: true,
          backgroundColor: dominantColor,
          flexibleSpace: FlexibleSpaceBar(
            background: Stack(
              fit: StackFit.expand,
              children: [
                if (artist.thumbnailUrl != null)
                  CachedNetworkImage(
                    imageUrl: artist.thumbnailUrl!,
                    fit: BoxFit.cover,
                  )
                else
                  const ColoredBox(
                      color: AppColors.surfaceElevated,
                      child: Icon(Icons.person,
                          size: 80, color: AppColors.textSecondary)),
                Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        dominantColor.withValues(alpha: 0.4),
                        AppColors.surfaceBase.withValues(alpha: 0.8),
                        AppColors.surfaceBase,
                      ],
                    ),
                  ),
                ),
                Positioned(
                  bottom: AppSpacing.lg,
                  left: AppSpacing.lg,
                  right: AppSpacing.lg,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Text(
                        artist.name,
                        style: theme.textTheme.headlineMedium?.copyWith(
                            fontWeight: FontWeight.bold, color: Colors.white),
                        textAlign: TextAlign.center,
                      ),
                      if (artist.subscribers != null) ...[
                        const SizedBox(height: AppSpacing.xs),
                        Text(
                          '${artist.subscribers}',
                          style: theme.textTheme.bodyMedium?.copyWith(
                              color: dominantColor != AppColors.surfaceBase
                                  ? dominantColor
                                  : AppColors.accentPrimary),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        if (artist.topSongs.isNotEmpty) ...[
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.sm),
              child: Row(
                children: [
                  Text('Top Songs', style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
                  const Spacer(),
                  ElevatedButton.icon(
                    onPressed: () => ref.read(playerControllerProvider.notifier).playTrack(artist.topSongs.first, queue: artist.topSongs),
                    icon: const Icon(Icons.play_arrow, size: 18, color: Colors.black),
                    label: const Text('Play All', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 12)),
                    style: ElevatedButton.styleFrom(backgroundColor: AppColors.accentPrimary, padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.full)), minimumSize: const Size(0, 32)),
                  ),
                  const SizedBox(width: 8),
                  OutlinedButton.icon(
                    onPressed: () { final s = List.of(artist.topSongs)..shuffle(); ref.read(playerControllerProvider.notifier).playTrack(s.first, queue: s); },
                    icon: const Icon(Icons.shuffle, size: 14, color: AppColors.textPrimary),
                    label: const Text('Acak', style: TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.bold, fontSize: 12)),
                    style: OutlinedButton.styleFrom(foregroundColor: AppColors.textPrimary, side: const BorderSide(color: AppColors.surfaceOverlay), padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.full)), minimumSize: const Size(0, 32)),
                  ),
                ],
              ),
            ),
          ),
          SliverList(
            delegate: SliverChildBuilderDelegate(
              (context, index) {
                final track = artist.topSongs[index];
                final playerState = ref.watch(playerControllerProvider);
                final isPlaying = playerState.currentTrack?.sourceId == track.sourceId;
                return ListTile(
                  contentPadding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
                  leading: ClipRRect(
                    borderRadius: BorderRadius.circular(AppRadius.sm),
                    child: track.thumbnailUrl != null ? CachedNetworkImage(imageUrl: track.thumbnailUrl!, width: 48, height: 48, fit: BoxFit.cover, errorWidget: (_, __, ___) => Container(width: 48, height: 48, color: AppColors.surfaceOverlay, child: const Icon(Icons.music_note))) : Container(width: 48, height: 48, color: AppColors.surfaceOverlay, child: const Icon(Icons.music_note)),
                  ),
                  title: Text(track.title, maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(color: isPlaying ? AppColors.accentPrimary : AppColors.textPrimary, fontWeight: isPlaying ? FontWeight.bold : FontWeight.normal)),
                  subtitle: Text(track.artist, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(color: AppColors.textSecondary)),
                  trailing: isPlaying ? const Icon(Icons.equalizer, color: AppColors.accentPrimary) : const Icon(Icons.more_vert, color: AppColors.textSecondary),
                  onTap: () {
                    ref.read(playerControllerProvider.notifier).playTrack(track, queue: artist.topSongs);
                  },
                );
              },
              childCount: artist.topSongs.length > 5 ? 5 : artist.topSongs.length,
            ),
          ),
        ],
        if (artist.albums.isNotEmpty) ...[
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(
                  AppSpacing.md, AppSpacing.xl, AppSpacing.md, AppSpacing.sm),
              child: Text('Albums',
                  style: theme.textTheme.titleLarge
                      ?.copyWith(fontWeight: FontWeight.bold)),
            ),
          ),
          SliverToBoxAdapter(
            child: SizedBox(
              height: 200,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
                itemCount: artist.albums.length,
                itemBuilder: (context, index) {
                  return _buildAlbumCard(context, artist.albums[index], theme);
                },
              ),
            ),
          ),
        ],
        if (artist.singles.isNotEmpty) ...[
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(
                  AppSpacing.md, AppSpacing.xl, AppSpacing.md, AppSpacing.sm),
              child: Text('Singles & EPs',
                  style: theme.textTheme.titleLarge
                      ?.copyWith(fontWeight: FontWeight.bold)),
            ),
          ),
          SliverToBoxAdapter(
            child: SizedBox(
              height: 200,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
                itemCount: artist.singles.length,
                itemBuilder: (context, index) {
                  return _buildAlbumCard(context, artist.singles[index], theme);
                },
              ),
            ),
          ),
        ],
        if (artist.playlists.isNotEmpty) ...[
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(
                  AppSpacing.md, AppSpacing.xl, AppSpacing.md, AppSpacing.sm),
              child: Text('Playlists',
                  style: theme.textTheme.titleLarge
                      ?.copyWith(fontWeight: FontWeight.bold)),
            ),
          ),
          SliverToBoxAdapter(
            child: SizedBox(
              height: 200,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
                itemCount: artist.playlists.length,
                itemBuilder: (context, index) {
                  return _buildPlaylistCard(
                      context, artist.playlists[index], theme);
                },
              ),
            ),
          ),
        ],
        const SliverToBoxAdapter(child: SizedBox(height: 100)),
      ],
    );
  }

  Widget _buildAlbumCard(
      BuildContext context, AlbumItem album, ThemeData theme) {
    return GestureDetector(
      onTap: () {
        // Premium: canonical push — works from any branch (Home/Search/Library) without tab switch
        context.push('/album/${album.browseId}');
      },
      child: Container(
        width: 140,
        margin: const EdgeInsets.only(right: AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 140,
              height: 140,
              decoration: BoxDecoration(
                color: AppColors.surfaceOverlay,
                borderRadius: BorderRadius.circular(AppRadius.md),
                image: album.thumbnailUrl != null
                    ? DecorationImage(
                        image: CachedNetworkImageProvider(album.thumbnailUrl!),
                        fit: BoxFit.cover)
                    : null,
              ),
              child: album.thumbnailUrl == null
                  ? const Icon(Icons.album, size: 40)
                  : null,
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              album.title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.bodyMedium
                  ?.copyWith(fontWeight: FontWeight.w600),
            ),
            if (album.year != null)
              Text(
                album.year!,
                style: theme.textTheme.bodySmall
                    ?.copyWith(color: AppColors.textSecondary),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildPlaylistCard(
      BuildContext context, PlaylistItem playlist, ThemeData theme) {
    return GestureDetector(
      onTap: () {
        context.push('/playlist/${playlist.browseId}');
      },
      child: Container(
        width: 140,
        margin: const EdgeInsets.only(right: AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 140,
              height: 140,
              decoration: BoxDecoration(
                color: AppColors.surfaceOverlay,
                borderRadius: BorderRadius.circular(AppRadius.md),
                image: playlist.thumbnailUrl != null
                    ? DecorationImage(
                        image:
                            CachedNetworkImageProvider(playlist.thumbnailUrl!),
                        fit: BoxFit.cover)
                    : null,
              ),
              child: playlist.thumbnailUrl == null
                  ? const Icon(Icons.playlist_play, size: 40)
                  : null,
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              playlist.title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.bodyMedium
                  ?.copyWith(fontWeight: FontWeight.w600),
            ),
            if (playlist.author != null)
              Text(
                playlist.author!,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.bodySmall
                    ?.copyWith(color: AppColors.textSecondary),
              ),
          ],
        ),
      ),
    );
  }
}
