import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:isar/isar.dart';
import '../../../../core/providers/isar_provider.dart';
import '../../../player/domain/entities/track.dart';
import '../../../player/data/models/track_model.dart';
import '../../../library/data/models/play_history_model.dart';
import '../../domain/entities/recap.dart';
import '../../domain/entities/recap_period.dart';

final recapRepositoryProvider = Provider<RecapRepository>((ref) {
  final isar = ref.read(isarProvider);
  return RecapRepository(isar);
});

class RecapRepository {
  final Isar isar;
  RecapRepository(this.isar);

  /// Returns the recap for [year], or for [month] when it is provided.
  ///
  /// `month` is `1..12`. The yearly behaviour is unchanged: the range is
  /// `[January 1, next January 1)`.
  Future<Recap> getRecap(int year, {int? month}) async {
    final range = RecapPeriodRange.of(
      period: month == null ? RecapPeriod.year : RecapPeriod.month,
      year: year,
      month: month,
    );
    final histories = await isar.playHistoryModels
        .filter()
        .playedAtBetween(range.start, range.end,
            includeLower: true, includeUpper: false)
        .findAll();

    if (histories.isEmpty) return Recap.empty(year);

    // Count per trackSourceId
    final countMap = <String, int>{};
    for (final h in histories) {
      countMap[h.trackSourceId] = (countMap[h.trackSourceId] ?? 0) + 1;
    }
    final sortedEntries = countMap.entries.toList()..sort((a, b) => b.value.compareTo(a.value));
    final totalPlays = histories.length;
    final totalTracks = countMap.length;

    // Top 5 ids
    final topIds = sortedEntries.take(5).map((e) => e.key).toList();
    // Batch fetch tracks
    final tracksById = <String, Track>{};
    // Use OR chunk 80 like track_repository_impl
    for (int i = 0; i < topIds.length; i += 80) {
      final chunk = topIds.sublist(i, (i + 80).clamp(0, topIds.length));
      if (chunk.isEmpty) continue;
      var q = isar.trackModels.filter().sourceIdEqualTo(chunk[0]);
      for (int j = 1; j < chunk.length; j++) {
        q = q.or().sourceIdEqualTo(chunk[j]);
      }
      final models = await q.findAll();
      for (final m in models) {
        tracksById[m.sourceId] = Track.fromModel(m);
      }
    }
    // For missing tracks (deleted cache?), create placeholder fallback
    final topSongs = <Track>[];
    final topCounts = <int>[];
    for (final e in sortedEntries.take(5)) {
      final t = tracksById[e.key];
      if (t != null) {
        topSongs.add(t);
        topCounts.add(e.value);
      }
    }
    final mostPlayed = topSongs.isNotEmpty ? topSongs.first : null;
    final mostCount = topCounts.isNotEmpty ? topCounts.first : 0;

    // Top artists: group by artist sum counts
    // Need all tracks for histories to map artist, fetch remaining if needed
    // For MVP fetch all distinct trackSourceIds (could be many), but yearly distinct usually <500
    final allIds = countMap.keys.toList();
    // Fetch all tracks for artist/album grouping (chunked)
    final allTracksById = <String, Track>{}..addAll(tracksById);
    final missingIds = allIds.where((id) => !allTracksById.containsKey(id)).toList();
    for (int i = 0; i < missingIds.length; i += 80) {
      final chunk = missingIds.sublist(i, (i + 80).clamp(0, missingIds.length));
      if (chunk.isEmpty) continue;
      var q = isar.trackModels.filter().sourceIdEqualTo(chunk[0]);
      for (int j = 1; j < chunk.length; j++) {
        q = q.or().sourceIdEqualTo(chunk[j]);
      }
      final models = await q.findAll();
      for (final m in models) {
        allTracksById[m.sourceId] = Track.fromModel(m);
      }
    }
    final artistCounts = <String, int>{};
    final artistThumb = <String, String?>{};
    final artistThumbLocal = <String, String?>{};
    for (final e in countMap.entries) {
      final t = allTracksById[e.key];
      if (t == null) continue;
      final name = t.artist.trim().isEmpty ? 'Unknown Artist' : t.artist.trim();
      artistCounts[name] = (artistCounts[name] ?? 0) + e.value;
      // first thumb
      if (!artistThumb.containsKey(name) || artistThumb[name] == null) {
        artistThumb[name] = t.thumbnailUrl;
        artistThumbLocal[name] = t.localThumbnailPath;
        if (t.localThumbnailPath != null) {
          artistThumbLocal[name] = t.localThumbnailPath;
          artistThumb[name] = t.thumbnailUrl;
        }
      }
    }
    final sortedArtists = artistCounts.entries.toList()..sort((a, b) => b.value.compareTo(a.value));
    final topArtists = sortedArtists.take(5).map((e) => ArtistCount(name: e.key, count: e.value, thumb: artistThumb[e.key], thumbLocal: artistThumbLocal[e.key])).toList();

    // Top albums
    final albumCounts = <String, int>{}; // key album|||artist
    final albumThumb = <String, String?>{};
    final albumThumbLocal = <String, String?>{};
    final albumArtist = <String, String>{};
    for (final e in countMap.entries) {
      final t = allTracksById[e.key];
      if (t == null) continue;
      final album = (t.album == null || t.album!.trim().isEmpty) ? 'Unknown Album' : t.album!.trim();
      final artist = t.artist.trim().isEmpty ? 'Unknown Artist' : t.artist.trim();
      final key = '$album|||$artist';
      albumCounts[key] = (albumCounts[key] ?? 0) + e.value;
      if (!albumThumb.containsKey(key) || albumThumb[key] == null) {
        albumThumb[key] = t.thumbnailUrl;
        albumThumbLocal[key] = t.localThumbnailPath;
        albumArtist[key] = artist;
      }
    }
    final sortedAlbums = albumCounts.entries.toList()..sort((a, b) => b.value.compareTo(a.value));
    final topAlbums = sortedAlbums.take(5).map((e) {
      final parts = e.key.split('|||');
      final album = parts.first;
      final artist = albumArtist[e.key] ?? (parts.length > 1 ? parts[1] : 'Unknown Artist');
      return AlbumCount(album: album, artist: artist, count: e.value, thumb: albumThumb[e.key], thumbLocal: albumThumbLocal[e.key]);
    }).toList();

    return Recap(
      year: year,
      mostPlayed: mostPlayed,
      mostPlayedCount: mostCount,
      topSongs: topSongs,
      topSongCounts: topCounts,
      topArtists: topArtists,
      topAlbums: topAlbums,
      totalPlays: totalPlays,
      totalTracks: totalTracks,
    );
  }

  Future<List<int>> getAvailableYears() async {
    final all = await isar.playHistoryModels.where().sortByPlayedAt().findAll();
    if (all.isEmpty) return [DateTime.now().year];
    final years = <int>{};
    for (final h in all) {
      years.add(h.playedAt.year);
    }
    years.add(DateTime.now().year);
    final list = years.toList()..sort((a, b) => b.compareTo(a));
    return list;
  }
}
