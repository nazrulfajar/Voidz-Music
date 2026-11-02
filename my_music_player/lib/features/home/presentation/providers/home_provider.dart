import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../features/player/domain/entities/track.dart';
import '../../../../features/player/data/repositories/track_repository_impl.dart';

final recentlyPlayedProvider = FutureProvider<List<Track>>((ref) async {
  final repo = ref.watch(trackRepositoryProvider);
  final result = await repo.getRecentlyPlayedTracks(limit: 10);
  return result.fold(
    (failure) => throw Exception(failure.message),
    (tracks) => tracks,
  );
});

final quickPicksProvider = FutureProvider<List<Track>>((ref) async {
  // Quick Picks only use local history/liked data; no mood parameter.
  final repo = ref.watch(trackRepositoryProvider);
  final result = await repo.getQuickPicksTracks(limit: 16);
  return result.fold(
    (failure) => throw Exception(failure.message),
    (tracks) => tracks.toList(),
  );
});
