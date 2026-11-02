import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/network/api_service.dart';
import '../../domain/entities/browse_models.dart';

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
