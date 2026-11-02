// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'browse_models.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
    'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models');

ArtistItem _$ArtistItemFromJson(Map<String, dynamic> json) {
  return _ArtistItem.fromJson(json);
}

/// @nodoc
mixin _$ArtistItem {
  String get browseId => throw _privateConstructorUsedError;
  String get name => throw _privateConstructorUsedError;
  String? get thumbnailUrl => throw _privateConstructorUsedError;
  String? get subscribers => throw _privateConstructorUsedError;

  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;
  @JsonKey(ignore: true)
  $ArtistItemCopyWith<ArtistItem> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $ArtistItemCopyWith<$Res> {
  factory $ArtistItemCopyWith(
          ArtistItem value, $Res Function(ArtistItem) then) =
      _$ArtistItemCopyWithImpl<$Res, ArtistItem>;
  @useResult
  $Res call(
      {String browseId,
      String name,
      String? thumbnailUrl,
      String? subscribers});
}

/// @nodoc
class _$ArtistItemCopyWithImpl<$Res, $Val extends ArtistItem>
    implements $ArtistItemCopyWith<$Res> {
  _$ArtistItemCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? browseId = null,
    Object? name = null,
    Object? thumbnailUrl = freezed,
    Object? subscribers = freezed,
  }) {
    return _then(_value.copyWith(
      browseId: null == browseId
          ? _value.browseId
          : browseId // ignore: cast_nullable_to_non_nullable
              as String,
      name: null == name
          ? _value.name
          : name // ignore: cast_nullable_to_non_nullable
              as String,
      thumbnailUrl: freezed == thumbnailUrl
          ? _value.thumbnailUrl
          : thumbnailUrl // ignore: cast_nullable_to_non_nullable
              as String?,
      subscribers: freezed == subscribers
          ? _value.subscribers
          : subscribers // ignore: cast_nullable_to_non_nullable
              as String?,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$ArtistItemImplCopyWith<$Res>
    implements $ArtistItemCopyWith<$Res> {
  factory _$$ArtistItemImplCopyWith(
          _$ArtistItemImpl value, $Res Function(_$ArtistItemImpl) then) =
      __$$ArtistItemImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {String browseId,
      String name,
      String? thumbnailUrl,
      String? subscribers});
}

/// @nodoc
class __$$ArtistItemImplCopyWithImpl<$Res>
    extends _$ArtistItemCopyWithImpl<$Res, _$ArtistItemImpl>
    implements _$$ArtistItemImplCopyWith<$Res> {
  __$$ArtistItemImplCopyWithImpl(
      _$ArtistItemImpl _value, $Res Function(_$ArtistItemImpl) _then)
      : super(_value, _then);

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? browseId = null,
    Object? name = null,
    Object? thumbnailUrl = freezed,
    Object? subscribers = freezed,
  }) {
    return _then(_$ArtistItemImpl(
      browseId: null == browseId
          ? _value.browseId
          : browseId // ignore: cast_nullable_to_non_nullable
              as String,
      name: null == name
          ? _value.name
          : name // ignore: cast_nullable_to_non_nullable
              as String,
      thumbnailUrl: freezed == thumbnailUrl
          ? _value.thumbnailUrl
          : thumbnailUrl // ignore: cast_nullable_to_non_nullable
              as String?,
      subscribers: freezed == subscribers
          ? _value.subscribers
          : subscribers // ignore: cast_nullable_to_non_nullable
              as String?,
    ));
  }
}

/// @nodoc

@JsonSerializable(fieldRename: FieldRename.snake)
class _$ArtistItemImpl implements _ArtistItem {
  const _$ArtistItemImpl(
      {required this.browseId,
      required this.name,
      this.thumbnailUrl,
      this.subscribers});

  factory _$ArtistItemImpl.fromJson(Map<String, dynamic> json) =>
      _$$ArtistItemImplFromJson(json);

  @override
  final String browseId;
  @override
  final String name;
  @override
  final String? thumbnailUrl;
  @override
  final String? subscribers;

  @override
  String toString() {
    return 'ArtistItem(browseId: $browseId, name: $name, thumbnailUrl: $thumbnailUrl, subscribers: $subscribers)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$ArtistItemImpl &&
            (identical(other.browseId, browseId) ||
                other.browseId == browseId) &&
            (identical(other.name, name) || other.name == name) &&
            (identical(other.thumbnailUrl, thumbnailUrl) ||
                other.thumbnailUrl == thumbnailUrl) &&
            (identical(other.subscribers, subscribers) ||
                other.subscribers == subscribers));
  }

  @JsonKey(ignore: true)
  @override
  int get hashCode =>
      Object.hash(runtimeType, browseId, name, thumbnailUrl, subscribers);

  @JsonKey(ignore: true)
  @override
  @pragma('vm:prefer-inline')
  _$$ArtistItemImplCopyWith<_$ArtistItemImpl> get copyWith =>
      __$$ArtistItemImplCopyWithImpl<_$ArtistItemImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$ArtistItemImplToJson(
      this,
    );
  }
}

abstract class _ArtistItem implements ArtistItem {
  const factory _ArtistItem(
      {required final String browseId,
      required final String name,
      final String? thumbnailUrl,
      final String? subscribers}) = _$ArtistItemImpl;

  factory _ArtistItem.fromJson(Map<String, dynamic> json) =
      _$ArtistItemImpl.fromJson;

  @override
  String get browseId;
  @override
  String get name;
  @override
  String? get thumbnailUrl;
  @override
  String? get subscribers;
  @override
  @JsonKey(ignore: true)
  _$$ArtistItemImplCopyWith<_$ArtistItemImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

AlbumItem _$AlbumItemFromJson(Map<String, dynamic> json) {
  return _AlbumItem.fromJson(json);
}

/// @nodoc
mixin _$AlbumItem {
  String get browseId => throw _privateConstructorUsedError;
  String get title => throw _privateConstructorUsedError;
  String? get artist => throw _privateConstructorUsedError;
  String? get year => throw _privateConstructorUsedError;
  String? get thumbnailUrl => throw _privateConstructorUsedError;

  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;
  @JsonKey(ignore: true)
  $AlbumItemCopyWith<AlbumItem> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $AlbumItemCopyWith<$Res> {
  factory $AlbumItemCopyWith(AlbumItem value, $Res Function(AlbumItem) then) =
      _$AlbumItemCopyWithImpl<$Res, AlbumItem>;
  @useResult
  $Res call(
      {String browseId,
      String title,
      String? artist,
      String? year,
      String? thumbnailUrl});
}

/// @nodoc
class _$AlbumItemCopyWithImpl<$Res, $Val extends AlbumItem>
    implements $AlbumItemCopyWith<$Res> {
  _$AlbumItemCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? browseId = null,
    Object? title = null,
    Object? artist = freezed,
    Object? year = freezed,
    Object? thumbnailUrl = freezed,
  }) {
    return _then(_value.copyWith(
      browseId: null == browseId
          ? _value.browseId
          : browseId // ignore: cast_nullable_to_non_nullable
              as String,
      title: null == title
          ? _value.title
          : title // ignore: cast_nullable_to_non_nullable
              as String,
      artist: freezed == artist
          ? _value.artist
          : artist // ignore: cast_nullable_to_non_nullable
              as String?,
      year: freezed == year
          ? _value.year
          : year // ignore: cast_nullable_to_non_nullable
              as String?,
      thumbnailUrl: freezed == thumbnailUrl
          ? _value.thumbnailUrl
          : thumbnailUrl // ignore: cast_nullable_to_non_nullable
              as String?,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$AlbumItemImplCopyWith<$Res>
    implements $AlbumItemCopyWith<$Res> {
  factory _$$AlbumItemImplCopyWith(
          _$AlbumItemImpl value, $Res Function(_$AlbumItemImpl) then) =
      __$$AlbumItemImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {String browseId,
      String title,
      String? artist,
      String? year,
      String? thumbnailUrl});
}

/// @nodoc
class __$$AlbumItemImplCopyWithImpl<$Res>
    extends _$AlbumItemCopyWithImpl<$Res, _$AlbumItemImpl>
    implements _$$AlbumItemImplCopyWith<$Res> {
  __$$AlbumItemImplCopyWithImpl(
      _$AlbumItemImpl _value, $Res Function(_$AlbumItemImpl) _then)
      : super(_value, _then);

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? browseId = null,
    Object? title = null,
    Object? artist = freezed,
    Object? year = freezed,
    Object? thumbnailUrl = freezed,
  }) {
    return _then(_$AlbumItemImpl(
      browseId: null == browseId
          ? _value.browseId
          : browseId // ignore: cast_nullable_to_non_nullable
              as String,
      title: null == title
          ? _value.title
          : title // ignore: cast_nullable_to_non_nullable
              as String,
      artist: freezed == artist
          ? _value.artist
          : artist // ignore: cast_nullable_to_non_nullable
              as String?,
      year: freezed == year
          ? _value.year
          : year // ignore: cast_nullable_to_non_nullable
              as String?,
      thumbnailUrl: freezed == thumbnailUrl
          ? _value.thumbnailUrl
          : thumbnailUrl // ignore: cast_nullable_to_non_nullable
              as String?,
    ));
  }
}

/// @nodoc

@JsonSerializable(fieldRename: FieldRename.snake)
class _$AlbumItemImpl implements _AlbumItem {
  const _$AlbumItemImpl(
      {required this.browseId,
      required this.title,
      this.artist,
      this.year,
      this.thumbnailUrl});

  factory _$AlbumItemImpl.fromJson(Map<String, dynamic> json) =>
      _$$AlbumItemImplFromJson(json);

  @override
  final String browseId;
  @override
  final String title;
  @override
  final String? artist;
  @override
  final String? year;
  @override
  final String? thumbnailUrl;

  @override
  String toString() {
    return 'AlbumItem(browseId: $browseId, title: $title, artist: $artist, year: $year, thumbnailUrl: $thumbnailUrl)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$AlbumItemImpl &&
            (identical(other.browseId, browseId) ||
                other.browseId == browseId) &&
            (identical(other.title, title) || other.title == title) &&
            (identical(other.artist, artist) || other.artist == artist) &&
            (identical(other.year, year) || other.year == year) &&
            (identical(other.thumbnailUrl, thumbnailUrl) ||
                other.thumbnailUrl == thumbnailUrl));
  }

  @JsonKey(ignore: true)
  @override
  int get hashCode =>
      Object.hash(runtimeType, browseId, title, artist, year, thumbnailUrl);

  @JsonKey(ignore: true)
  @override
  @pragma('vm:prefer-inline')
  _$$AlbumItemImplCopyWith<_$AlbumItemImpl> get copyWith =>
      __$$AlbumItemImplCopyWithImpl<_$AlbumItemImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$AlbumItemImplToJson(
      this,
    );
  }
}

abstract class _AlbumItem implements AlbumItem {
  const factory _AlbumItem(
      {required final String browseId,
      required final String title,
      final String? artist,
      final String? year,
      final String? thumbnailUrl}) = _$AlbumItemImpl;

  factory _AlbumItem.fromJson(Map<String, dynamic> json) =
      _$AlbumItemImpl.fromJson;

  @override
  String get browseId;
  @override
  String get title;
  @override
  String? get artist;
  @override
  String? get year;
  @override
  String? get thumbnailUrl;
  @override
  @JsonKey(ignore: true)
  _$$AlbumItemImplCopyWith<_$AlbumItemImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

ArtistDetails _$ArtistDetailsFromJson(Map<String, dynamic> json) {
  return _ArtistDetails.fromJson(json);
}

/// @nodoc
mixin _$ArtistDetails {
  String get browseId => throw _privateConstructorUsedError;
  String get name => throw _privateConstructorUsedError;
  String? get description => throw _privateConstructorUsedError;
  String? get views => throw _privateConstructorUsedError;
  String? get subscribers => throw _privateConstructorUsedError;
  String? get thumbnailUrl => throw _privateConstructorUsedError;
  List<Track> get topSongs => throw _privateConstructorUsedError;
  List<AlbumItem> get albums => throw _privateConstructorUsedError;
  List<AlbumItem> get singles => throw _privateConstructorUsedError;
  List<PlaylistItem> get playlists => throw _privateConstructorUsedError;

  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;
  @JsonKey(ignore: true)
  $ArtistDetailsCopyWith<ArtistDetails> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $ArtistDetailsCopyWith<$Res> {
  factory $ArtistDetailsCopyWith(
          ArtistDetails value, $Res Function(ArtistDetails) then) =
      _$ArtistDetailsCopyWithImpl<$Res, ArtistDetails>;
  @useResult
  $Res call(
      {String browseId,
      String name,
      String? description,
      String? views,
      String? subscribers,
      String? thumbnailUrl,
      List<Track> topSongs,
      List<AlbumItem> albums,
      List<AlbumItem> singles,
      List<PlaylistItem> playlists});
}

/// @nodoc
class _$ArtistDetailsCopyWithImpl<$Res, $Val extends ArtistDetails>
    implements $ArtistDetailsCopyWith<$Res> {
  _$ArtistDetailsCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? browseId = null,
    Object? name = null,
    Object? description = freezed,
    Object? views = freezed,
    Object? subscribers = freezed,
    Object? thumbnailUrl = freezed,
    Object? topSongs = null,
    Object? albums = null,
    Object? singles = null,
    Object? playlists = null,
  }) {
    return _then(_value.copyWith(
      browseId: null == browseId
          ? _value.browseId
          : browseId // ignore: cast_nullable_to_non_nullable
              as String,
      name: null == name
          ? _value.name
          : name // ignore: cast_nullable_to_non_nullable
              as String,
      description: freezed == description
          ? _value.description
          : description // ignore: cast_nullable_to_non_nullable
              as String?,
      views: freezed == views
          ? _value.views
          : views // ignore: cast_nullable_to_non_nullable
              as String?,
      subscribers: freezed == subscribers
          ? _value.subscribers
          : subscribers // ignore: cast_nullable_to_non_nullable
              as String?,
      thumbnailUrl: freezed == thumbnailUrl
          ? _value.thumbnailUrl
          : thumbnailUrl // ignore: cast_nullable_to_non_nullable
              as String?,
      topSongs: null == topSongs
          ? _value.topSongs
          : topSongs // ignore: cast_nullable_to_non_nullable
              as List<Track>,
      albums: null == albums
          ? _value.albums
          : albums // ignore: cast_nullable_to_non_nullable
              as List<AlbumItem>,
      singles: null == singles
          ? _value.singles
          : singles // ignore: cast_nullable_to_non_nullable
              as List<AlbumItem>,
      playlists: null == playlists
          ? _value.playlists
          : playlists // ignore: cast_nullable_to_non_nullable
              as List<PlaylistItem>,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$ArtistDetailsImplCopyWith<$Res>
    implements $ArtistDetailsCopyWith<$Res> {
  factory _$$ArtistDetailsImplCopyWith(
          _$ArtistDetailsImpl value, $Res Function(_$ArtistDetailsImpl) then) =
      __$$ArtistDetailsImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {String browseId,
      String name,
      String? description,
      String? views,
      String? subscribers,
      String? thumbnailUrl,
      List<Track> topSongs,
      List<AlbumItem> albums,
      List<AlbumItem> singles,
      List<PlaylistItem> playlists});
}

/// @nodoc
class __$$ArtistDetailsImplCopyWithImpl<$Res>
    extends _$ArtistDetailsCopyWithImpl<$Res, _$ArtistDetailsImpl>
    implements _$$ArtistDetailsImplCopyWith<$Res> {
  __$$ArtistDetailsImplCopyWithImpl(
      _$ArtistDetailsImpl _value, $Res Function(_$ArtistDetailsImpl) _then)
      : super(_value, _then);

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? browseId = null,
    Object? name = null,
    Object? description = freezed,
    Object? views = freezed,
    Object? subscribers = freezed,
    Object? thumbnailUrl = freezed,
    Object? topSongs = null,
    Object? albums = null,
    Object? singles = null,
    Object? playlists = null,
  }) {
    return _then(_$ArtistDetailsImpl(
      browseId: null == browseId
          ? _value.browseId
          : browseId // ignore: cast_nullable_to_non_nullable
              as String,
      name: null == name
          ? _value.name
          : name // ignore: cast_nullable_to_non_nullable
              as String,
      description: freezed == description
          ? _value.description
          : description // ignore: cast_nullable_to_non_nullable
              as String?,
      views: freezed == views
          ? _value.views
          : views // ignore: cast_nullable_to_non_nullable
              as String?,
      subscribers: freezed == subscribers
          ? _value.subscribers
          : subscribers // ignore: cast_nullable_to_non_nullable
              as String?,
      thumbnailUrl: freezed == thumbnailUrl
          ? _value.thumbnailUrl
          : thumbnailUrl // ignore: cast_nullable_to_non_nullable
              as String?,
      topSongs: null == topSongs
          ? _value._topSongs
          : topSongs // ignore: cast_nullable_to_non_nullable
              as List<Track>,
      albums: null == albums
          ? _value._albums
          : albums // ignore: cast_nullable_to_non_nullable
              as List<AlbumItem>,
      singles: null == singles
          ? _value._singles
          : singles // ignore: cast_nullable_to_non_nullable
              as List<AlbumItem>,
      playlists: null == playlists
          ? _value._playlists
          : playlists // ignore: cast_nullable_to_non_nullable
              as List<PlaylistItem>,
    ));
  }
}

/// @nodoc

@JsonSerializable(fieldRename: FieldRename.snake)
class _$ArtistDetailsImpl implements _ArtistDetails {
  const _$ArtistDetailsImpl(
      {required this.browseId,
      required this.name,
      this.description,
      this.views,
      this.subscribers,
      this.thumbnailUrl,
      final List<Track> topSongs = const [],
      final List<AlbumItem> albums = const [],
      final List<AlbumItem> singles = const [],
      final List<PlaylistItem> playlists = const []})
      : _topSongs = topSongs,
        _albums = albums,
        _singles = singles,
        _playlists = playlists;

  factory _$ArtistDetailsImpl.fromJson(Map<String, dynamic> json) =>
      _$$ArtistDetailsImplFromJson(json);

  @override
  final String browseId;
  @override
  final String name;
  @override
  final String? description;
  @override
  final String? views;
  @override
  final String? subscribers;
  @override
  final String? thumbnailUrl;
  final List<Track> _topSongs;
  @override
  @JsonKey()
  List<Track> get topSongs {
    if (_topSongs is EqualUnmodifiableListView) return _topSongs;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_topSongs);
  }

  final List<AlbumItem> _albums;
  @override
  @JsonKey()
  List<AlbumItem> get albums {
    if (_albums is EqualUnmodifiableListView) return _albums;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_albums);
  }

  final List<AlbumItem> _singles;
  @override
  @JsonKey()
  List<AlbumItem> get singles {
    if (_singles is EqualUnmodifiableListView) return _singles;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_singles);
  }

  final List<PlaylistItem> _playlists;
  @override
  @JsonKey()
  List<PlaylistItem> get playlists {
    if (_playlists is EqualUnmodifiableListView) return _playlists;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_playlists);
  }

  @override
  String toString() {
    return 'ArtistDetails(browseId: $browseId, name: $name, description: $description, views: $views, subscribers: $subscribers, thumbnailUrl: $thumbnailUrl, topSongs: $topSongs, albums: $albums, singles: $singles, playlists: $playlists)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$ArtistDetailsImpl &&
            (identical(other.browseId, browseId) ||
                other.browseId == browseId) &&
            (identical(other.name, name) || other.name == name) &&
            (identical(other.description, description) ||
                other.description == description) &&
            (identical(other.views, views) || other.views == views) &&
            (identical(other.subscribers, subscribers) ||
                other.subscribers == subscribers) &&
            (identical(other.thumbnailUrl, thumbnailUrl) ||
                other.thumbnailUrl == thumbnailUrl) &&
            const DeepCollectionEquality().equals(other._topSongs, _topSongs) &&
            const DeepCollectionEquality().equals(other._albums, _albums) &&
            const DeepCollectionEquality().equals(other._singles, _singles) &&
            const DeepCollectionEquality()
                .equals(other._playlists, _playlists));
  }

  @JsonKey(ignore: true)
  @override
  int get hashCode => Object.hash(
      runtimeType,
      browseId,
      name,
      description,
      views,
      subscribers,
      thumbnailUrl,
      const DeepCollectionEquality().hash(_topSongs),
      const DeepCollectionEquality().hash(_albums),
      const DeepCollectionEquality().hash(_singles),
      const DeepCollectionEquality().hash(_playlists));

  @JsonKey(ignore: true)
  @override
  @pragma('vm:prefer-inline')
  _$$ArtistDetailsImplCopyWith<_$ArtistDetailsImpl> get copyWith =>
      __$$ArtistDetailsImplCopyWithImpl<_$ArtistDetailsImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$ArtistDetailsImplToJson(
      this,
    );
  }
}

abstract class _ArtistDetails implements ArtistDetails {
  const factory _ArtistDetails(
      {required final String browseId,
      required final String name,
      final String? description,
      final String? views,
      final String? subscribers,
      final String? thumbnailUrl,
      final List<Track> topSongs,
      final List<AlbumItem> albums,
      final List<AlbumItem> singles,
      final List<PlaylistItem> playlists}) = _$ArtistDetailsImpl;

  factory _ArtistDetails.fromJson(Map<String, dynamic> json) =
      _$ArtistDetailsImpl.fromJson;

  @override
  String get browseId;
  @override
  String get name;
  @override
  String? get description;
  @override
  String? get views;
  @override
  String? get subscribers;
  @override
  String? get thumbnailUrl;
  @override
  List<Track> get topSongs;
  @override
  List<AlbumItem> get albums;
  @override
  List<AlbumItem> get singles;
  @override
  List<PlaylistItem> get playlists;
  @override
  @JsonKey(ignore: true)
  _$$ArtistDetailsImplCopyWith<_$ArtistDetailsImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

AlbumDetails _$AlbumDetailsFromJson(Map<String, dynamic> json) {
  return _AlbumDetails.fromJson(json);
}

/// @nodoc
mixin _$AlbumDetails {
  String get browseId => throw _privateConstructorUsedError;
  String get title => throw _privateConstructorUsedError;
  String? get artist => throw _privateConstructorUsedError;
  String? get year => throw _privateConstructorUsedError;
  int? get trackCount => throw _privateConstructorUsedError;
  String? get duration => throw _privateConstructorUsedError;
  String? get thumbnailUrl => throw _privateConstructorUsedError;
  List<Track> get tracks => throw _privateConstructorUsedError;

  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;
  @JsonKey(ignore: true)
  $AlbumDetailsCopyWith<AlbumDetails> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $AlbumDetailsCopyWith<$Res> {
  factory $AlbumDetailsCopyWith(
          AlbumDetails value, $Res Function(AlbumDetails) then) =
      _$AlbumDetailsCopyWithImpl<$Res, AlbumDetails>;
  @useResult
  $Res call(
      {String browseId,
      String title,
      String? artist,
      String? year,
      int? trackCount,
      String? duration,
      String? thumbnailUrl,
      List<Track> tracks});
}

/// @nodoc
class _$AlbumDetailsCopyWithImpl<$Res, $Val extends AlbumDetails>
    implements $AlbumDetailsCopyWith<$Res> {
  _$AlbumDetailsCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? browseId = null,
    Object? title = null,
    Object? artist = freezed,
    Object? year = freezed,
    Object? trackCount = freezed,
    Object? duration = freezed,
    Object? thumbnailUrl = freezed,
    Object? tracks = null,
  }) {
    return _then(_value.copyWith(
      browseId: null == browseId
          ? _value.browseId
          : browseId // ignore: cast_nullable_to_non_nullable
              as String,
      title: null == title
          ? _value.title
          : title // ignore: cast_nullable_to_non_nullable
              as String,
      artist: freezed == artist
          ? _value.artist
          : artist // ignore: cast_nullable_to_non_nullable
              as String?,
      year: freezed == year
          ? _value.year
          : year // ignore: cast_nullable_to_non_nullable
              as String?,
      trackCount: freezed == trackCount
          ? _value.trackCount
          : trackCount // ignore: cast_nullable_to_non_nullable
              as int?,
      duration: freezed == duration
          ? _value.duration
          : duration // ignore: cast_nullable_to_non_nullable
              as String?,
      thumbnailUrl: freezed == thumbnailUrl
          ? _value.thumbnailUrl
          : thumbnailUrl // ignore: cast_nullable_to_non_nullable
              as String?,
      tracks: null == tracks
          ? _value.tracks
          : tracks // ignore: cast_nullable_to_non_nullable
              as List<Track>,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$AlbumDetailsImplCopyWith<$Res>
    implements $AlbumDetailsCopyWith<$Res> {
  factory _$$AlbumDetailsImplCopyWith(
          _$AlbumDetailsImpl value, $Res Function(_$AlbumDetailsImpl) then) =
      __$$AlbumDetailsImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {String browseId,
      String title,
      String? artist,
      String? year,
      int? trackCount,
      String? duration,
      String? thumbnailUrl,
      List<Track> tracks});
}

/// @nodoc
class __$$AlbumDetailsImplCopyWithImpl<$Res>
    extends _$AlbumDetailsCopyWithImpl<$Res, _$AlbumDetailsImpl>
    implements _$$AlbumDetailsImplCopyWith<$Res> {
  __$$AlbumDetailsImplCopyWithImpl(
      _$AlbumDetailsImpl _value, $Res Function(_$AlbumDetailsImpl) _then)
      : super(_value, _then);

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? browseId = null,
    Object? title = null,
    Object? artist = freezed,
    Object? year = freezed,
    Object? trackCount = freezed,
    Object? duration = freezed,
    Object? thumbnailUrl = freezed,
    Object? tracks = null,
  }) {
    return _then(_$AlbumDetailsImpl(
      browseId: null == browseId
          ? _value.browseId
          : browseId // ignore: cast_nullable_to_non_nullable
              as String,
      title: null == title
          ? _value.title
          : title // ignore: cast_nullable_to_non_nullable
              as String,
      artist: freezed == artist
          ? _value.artist
          : artist // ignore: cast_nullable_to_non_nullable
              as String?,
      year: freezed == year
          ? _value.year
          : year // ignore: cast_nullable_to_non_nullable
              as String?,
      trackCount: freezed == trackCount
          ? _value.trackCount
          : trackCount // ignore: cast_nullable_to_non_nullable
              as int?,
      duration: freezed == duration
          ? _value.duration
          : duration // ignore: cast_nullable_to_non_nullable
              as String?,
      thumbnailUrl: freezed == thumbnailUrl
          ? _value.thumbnailUrl
          : thumbnailUrl // ignore: cast_nullable_to_non_nullable
              as String?,
      tracks: null == tracks
          ? _value._tracks
          : tracks // ignore: cast_nullable_to_non_nullable
              as List<Track>,
    ));
  }
}

/// @nodoc

@JsonSerializable(fieldRename: FieldRename.snake)
class _$AlbumDetailsImpl implements _AlbumDetails {
  const _$AlbumDetailsImpl(
      {required this.browseId,
      required this.title,
      this.artist,
      this.year,
      this.trackCount,
      this.duration,
      this.thumbnailUrl,
      final List<Track> tracks = const []})
      : _tracks = tracks;

  factory _$AlbumDetailsImpl.fromJson(Map<String, dynamic> json) =>
      _$$AlbumDetailsImplFromJson(json);

  @override
  final String browseId;
  @override
  final String title;
  @override
  final String? artist;
  @override
  final String? year;
  @override
  final int? trackCount;
  @override
  final String? duration;
  @override
  final String? thumbnailUrl;
  final List<Track> _tracks;
  @override
  @JsonKey()
  List<Track> get tracks {
    if (_tracks is EqualUnmodifiableListView) return _tracks;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_tracks);
  }

  @override
  String toString() {
    return 'AlbumDetails(browseId: $browseId, title: $title, artist: $artist, year: $year, trackCount: $trackCount, duration: $duration, thumbnailUrl: $thumbnailUrl, tracks: $tracks)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$AlbumDetailsImpl &&
            (identical(other.browseId, browseId) ||
                other.browseId == browseId) &&
            (identical(other.title, title) || other.title == title) &&
            (identical(other.artist, artist) || other.artist == artist) &&
            (identical(other.year, year) || other.year == year) &&
            (identical(other.trackCount, trackCount) ||
                other.trackCount == trackCount) &&
            (identical(other.duration, duration) ||
                other.duration == duration) &&
            (identical(other.thumbnailUrl, thumbnailUrl) ||
                other.thumbnailUrl == thumbnailUrl) &&
            const DeepCollectionEquality().equals(other._tracks, _tracks));
  }

  @JsonKey(ignore: true)
  @override
  int get hashCode => Object.hash(
      runtimeType,
      browseId,
      title,
      artist,
      year,
      trackCount,
      duration,
      thumbnailUrl,
      const DeepCollectionEquality().hash(_tracks));

  @JsonKey(ignore: true)
  @override
  @pragma('vm:prefer-inline')
  _$$AlbumDetailsImplCopyWith<_$AlbumDetailsImpl> get copyWith =>
      __$$AlbumDetailsImplCopyWithImpl<_$AlbumDetailsImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$AlbumDetailsImplToJson(
      this,
    );
  }
}

abstract class _AlbumDetails implements AlbumDetails {
  const factory _AlbumDetails(
      {required final String browseId,
      required final String title,
      final String? artist,
      final String? year,
      final int? trackCount,
      final String? duration,
      final String? thumbnailUrl,
      final List<Track> tracks}) = _$AlbumDetailsImpl;

  factory _AlbumDetails.fromJson(Map<String, dynamic> json) =
      _$AlbumDetailsImpl.fromJson;

  @override
  String get browseId;
  @override
  String get title;
  @override
  String? get artist;
  @override
  String? get year;
  @override
  int? get trackCount;
  @override
  String? get duration;
  @override
  String? get thumbnailUrl;
  @override
  List<Track> get tracks;
  @override
  @JsonKey(ignore: true)
  _$$AlbumDetailsImplCopyWith<_$AlbumDetailsImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

PlaylistItem _$PlaylistItemFromJson(Map<String, dynamic> json) {
  return _PlaylistItem.fromJson(json);
}

/// @nodoc
mixin _$PlaylistItem {
  String get browseId => throw _privateConstructorUsedError;
  String get title => throw _privateConstructorUsedError;
  String? get author => throw _privateConstructorUsedError;
  String? get itemCount => throw _privateConstructorUsedError;
  String? get thumbnailUrl => throw _privateConstructorUsedError;

  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;
  @JsonKey(ignore: true)
  $PlaylistItemCopyWith<PlaylistItem> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $PlaylistItemCopyWith<$Res> {
  factory $PlaylistItemCopyWith(
          PlaylistItem value, $Res Function(PlaylistItem) then) =
      _$PlaylistItemCopyWithImpl<$Res, PlaylistItem>;
  @useResult
  $Res call(
      {String browseId,
      String title,
      String? author,
      String? itemCount,
      String? thumbnailUrl});
}

/// @nodoc
class _$PlaylistItemCopyWithImpl<$Res, $Val extends PlaylistItem>
    implements $PlaylistItemCopyWith<$Res> {
  _$PlaylistItemCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? browseId = null,
    Object? title = null,
    Object? author = freezed,
    Object? itemCount = freezed,
    Object? thumbnailUrl = freezed,
  }) {
    return _then(_value.copyWith(
      browseId: null == browseId
          ? _value.browseId
          : browseId // ignore: cast_nullable_to_non_nullable
              as String,
      title: null == title
          ? _value.title
          : title // ignore: cast_nullable_to_non_nullable
              as String,
      author: freezed == author
          ? _value.author
          : author // ignore: cast_nullable_to_non_nullable
              as String?,
      itemCount: freezed == itemCount
          ? _value.itemCount
          : itemCount // ignore: cast_nullable_to_non_nullable
              as String?,
      thumbnailUrl: freezed == thumbnailUrl
          ? _value.thumbnailUrl
          : thumbnailUrl // ignore: cast_nullable_to_non_nullable
              as String?,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$PlaylistItemImplCopyWith<$Res>
    implements $PlaylistItemCopyWith<$Res> {
  factory _$$PlaylistItemImplCopyWith(
          _$PlaylistItemImpl value, $Res Function(_$PlaylistItemImpl) then) =
      __$$PlaylistItemImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {String browseId,
      String title,
      String? author,
      String? itemCount,
      String? thumbnailUrl});
}

/// @nodoc
class __$$PlaylistItemImplCopyWithImpl<$Res>
    extends _$PlaylistItemCopyWithImpl<$Res, _$PlaylistItemImpl>
    implements _$$PlaylistItemImplCopyWith<$Res> {
  __$$PlaylistItemImplCopyWithImpl(
      _$PlaylistItemImpl _value, $Res Function(_$PlaylistItemImpl) _then)
      : super(_value, _then);

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? browseId = null,
    Object? title = null,
    Object? author = freezed,
    Object? itemCount = freezed,
    Object? thumbnailUrl = freezed,
  }) {
    return _then(_$PlaylistItemImpl(
      browseId: null == browseId
          ? _value.browseId
          : browseId // ignore: cast_nullable_to_non_nullable
              as String,
      title: null == title
          ? _value.title
          : title // ignore: cast_nullable_to_non_nullable
              as String,
      author: freezed == author
          ? _value.author
          : author // ignore: cast_nullable_to_non_nullable
              as String?,
      itemCount: freezed == itemCount
          ? _value.itemCount
          : itemCount // ignore: cast_nullable_to_non_nullable
              as String?,
      thumbnailUrl: freezed == thumbnailUrl
          ? _value.thumbnailUrl
          : thumbnailUrl // ignore: cast_nullable_to_non_nullable
              as String?,
    ));
  }
}

/// @nodoc

@JsonSerializable(fieldRename: FieldRename.snake)
class _$PlaylistItemImpl implements _PlaylistItem {
  const _$PlaylistItemImpl(
      {required this.browseId,
      required this.title,
      this.author,
      this.itemCount,
      this.thumbnailUrl});

  factory _$PlaylistItemImpl.fromJson(Map<String, dynamic> json) =>
      _$$PlaylistItemImplFromJson(json);

  @override
  final String browseId;
  @override
  final String title;
  @override
  final String? author;
  @override
  final String? itemCount;
  @override
  final String? thumbnailUrl;

  @override
  String toString() {
    return 'PlaylistItem(browseId: $browseId, title: $title, author: $author, itemCount: $itemCount, thumbnailUrl: $thumbnailUrl)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$PlaylistItemImpl &&
            (identical(other.browseId, browseId) ||
                other.browseId == browseId) &&
            (identical(other.title, title) || other.title == title) &&
            (identical(other.author, author) || other.author == author) &&
            (identical(other.itemCount, itemCount) ||
                other.itemCount == itemCount) &&
            (identical(other.thumbnailUrl, thumbnailUrl) ||
                other.thumbnailUrl == thumbnailUrl));
  }

  @JsonKey(ignore: true)
  @override
  int get hashCode => Object.hash(
      runtimeType, browseId, title, author, itemCount, thumbnailUrl);

  @JsonKey(ignore: true)
  @override
  @pragma('vm:prefer-inline')
  _$$PlaylistItemImplCopyWith<_$PlaylistItemImpl> get copyWith =>
      __$$PlaylistItemImplCopyWithImpl<_$PlaylistItemImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$PlaylistItemImplToJson(
      this,
    );
  }
}

abstract class _PlaylistItem implements PlaylistItem {
  const factory _PlaylistItem(
      {required final String browseId,
      required final String title,
      final String? author,
      final String? itemCount,
      final String? thumbnailUrl}) = _$PlaylistItemImpl;

  factory _PlaylistItem.fromJson(Map<String, dynamic> json) =
      _$PlaylistItemImpl.fromJson;

  @override
  String get browseId;
  @override
  String get title;
  @override
  String? get author;
  @override
  String? get itemCount;
  @override
  String? get thumbnailUrl;
  @override
  @JsonKey(ignore: true)
  _$$PlaylistItemImplCopyWith<_$PlaylistItemImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

PlaylistDetails _$PlaylistDetailsFromJson(Map<String, dynamic> json) {
  return _PlaylistDetails.fromJson(json);
}

/// @nodoc
mixin _$PlaylistDetails {
  String get browseId => throw _privateConstructorUsedError;
  String get title => throw _privateConstructorUsedError;
  String? get author => throw _privateConstructorUsedError;
  int? get trackCount => throw _privateConstructorUsedError;
  String? get thumbnailUrl => throw _privateConstructorUsedError;
  List<Track> get tracks => throw _privateConstructorUsedError;

  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;
  @JsonKey(ignore: true)
  $PlaylistDetailsCopyWith<PlaylistDetails> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $PlaylistDetailsCopyWith<$Res> {
  factory $PlaylistDetailsCopyWith(
          PlaylistDetails value, $Res Function(PlaylistDetails) then) =
      _$PlaylistDetailsCopyWithImpl<$Res, PlaylistDetails>;
  @useResult
  $Res call(
      {String browseId,
      String title,
      String? author,
      int? trackCount,
      String? thumbnailUrl,
      List<Track> tracks});
}

/// @nodoc
class _$PlaylistDetailsCopyWithImpl<$Res, $Val extends PlaylistDetails>
    implements $PlaylistDetailsCopyWith<$Res> {
  _$PlaylistDetailsCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? browseId = null,
    Object? title = null,
    Object? author = freezed,
    Object? trackCount = freezed,
    Object? thumbnailUrl = freezed,
    Object? tracks = null,
  }) {
    return _then(_value.copyWith(
      browseId: null == browseId
          ? _value.browseId
          : browseId // ignore: cast_nullable_to_non_nullable
              as String,
      title: null == title
          ? _value.title
          : title // ignore: cast_nullable_to_non_nullable
              as String,
      author: freezed == author
          ? _value.author
          : author // ignore: cast_nullable_to_non_nullable
              as String?,
      trackCount: freezed == trackCount
          ? _value.trackCount
          : trackCount // ignore: cast_nullable_to_non_nullable
              as int?,
      thumbnailUrl: freezed == thumbnailUrl
          ? _value.thumbnailUrl
          : thumbnailUrl // ignore: cast_nullable_to_non_nullable
              as String?,
      tracks: null == tracks
          ? _value.tracks
          : tracks // ignore: cast_nullable_to_non_nullable
              as List<Track>,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$PlaylistDetailsImplCopyWith<$Res>
    implements $PlaylistDetailsCopyWith<$Res> {
  factory _$$PlaylistDetailsImplCopyWith(_$PlaylistDetailsImpl value,
          $Res Function(_$PlaylistDetailsImpl) then) =
      __$$PlaylistDetailsImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {String browseId,
      String title,
      String? author,
      int? trackCount,
      String? thumbnailUrl,
      List<Track> tracks});
}

/// @nodoc
class __$$PlaylistDetailsImplCopyWithImpl<$Res>
    extends _$PlaylistDetailsCopyWithImpl<$Res, _$PlaylistDetailsImpl>
    implements _$$PlaylistDetailsImplCopyWith<$Res> {
  __$$PlaylistDetailsImplCopyWithImpl(
      _$PlaylistDetailsImpl _value, $Res Function(_$PlaylistDetailsImpl) _then)
      : super(_value, _then);

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? browseId = null,
    Object? title = null,
    Object? author = freezed,
    Object? trackCount = freezed,
    Object? thumbnailUrl = freezed,
    Object? tracks = null,
  }) {
    return _then(_$PlaylistDetailsImpl(
      browseId: null == browseId
          ? _value.browseId
          : browseId // ignore: cast_nullable_to_non_nullable
              as String,
      title: null == title
          ? _value.title
          : title // ignore: cast_nullable_to_non_nullable
              as String,
      author: freezed == author
          ? _value.author
          : author // ignore: cast_nullable_to_non_nullable
              as String?,
      trackCount: freezed == trackCount
          ? _value.trackCount
          : trackCount // ignore: cast_nullable_to_non_nullable
              as int?,
      thumbnailUrl: freezed == thumbnailUrl
          ? _value.thumbnailUrl
          : thumbnailUrl // ignore: cast_nullable_to_non_nullable
              as String?,
      tracks: null == tracks
          ? _value._tracks
          : tracks // ignore: cast_nullable_to_non_nullable
              as List<Track>,
    ));
  }
}

/// @nodoc

@JsonSerializable(fieldRename: FieldRename.snake)
class _$PlaylistDetailsImpl implements _PlaylistDetails {
  const _$PlaylistDetailsImpl(
      {required this.browseId,
      required this.title,
      this.author,
      this.trackCount,
      this.thumbnailUrl,
      final List<Track> tracks = const []})
      : _tracks = tracks;

  factory _$PlaylistDetailsImpl.fromJson(Map<String, dynamic> json) =>
      _$$PlaylistDetailsImplFromJson(json);

  @override
  final String browseId;
  @override
  final String title;
  @override
  final String? author;
  @override
  final int? trackCount;
  @override
  final String? thumbnailUrl;
  final List<Track> _tracks;
  @override
  @JsonKey()
  List<Track> get tracks {
    if (_tracks is EqualUnmodifiableListView) return _tracks;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_tracks);
  }

  @override
  String toString() {
    return 'PlaylistDetails(browseId: $browseId, title: $title, author: $author, trackCount: $trackCount, thumbnailUrl: $thumbnailUrl, tracks: $tracks)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$PlaylistDetailsImpl &&
            (identical(other.browseId, browseId) ||
                other.browseId == browseId) &&
            (identical(other.title, title) || other.title == title) &&
            (identical(other.author, author) || other.author == author) &&
            (identical(other.trackCount, trackCount) ||
                other.trackCount == trackCount) &&
            (identical(other.thumbnailUrl, thumbnailUrl) ||
                other.thumbnailUrl == thumbnailUrl) &&
            const DeepCollectionEquality().equals(other._tracks, _tracks));
  }

  @JsonKey(ignore: true)
  @override
  int get hashCode => Object.hash(runtimeType, browseId, title, author,
      trackCount, thumbnailUrl, const DeepCollectionEquality().hash(_tracks));

  @JsonKey(ignore: true)
  @override
  @pragma('vm:prefer-inline')
  _$$PlaylistDetailsImplCopyWith<_$PlaylistDetailsImpl> get copyWith =>
      __$$PlaylistDetailsImplCopyWithImpl<_$PlaylistDetailsImpl>(
          this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$PlaylistDetailsImplToJson(
      this,
    );
  }
}

abstract class _PlaylistDetails implements PlaylistDetails {
  const factory _PlaylistDetails(
      {required final String browseId,
      required final String title,
      final String? author,
      final int? trackCount,
      final String? thumbnailUrl,
      final List<Track> tracks}) = _$PlaylistDetailsImpl;

  factory _PlaylistDetails.fromJson(Map<String, dynamic> json) =
      _$PlaylistDetailsImpl.fromJson;

  @override
  String get browseId;
  @override
  String get title;
  @override
  String? get author;
  @override
  int? get trackCount;
  @override
  String? get thumbnailUrl;
  @override
  List<Track> get tracks;
  @override
  @JsonKey(ignore: true)
  _$$PlaylistDetailsImplCopyWith<_$PlaylistDetailsImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
