// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'track.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$TrackImpl _$$TrackImplFromJson(Map<String, dynamic> json) => _$TrackImpl(
      sourceId: json['source_id'] as String,
      title: json['title'] as String,
      artist: json['artist'] as String? ?? 'Unknown Artist',
      album: json['album'] as String?,
      durationMs: (json['duration_ms'] as num).toInt(),
      thumbnailUrl: json['thumbnail_url'] as String?,
      localThumbnailPath: json['localThumbnailPath'] as String?,
      source: $enumDecode(_$TrackSourceEnumMap, json['source']),
      streamUrl: json['streamUrl'] as String?,
      streamUrlExpiresAt: json['streamUrlExpiresAt'] == null
          ? null
          : DateTime.parse(json['streamUrlExpiresAt'] as String),
      localAudioPath: json['localAudioPath'] as String?,
      isCached: json['isCached'] as bool? ?? false,
      isLiked: json['isLiked'] as bool? ?? false,
      isPinned: json['isPinned'] as bool? ?? false,
      fileSizeBytes: (json['fileSizeBytes'] as num?)?.toInt(),
      audioFormat: json['audioFormat'] as String?,
      bitrateKbps: (json['bitrateKbps'] as num?)?.toInt(),
      cachedQuality: json['cachedQuality'] as String?,
      cacheEtag: json['cacheEtag'] as String?,
      cachedAt: json['cachedAt'] == null
          ? null
          : DateTime.parse(json['cachedAt'] as String),
      lastPlayedAt: json['lastPlayedAt'] == null
          ? null
          : DateTime.parse(json['lastPlayedAt'] as String),
      playCount: (json['playCount'] as num?)?.toInt() ?? 0,
      trackNumber: (json['trackNumber'] as num?)?.toInt(),
      discNumber: (json['discNumber'] as num?)?.toInt(),
      year: (json['year'] as num?)?.toInt(),
    );

Map<String, dynamic> _$$TrackImplToJson(_$TrackImpl instance) =>
    <String, dynamic>{
      'source_id': instance.sourceId,
      'title': instance.title,
      'artist': instance.artist,
      'album': instance.album,
      'duration_ms': instance.durationMs,
      'thumbnail_url': instance.thumbnailUrl,
      'localThumbnailPath': instance.localThumbnailPath,
      'source': _$TrackSourceEnumMap[instance.source]!,
      'streamUrl': instance.streamUrl,
      'streamUrlExpiresAt': instance.streamUrlExpiresAt?.toIso8601String(),
      'localAudioPath': instance.localAudioPath,
      'isCached': instance.isCached,
      'isLiked': instance.isLiked,
      'isPinned': instance.isPinned,
      'fileSizeBytes': instance.fileSizeBytes,
      'audioFormat': instance.audioFormat,
      'bitrateKbps': instance.bitrateKbps,
      'cachedQuality': instance.cachedQuality,
      'cacheEtag': instance.cacheEtag,
      'cachedAt': instance.cachedAt?.toIso8601String(),
      'lastPlayedAt': instance.lastPlayedAt?.toIso8601String(),
      'playCount': instance.playCount,
      'trackNumber': instance.trackNumber,
      'discNumber': instance.discNumber,
      'year': instance.year,
    };

const _$TrackSourceEnumMap = {
  TrackSource.youtube: 'youtube',
  TrackSource.jamendo: 'jamendo',
  TrackSource.local: 'local',
};
