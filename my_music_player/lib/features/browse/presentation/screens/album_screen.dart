import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_radius.dart';
import '../providers/browse_provider.dart';
import '../../domain/entities/browse_models.dart';
import '../../../player/presentation/providers/player_controller.dart';
import '../../../../shared/providers/palette_provider.dart';
import '../../../../shared/widgets/add_to_playlist_sheet.dart';

class AlbumScreen extends ConsumerWidget {
  final String albumId;

  const AlbumScreen({super.key, required this.albumId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final albumAsync = ref.watch(albumDetailsProvider(albumId));
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: AppColors.surfaceBase,
      body: albumAsync.when(
        data: (album) => _buildBody(context, ref, album, theme),
        loading: () => const Center(
            child: CircularProgressIndicator(color: AppColors.accentPrimary)),
        error: (err, stack) => Center(
            child: Text('Error: $err',
                style: const TextStyle(color: AppColors.statusError))),
      ),
    );
  }

  Widget _buildBody(BuildContext context, WidgetRef ref, AlbumDetails album,
      ThemeData theme) {
    final palette = ref.watch(paletteProvider(album.thumbnailUrl ?? ''));
    final dominantColor =
        palette.value?.dominantColor?.color ?? AppColors.surfaceBase;

    return CustomScrollView(
      slivers: [
        SliverAppBar(
          expandedHeight: 350.0,
          pinned: true,
          backgroundColor: dominantColor,
          flexibleSpace: FlexibleSpaceBar(
            background: Stack(
              fit: StackFit.expand,
              children: [
                if (album.thumbnailUrl != null)
                  CachedNetworkImage(
                    imageUrl: album.thumbnailUrl!,
                    fit: BoxFit.cover,
                  )
                else
                  const ColoredBox(
                      color: AppColors.surfaceElevated,
                      child: Icon(Icons.album,
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
                        album.title,
                        style: theme.textTheme.headlineSmall?.copyWith(
                            fontWeight: FontWeight.bold, color: Colors.white),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: AppSpacing.xs),
                      Text(
                        album.artist ?? 'Unknown Artist',
                        style: theme.textTheme.titleMedium?.copyWith(
                            color: dominantColor != AppColors.surfaceBase
                                ? dominantColor
                                : AppColors.accentPrimary,
                            fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: AppSpacing.xs),
                      Text(
                        'Album • ${album.year ?? ""} • ${album.trackCount ?? 0} songs',
                        style: theme.textTheme.bodyMedium
                            ?.copyWith(color: AppColors.textSecondary),
                      ),
                      const SizedBox(height: AppSpacing.lg),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          ElevatedButton.icon(
                            onPressed: () {
                              if (album.tracks.isNotEmpty) {
                                ref
                                    .read(playerControllerProvider.notifier)
                                    .playTrack(album.tracks.first,
                                        queue: album.tracks);
                              }
                            },
                            icon: const Icon(Icons.play_arrow,
                                color: Colors.black),
                            label: const Text('Play',
                                style: TextStyle(
                                    color: Colors.black,
                                    fontWeight: FontWeight.bold)),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.accentPrimary,
                              padding: const EdgeInsets.symmetric(
                                  horizontal: AppSpacing.xl,
                                  vertical: AppSpacing.md),
                              shape: RoundedRectangleBorder(
                                  borderRadius:
                                      BorderRadius.circular(AppRadius.full)),
                            ),
                          ),
                          const SizedBox(width: AppSpacing.md),
                          OutlinedButton.icon(
                            onPressed: () {
                              if (album.tracks.isNotEmpty) {
                                final shuffled = List.of(album.tracks)..shuffle();
                                ref.read(playerControllerProvider.notifier).playTrack(shuffled.first, queue: shuffled);
                              }
                            },
                            icon: const Icon(Icons.shuffle, color: AppColors.textPrimary),
                            label: const Text('Acak', style: TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.bold)),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: AppColors.textPrimary,
                              side: const BorderSide(color: AppColors.surfaceOverlay),
                              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl, vertical: AppSpacing.md),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.full)),
                            ),
                          ),
                          const SizedBox(width: AppSpacing.md),
                          Container(
                            decoration: const BoxDecoration(
                              color: AppColors.surfaceHover,
                              shape: BoxShape.circle,
                            ),
                            child: IconButton(
                              icon: const Icon(Icons.playlist_add,
                                  color: AppColors.textPrimary),
                              onPressed: () {
                                if (album.tracks.isNotEmpty) {
                                  showAddToPlaylistSheet(context,
                                      tracks: album.tracks);
                                }
                              },
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        SliverList(
          delegate: SliverChildBuilderDelegate(
            (context, index) {
              final track = album.tracks[index];
              final playerState = ref.watch(playerControllerProvider);
              final isPlaying =
                  playerState.currentTrack?.sourceId == track.sourceId;

              return ListTile(
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: AppSpacing.md),
                leading: isPlaying
                    ? const Icon(Icons.equalizer,
                        color: AppColors.accentPrimary)
                    : Text(
                        '${index + 1}',
                        style: theme.textTheme.titleMedium
                            ?.copyWith(color: AppColors.textTertiary),
                      ),
                title: Text(
                  track.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: isPlaying
                        ? AppColors.accentPrimary
                        : AppColors.textPrimary,
                    fontWeight: isPlaying ? FontWeight.bold : FontWeight.normal,
                  ),
                ),
                subtitle: Text(track.artist,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(color: AppColors.textSecondary)),
                trailing: PopupMenuButton<String>(
                  icon: const Icon(Icons.more_vert,
                      color: AppColors.textSecondary),
                  color: AppColors.surfaceElevated,
                  onSelected: (value) {
                    if (value == 'add_playlist') {
                      showAddToPlaylistSheet(context, track: track);
                    }
                  },
                  itemBuilder: (context) => [
                    const PopupMenuItem(
                      value: 'add_playlist',
                      child: Text('Add to Playlist',
                          style: TextStyle(color: AppColors.textPrimary)),
                    ),
                  ],
                ),
                onTap: () {
                  ref
                      .read(playerControllerProvider.notifier)
                      .playTrack(track, queue: album.tracks);
                },
              );
            },
            childCount: album.tracks.length,
          ),
        ),
        const SliverToBoxAdapter(child: SizedBox(height: 100)),
      ],
    );
  }
}
