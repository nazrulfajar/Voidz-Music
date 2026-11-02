import '../../../player/domain/entities/track.dart';

/// The five product moods for Daily Mix (`docs/PRD.md` F1.5).
enum DailyMixMood {
  energize('Energize'),
  workout('Workout'),
  relax('Relax'),
  commute('Commute'),
  focus('Focus');

  const DailyMixMood(this.label);

  /// Search query and display label for the mood.
  final String label;

  /// Resolves a route slug, defaulting to [energize] for unknown values.
  static DailyMixMood fromSlug(String slug) {
    for (final mood in values) {
      if (mood.name == slug) return mood;
    }
    return energize;
  }
}

/// A mood mix with its tracks and up to four mosaic artwork URLs.
class DailyMix {
  const DailyMix({
    required this.mood,
    this.tracks = const [],
    this.artworkUrls = const [],
  });

  factory DailyMix.fromTracks(DailyMixMood mood, List<Track> tracks) {
    final artworkUrls = <String>[];
    for (final track in tracks) {
      final url = track.thumbnailUrl;
      if (url == null || url.isEmpty || artworkUrls.contains(url)) continue;
      artworkUrls.add(url);
      if (artworkUrls.length == 4) break;
    }
    return DailyMix(
      mood: mood,
      tracks: List<Track>.unmodifiable(tracks.take(8)),
      artworkUrls: List<String>.unmodifiable(artworkUrls),
    );
  }

  final DailyMixMood mood;
  final List<Track> tracks;
  final List<String> artworkUrls;

  bool get isEmpty => tracks.isEmpty;
}
