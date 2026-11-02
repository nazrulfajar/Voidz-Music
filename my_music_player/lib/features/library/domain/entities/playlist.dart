import '../../../player/domain/entities/track.dart';

class Playlist {
  final int? id;
  final String name;
  final String? description;
  final bool isSystem;
  final int trackCount;
  final List<String> thumbnailUrls;
  final DateTime createdAt;
  final DateTime updatedAt;
  final List<Track>? tracks;

  /// Sum of [Track.durationMs] for every track in the playlist.
  ///
  /// Computed by the repository on read; never persisted.
  final int totalDurationMs;

  Playlist({
    this.id,
    required this.name,
    this.description,
    this.isSystem = false,
    this.trackCount = 0,
    this.thumbnailUrls = const [],
    required this.createdAt,
    required this.updatedAt,
    this.tracks,
    this.totalDurationMs = 0,
  });

  Playlist copyWith({
    int? id,
    String? name,
    String? description,
    bool? isSystem,
    int? trackCount,
    List<String>? thumbnailUrls,
    DateTime? createdAt,
    DateTime? updatedAt,
    List<Track>? tracks,
    int? totalDurationMs,
  }) {
    return Playlist(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      isSystem: isSystem ?? this.isSystem,
      trackCount: trackCount ?? this.trackCount,
      thumbnailUrls: thumbnailUrls ?? this.thumbnailUrls,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      tracks: tracks ?? this.tracks,
      totalDurationMs: totalDurationMs ?? this.totalDurationMs,
    );
  }
}
