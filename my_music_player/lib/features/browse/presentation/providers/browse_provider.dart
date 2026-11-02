import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/network/api_service.dart';
import '../../../player/data/repositories/track_repository_impl.dart';
import '../../../player/domain/entities/track.dart';
import '../../domain/entities/browse_models.dart';

/// Recent tracks for the browse hub. Uses the same local history as Home —
/// no mock data and no new endpoint.
final browseRecentlyPlayedProvider = FutureProvider<List<Track>>((ref) async {
  final repo = ref.watch(trackRepositoryProvider);
  final result = await repo.getRecentlyPlayedTracks(limit: 6);
  return result.fold(
    (failure) => throw Exception(failure.message),
    (tracks) => tracks,
  );
});

final artistDetailsProvider = FutureProvider.family<ArtistDetails, String>((ref, id) async {
  final apiService = ref.read(apiServiceProvider);
  final data = await apiService.getArtistDetails(id);
  return ArtistDetails.fromJson(data);
});

final albumDetailsProvider = FutureProvider.family<AlbumDetails, String>((ref, id) async {
  final apiService = ref.read(apiServiceProvider);
  final data = await apiService.getAlbumDetails(id);
  return AlbumDetails.fromJson(data);
});

final playlistDetailsProvider = FutureProvider.family<PlaylistDetails, String>((ref, id) async {
  final apiService = ref.read(apiServiceProvider);
  final data = await apiService.getPlaylistDetails(id);
  return PlaylistDetails.fromJson(data);
});
