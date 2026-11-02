import 'package:freezed_annotation/freezed_annotation.dart';
import '../../../player/domain/entities/track.dart';

part 'browse_models.freezed.dart';
part 'browse_models.g.dart';

@freezed
class ArtistItem with _$ArtistItem {
  @JsonSerializable(fieldRename: FieldRename.snake)
  const factory ArtistItem({
    required String browseId,
    required String name,
    String? thumbnailUrl,
    String? subscribers,
  }) = _ArtistItem;

  factory ArtistItem.fromJson(Map<String, dynamic> json) => _$ArtistItemFromJson(json);
}

@freezed
class AlbumItem with _$AlbumItem {
  @JsonSerializable(fieldRename: FieldRename.snake)
  const factory AlbumItem({
    required String browseId,
    required String title,
    String? artist,
    String? year,
    String? thumbnailUrl,
  }) = _AlbumItem;

  factory AlbumItem.fromJson(Map<String, dynamic> json) => _$AlbumItemFromJson(json);
}

@freezed
class ArtistDetails with _$ArtistDetails {
  @JsonSerializable(fieldRename: FieldRename.snake)
  const factory ArtistDetails({
    required String browseId,
    required String name,
    String? description,
    String? views,
    String? subscribers,
    String? thumbnailUrl,
    @Default([]) List<Track> topSongs,
    @Default([]) List<AlbumItem> albums,
    @Default([]) List<AlbumItem> singles,
    @Default([]) List<PlaylistItem> playlists,
  }) = _ArtistDetails;

  factory ArtistDetails.fromJson(Map<String, dynamic> json) => _$ArtistDetailsFromJson(json);
}

@freezed
class AlbumDetails with _$AlbumDetails {
  @JsonSerializable(fieldRename: FieldRename.snake)
  const factory AlbumDetails({
    required String browseId,
    required String title,
    String? artist,
    String? year,
    int? trackCount,
    String? duration,
    String? thumbnailUrl,
    @Default([]) List<Track> tracks,
  }) = _AlbumDetails;

  factory AlbumDetails.fromJson(Map<String, dynamic> json) => _$AlbumDetailsFromJson(json);
}

@freezed
class PlaylistItem with _$PlaylistItem {
  @JsonSerializable(fieldRename: FieldRename.snake)
  const factory PlaylistItem({
    required String browseId,
    required String title,
    String? author,
    String? itemCount,
    String? thumbnailUrl,
  }) = _PlaylistItem;

  factory PlaylistItem.fromJson(Map<String, dynamic> json) => _$PlaylistItemFromJson(json);
}

@freezed
class PlaylistDetails with _$PlaylistDetails {
  @JsonSerializable(fieldRename: FieldRename.snake)
  const factory PlaylistDetails({
    required String browseId,
    required String title,
    String? author,
    int? trackCount,
    String? thumbnailUrl,
    @Default([]) List<Track> tracks,
  }) = _PlaylistDetails;

  factory PlaylistDetails.fromJson(Map<String, dynamic> json) => _$PlaylistDetailsFromJson(json);
}
