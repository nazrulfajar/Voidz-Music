// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'recap.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
    'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models');

Recap _$RecapFromJson(Map<String, dynamic> json) {
  return _Recap.fromJson(json);
}

/// @nodoc
mixin _$Recap {
  int get year => throw _privateConstructorUsedError;
  Track? get mostPlayed => throw _privateConstructorUsedError;
  int get mostPlayedCount => throw _privateConstructorUsedError;
  List<Track> get topSongs => throw _privateConstructorUsedError;
  List<int> get topSongCounts => throw _privateConstructorUsedError;
  List<ArtistCount> get topArtists => throw _privateConstructorUsedError;
  List<AlbumCount> get topAlbums => throw _privateConstructorUsedError;
  int get totalPlays => throw _privateConstructorUsedError;
  int get totalTracks => throw _privateConstructorUsedError;

  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;
  @JsonKey(ignore: true)
  $RecapCopyWith<Recap> get copyWith => throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $RecapCopyWith<$Res> {
  factory $RecapCopyWith(Recap value, $Res Function(Recap) then) =
      _$RecapCopyWithImpl<$Res, Recap>;
  @useResult
  $Res call(
      {int year,
      Track? mostPlayed,
      int mostPlayedCount,
      List<Track> topSongs,
      List<int> topSongCounts,
      List<ArtistCount> topArtists,
      List<AlbumCount> topAlbums,
      int totalPlays,
      int totalTracks});

  $TrackCopyWith<$Res>? get mostPlayed;
}

/// @nodoc
class _$RecapCopyWithImpl<$Res, $Val extends Recap>
    implements $RecapCopyWith<$Res> {
  _$RecapCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? year = null,
    Object? mostPlayed = freezed,
    Object? mostPlayedCount = null,
    Object? topSongs = null,
    Object? topSongCounts = null,
    Object? topArtists = null,
    Object? topAlbums = null,
    Object? totalPlays = null,
    Object? totalTracks = null,
  }) {
    return _then(_value.copyWith(
      year: null == year
          ? _value.year
          : year // ignore: cast_nullable_to_non_nullable
              as int,
      mostPlayed: freezed == mostPlayed
          ? _value.mostPlayed
          : mostPlayed // ignore: cast_nullable_to_non_nullable
              as Track?,
      mostPlayedCount: null == mostPlayedCount
          ? _value.mostPlayedCount
          : mostPlayedCount // ignore: cast_nullable_to_non_nullable
              as int,
      topSongs: null == topSongs
          ? _value.topSongs
          : topSongs // ignore: cast_nullable_to_non_nullable
              as List<Track>,
      topSongCounts: null == topSongCounts
          ? _value.topSongCounts
          : topSongCounts // ignore: cast_nullable_to_non_nullable
              as List<int>,
      topArtists: null == topArtists
          ? _value.topArtists
          : topArtists // ignore: cast_nullable_to_non_nullable
              as List<ArtistCount>,
      topAlbums: null == topAlbums
          ? _value.topAlbums
          : topAlbums // ignore: cast_nullable_to_non_nullable
              as List<AlbumCount>,
      totalPlays: null == totalPlays
          ? _value.totalPlays
          : totalPlays // ignore: cast_nullable_to_non_nullable
              as int,
      totalTracks: null == totalTracks
          ? _value.totalTracks
          : totalTracks // ignore: cast_nullable_to_non_nullable
              as int,
    ) as $Val);
  }

  @override
  @pragma('vm:prefer-inline')
  $TrackCopyWith<$Res>? get mostPlayed {
    if (_value.mostPlayed == null) {
      return null;
    }

    return $TrackCopyWith<$Res>(_value.mostPlayed!, (value) {
      return _then(_value.copyWith(mostPlayed: value) as $Val);
    });
  }
}

/// @nodoc
abstract class _$$RecapImplCopyWith<$Res> implements $RecapCopyWith<$Res> {
  factory _$$RecapImplCopyWith(
          _$RecapImpl value, $Res Function(_$RecapImpl) then) =
      __$$RecapImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {int year,
      Track? mostPlayed,
      int mostPlayedCount,
      List<Track> topSongs,
      List<int> topSongCounts,
      List<ArtistCount> topArtists,
      List<AlbumCount> topAlbums,
      int totalPlays,
      int totalTracks});

  @override
  $TrackCopyWith<$Res>? get mostPlayed;
}

/// @nodoc
class __$$RecapImplCopyWithImpl<$Res>
    extends _$RecapCopyWithImpl<$Res, _$RecapImpl>
    implements _$$RecapImplCopyWith<$Res> {
  __$$RecapImplCopyWithImpl(
      _$RecapImpl _value, $Res Function(_$RecapImpl) _then)
      : super(_value, _then);

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? year = null,
    Object? mostPlayed = freezed,
    Object? mostPlayedCount = null,
    Object? topSongs = null,
    Object? topSongCounts = null,
    Object? topArtists = null,
    Object? topAlbums = null,
    Object? totalPlays = null,
    Object? totalTracks = null,
  }) {
    return _then(_$RecapImpl(
      year: null == year
          ? _value.year
          : year // ignore: cast_nullable_to_non_nullable
              as int,
      mostPlayed: freezed == mostPlayed
          ? _value.mostPlayed
          : mostPlayed // ignore: cast_nullable_to_non_nullable
              as Track?,
      mostPlayedCount: null == mostPlayedCount
          ? _value.mostPlayedCount
          : mostPlayedCount // ignore: cast_nullable_to_non_nullable
              as int,
      topSongs: null == topSongs
          ? _value._topSongs
          : topSongs // ignore: cast_nullable_to_non_nullable
              as List<Track>,
      topSongCounts: null == topSongCounts
          ? _value._topSongCounts
          : topSongCounts // ignore: cast_nullable_to_non_nullable
              as List<int>,
      topArtists: null == topArtists
          ? _value._topArtists
          : topArtists // ignore: cast_nullable_to_non_nullable
              as List<ArtistCount>,
      topAlbums: null == topAlbums
          ? _value._topAlbums
          : topAlbums // ignore: cast_nullable_to_non_nullable
              as List<AlbumCount>,
      totalPlays: null == totalPlays
          ? _value.totalPlays
          : totalPlays // ignore: cast_nullable_to_non_nullable
              as int,
      totalTracks: null == totalTracks
          ? _value.totalTracks
          : totalTracks // ignore: cast_nullable_to_non_nullable
              as int,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$RecapImpl implements _Recap {
  const _$RecapImpl(
      {required this.year,
      required this.mostPlayed,
      required this.mostPlayedCount,
      required final List<Track> topSongs,
      required final List<int> topSongCounts,
      required final List<ArtistCount> topArtists,
      required final List<AlbumCount> topAlbums,
      required this.totalPlays,
      required this.totalTracks})
      : _topSongs = topSongs,
        _topSongCounts = topSongCounts,
        _topArtists = topArtists,
        _topAlbums = topAlbums;

  factory _$RecapImpl.fromJson(Map<String, dynamic> json) =>
      _$$RecapImplFromJson(json);

  @override
  final int year;
  @override
  final Track? mostPlayed;
  @override
  final int mostPlayedCount;
  final List<Track> _topSongs;
  @override
  List<Track> get topSongs {
    if (_topSongs is EqualUnmodifiableListView) return _topSongs;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_topSongs);
  }

  final List<int> _topSongCounts;
  @override
  List<int> get topSongCounts {
    if (_topSongCounts is EqualUnmodifiableListView) return _topSongCounts;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_topSongCounts);
  }

  final List<ArtistCount> _topArtists;
  @override
  List<ArtistCount> get topArtists {
    if (_topArtists is EqualUnmodifiableListView) return _topArtists;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_topArtists);
  }

  final List<AlbumCount> _topAlbums;
  @override
  List<AlbumCount> get topAlbums {
    if (_topAlbums is EqualUnmodifiableListView) return _topAlbums;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_topAlbums);
  }

  @override
  final int totalPlays;
  @override
  final int totalTracks;

  @override
  String toString() {
    return 'Recap(year: $year, mostPlayed: $mostPlayed, mostPlayedCount: $mostPlayedCount, topSongs: $topSongs, topSongCounts: $topSongCounts, topArtists: $topArtists, topAlbums: $topAlbums, totalPlays: $totalPlays, totalTracks: $totalTracks)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$RecapImpl &&
            (identical(other.year, year) || other.year == year) &&
            (identical(other.mostPlayed, mostPlayed) ||
                other.mostPlayed == mostPlayed) &&
            (identical(other.mostPlayedCount, mostPlayedCount) ||
                other.mostPlayedCount == mostPlayedCount) &&
            const DeepCollectionEquality().equals(other._topSongs, _topSongs) &&
            const DeepCollectionEquality()
                .equals(other._topSongCounts, _topSongCounts) &&
            const DeepCollectionEquality()
                .equals(other._topArtists, _topArtists) &&
            const DeepCollectionEquality()
                .equals(other._topAlbums, _topAlbums) &&
            (identical(other.totalPlays, totalPlays) ||
                other.totalPlays == totalPlays) &&
            (identical(other.totalTracks, totalTracks) ||
                other.totalTracks == totalTracks));
  }

  @JsonKey(ignore: true)
  @override
  int get hashCode => Object.hash(
      runtimeType,
      year,
      mostPlayed,
      mostPlayedCount,
      const DeepCollectionEquality().hash(_topSongs),
      const DeepCollectionEquality().hash(_topSongCounts),
      const DeepCollectionEquality().hash(_topArtists),
      const DeepCollectionEquality().hash(_topAlbums),
      totalPlays,
      totalTracks);

  @JsonKey(ignore: true)
  @override
  @pragma('vm:prefer-inline')
  _$$RecapImplCopyWith<_$RecapImpl> get copyWith =>
      __$$RecapImplCopyWithImpl<_$RecapImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$RecapImplToJson(
      this,
    );
  }
}

abstract class _Recap implements Recap {
  const factory _Recap(
      {required final int year,
      required final Track? mostPlayed,
      required final int mostPlayedCount,
      required final List<Track> topSongs,
      required final List<int> topSongCounts,
      required final List<ArtistCount> topArtists,
      required final List<AlbumCount> topAlbums,
      required final int totalPlays,
      required final int totalTracks}) = _$RecapImpl;

  factory _Recap.fromJson(Map<String, dynamic> json) = _$RecapImpl.fromJson;

  @override
  int get year;
  @override
  Track? get mostPlayed;
  @override
  int get mostPlayedCount;
  @override
  List<Track> get topSongs;
  @override
  List<int> get topSongCounts;
  @override
  List<ArtistCount> get topArtists;
  @override
  List<AlbumCount> get topAlbums;
  @override
  int get totalPlays;
  @override
  int get totalTracks;
  @override
  @JsonKey(ignore: true)
  _$$RecapImplCopyWith<_$RecapImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

ArtistCount _$ArtistCountFromJson(Map<String, dynamic> json) {
  return _ArtistCount.fromJson(json);
}

/// @nodoc
mixin _$ArtistCount {
  String get name => throw _privateConstructorUsedError;
  int get count => throw _privateConstructorUsedError;
  String? get thumb => throw _privateConstructorUsedError;
  String? get thumbLocal => throw _privateConstructorUsedError;

  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;
  @JsonKey(ignore: true)
  $ArtistCountCopyWith<ArtistCount> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $ArtistCountCopyWith<$Res> {
  factory $ArtistCountCopyWith(
          ArtistCount value, $Res Function(ArtistCount) then) =
      _$ArtistCountCopyWithImpl<$Res, ArtistCount>;
  @useResult
  $Res call({String name, int count, String? thumb, String? thumbLocal});
}

/// @nodoc
class _$ArtistCountCopyWithImpl<$Res, $Val extends ArtistCount>
    implements $ArtistCountCopyWith<$Res> {
  _$ArtistCountCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? name = null,
    Object? count = null,
    Object? thumb = freezed,
    Object? thumbLocal = freezed,
  }) {
    return _then(_value.copyWith(
      name: null == name
          ? _value.name
          : name // ignore: cast_nullable_to_non_nullable
              as String,
      count: null == count
          ? _value.count
          : count // ignore: cast_nullable_to_non_nullable
              as int,
      thumb: freezed == thumb
          ? _value.thumb
          : thumb // ignore: cast_nullable_to_non_nullable
              as String?,
      thumbLocal: freezed == thumbLocal
          ? _value.thumbLocal
          : thumbLocal // ignore: cast_nullable_to_non_nullable
              as String?,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$ArtistCountImplCopyWith<$Res>
    implements $ArtistCountCopyWith<$Res> {
  factory _$$ArtistCountImplCopyWith(
          _$ArtistCountImpl value, $Res Function(_$ArtistCountImpl) then) =
      __$$ArtistCountImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({String name, int count, String? thumb, String? thumbLocal});
}

/// @nodoc
class __$$ArtistCountImplCopyWithImpl<$Res>
    extends _$ArtistCountCopyWithImpl<$Res, _$ArtistCountImpl>
    implements _$$ArtistCountImplCopyWith<$Res> {
  __$$ArtistCountImplCopyWithImpl(
      _$ArtistCountImpl _value, $Res Function(_$ArtistCountImpl) _then)
      : super(_value, _then);

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? name = null,
    Object? count = null,
    Object? thumb = freezed,
    Object? thumbLocal = freezed,
  }) {
    return _then(_$ArtistCountImpl(
      name: null == name
          ? _value.name
          : name // ignore: cast_nullable_to_non_nullable
              as String,
      count: null == count
          ? _value.count
          : count // ignore: cast_nullable_to_non_nullable
              as int,
      thumb: freezed == thumb
          ? _value.thumb
          : thumb // ignore: cast_nullable_to_non_nullable
              as String?,
      thumbLocal: freezed == thumbLocal
          ? _value.thumbLocal
          : thumbLocal // ignore: cast_nullable_to_non_nullable
              as String?,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$ArtistCountImpl implements _ArtistCount {
  const _$ArtistCountImpl(
      {required this.name, required this.count, this.thumb, this.thumbLocal});

  factory _$ArtistCountImpl.fromJson(Map<String, dynamic> json) =>
      _$$ArtistCountImplFromJson(json);

  @override
  final String name;
  @override
  final int count;
  @override
  final String? thumb;
  @override
  final String? thumbLocal;

  @override
  String toString() {
    return 'ArtistCount(name: $name, count: $count, thumb: $thumb, thumbLocal: $thumbLocal)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$ArtistCountImpl &&
            (identical(other.name, name) || other.name == name) &&
            (identical(other.count, count) || other.count == count) &&
            (identical(other.thumb, thumb) || other.thumb == thumb) &&
            (identical(other.thumbLocal, thumbLocal) ||
                other.thumbLocal == thumbLocal));
  }

  @JsonKey(ignore: true)
  @override
  int get hashCode => Object.hash(runtimeType, name, count, thumb, thumbLocal);

  @JsonKey(ignore: true)
  @override
  @pragma('vm:prefer-inline')
  _$$ArtistCountImplCopyWith<_$ArtistCountImpl> get copyWith =>
      __$$ArtistCountImplCopyWithImpl<_$ArtistCountImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$ArtistCountImplToJson(
      this,
    );
  }
}

abstract class _ArtistCount implements ArtistCount {
  const factory _ArtistCount(
      {required final String name,
      required final int count,
      final String? thumb,
      final String? thumbLocal}) = _$ArtistCountImpl;

  factory _ArtistCount.fromJson(Map<String, dynamic> json) =
      _$ArtistCountImpl.fromJson;

  @override
  String get name;
  @override
  int get count;
  @override
  String? get thumb;
  @override
  String? get thumbLocal;
  @override
  @JsonKey(ignore: true)
  _$$ArtistCountImplCopyWith<_$ArtistCountImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

AlbumCount _$AlbumCountFromJson(Map<String, dynamic> json) {
  return _AlbumCount.fromJson(json);
}

/// @nodoc
mixin _$AlbumCount {
  String get album => throw _privateConstructorUsedError;
  String get artist => throw _privateConstructorUsedError;
  int get count => throw _privateConstructorUsedError;
  String? get thumb => throw _privateConstructorUsedError;
  String? get thumbLocal => throw _privateConstructorUsedError;

  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;
  @JsonKey(ignore: true)
  $AlbumCountCopyWith<AlbumCount> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $AlbumCountCopyWith<$Res> {
  factory $AlbumCountCopyWith(
          AlbumCount value, $Res Function(AlbumCount) then) =
      _$AlbumCountCopyWithImpl<$Res, AlbumCount>;
  @useResult
  $Res call(
      {String album,
      String artist,
      int count,
      String? thumb,
      String? thumbLocal});
}

/// @nodoc
class _$AlbumCountCopyWithImpl<$Res, $Val extends AlbumCount>
    implements $AlbumCountCopyWith<$Res> {
  _$AlbumCountCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? album = null,
    Object? artist = null,
    Object? count = null,
    Object? thumb = freezed,
    Object? thumbLocal = freezed,
  }) {
    return _then(_value.copyWith(
      album: null == album
          ? _value.album
          : album // ignore: cast_nullable_to_non_nullable
              as String,
      artist: null == artist
          ? _value.artist
          : artist // ignore: cast_nullable_to_non_nullable
              as String,
      count: null == count
          ? _value.count
          : count // ignore: cast_nullable_to_non_nullable
              as int,
      thumb: freezed == thumb
          ? _value.thumb
          : thumb // ignore: cast_nullable_to_non_nullable
              as String?,
      thumbLocal: freezed == thumbLocal
          ? _value.thumbLocal
          : thumbLocal // ignore: cast_nullable_to_non_nullable
              as String?,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$AlbumCountImplCopyWith<$Res>
    implements $AlbumCountCopyWith<$Res> {
  factory _$$AlbumCountImplCopyWith(
          _$AlbumCountImpl value, $Res Function(_$AlbumCountImpl) then) =
      __$$AlbumCountImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {String album,
      String artist,
      int count,
      String? thumb,
      String? thumbLocal});
}

/// @nodoc
class __$$AlbumCountImplCopyWithImpl<$Res>
    extends _$AlbumCountCopyWithImpl<$Res, _$AlbumCountImpl>
    implements _$$AlbumCountImplCopyWith<$Res> {
  __$$AlbumCountImplCopyWithImpl(
      _$AlbumCountImpl _value, $Res Function(_$AlbumCountImpl) _then)
      : super(_value, _then);

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? album = null,
    Object? artist = null,
    Object? count = null,
    Object? thumb = freezed,
    Object? thumbLocal = freezed,
  }) {
    return _then(_$AlbumCountImpl(
      album: null == album
          ? _value.album
          : album // ignore: cast_nullable_to_non_nullable
              as String,
      artist: null == artist
          ? _value.artist
          : artist // ignore: cast_nullable_to_non_nullable
              as String,
      count: null == count
          ? _value.count
          : count // ignore: cast_nullable_to_non_nullable
              as int,
      thumb: freezed == thumb
          ? _value.thumb
          : thumb // ignore: cast_nullable_to_non_nullable
              as String?,
      thumbLocal: freezed == thumbLocal
          ? _value.thumbLocal
          : thumbLocal // ignore: cast_nullable_to_non_nullable
              as String?,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$AlbumCountImpl implements _AlbumCount {
  const _$AlbumCountImpl(
      {required this.album,
      required this.artist,
      required this.count,
      this.thumb,
      this.thumbLocal});

  factory _$AlbumCountImpl.fromJson(Map<String, dynamic> json) =>
      _$$AlbumCountImplFromJson(json);

  @override
  final String album;
  @override
  final String artist;
  @override
  final int count;
  @override
  final String? thumb;
  @override
  final String? thumbLocal;

  @override
  String toString() {
    return 'AlbumCount(album: $album, artist: $artist, count: $count, thumb: $thumb, thumbLocal: $thumbLocal)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$AlbumCountImpl &&
            (identical(other.album, album) || other.album == album) &&
            (identical(other.artist, artist) || other.artist == artist) &&
            (identical(other.count, count) || other.count == count) &&
            (identical(other.thumb, thumb) || other.thumb == thumb) &&
            (identical(other.thumbLocal, thumbLocal) ||
                other.thumbLocal == thumbLocal));
  }

  @JsonKey(ignore: true)
  @override
  int get hashCode =>
      Object.hash(runtimeType, album, artist, count, thumb, thumbLocal);

  @JsonKey(ignore: true)
  @override
  @pragma('vm:prefer-inline')
  _$$AlbumCountImplCopyWith<_$AlbumCountImpl> get copyWith =>
      __$$AlbumCountImplCopyWithImpl<_$AlbumCountImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$AlbumCountImplToJson(
      this,
    );
  }
}

abstract class _AlbumCount implements AlbumCount {
  const factory _AlbumCount(
      {required final String album,
      required final String artist,
      required final int count,
      final String? thumb,
      final String? thumbLocal}) = _$AlbumCountImpl;

  factory _AlbumCount.fromJson(Map<String, dynamic> json) =
      _$AlbumCountImpl.fromJson;

  @override
  String get album;
  @override
  String get artist;
  @override
  int get count;
  @override
  String? get thumb;
  @override
  String? get thumbLocal;
  @override
  @JsonKey(ignore: true)
  _$$AlbumCountImplCopyWith<_$AlbumCountImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
