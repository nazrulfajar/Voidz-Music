import '../../../player/domain/entities/track.dart';
import '../entities/playlist.dart';

abstract class PlaylistRepository {
  Future<Playlist> createPlaylist(String name, {String? description});
  Future<void> updatePlaylist(Playlist playlist);
  Future<void> deletePlaylist(int id);
  Future<List<Playlist>> getAllPlaylists();
  Future<Playlist?> getPlaylistById(int id);
  
  // Track operations inside playlist
  Future<List<Track>> getPlaylistTracks(int playlistId);
  Future<void> addTrackToPlaylist(int playlistId, Track track);
  /// Premium batch: single writeTxn, return {added, existed}
  Future<({int added, int existed})> addTracksToPlaylist(int playlistId, List<Track> tracks);
  Future<void> removeTrackFromPlaylist(int playlistId, String trackSourceId);
  Future<void> reorderTracks(int playlistId, int oldIndex, int newIndex);
  
  // Virtual Playlists (System)
  Future<Playlist> getVirtualPlaylist(String virtualId);
  
  // Play History
  Future<void> addToPlayHistory(String trackSourceId);
  Future<List<Track>> getPlayHistory({int limit = 20});

  /// Distinct tracks played since [now] minus [days], newest first.
  ///
  /// [now] is injectable so tests can pin the cutoff.
  Future<List<Track>> getRecentlyPlayedTracks({
    int days = 30,
    int limit = 100,
    DateTime? now,
  });

  /// Distinct `trackSourceId` values played since [now] minus [days].
  Future<int> getRecentlyPlayedCount({int days = 30, DateTime? now});

  /// Deletes the play history and clears `lastPlayedAt`.
  ///
  /// `playCount` is intentionally preserved for recap and track stats.
  Future<void> clearPlayHistory();
}

// Constants for virtual playlists
class VirtualPlaylists {
  static const String likedSongs = '__liked_songs__';
  static const String recentlyPlayed = '__recently_played__';
  static const String cachedSongs = '__cached_songs__';
}
