import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/network/api_service.dart';
import '../../../player/data/repositories/track_repository_impl.dart';
import '../../domain/entities/daily_mix.dart';

const _mixLimit = 8;

/// Searches YouTube Music for a mood and falls back to local quick picks.
///
/// Search failures (offline, resolver error) and empty results never reach the
/// widget; the provider returns an empty [DailyMix] instead.
final moodMixProvider =
    FutureProvider.family<DailyMix, DailyMixMood>((ref, mood) async {
  final apiService = ref.read(apiServiceProvider);
  DailyMix? mix;
  try {
    final tracks = await apiService.search(mood.label, limit: _mixLimit);
    if (tracks.isNotEmpty) mix = DailyMix.fromTracks(mood, tracks);
  } catch (_) {
    // Fall through to the local fallback.
  }
  if (mix != null) return mix;

  final repository = ref.read(trackRepositoryProvider);
  try {
    final result = await repository.getQuickPicksTracks(limit: _mixLimit);
    mix = result.fold(
      (_) => DailyMix(mood: mood),
      (tracks) => DailyMix.fromTracks(mood, tracks),
    );
  } catch (_) {
    mix = DailyMix(mood: mood);
  }
  return mix ?? DailyMix(mood: mood);
});
