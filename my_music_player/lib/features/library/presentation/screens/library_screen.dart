import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../shared/widgets/shimmer_loading.dart';
import '../providers/playlist_provider.dart';
import '../../data/repositories/playlist_repository_impl.dart';
import '../../../../shared/widgets/playlist_mosaic_cover.dart';
import '../../../player/presentation/providers/device_songs_provider.dart';

class LibraryScreen extends ConsumerWidget {
  const LibraryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final playlistsAsync = ref.watch(allPlaylistsProvider);

    return Scaffold(
      backgroundColor: AppColors.surfaceBase,
      appBar: AppBar(
        backgroundColor: AppColors.surfaceBase,
        title: Text('Your Library',
            style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(allPlaylistsProvider);
          try {
            await ref.read(allPlaylistsProvider.future);
          } catch (_) {}
        },
        color: AppColors.accentPrimary,
        backgroundColor: AppColors.surfaceElevated,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.only(
              left: AppSpacing.md,
              right: AppSpacing.md,
              top: AppSpacing.md,
              bottom: 160),
          child: Column(
            children: [
              playlistsAsync.when(
                data: (playlists) {
                  final deviceAsync = ref.watch(deviceSongsProvider);
                  final deviceCount = deviceAsync.value?.length ?? 0;
                  // Playlists + Device Songs + Rekap + Create = length+3
                  return GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      crossAxisSpacing: AppSpacing.sm,
                      mainAxisSpacing: AppSpacing.sm,
                      childAspectRatio: 0.95,
                    ),
                    itemCount: playlists.length + 3, // +1 Device +1 Rekap +1 Create
                    itemBuilder: (context, index) {
                      if (index == 0) {
                        return _buildDeviceSongsCard(context, ref, deviceCount);
                      }
                      if (index == 1) {
                        return _buildRecapCard(context);
                      }
                      if (index == playlists.length + 2) {
                        return _buildCreatePlaylistCard(context, ref);
                      }
                      final playlist = playlists[index - 2];
                      return _buildPlaylistCard(context, playlist);
                    },
                  );
                },
                loading: () => const ShimmerSection(isGrid: true, itemCount: 4),
                error: (e, st) => Center(
                    child: Text('Error: $e',
                        style: const TextStyle(color: AppColors.statusError))),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPlaylistCard(BuildContext context, dynamic playlist) {
    final theme = Theme.of(context);
    IconData icon;
    Color color;

    if (playlist.name == 'Liked Songs') {
      icon = Icons.favorite;
      color = Colors.pinkAccent;
    } else if (playlist.name == 'Recently Played') {
      icon = Icons.history;
      color = Colors.orangeAccent;
    } else if (playlist.name == 'Downloaded') {
      icon = Icons.offline_pin;
      color = AppColors.statusSuccess;
    } else {
      icon = Icons.queue_music;
      color = AppColors.accentPrimary;
    }

    return GestureDetector(
      onTap: () {
        if (playlist.name == 'Downloaded') {
          context.push('/library/downloaded');
        } else {
          context.push('/library/playlist-detail/${playlist.id}',
              extra: playlist);
        }
      },
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.surfaceElevated,
          borderRadius: BorderRadius.circular(AppRadius.lg),
          boxShadow: [
            BoxShadow(
              color: color.withValues(alpha: 0.1),
              blurRadius: 10,
              offset: const Offset(0, 4),
            )
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              child: ClipRRect(
                borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(AppRadius.lg)),
                child: PlaylistMosaicCover(
                  imageUrls: playlist.thumbnailUrls,
                  defaultIcon: icon,
                  iconColor: color,
                  size: 200.0,
                ),
              ),
            ),
            Container(
              padding: const EdgeInsets.all(AppSpacing.sm),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    AppColors.surfaceElevated,
                    AppColors.surfaceElevated.withValues(alpha: 0.9),
                  ],
                ),
                borderRadius: const BorderRadius.vertical(
                    bottom: Radius.circular(AppRadius.lg)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    playlist.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${playlist.trackCount} tracks',
                    style: theme.textTheme.bodyMedium
                        ?.copyWith(color: AppColors.textSecondary),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRecapCard(BuildContext context) {
    return GestureDetector(
      onTap: () => context.push('/library/recap'),
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.surfaceElevated,
          borderRadius: BorderRadius.circular(AppRadius.lg),
          boxShadow: [BoxShadow(color: Colors.amber.withValues(alpha: 0.12), blurRadius: 10, offset: const Offset(0, 4))],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              child: ClipRRect(
                borderRadius: const BorderRadius.vertical(top: Radius.circular(AppRadius.lg)),
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(colors: [Colors.amber.withValues(alpha: 0.9), Colors.deepOrange.withValues(alpha: 0.85)], begin: Alignment.topLeft, end: Alignment.bottomRight),
                  ),
                  child: const Icon(Icons.auto_awesome, size: 56, color: Colors.white),
                ),
              ),
            ),
            Container(
              padding: const EdgeInsets.all(AppSpacing.sm),
              decoration: BoxDecoration(
                gradient: LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [AppColors.surfaceElevated, AppColors.surfaceElevated.withValues(alpha: 0.9)]),
                borderRadius: const BorderRadius.vertical(bottom: Radius.circular(AppRadius.lg)),
              ),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('Rekap', maxLines: 1, overflow: TextOverflow.ellipsis, style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
                const SizedBox(height: 4),
                Text('Top lagu • artis • album', style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: AppColors.textSecondary)),
              ]),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDeviceSongsCard(BuildContext context, WidgetRef ref, int count) {
    return GestureDetector(
      onTap: () => context.push('/library/device-songs'),
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.surfaceElevated,
          borderRadius: BorderRadius.circular(AppRadius.lg),
          boxShadow: [
            BoxShadow(
              color: Colors.teal.withValues(alpha: 0.1),
              blurRadius: 10,
              offset: const Offset(0, 4),
            )
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              child: ClipRRect(
                borderRadius: const BorderRadius.vertical(top: Radius.circular(AppRadius.lg)),
                child: Container(
                  color: Colors.teal.withValues(alpha: 0.12),
                  child: const Icon(Icons.folder_special, size: 56, color: Colors.teal),
                ),
              ),
            ),
            Container(
              padding: const EdgeInsets.all(AppSpacing.sm),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [AppColors.surfaceElevated, AppColors.surfaceElevated.withValues(alpha: 0.9)],
                ),
                borderRadius: const BorderRadius.vertical(bottom: Radius.circular(AppRadius.lg)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Perangkat',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
                  const SizedBox(height: 4),
                  Text('$count lagu di perangkat',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: AppColors.textSecondary)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCreatePlaylistCard(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    return GestureDetector(
      onTap: () {
        _showCreatePlaylistDialog(context, ref);
      },
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.surfaceElevated.withValues(alpha: 0.3),
          borderRadius: BorderRadius.circular(AppRadius.lg),
          border: Border.all(color: AppColors.surfaceOverlay, width: 2),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(AppSpacing.md),
              decoration: const BoxDecoration(
                color: AppColors.surfaceOverlay,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.add,
                  size: 32, color: AppColors.accentPrimary),
            ),
            const SizedBox(height: AppSpacing.md),
            Text(
              'New Playlist',
              style: theme.textTheme.titleMedium?.copyWith(
                  color: AppColors.textPrimary, fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ),
    );
  }

  void _showCreatePlaylistDialog(BuildContext context, WidgetRef ref) {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.surfaceElevated,
        title: const Text('New Playlist'),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: const InputDecoration(
            hintText: 'Playlist name',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel',
                style: TextStyle(color: AppColors.textSecondary)),
          ),
          TextButton(
            onPressed: () async {
              final name = controller.text.trim();
              if (name.isNotEmpty) {
                await ref.read(playlistRepositoryProvider).createPlaylist(name);
                ref.invalidate(allPlaylistsProvider);
              }
              if (context.mounted) Navigator.pop(context);
            },
            child: const Text('Create',
                style: TextStyle(color: AppColors.accentPrimary)),
          ),
        ],
      ),
    );
  }
}
