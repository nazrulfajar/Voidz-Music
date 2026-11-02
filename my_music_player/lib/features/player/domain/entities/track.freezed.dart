// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'track.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
    'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models');

Track _$TrackFromJson(Map<String, dynamic> json) {
  return _Track.fromJson(json);
}

/// @nodoc
mixin _$Track {
  @JsonKey(name: 'source_id')
  String get sourceId => throw _privateConstructorUsedError;
  String get title => throw _privateConstructorUsedError;
  String get artist => throw _privateConstructorUsedError;
  String? get album => throw _privateConstructorUsedError;
  @JsonKey(name: 'duration_ms')
  int get durationMs => throw _privateConstructorUsedError;
  @JsonKey(name: 'thumbnail_url')
  String? get thumbnailUrl => throw _privateConstructorUsedError;
  String? get localThumbnailPath => throw _privateConstructorUsedError;
  TrackSource get source => throw _privateConstructorUsedError;
  String? get streamUrl => throw _privateConstructorUsedError;
  DateTime? get streamUrlExpiresAt => throw _privateConstructorUsedError;
  String? get localAudioPath => throw _privateConstructorUsedError;
  bool get isCached => throw _privateConstructorUsedError;
  bool get isLiked => throw _privateConstructorUsedError;
  bool get isPinned => throw _privateConstructorUsedError;
  int? get fileSizeBytes => throw _privateConstructorUsedError;
  String? get audioFormat => throw _privateConstructorUsedError;
  int? get bitrateKbps => throw _privateConstructorUsedError;
  String? get cachedQuality => throw _privateConstructorUsedError;
  String? get cacheEtag => throw _privateConstructorUsedError;
  DateTime? get cachedAt => throw _privateConstructorUsedError;
  DateTime? get lastPlayedAt => throw _privateConstructorUsedError;
  int get playCount => throw _privateConstructorUsedError;
  int? get trackNumber => throw _privateConstructorUsedError;
  int? get discNumber => throw _privateConstructorUsedError;
  int? get year => throw _privateConstructorUsedError;

  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;
  @JsonKey(ignore: true)
  $TrackCopyWith<Track> get copyWith => throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $TrackCopyWith<$Res> {
  factory $TrackCopyWith(Track value, $Res Function(Track) then) =
      _$TrackCopyWithImpl<$Res, Track>;
  @useResult
  $Res call(
      {@JsonKey(name: 'source_id') String sourceId,
      String title,
      String artist,
      String? album,
      @JsonKey(name: 'duration_ms') int durationMs,
      @JsonKey(name: 'thumbnail_url') String? thumbnailUrl,
      String? localThumbnailPath,
      TrackSource source,
      String? streamUrl,
      DateTime? streamUrlExpiresAt,
      String? localAudioPath,
      bool isCached,
      bool isLiked,
      bool isPinned,
      int? fileSizeBytes,
      String? audioFormat,
      int? bitrateKbps,
      String? cachedQuality,
      String? cacheEtag,
      DateTime? cachedAt,
      DateTime? lastPlayedAt,
      int playCount,
      int? trackNumber,
      int? discNumber,
      int? year});
}

/// @nodoc
class _$TrackCopyWithImpl<$Res, $Val extends Track>
    implements $TrackCopyWith<$Res> {
  _$TrackCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? sourceId = null,
    Object? title = null,
    Object? artist = null,
    Object? album = freezed,
    Object? durationMs = null,
    Object? thumbnailUrl = freezed,
    Object? localThumbnailPath = freezed,
    Object? source = null,
    Object? streamUrl = freezed,
    Object? streamUrlExpiresAt = freezed,
    Object? localAudioPath = freezed,
    Object? isCached = null,
    Object? isLiked = null,
    Object? isPinned = null,
    Object? fileSizeBytes = freezed,
    Object? audioFormat = freezed,
    Object? bitrateKbps = freezed,
    Object? cachedQuality = freezed,
    Object? cacheEtag = freezed,
    Object? cachedAt = freezed,
    Object? lastPlayedAt = freezed,
    Object? playCount = null,
    Object? trackNumber = freezed,
    Object? discNumber = freezed,
    Object? year = freezed,
  }) {
    return _then(_value.copyWith(
      sourceId: null == sourceId
          ? _value.sourceId
          : sourceId // ignore: cast_nullable_to_non_nullable
              as String,
      title: null == title
          ? _value.title
          : title // ignore: cast_nullable_to_non_nullable
              as String,
      artist: null == artist
          ? _value.artist
          : artist // ignore: cast_nullable_to_non_nullable
              as String,
      album: freezed == album
          ? _value.album
          : album // ignore: cast_nullable_to_non_nullable
              as String?,
      durationMs: null == durationMs
          ? _value.durationMs
          : durationMs // ignore: cast_nullable_to_non_nullable
              as int,
      thumbnailUrl: freezed == thumbnailUrl
          ? _value.thumbnailUrl
          : thumbnailUrl // ignore: cast_nullable_to_non_nullable
              as String?,
      localThumbnailPath: freezed == localThumbnailPath
          ? _value.localThumbnailPath
          : localThumbnailPath // ignore: cast_nullable_to_non_nullable
              as String?,
      source: null == source
          ? _value.source
          : source // ignore: cast_nullable_to_non_nullable
              as TrackSource,
      streamUrl: freezed == streamUrl
          ? _value.streamUrl
          : streamUrl // ignore: cast_nullable_to_non_nullable
              as String?,
      streamUrlExpiresAt: freezed == streamUrlExpiresAt
          ? _value.streamUrlExpiresAt
          : streamUrlExpiresAt // ignore: cast_nullable_to_non_nullable
              as DateTime?,
      localAudioPath: freezed == localAudioPath
          ? _value.localAudioPath
          : localAudioPath // ignore: cast_nullable_to_non_nullable
              as String?,
      isCached: null == isCached
          ? _value.isCached
          : isCached // ignore: cast_nullable_to_non_nullable
              as bool,
      isLiked: null == isLiked
          ? _value.isLiked
          : isLiked // ignore: cast_nullable_to_non_nullable
              as bool,
      isPinned: null == isPinned
          ? _value.isPinned
          : isPinned // ignore: cast_nullable_to_non_nullable
              as bool,
      fileSizeBytes: freezed == fileSizeBytes
          ? _value.fileSizeBytes
          : fileSizeBytes // ignore: cast_nullable_to_non_nullable
              as int?,
      audioFormat: freezed == audioFormat
          ? _value.audioFormat
          : audioFormat // ignore: cast_nullable_to_non_nullable
              as String?,
      bitrateKbps: freezed == bitrateKbps
          ? _value.bitrateKbps
          : bitrateKbps // ignore: cast_nullable_to_non_nullable
              as int?,
      cachedQuality: freezed == cachedQuality
          ? _value.cachedQuality
          : cachedQuality // ignore: cast_nullable_to_non_nullable
              as String?,
      cacheEtag: freezed == cacheEtag
          ? _value.cacheEtag
          : cacheEtag // ignore: cast_nullable_to_non_nullable
              as String?,
      cachedAt: freezed == cachedAt
          ? _value.cachedAt
          : cachedAt // ignore: cast_nullable_to_non_nullable
              as DateTime?,
      lastPlayedAt: freezed == lastPlayedAt
          ? _value.lastPlayedAt
          : lastPlayedAt // ignore: cast_nullable_to_non_nullable
              as DateTime?,
      playCount: null == playCount
          ? _value.playCount
          : playCount // ignore: cast_nullable_to_non_nullable
              as int,
      trackNumber: freezed == trackNumber
          ? _value.trackNumber
          : trackNumber // ignore: cast_nullable_to_non_nullable
              as int?,
      discNumber: freezed == discNumber
          ? _value.discNumber
          : discNumber // ignore: cast_nullable_to_non_nullable
              as int?,
      year: freezed == year
          ? _value.year
          : year // ignore: cast_nullable_to_non_nullable
              as int?,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$TrackImplCopyWith<$Res> implements $TrackCopyWith<$Res> {
  factory _$$TrackImplCopyWith(
          _$TrackImpl value, $Res Function(_$TrackImpl) then) =
      __$$TrackImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {@JsonKey(name: 'source_id') String sourceId,
      String title,
      String artist,
      String? album,
      @JsonKey(name: 'duration_ms') int durationMs,
      @JsonKey(name: 'thumbnail_url') String? thumbnailUrl,
      String? localThumbnailPath,
      TrackSource source,
      String? streamUrl,
      DateTime? streamUrlExpiresAt,
      String? localAudioPath,
      bool isCached,
      bool isLiked,
      bool isPinned,
      int? fileSizeBytes,
      String? audioFormat,
      int? bitrateKbps,
      String? cachedQuality,
      String? cacheEtag,
      DateTime? cachedAt,
      DateTime? lastPlayedAt,
      int playCount,
      int? trackNumber,
      int? discNumber,
      int? year});
}

/// @nodoc
class __$$TrackImplCopyWithImpl<$Res>
    extends _$TrackCopyWithImpl<$Res, _$TrackImpl>
    implements _$$TrackImplCopyWith<$Res> {
  __$$TrackImplCopyWithImpl(
      _$TrackImpl _value, $Res Function(_$TrackImpl) _then)
      : super(_value, _then);

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? sourceId = null,
    Object? title = null,
    Object? artist = null,
    Object? album = freezed,
    Object? durationMs = null,
    Object? thumbnailUrl = freezed,
    Object? localThumbnailPath = freezed,
    Object? source = null,
    Object? streamUrl = freezed,
    Object? streamUrlExpiresAt = freezed,
    Object? localAudioPath = freezed,
    Object? isCached = null,
    Object? isLiked = null,
    Object? isPinned = null,
    Object? fileSizeBytes = freezed,
    Object? audioFormat = freezed,
    Object? bitrateKbps = freezed,
    Object? cachedQuality = freezed,
    Object? cacheEtag = freezed,
    Object? cachedAt = freezed,
    Object? lastPlayedAt = freezed,
    Object? playCount = null,
    Object? trackNumber = freezed,
    Object? discNumber = freezed,
    Object? year = freezed,
  }) {
    return _then(_$TrackImpl(
      sourceId: null == sourceId
          ? _value.sourceId
          : sourceId // ignore: cast_nullable_to_non_nullable
              as String,
      title: null == title
          ? _value.title
          : title // ignore: cast_nullable_to_non_nullable
              as String,
      artist: null == artist
          ? _value.artist
          : artist // ignore: cast_nullable_to_non_nullable
              as String,
      album: freezed == album
          ? _value.album
          : album // ignore: cast_nullable_to_non_nullable
              as String?,
      durationMs: null == durationMs
          ? _value.durationMs
          : durationMs // ignore: cast_nullable_to_non_nullable
              as int,
      thumbnailUrl: freezed == thumbnailUrl
          ? _value.thumbnailUrl
          : thumbnailUrl // ignore: cast_nullable_to_non_nullable
              as String?,
      localThumbnailPath: freezed == localThumbnailPath
          ? _value.localThumbnailPath
          : localThumbnailPath // ignore: cast_nullable_to_non_nullable
              as String?,
      source: null == source
          ? _value.source
          : source // ignore: cast_nullable_to_non_nullable
              as TrackSource,
      streamUrl: freezed == streamUrl
          ? _value.streamUrl
          : streamUrl // ignore: cast_nullable_to_non_nullable
              as String?,
      streamUrlExpiresAt: freezed == streamUrlExpiresAt
          ? _value.streamUrlExpiresAt
          : streamUrlExpiresAt // ignore: cast_nullable_to_non_nullable
              as DateTime?,
      localAudioPath: freezed == localAudioPath
          ? _value.localAudioPath
          : localAudioPath // ignore: cast_nullable_to_non_nullable
              as String?,
      isCached: null == isCached
          ? _value.isCached
          : isCached // ignore: cast_nullable_to_non_nullable
              as bool,
      isLiked: null == isLiked
          ? _value.isLiked
          : isLiked // ignore: cast_nullable_to_non_nullable
              as bool,
      isPinned: null == isPinned
          ? _value.isPinned
          : isPinned // ignore: cast_nullable_to_non_nullable
              as bool,
      fileSizeBytes: freezed == fileSizeBytes
          ? _value.fileSizeBytes
          : fileSizeBytes // ignore: cast_nullable_to_non_nullable
              as int?,
      audioFormat: freezed == audioFormat
          ? _value.audioFormat
          : audioFormat // ignore: cast_nullable_to_non_nullable
              as String?,
      bitrateKbps: freezed == bitrateKbps
          ? _value.bitrateKbps
          : bitrateKbps // ignore: cast_nullable_to_non_nullable
              as int?,
      cachedQuality: freezed == cachedQuality
          ? _value.cachedQuality
          : cachedQuality // ignore: cast_nullable_to_non_nullable
              as String?,
      cacheEtag: freezed == cacheEtag
          ? _value.cacheEtag
          : cacheEtag // ignore: cast_nullable_to_non_nullable
              as String?,
      cachedAt: freezed == cachedAt
          ? _value.cachedAt
          : cachedAt // ignore: cast_nullable_to_non_nullable
              as DateTime?,
      lastPlayedAt: freezed == lastPlayedAt
          ? _value.lastPlayedAt
          : lastPlayedAt // ignore: cast_nullable_to_non_nullable
              as DateTime?,
      playCount: null == playCount
          ? _value.playCount
          : playCount // ignore: cast_nullable_to_non_nullable
              as int,
      trackNumber: freezed == trackNumber
          ? _value.trackNumber
          : trackNumber // ignore: cast_nullable_to_non_nullable
              as int?,
      discNumber: freezed == discNumber
          ? _value.discNumber
          : discNumber // ignore: cast_nullable_to_non_nullable
              as int?,
      year: freezed == year
          ? _value.year
          : year // ignore: cast_nullable_to_non_nullable
              as int?,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$TrackImpl extends _Track {
  const _$TrackImpl(
      {@JsonKey(name: 'source_id') required this.sourceId,
      required this.title,
      this.artist = 'Unknown Artist',
      this.album,
      @JsonKey(name: 'duration_ms') required this.durationMs,
      @JsonKey(name: 'thumbnail_url') this.thumbnailUrl,
      this.localThumbnailPath,
      required this.source,
      this.streamUrl,
      this.streamUrlExpiresAt,
      this.localAudioPath,
      this.isCached = false,
      this.isLiked = false,
      this.isPinned = false,
      this.fileSizeBytes,
      this.audioFormat,
      this.bitrateKbps,
      this.cachedQuality,
      this.cacheEtag,
      this.cachedAt,
      this.lastPlayedAt,
      this.playCount = 0,
      this.trackNumber,
      this.discNumber,
      this.year})
      : super._();

  factory _$TrackImpl.fromJson(Map<String, dynamic> json) =>
      _$$TrackImplFromJson(json);

  @override
  @JsonKey(name: 'source_id')
  final String sourceId;
  @override
  final String title;
  @override
  @JsonKey()
  final String artist;
  @override
  final String? album;
  @override
  @JsonKey(name: 'duration_ms')
  final int durationMs;
  @override
  @JsonKey(name: 'thumbnail_url')
  final String? thumbnailUrl;
  @override
  final String? localThumbnailPath;
  @override
  final TrackSource source;
  @override
  final String? streamUrl;
  @override
  final DateTime? streamUrlExpiresAt;
  @override
  final String? localAudioPath;
  @override
  @JsonKey()
  final bool isCached;
  @override
  @JsonKey()
  final bool isLiked;
  @override
  @JsonKey()
  final bool isPinned;
  @override
  final int? fileSizeBytes;
  @override
  final String? audioFormat;
  @override
  final int? bitrateKbps;
  @override
  final String? cachedQuality;
  @override
  final String? cacheEtag;
  @override
  final DateTime? cachedAt;
  @override
  final DateTime? lastPlayedAt;
  @override
  @JsonKey()
  final int playCount;
  @override
  final int? trackNumber;
  @override
  final int? discNumber;
  @override
  final int? year;

  @override
  String toString() {
    return 'Track(sourceId: $sourceId, title: $title, artist: $artist, album: $album, durationMs: $durationMs, thumbnailUrl: $thumbnailUrl, localThumbnailPath: $localThumbnailPath, source: $source, streamUrl: $streamUrl, streamUrlExpiresAt: $streamUrlExpiresAt, localAudioPath: $localAudioPath, isCached: $isCached, isLiked: $isLiked, isPinned: $isPinned, fileSizeBytes: $fileSizeBytes, audioFormat: $audioFormat, bitrateKbps: $bitrateKbps, cachedQuality: $cachedQuality, cacheEtag: $cacheEtag, cachedAt: $cachedAt, lastPlayedAt: $lastPlayedAt, playCount: $playCount, trackNumber: $trackNumber, discNumber: $discNumber, year: $year)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$TrackImpl &&
            (identical(other.sourceId, sourceId) ||
                other.sourceId == sourceId) &&
            (identical(other.title, title) || other.title == title) &&
            (identical(other.artist, artist) || other.artist == artist) &&
            (identical(other.album, album) || other.album == album) &&
            (identical(other.durationMs, durationMs) ||
                other.durationMs == durationMs) &&
            (identical(other.thumbnailUrl, thumbnailUrl) ||
                other.thumbnailUrl == thumbnailUrl) &&
            (identical(other.localThumbnailPath, localThumbnailPath) ||
                other.localThumbnailPath == localThumbnailPath) &&
            (identical(other.source, source) || other.source == source) &&
            (identical(other.streamUrl, streamUrl) ||
                other.streamUrl == streamUrl) &&
            (identical(other.streamUrlExpiresAt, streamUrlExpiresAt) ||
                other.streamUrlExpiresAt == streamUrlExpiresAt) &&
            (identical(other.localAudioPath, localAudioPath) ||
                other.localAudioPath == localAudioPath) &&
            (identical(other.isCached, isCached) ||
                other.isCached == isCached) &&
            (identical(other.isLiked, isLiked) || other.isLiked == isLiked) &&
            (identical(other.isPinned, isPinned) ||
                other.isPinned == isPinned) &&
            (identical(other.fileSizeBytes, fileSizeBytes) ||
                other.fileSizeBytes == fileSizeBytes) &&
            (identical(other.audioFormat, audioFormat) ||
                other.audioFormat == audioFormat) &&
            (identical(other.bitrateKbps, bitrateKbps) ||
                other.bitrateKbps == bitrateKbps) &&
            (identical(other.cachedQuality, cachedQuality) ||
                other.cachedQuality == cachedQuality) &&
            (identical(other.cacheEtag, cacheEtag) ||
                other.cacheEtag == cacheEtag) &&
            (identical(other.cachedAt, cachedAt) ||
                other.cachedAt == cachedAt) &&
            (identical(other.lastPlayedAt, lastPlayedAt) ||
                other.lastPlayedAt == lastPlayedAt) &&
            (identical(other.playCount, playCount) ||
                other.playCount == playCount) &&
            (identical(other.trackNumber, trackNumber) ||
                other.trackNumber == trackNumber) &&
            (identical(other.discNumber, discNumber) ||
                other.discNumber == discNumber) &&
            (identical(other.year, year) || other.year == year));
  }

  @JsonKey(ignore: true)
  @override
  int get hashCode => Object.hashAll([
        runtimeType,
        sourceId,
        title,
        artist,
        album,
        durationMs,
        thumbnailUrl,
        localThumbnailPath,
        source,
        streamUrl,
        streamUrlExpiresAt,
        localAudioPath,
        isCached,
        isLiked,
        isPinned,
        fileSizeBytes,
        audioFormat,
        bitrateKbps,
        cachedQuality,
        cacheEtag,
        cachedAt,
        lastPlayedAt,
        playCount,
        trackNumber,
        discNumber,
        year
      ]);

  @JsonKey(ignore: true)
  @override
  @pragma('vm:prefer-inline')
  _$$TrackImplCopyWith<_$TrackImpl> get copyWith =>
      __$$TrackImplCopyWithImpl<_$TrackImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$TrackImplToJson(
      this,
    );
  }
}

abstract class _Track extends Track {
  const factory _Track(
      {@JsonKey(name: 'source_id') required final String sourceId,
      required final String title,
      final String artist,
      final String? album,
      @JsonKey(name: 'duration_ms') required final int durationMs,
      @JsonKey(name: 'thumbnail_url') final String? thumbnailUrl,
      final String? localThumbnailPath,
      required final TrackSource source,
      final String? streamUrl,
      final DateTime? streamUrlExpiresAt,
      final String? localAudioPath,
      final bool isCached,
      final bool isLiked,
      final bool isPinned,
      final int? fileSizeBytes,
      final String? audioFormat,
      final int? bitrateKbps,
      final String? cachedQuality,
      final String? cacheEtag,
      final DateTime? cachedAt,
      final DateTime? lastPlayedAt,
      final int playCount,
      final int? trackNumber,
      final int? discNumber,
      final int? year}) = _$TrackImpl;
  const _Track._() : super._();

  factory _Track.fromJson(Map<String, dynamic> json) = _$TrackImpl.fromJson;

  @override
  @JsonKey(name: 'source_id')
  String get sourceId;
  @override
  String get title;
  @override
  String get artist;
  @override
  String? get album;
  @override
  @JsonKey(name: 'duration_ms')
  int get durationMs;
  @override
  @JsonKey(name: 'thumbnail_url')
  String? get thumbnailUrl;
  @override
  String? get localThumbnailPath;
  @override
  TrackSource get source;
  @override
  String? get streamUrl;
  @override
  DateTime? get streamUrlExpiresAt;
  @override
  String? get localAudioPath;
  @override
  bool get isCached;
  @override
  bool get isLiked;
  @override
  bool get isPinned;
  @override
  int? get fileSizeBytes;
  @override
  String? get audioFormat;
  @override
  int? get bitrateKbps;
  @override
  String? get cachedQuality;
  @override
  String? get cacheEtag;
  @override
  DateTime? get cachedAt;
  @override
  DateTime? get lastPlayedAt;
  @override
  int get playCount;
  @override
  int? get trackNumber;
  @override
  int? get discNumber;
  @override
  int? get year;
  @override
  @JsonKey(ignore: true)
  _$$TrackImplCopyWith<_$TrackImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
