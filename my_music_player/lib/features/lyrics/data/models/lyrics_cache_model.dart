import 'package:isar/isar.dart';

part 'lyrics_cache_model.g.dart';

enum LyricsType {
  synced,
  plain,
  notFound
}

@collection
class LyricsCacheModel {
  Id id = Isar.autoIncrement;

  @Index(unique: true, replace: true)
  late String sourceId; // The YouTube video ID

  String? syncedLyrics;
  String? plainLyrics;

  @enumerated
  late LyricsType lyricsType;

  late DateTime fetchedAt;
}
