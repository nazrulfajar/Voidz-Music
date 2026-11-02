// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'recap.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$RecapImpl _$$RecapImplFromJson(Map<String, dynamic> json) => _$RecapImpl(
      year: (json['year'] as num).toInt(),
      mostPlayed: json['mostPlayed'] == null
          ? null
          : Track.fromJson(json['mostPlayed'] as Map<String, dynamic>),
      mostPlayedCount: (json['mostPlayedCount'] as num).toInt(),
      topSongs: (json['topSongs'] as List<dynamic>)
          .map((e) => Track.fromJson(e as Map<String, dynamic>))
          .toList(),
      topSongCounts: (json['topSongCounts'] as List<dynamic>)
          .map((e) => (e as num).toInt())
          .toList(),
      topArtists: (json['topArtists'] as List<dynamic>)
          .map((e) => ArtistCount.fromJson(e as Map<String, dynamic>))
          .toList(),
      topAlbums: (json['topAlbums'] as List<dynamic>)
          .map((e) => AlbumCount.fromJson(e as Map<String, dynamic>))
          .toList(),
      totalPlays: (json['totalPlays'] as num).toInt(),
      totalTracks: (json['totalTracks'] as num).toInt(),
    );

Map<String, dynamic> _$$RecapImplToJson(_$RecapImpl instance) =>
    <String, dynamic>{
      'year': instance.year,
      'mostPlayed': instance.mostPlayed,
      'mostPlayedCount': instance.mostPlayedCount,
      'topSongs': instance.topSongs,
      'topSongCounts': instance.topSongCounts,
      'topArtists': instance.topArtists,
      'topAlbums': instance.topAlbums,
      'totalPlays': instance.totalPlays,
      'totalTracks': instance.totalTracks,
    };

_$ArtistCountImpl _$$ArtistCountImplFromJson(Map<String, dynamic> json) =>
    _$ArtistCountImpl(
      name: json['name'] as String,
      count: (json['count'] as num).toInt(),
      thumb: json['thumb'] as String?,
      thumbLocal: json['thumbLocal'] as String?,
    );

Map<String, dynamic> _$$ArtistCountImplToJson(_$ArtistCountImpl instance) =>
    <String, dynamic>{
      'name': instance.name,
      'count': instance.count,
      'thumb': instance.thumb,
      'thumbLocal': instance.thumbLocal,
    };

_$AlbumCountImpl _$$AlbumCountImplFromJson(Map<String, dynamic> json) =>
    _$AlbumCountImpl(
      album: json['album'] as String,
      artist: json['artist'] as String,
      count: (json['count'] as num).toInt(),
      thumb: json['thumb'] as String?,
      thumbLocal: json['thumbLocal'] as String?,
    );

Map<String, dynamic> _$$AlbumCountImplToJson(_$AlbumCountImpl instance) =>
    <String, dynamic>{
      'album': instance.album,
      'artist': instance.artist,
      'count': instance.count,
      'thumb': instance.thumb,
      'thumbLocal': instance.thumbLocal,
    };
