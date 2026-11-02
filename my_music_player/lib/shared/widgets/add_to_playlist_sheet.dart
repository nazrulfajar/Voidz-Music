import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_radius.dart';
import '../../features/player/domain/entities/track.dart';
import '../../features/library/presentation/providers/playlist_provider.dart';
import '../../features/library/data/repositories/playlist_repository_impl.dart';
import 'create_playlist_dialog.dart';

void showAddToPlaylistSheet(BuildContext context, {Track? track, List<Track>? tracks}) {
  assert(track != null || tracks != null);
  final tracksToAdd = tracks ?? [track!];
  showModalBottomSheet(
    context: context,
    backgroundColor: Colors.transparent,
    isScrollControlled: true,
    useRootNavigator: true, // premium: sheet above shell + miniPlayer
    builder: (context) => _AddToPlaylistSheet(tracks: tracksToAdd),
  );
}

class _AddToPlaylistSheet extends ConsumerWidget {
  final List<Track> tracks;

  const _AddToPlaylistSheet({required this.tracks});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final playlistsAsync = ref.watch(allPlaylistsProvider);

    return Container(
      constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.7),
      decoration: const BoxDecoration(
        color: AppColors.surfaceElevated,
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.lg)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: AppSpacing.sm),
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: AppColors.surfaceOverlay,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
            child: Text(
              'Add to Playlist',
              style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          Expanded(
            child: playlistsAsync.when(
              data: (playlists) {
                // Filter out system playlists (like Liked Songs, Recently Played, etc)
                final customPlaylists = playlists.where((p) => !p.isSystem).toList();
                
                if (customPlaylists.isEmpty) {
                  return Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text('No custom playlists found.', style: TextStyle(color: AppColors.textSecondary)),
                      const SizedBox(height: AppSpacing.md),
                      ElevatedButton.icon(
                        onPressed: () => _showCreatePlaylistDialog(context, ref, tracks),
                        icon: const Icon(Icons.add),
                        label: const Text('Create New Playlist'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.surfaceOverlay,
                          foregroundColor: AppColors.accentPrimary,
                        ),
                      ),
                    ],
                  );
                }

                return ListView.builder(
                  itemCount: customPlaylists.length + 1,
                  itemBuilder: (context, index) {
                    if (index == 0) {
                      return ListTile(
                        leading: Container(
                          width: 48,
                          height: 48,
                          decoration: const BoxDecoration(
                            color: AppColors.surfaceOverlay,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.add, color: AppColors.accentPrimary),
                        ),
                        title: const Text('New Playlist', style: TextStyle(color: AppColors.accentPrimary, fontWeight: FontWeight.bold)),
                        onTap: () {
                           _showCreatePlaylistDialog(context, ref, tracks);
                        },
                      );
                    }
                    final playlist = customPlaylists[index - 1];
                    return ListTile(
                      leading: const Icon(Icons.queue_music, color: AppColors.textSecondary),
                      title: Text(playlist.name),
                      subtitle: Text('${playlist.trackCount} tracks', style: const TextStyle(color: AppColors.textSecondary)),
                      onTap: () async {
                        final messenger = ScaffoldMessenger.of(context);
                        final res = await ref.read(playlistRepositoryProvider).addTracksToPlaylist(playlist.id!, tracks);
                        ref.invalidate(allPlaylistsProvider);
                        if (context.mounted) {
                          Navigator.pop(context);
                          final msg = res.added == 0
                              ? 'Already in ${playlist.name}'
                              : (tracks.length == 1 ? 'Added to ${playlist.name}' : 'Added ${res.added} tracks to ${playlist.name}${res.existed > 0 ? ' (${res.existed} already existed)' : ''}');
                          messenger.showSnackBar(SnackBar(content: Text(msg, style: const TextStyle(color: AppColors.textPrimary)), backgroundColor: AppColors.surfaceOverlay));
                        }
                      },
                    );
                  },
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, st) => Center(child: Text('Error: $e')),
            ),
          ),
        ],
      ),
    );
  }

  void _showCreatePlaylistDialog(BuildContext context, WidgetRef ref, List<Track> tracks) {
    // Reuse single dialog — tidak duplikat, tidak leak controller
    showCreateAndAddDialog(context, ref, tracks);
  }
}
