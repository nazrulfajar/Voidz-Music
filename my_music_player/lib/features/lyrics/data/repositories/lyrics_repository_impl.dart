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
    // 1. Cek cache lokal.
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

    // 2. Ambil langsung dari LRCLIB (tanpa proxy backend).
    try {
      final response = await dio.get(
        '/api/get',
        queryParameters: {
          'track_name': title,
          'artist_name': artist,
        },
      );

      final data = response.data;
      if (data is! Map) {
        return entity.Lyrics(
          sourceId: sourceId,
          type: entity.LyricsType.notFound,
        );
      }

      final synced = data['syncedLyrics'] as String?;
      final plain = data['plainLyrics'] as String?;
      final instrumental = data['instrumental'] == true;

      final lyricsType = instrumental || (synced == null && plain == null)
          ? LyricsType.notFound
          : (synced != null ? LyricsType.synced : LyricsType.plain);

      if (lyricsType == LyricsType.notFound) {
        return entity.Lyrics(
          sourceId: sourceId,
          type: entity.LyricsType.notFound,
        );
      }

      final newCache = LyricsCacheModel()
        ..sourceId = sourceId
        ..syncedLyrics = synced
        ..plainLyrics = plain
        ..lyricsType = lyricsType
        ..fetchedAt = DateTime.now();

      await isar.writeTxn(() async {
        await isar.lyricsCacheModels.put(newCache);
      });

      return entity.Lyrics(
        sourceId: sourceId,
        syncedLyrics: synced,
        plainLyrics: plain,
        type: _mapTypeToEntity(lyricsType),
      );
    } on DioException catch (error) {
      // 404 = lagu tidak ada di LRCLIB; bukan error fatal.
      if (error.response?.statusCode == 404) {
        return entity.Lyrics(
          sourceId: sourceId,
          type: entity.LyricsType.notFound,
        );
      }
      return entity.Lyrics(
        sourceId: sourceId,
        type: entity.LyricsType.notFound,
      );
    } catch (_) {
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
