enum LyricsType { synced, plain, notFound }

class Lyrics {
  final String sourceId;
  final String? syncedLyrics;
  final String? plainLyrics;
  final LyricsType type;

  Lyrics({
    required this.sourceId,
    this.syncedLyrics,
    this.plainLyrics,
    required this.type,
  });
}
