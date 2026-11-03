import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/entities/playlist.dart';
import '../../domain/repositories/playlist_repository.dart';
import '../../data/repositories/playlist_repository_impl.dart';
import '../../../player/domain/entities/track.dart';
import '../../../player/presentation/providers/device_songs_provider.dart';
import 'downloaded_provider.dart';
import 'playlist_detail_provider.dart';

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
final playlistByIdProvider =
    FutureProvider.family<Playlist?, int>((ref, id) async {
  final repo = ref.watch(playlistRepositoryProvider);
  // virtual playlists use synthetic id -1 — resolve from allPlaylists
  if (id == -1) return null;
  return repo.getPlaylistById(id);
});

/// Distinct tracks reachable from the library hub header.
///
/// Unions Liked Songs, every user playlist, device songs and downloads, so a
/// track that appears in more than one place is counted once.
final libraryTrackTotalProvider = FutureProvider<int>((ref) async {
  final playlists = await ref.watch(allPlaylistsProvider.future);
  final liked = playlists
      .where((playlist) => playlist.isSystem && playlist.name == 'Liked Songs')
      .firstOrNull;
  final userPlaylists = playlists.where((playlist) => !playlist.isSystem);

  final sourceIds = <String>{};
  void addAll(Iterable<Track> tracks) {
    for (final track in tracks) {
      sourceIds.add(track.sourceId);
    }
  }

  if (liked != null) {
    addAll(await ref.watch(playlistTracksProvider(liked).future));
  }
  for (final playlist in userPlaylists) {
    addAll(await ref.watch(playlistTracksProvider(playlist).future));
  }
  addAll(await ref.watch(deviceSongsProvider.future));
  addAll(await ref.watch(downloadedTracksProvider.future));

  return sourceIds.length;
});
