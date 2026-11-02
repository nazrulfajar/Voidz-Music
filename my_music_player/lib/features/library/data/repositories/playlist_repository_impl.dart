import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:isar/isar.dart';
import '../../domain/entities/playlist.dart';
import '../../domain/repositories/playlist_repository.dart';
import '../../../player/domain/entities/track.dart';
import '../../../player/data/models/track_model.dart';
import '../../../../core/constants/enums.dart';
import '../../../../core/providers/isar_provider.dart';
import '../models/playlist_model.dart';
import '../models/playlist_track_model.dart';
import '../models/play_history_model.dart';

final playlistRepositoryProvider = Provider<PlaylistRepository>((ref) {
  final isar = ref.watch(isarProvider);
  return PlaylistRepositoryImpl(isar);
});

class PlaylistRepositoryImpl implements PlaylistRepository {
  final Isar isar;

  PlaylistRepositoryImpl(this.isar);

  @override
  Future<Playlist> createPlaylist(String name, {String? description}) async {
    final now = DateTime.now();
    final model = PlaylistModel()
      ..name = name
      ..description = description
      ..createdAt = now
      ..updatedAt = now;

    await isar.writeTxn(() async {
      await isar.playlistModels.put(model);
    });

    return _mapPlaylistModelToEntity(model, 0, const []);
  }

  @override
  Future<void> updatePlaylist(Playlist playlist) async {
    if (playlist.id == null) return;
    
    final model = await isar.playlistModels.get(playlist.id!);
    if (model == null) return;

    model.name = playlist.name;
    model.description = playlist.description;
    model.updatedAt = DateTime.now();

    await isar.writeTxn(() async {
      await isar.playlistModels.put(model);
    });
  }

  @override
  Future<void> deletePlaylist(int id) async {
    await isar.writeTxn(() async {
      await isar.playlistModels.delete(id);
      await isar.playlistTrackModels.filter().playlistIdEqualTo(id).deleteAll();
    });
  }

  // Premium: single helper — tidak duplikat mosaic logic di 2 method
  Future<List<String>> _thumbUrlsForPlaylist(int playlistId) async {
    final firstPtModels = await isar.playlistTrackModels
        .filter()
        .playlistIdEqualTo(playlistId)
        .sortByOrderIndex()
        .limit(4)
        .findAll();
    final urls = <String>[];
    for (final pt in firstPtModels) {
      final tm = await isar.trackModels.filter().sourceIdEqualTo(pt.trackSourceId).findFirst();
      if (tm != null) {
        final url = tm.localThumbnailPath ?? tm.thumbnailUrl;
        if (url != null && url.isNotEmpty) urls.add(url);
      }
    }
    return urls;
  }

  @override
  Future<List<Playlist>> getAllPlaylists() async {
    final models = await isar.playlistModels.where().findAll();
    final result = <Playlist>[];
    for (final model in models) {
      final count = await isar.playlistTrackModels.filter().playlistIdEqualTo(model.id).count();
      final thumbnailUrls = await _thumbUrlsForPlaylist(model.id);
      result.add(_mapPlaylistModelToEntity(model, count, thumbnailUrls));
    }
    return result;
  }

  @override
  Future<Playlist?> getPlaylistById(int id) async {
    final model = await isar.playlistModels.get(id);
    if (model == null) return null;
    final count = await isar.playlistTrackModels.filter().playlistIdEqualTo(id).count();
    final thumbnailUrls = await _thumbUrlsForPlaylist(model.id);
    return _mapPlaylistModelToEntity(model, count, thumbnailUrls);
  }

  @override
  Future<List<Track>> getPlaylistTracks(int playlistId) async {
    final ptModels = await isar.playlistTrackModels
        .filter()
        .playlistIdEqualTo(playlistId)
        .sortByOrderIndex()
        .findAll();
        
    final trackSourceIds = ptModels.map((e) => e.trackSourceId).toList();
    
    final tracks = <Track>[];
    for (final id in trackSourceIds) {
      final trackModel = await isar.trackModels.filter().sourceIdEqualTo(id).findFirst();
      if (trackModel != null) {
        tracks.add(Track.fromModel(trackModel));
      }
    }
    
    return tracks;
  }

  @override
  Future<void> addTrackToPlaylist(int playlistId, Track track) async {
    final res = await addTracksToPlaylist(playlistId, [track]);
    if (res.existed > 0) {
      // No-op for UI, caller shows AlreadyExists
    }
  }

  @override
  Future<({int added, int existed})> addTracksToPlaylist(int playlistId, List<Track> tracks) async {
    if (tracks.isEmpty) return (added: 0, existed: 0);
    // Batch check exists in single query
    final ids = tracks.map((t) => t.sourceId).toList();
    var q = isar.playlistTrackModels.filter().playlistIdEqualTo(playlistId).trackSourceIdEqualTo(ids[0]);
    for (int i = 1; i < ids.length; i++) {
      q = q.or().playlistIdEqualTo(playlistId).trackSourceIdEqualTo(ids[i]);
    }
    final existingModels = await q.findAll();
    final existingIds = existingModels.map((m) => m.trackSourceId).toSet();

    final toAdd = tracks.where((t) => !existingIds.contains(t.sourceId)).toList();
    final existed = tracks.length - toAdd.length;
    if (toAdd.isEmpty) return (added: 0, existed: existed);

    final lastItem = await isar.playlistTrackModels
        .filter()
        .playlistIdEqualTo(playlistId)
        .sortByOrderIndexDesc()
        .findFirst();
    int nextOrder = (lastItem?.orderIndex ?? -1) + 1;
    final models = toAdd.map((track) => PlaylistTrackModel()
      ..playlistId = playlistId
      ..trackSourceId = track.sourceId
      ..orderIndex = nextOrder++
      ..addedAt = DateTime.now()).toList();

    await isar.writeTxn(() async {
      await isar.playlistTrackModels.putAll(models);
      final playlist = await isar.playlistModels.get(playlistId);
      if (playlist != null) {
        playlist.updatedAt = DateTime.now();
        await isar.playlistModels.put(playlist);
      }
    });
    return (added: toAdd.length, existed: existed);
  }

  @override
  Future<void> removeTrackFromPlaylist(int playlistId, String trackSourceId) async {
    await isar.writeTxn(() async {
      await isar.playlistTrackModels
          .filter()
          .playlistIdEqualTo(playlistId)
          .trackSourceIdEqualTo(trackSourceId)
          .deleteAll();
          
      // We should ideally re-adjust orderIndex for remaining items, but not strictly necessary for display
      final playlist = await isar.playlistModels.get(playlistId);
      if (playlist != null) {
        playlist.updatedAt = DateTime.now();
        await isar.playlistModels.put(playlist);
      }
    });
  }

  @override
  Future<void> reorderTracks(int playlistId, int oldIndex, int newIndex) async {
    // Reorder logic
    if (oldIndex == newIndex) return;
    
    final tracks = await isar.playlistTrackModels
        .filter()
        .playlistIdEqualTo(playlistId)
        .sortByOrderIndex()
        .findAll();
        
    if (oldIndex >= tracks.length || newIndex > tracks.length) return;
    
    if (newIndex > oldIndex) {
      newIndex -= 1;
    }
    
    final item = tracks.removeAt(oldIndex);
    tracks.insert(newIndex, item);
    
    await isar.writeTxn(() async {
      for (int i = 0; i < tracks.length; i++) {
        tracks[i].orderIndex = i;
        await isar.playlistTrackModels.put(tracks[i]);
      }
    });
  }

  @override
  Future<Playlist> getVirtualPlaylist(String virtualId) async {
    String name = 'Playlist';
    int count = 0;
    List<String> thumbnailUrls = [];
    List<TrackModel> topTracks = [];
    
    if (virtualId == VirtualPlaylists.likedSongs) {
      name = 'Liked Songs';
      count = await isar.trackModels.filter().isLikedEqualTo(true).count();
      topTracks = await isar.trackModels.filter().isLikedEqualTo(true).limit(4).findAll();
    } else if (virtualId == VirtualPlaylists.recentlyPlayed) {
      name = 'Recently Played';
      count = await isar.trackModels.filter().lastPlayedAtIsNotNull().count();
      topTracks = await isar.trackModels
          .filter()
          .lastPlayedAtIsNotNull()
          .sortByLastPlayedAtDesc()
          .limit(4)
          .findAll();
    } else if (virtualId == VirtualPlaylists.cachedSongs) {
      name = 'Downloaded';
      // Exclude local device songs
      final allCached = await isar.trackModels.filter().isCachedEqualTo(true).findAll();
      final downloaded = allCached.where((t) => t.source != TrackSource.local).toList();
      count = downloaded.length;
      topTracks = downloaded.take(4).toList();
    }
    
    for (final trackModel in topTracks) {
      final url = trackModel.localThumbnailPath ?? trackModel.thumbnailUrl;
      if (url != null && url.isNotEmpty) {
        thumbnailUrls.add(url);
      }
    }
    
    return Playlist(
      id: -1, // Use -1 to denote virtual
      name: name,
      isSystem: true,
      trackCount: count,
      thumbnailUrls: thumbnailUrls,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
  }

  @override
  Future<void> addToPlayHistory(String trackSourceId) async {
    final model = PlayHistoryModel()
      ..trackSourceId = trackSourceId
      ..playedAt = DateTime.now();
      
    await isar.writeTxn(() async {
      await isar.playHistoryModels.put(model);
      
      // Enforce 10000 items limit for yearly Recap (was 1000 → hilang Jan-Nov)
      final count = await isar.playHistoryModels.count();
      if (count > 10000) {
        // Delete oldest
        final toDeleteCount = count - 10000;
        final toDelete = await isar.playHistoryModels.where().sortByPlayedAt().limit(toDeleteCount).findAll();
        for (final item in toDelete) {
          await isar.playHistoryModels.delete(item.id);
        }
      }
    });
  }

  @override
  Future<List<Track>> getPlayHistory({int limit = 20}) async {
    final trackModels = await isar.trackModels
        .filter()
        .lastPlayedAtIsNotNull()
        .sortByLastPlayedAtDesc()
        .limit(limit)
        .findAll();
        
    return trackModels.map((m) => Track.fromModel(m)).toList();
  }

  @override
  Future<List<Track>> getRecentlyPlayedTracks({
    int days = 30,
    int limit = 100,
    DateTime? now,
  }) async {
    if (days <= 0 || limit <= 0) return const [];

    final history = await _playHistorySince(days: days, now: now);
    final seen = <String>{};
    final sourceIds = <String>[];
    for (final entry in history) {
      if (!seen.add(entry.trackSourceId)) continue;
      sourceIds.add(entry.trackSourceId);
      if (sourceIds.length >= limit) break;
    }

    final tracks = <Track>[];
    for (final sourceId in sourceIds) {
      final model = await isar.trackModels
          .filter()
          .sourceIdEqualTo(sourceId)
          .findFirst();
      if (model != null) tracks.add(Track.fromModel(model));
    }
    return tracks;
  }

  @override
  Future<int> getRecentlyPlayedCount({int days = 30, DateTime? now}) async {
    if (days <= 0) return 0;
    final history = await _playHistorySince(days: days, now: now);
    return history.map((entry) => entry.trackSourceId).toSet().length;
  }

  Future<List<PlayHistoryModel>> _playHistorySince({
    required int days,
    DateTime? now,
  }) {
    final cutoff = (now ?? DateTime.now()).subtract(Duration(days: days));
    return isar.playHistoryModels
        .filter()
        .playedAtGreaterThan(cutoff, include: true)
        .sortByPlayedAtDesc()
        .findAll();
  }

  @override
  Future<void> clearPlayHistory() async {
    await isar.writeTxn(() async {
      await isar.playHistoryModels.clear();
      final tracks = await isar.trackModels
          .filter()
          .lastPlayedAtIsNotNull()
          .findAll();
      for (final track in tracks) {
        track.lastPlayedAt = null;
      }
      await isar.trackModels.putAll(tracks);
    });
  }
  
  Playlist _mapPlaylistModelToEntity(PlaylistModel model, int trackCount, List<String> thumbnailUrls) {
    return Playlist(
      id: model.id,
      name: model.name,
      description: model.description,
      isSystem: model.isSystem,
      trackCount: trackCount,
      thumbnailUrls: thumbnailUrls,
      createdAt: model.createdAt,
      updatedAt: model.updatedAt,
    );
  }
}
