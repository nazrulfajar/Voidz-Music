import 'package:freezed_annotation/freezed_annotation.dart';
import '../../../player/domain/entities/track.dart';

part 'recap.freezed.dart';
part 'recap.g.dart';

@freezed
class Recap with _$Recap {
  const factory Recap({
    required int year,
    required Track? mostPlayed,
    required int mostPlayedCount,
    required List<Track> topSongs,
    required List<int> topSongCounts,
    required List<ArtistCount> topArtists,
    required List<AlbumCount> topAlbums,
    required int totalPlays,
    required int totalTracks,
  }) = _Recap;

  factory Recap.fromJson(Map<String, dynamic> json) => _$RecapFromJson(json);

  factory Recap.empty(int year) => Recap(
        year: year,
        mostPlayed: null,
        mostPlayedCount: 0,
        topSongs: const [],
        topSongCounts: const [],
        topArtists: const [],
        topAlbums: const [],
        totalPlays: 0,
        totalTracks: 0,
      );
}

@freezed
class ArtistCount with _$ArtistCount {
  const factory ArtistCount({
    required String name,
    required int count,
    String? thumb,
    String? thumbLocal,
  }) = _ArtistCount;

  factory ArtistCount.fromJson(Map<String, dynamic> json) => _$ArtistCountFromJson(json);
}

@freezed
class AlbumCount with _$AlbumCount {
  const factory AlbumCount({
    required String album,
    required String artist,
    required int count,
    String? thumb,
    String? thumbLocal,
  }) = _AlbumCount;

  factory AlbumCount.fromJson(Map<String, dynamic> json) => _$AlbumCountFromJson(json);
}
