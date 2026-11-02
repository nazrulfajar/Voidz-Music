import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../player/domain/entities/track.dart';
import '../../../player/data/repositories/track_repository_impl.dart';

final downloadedTracksProvider = FutureProvider<List<Track>>((ref) async {
  final repo = ref.read(trackRepositoryProvider);
  final result = await repo.getAllCachedTracks();

  return result.fold(
    (failure) => throw Exception(failure.message),
    (tracks) {
      // Sort by recently cached descending
      tracks.sort((a, b) {
        final aTime = a.cachedAt ?? DateTime.fromMillisecondsSinceEpoch(0);
        final bTime = b.cachedAt ?? DateTime.fromMillisecondsSinceEpoch(0);
        return bTime.compareTo(aTime);
      });
      return tracks;
    },
  );
});
