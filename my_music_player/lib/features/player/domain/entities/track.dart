// ignore_for_file: invalid_annotation_target
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:my_music_player/core/constants/enums.dart';
import 'package:my_music_player/features/player/data/models/track_model.dart';

part 'track.freezed.dart';
part 'track.g.dart';

@freezed
class Track with _$Track {
  const Track._();

  const factory Track({
    @JsonKey(name: 'source_id') required String sourceId,
    required String title,
    @Default('Unknown Artist') String artist,
    String? album,
    @JsonKey(name: 'duration_ms') required int durationMs,
    @JsonKey(name: 'thumbnail_url') String? thumbnailUrl,
    String? localThumbnailPath,
    required TrackSource source,
    String? streamUrl,
    DateTime? streamUrlExpiresAt,
    String? localAudioPath,
    @Default(false) bool isCached,
    @Default(false) bool isLiked,
    @Default(false) bool isPinned,
    int? fileSizeBytes,
    String? audioFormat,
    int? bitrateKbps,
    String? cachedQuality,
    String? cacheEtag,
    DateTime? cachedAt,
    DateTime? lastPlayedAt,
    @Default(0) int playCount,
    int? trackNumber,
    int? discNumber,
    int? year,
  }) = _Track;

  factory Track.fromJson(Map<String, dynamic> json) => _$TrackFromJson(json);

  // Mapper to Isar Model
  TrackModel toModel() {
    return TrackModel()
      ..sourceId = sourceId
      ..title = title
      ..artist = artist
      ..album = album
      ..durationMs = durationMs
      ..thumbnailUrl = thumbnailUrl
      ..localThumbnailPath = localThumbnailPath
      ..source = source
      ..streamUrl = streamUrl
      ..streamUrlExpiresAt = streamUrlExpiresAt
      ..localAudioPath = localAudioPath
      ..isCached = isCached
      ..isLiked = isLiked
      ..isPinned = isPinned
      ..fileSizeBytes = fileSizeBytes
      ..audioFormat = audioFormat
      ..bitrateKbps = bitrateKbps
      ..cachedQuality = cachedQuality
      ..cacheEtag = cacheEtag
      ..cachedAt = cachedAt
      ..lastPlayedAt = lastPlayedAt
      ..playCount = playCount
      ..trackNumber = trackNumber
      ..discNumber = discNumber
      ..year = year
      ..createdAt = DateTime.now()
      ..updatedAt = DateTime.now();
  }

  // Mapper from Isar Model
  factory Track.fromModel(TrackModel model) {
    return Track(
      sourceId: model.sourceId,
      title: model.title,
      artist: model.artist,
      album: model.album,
      durationMs: model.durationMs,
      thumbnailUrl: model.thumbnailUrl,
      localThumbnailPath: model.localThumbnailPath,
      source: model.source,
      streamUrl: model.streamUrl,
      streamUrlExpiresAt: model.streamUrlExpiresAt,
      localAudioPath: model.localAudioPath,
      isCached: model.isCached,
      isLiked: model.isLiked,
      isPinned: model.isPinned,
      fileSizeBytes: model.fileSizeBytes,
      audioFormat: model.audioFormat,
      bitrateKbps: model.bitrateKbps,
      cachedQuality: model.cachedQuality,
      cacheEtag: model.cacheEtag,
      cachedAt: model.cachedAt,
      lastPlayedAt: model.lastPlayedAt,
      playCount: model.playCount,
      trackNumber: model.trackNumber,
      discNumber: model.discNumber,
      year: model.year,
    );
  }
}
