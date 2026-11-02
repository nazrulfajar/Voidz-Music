import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../player/domain/entities/track.dart';
import '../../data/repositories/playlist_repository_impl.dart';

const recentlyPlayedWindowDays = 30;
const recentlyPlayedLimit = 100;

class RecentlyPlayedData {
  const RecentlyPlayedData({
    required this.tracks,
    required this.uniqueTrackCount,
  });

  final List<Track> tracks;
  final int uniqueTrackCount;

  bool get isEmpty => tracks.isEmpty;
}

/// Single clock for the screen and its queries.
///
/// Tests override this to pin the 30-day cutoff.
final recentlyPlayedNowProvider = Provider<DateTime>((ref) {
  return DateTime.now();
});

final recentlyPlayedProvider =
    FutureProvider.autoDispose<RecentlyPlayedData>((ref) async {
  final repository = ref.watch(playlistRepositoryProvider);
  final now = ref.watch(recentlyPlayedNowProvider);

  final tracks = await repository.getRecentlyPlayedTracks(
    days: recentlyPlayedWindowDays,
    limit: recentlyPlayedLimit,
    now: now,
  );
  final uniqueTrackCount = await repository.getRecentlyPlayedCount(
    days: recentlyPlayedWindowDays,
    now: now,
  );

  return RecentlyPlayedData(
    tracks: tracks,
    uniqueTrackCount: uniqueTrackCount,
  );
});
