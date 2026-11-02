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

class PlaylistScreen extends ConsumerWidget {
  final String playlistId;

  const PlaylistScreen({super.key, required this.playlistId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final playlistAsync = ref.watch(playlistDetailsProvider(playlistId));
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: AppColors.surfaceBase,
      body: playlistAsync.when(
        data: (playlist) => _buildBody(context, ref, playlist, theme),
        loading: () => const Center(
            child: CircularProgressIndicator(color: AppColors.accentPrimary)),
        error: (err, stack) => Center(
            child: Text('Error: $err',
                style: const TextStyle(color: AppColors.statusError))),
      ),
    );
  }

  Widget _buildBody(BuildContext context, WidgetRef ref,
      PlaylistDetails playlist, ThemeData theme) {
    final palette = ref.watch(paletteProvider(playlist.thumbnailUrl ?? ''));
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
                if (playlist.thumbnailUrl != null)
                  CachedNetworkImage(
                    imageUrl: playlist.thumbnailUrl!,
                    fit: BoxFit.cover,
                  )
                else
                  const ColoredBox(
                      color: AppColors.surfaceElevated,
                      child: Icon(Icons.playlist_play,
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
                        playlist.title,
                        style: theme.textTheme.headlineSmall?.copyWith(
                            fontWeight: FontWeight.bold, color: Colors.white),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: AppSpacing.xs),
                      Text(
                        playlist.author ?? 'Unknown Author',
                        style: theme.textTheme.titleMedium?.copyWith(
                            color: dominantColor != AppColors.surfaceBase
                                ? dominantColor
                                : AppColors.accentPrimary,
                            fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: AppSpacing.xs),
                      Text(
                        'Playlist • ${playlist.trackCount ?? 0} songs',
                        style: theme.textTheme.bodyMedium
                            ?.copyWith(color: AppColors.textSecondary),
                      ),
                      const SizedBox(height: AppSpacing.lg),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          ElevatedButton.icon(
                            onPressed: () {
                              if (playlist.tracks.isNotEmpty) {
                                ref.read(playerControllerProvider.notifier).playTrack(playlist.tracks.first, queue: playlist.tracks);
                              }
                            },
                            icon: const Icon(Icons.play_arrow, color: Colors.black),
                            label: const Text('Play All', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
                            style: ElevatedButton.styleFrom(backgroundColor: AppColors.accentPrimary, foregroundColor: Colors.black, padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl, vertical: AppSpacing.md), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.full))),
                          ),
                          const SizedBox(width: AppSpacing.md),
                          OutlinedButton.icon(
                            onPressed: () {
                              if (playlist.tracks.isNotEmpty) {
                                final shuffled = List.of(playlist.tracks)..shuffle();
                                ref.read(playerControllerProvider.notifier).playTrack(shuffled.first, queue: shuffled);
                              }
                            },
                            icon: const Icon(Icons.shuffle, color: AppColors.textPrimary),
                            label: const Text('Acak', style: TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.bold)),
                            style: OutlinedButton.styleFrom(foregroundColor: AppColors.textPrimary, side: const BorderSide(color: AppColors.surfaceOverlay), padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl, vertical: AppSpacing.md), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.full))),
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
              if (index == playlist.tracks.length) {
                return const SizedBox(height: 120); // Bottom padding
              }
              final track = playlist.tracks[index];
              return ListTile(
                contentPadding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.lg, vertical: AppSpacing.xs),
                leading: ClipRRect(
                  borderRadius: BorderRadius.circular(AppRadius.sm),
                  child: CachedNetworkImage(
                    imageUrl: track.thumbnailUrl ?? '',
                    width: 48,
                    height: 48,
                    fit: BoxFit.cover,
                    errorWidget: (context, url, error) => const ColoredBox(
                        color: AppColors.surfaceElevated,
                        child: Icon(Icons.music_note,
                            color: AppColors.textSecondary)),
                  ),
                ),
                title: Text(track.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontWeight: FontWeight.w600)),
                subtitle: Text(track.artist,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(color: AppColors.textSecondary)),
                trailing: IconButton(
                  icon: const Icon(Icons.more_vert,
                      color: AppColors.textSecondary),
                  onPressed: () {
                    showAddToPlaylistSheet(context, track: track);
                  },
                ),
                onTap: () {
                  ref
                      .read(playerControllerProvider.notifier)
                      .playTrack(track, queue: playlist.tracks);
                },
              );
            },
            childCount: playlist.tracks.length + 1,
          ),
        ),
      ],
    );
  }
}
