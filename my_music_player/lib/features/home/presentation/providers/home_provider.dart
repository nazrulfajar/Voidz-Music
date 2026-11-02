import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../features/player/domain/entities/track.dart';
import '../../../../features/player/data/repositories/track_repository_impl.dart';
import '../../../../core/network/api_service.dart';

final homeMoodProvider = StateProvider<String>((ref) => 'All');

final recentlyPlayedProvider = FutureProvider<List<Track>>((ref) async {
  final repo = ref.watch(trackRepositoryProvider);
  final result = await repo.getRecentlyPlayedTracks(limit: 10);
  return result.fold(
    (failure) => throw Exception(failure.message),
    (tracks) => tracks,
  );
});

final quickPicksProvider = FutureProvider<List<Track>>((ref) async {
  final selectedMood = ref.watch(homeMoodProvider);
  
  if (selectedMood != 'All') {
    // If a mood is selected, search the API for that mood
    final apiService = ref.watch(apiServiceProvider);
    try {
      final searchResults = await apiService.search(selectedMood);
      final tracks = List<Track>.from(searchResults);
      return tracks.take(16).toList(); // Up to 16 tracks for 4 columns of 4
    } catch (e) {
      throw Exception('Failed to load mood tracks: $e');
    }
  }

  // Default Quick Picks from local history
  final repo = ref.watch(trackRepositoryProvider);
  final result = await repo.getQuickPicksTracks(limit: 16);
  return result.fold(
    (failure) => throw Exception(failure.message),
    (tracks) => tracks.toList(),
  );
});
