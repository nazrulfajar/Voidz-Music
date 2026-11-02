import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../entities/lyrics.dart';

import '../../../../core/providers/isar_provider.dart';
import '../../../../core/network/dio_client.dart';
import '../../data/repositories/lyrics_repository_impl.dart';

final lyricsRepositoryProvider = Provider<LyricsRepository>((ref) {
  return LyricsRepositoryImpl(
    isar: ref.watch(isarProvider), 
    dio: ref.watch(dioProvider)
  );
});

abstract class LyricsRepository {
  Future<Lyrics> getLyrics(String sourceId, String title, String artist);
}
