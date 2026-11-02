import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/entities/lyrics.dart';
import '../../domain/repositories/lyrics_repository.dart';
import '../../../player/presentation/providers/player_controller.dart';
import '../../utils/lrc_parser.dart';

final currentLyricsProvider = FutureProvider<Lyrics?>((ref) async {
  final track = ref.watch(playerControllerProvider.select((state) => state.currentTrack));
  
  if (track == null) return null;
  
  final repo = ref.watch(lyricsRepositoryProvider);
  return await repo.getLyrics(track.sourceId, track.title, track.artist);
});

final parsedLyricsProvider = Provider<ParsedLyrics?>((ref) {
  final lyrics = ref.watch(currentLyricsProvider).valueOrNull;
  if (lyrics == null || lyrics.type != LyricsType.synced || lyrics.syncedLyrics == null) {
    return null;
  }
  return LrcParser.parse(lyrics.syncedLyrics!);
});
