import 'package:dio/dio.dart';
import 'package:isar/isar.dart';
import '../../domain/repositories/lyrics_repository.dart';
import '../../domain/entities/lyrics.dart' as entity;
import '../models/lyrics_cache_model.dart';

class LyricsRepositoryImpl implements LyricsRepository {
  final Isar isar;
  final Dio dio;

  LyricsRepositoryImpl({required this.isar, required this.dio});

  @override
  Future<entity.Lyrics> getLyrics(
      String sourceId, String title, String artist) async {
    // 1. Check local Isar cache
    final cached = await isar.lyricsCacheModels
        .where()
        .sourceIdEqualTo(sourceId)
        .findFirst();
    if (cached != null && cached.lyricsType != LyricsType.notFound) {
      return entity.Lyrics(
        sourceId: cached.sourceId,
        syncedLyrics: cached.syncedLyrics,
        plainLyrics: cached.plainLyrics,
        type: _mapTypeToEntity(cached.lyricsType),
      );
    }

    // 2. Fetch from backend
    try {
      print('Fetching lyrics for: $title by $artist');
      final response = await dio.get(
        '/api/lyrics',
        queryParameters: {
          'track_name': title,
          'artist_name': artist,
        },
      );

      print('Lyrics response status: ${response.statusCode}');

      final data = response.data;
      final isFound = data['status'] == 'found';

      final lyricsType = !isFound
          ? LyricsType.notFound
          : (data['syncedLyrics'] != null
              ? LyricsType.synced
              : LyricsType.plain);

      final newCache = LyricsCacheModel()
        ..sourceId = sourceId
        ..syncedLyrics = data['syncedLyrics']
        ..plainLyrics = data['plainLyrics']
        ..lyricsType = lyricsType
        ..fetchedAt = DateTime.now();

      // 3. Save to Isar
      await isar.writeTxn(() async {
        await isar.lyricsCacheModels.put(newCache);
      });

      return entity.Lyrics(
        sourceId: sourceId,
        syncedLyrics: newCache.syncedLyrics,
        plainLyrics: newCache.plainLyrics,
        type: _mapTypeToEntity(newCache.lyricsType),
      );
    } catch (e) {
      print('Failed to fetch lyrics: \$e');
      return entity.Lyrics(
        sourceId: sourceId,
        type: entity.LyricsType.notFound,
      );
    }
  }

  entity.LyricsType _mapTypeToEntity(LyricsType type) {
    switch (type) {
      case LyricsType.synced:
        return entity.LyricsType.synced;
      case LyricsType.plain:
        return entity.LyricsType.plain;
      case LyricsType.notFound:
        return entity.LyricsType.notFound;
    }
  }
}
