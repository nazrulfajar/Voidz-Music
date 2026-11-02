import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../player/domain/entities/track.dart';
import '../../domain/entities/playlist.dart';
import '../../data/repositories/playlist_repository_impl.dart';
import '../../../../core/providers/isar_provider.dart';
import '../../../player/data/models/track_model.dart';
import 'package:isar/isar.dart';

final playlistTracksProvider = FutureProvider.family<List<Track>, Playlist>((ref, playlist) async {
  final repo = ref.watch(playlistRepositoryProvider);
  final isar = ref.watch(isarProvider);
  
  if (playlist.isSystem) {
    if (playlist.name == 'Liked Songs') {
      final models = await isar.trackModels.filter().isLikedEqualTo(true).findAll();
      return models.map((m) => Track.fromModel(m)).toList();
    } else if (playlist.name == 'Recently Played') {
      final repoImpl = repo as PlaylistRepositoryImpl;
      return await repoImpl.getPlayHistory();
    } else if (playlist.name == 'Downloaded') {
      final models = await isar.trackModels.filter().isCachedEqualTo(true).findAll();
      return models.map((m) => Track.fromModel(m)).toList();
    }
    return [];
  }
  
  return repo.getPlaylistTracks(playlist.id!);
});

