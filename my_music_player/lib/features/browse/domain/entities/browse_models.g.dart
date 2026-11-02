// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'browse_models.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$ArtistItemImpl _$$ArtistItemImplFromJson(Map<String, dynamic> json) =>
    _$ArtistItemImpl(
      browseId: json['browse_id'] as String,
      name: json['name'] as String,
      thumbnailUrl: json['thumbnail_url'] as String?,
      subscribers: json['subscribers'] as String?,
    );

Map<String, dynamic> _$$ArtistItemImplToJson(_$ArtistItemImpl instance) =>
    <String, dynamic>{
      'browse_id': instance.browseId,
      'name': instance.name,
      'thumbnail_url': instance.thumbnailUrl,
      'subscribers': instance.subscribers,
    };

_$AlbumItemImpl _$$AlbumItemImplFromJson(Map<String, dynamic> json) =>
    _$AlbumItemImpl(
      browseId: json['browse_id'] as String,
      title: json['title'] as String,
      artist: json['artist'] as String?,
      year: json['year'] as String?,
      thumbnailUrl: json['thumbnail_url'] as String?,
    );

Map<String, dynamic> _$$AlbumItemImplToJson(_$AlbumItemImpl instance) =>
    <String, dynamic>{
      'browse_id': instance.browseId,
      'title': instance.title,
      'artist': instance.artist,
      'year': instance.year,
      'thumbnail_url': instance.thumbnailUrl,
    };

_$ArtistDetailsImpl _$$ArtistDetailsImplFromJson(Map<String, dynamic> json) =>
    _$ArtistDetailsImpl(
      browseId: json['browse_id'] as String,
      name: json['name'] as String,
      description: json['description'] as String?,
      views: json['views'] as String?,
      subscribers: json['subscribers'] as String?,
      thumbnailUrl: json['thumbnail_url'] as String?,
      topSongs: (json['top_songs'] as List<dynamic>?)
              ?.map((e) => Track.fromJson(e as Map<String, dynamic>))
              .toList() ??
          const [],
      albums: (json['albums'] as List<dynamic>?)
              ?.map((e) => AlbumItem.fromJson(e as Map<String, dynamic>))
              .toList() ??
          const [],
      singles: (json['singles'] as List<dynamic>?)
              ?.map((e) => AlbumItem.fromJson(e as Map<String, dynamic>))
              .toList() ??
          const [],
      playlists: (json['playlists'] as List<dynamic>?)
              ?.map((e) => PlaylistItem.fromJson(e as Map<String, dynamic>))
              .toList() ??
          const [],
    );

Map<String, dynamic> _$$ArtistDetailsImplToJson(_$ArtistDetailsImpl instance) =>
    <String, dynamic>{
      'browse_id': instance.browseId,
      'name': instance.name,
      'description': instance.description,
      'views': instance.views,
      'subscribers': instance.subscribers,
      'thumbnail_url': instance.thumbnailUrl,
      'top_songs': instance.topSongs,
      'albums': instance.albums,
      'singles': instance.singles,
      'playlists': instance.playlists,
    };

_$AlbumDetailsImpl _$$AlbumDetailsImplFromJson(Map<String, dynamic> json) =>
    _$AlbumDetailsImpl(
      browseId: json['browse_id'] as String,
      title: json['title'] as String,
      artist: json['artist'] as String?,
      year: json['year'] as String?,
      trackCount: (json['track_count'] as num?)?.toInt(),
      duration: json['duration'] as String?,
      thumbnailUrl: json['thumbnail_url'] as String?,
      tracks: (json['tracks'] as List<dynamic>?)
              ?.map((e) => Track.fromJson(e as Map<String, dynamic>))
              .toList() ??
          const [],
    );

Map<String, dynamic> _$$AlbumDetailsImplToJson(_$AlbumDetailsImpl instance) =>
    <String, dynamic>{
      'browse_id': instance.browseId,
      'title': instance.title,
      'artist': instance.artist,
      'year': instance.year,
      'track_count': instance.trackCount,
      'duration': instance.duration,
      'thumbnail_url': instance.thumbnailUrl,
      'tracks': instance.tracks,
    };

_$PlaylistItemImpl _$$PlaylistItemImplFromJson(Map<String, dynamic> json) =>
    _$PlaylistItemImpl(
      browseId: json['browse_id'] as String,
      title: json['title'] as String,
      author: json['author'] as String?,
      itemCount: json['item_count'] as String?,
      thumbnailUrl: json['thumbnail_url'] as String?,
    );

Map<String, dynamic> _$$PlaylistItemImplToJson(_$PlaylistItemImpl instance) =>
    <String, dynamic>{
      'browse_id': instance.browseId,
      'title': instance.title,
      'author': instance.author,
      'item_count': instance.itemCount,
      'thumbnail_url': instance.thumbnailUrl,
    };

_$PlaylistDetailsImpl _$$PlaylistDetailsImplFromJson(
        Map<String, dynamic> json) =>
    _$PlaylistDetailsImpl(
      browseId: json['browse_id'] as String,
      title: json['title'] as String,
      author: json['author'] as String?,
      trackCount: (json['track_count'] as num?)?.toInt(),
      thumbnailUrl: json['thumbnail_url'] as String?,
      tracks: (json['tracks'] as List<dynamic>?)
              ?.map((e) => Track.fromJson(e as Map<String, dynamic>))
              .toList() ??
          const [],
    );

Map<String, dynamic> _$$PlaylistDetailsImplToJson(
        _$PlaylistDetailsImpl instance) =>
    <String, dynamic>{
      'browse_id': instance.browseId,
      'title': instance.title,
      'author': instance.author,
      'track_count': instance.trackCount,
      'thumbnail_url': instance.thumbnailUrl,
      'tracks': instance.tracks,
    };
