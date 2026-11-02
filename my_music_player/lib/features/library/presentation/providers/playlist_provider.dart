import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/entities/playlist.dart';
import '../../domain/repositories/playlist_repository.dart';
import '../../data/repositories/playlist_repository_impl.dart';

final allPlaylistsProvider = FutureProvider<List<Playlist>>((ref) async {
  final repo = ref.watch(playlistRepositoryProvider);
  
  final virtuals = [
    await repo.getVirtualPlaylist(VirtualPlaylists.likedSongs),
    await repo.getVirtualPlaylist(VirtualPlaylists.recentlyPlayed),
    await repo.getVirtualPlaylist(VirtualPlaylists.cachedSongs),
  ];
  
  final users = await repo.getAllPlaylists();
  
  return [...virtuals, ...users];
});

/// Premium: fetch single playlist by id deep-link safe (no `extra` needed)
final playlistByIdProvider = FutureProvider.family<Playlist?, int>((ref, id) async {
  final repo = ref.watch(playlistRepositoryProvider);
  // virtual playlists use synthetic id -1 — resolve from allPlaylists
  if (id == -1) return null;
  return repo.getPlaylistById(id);
});
