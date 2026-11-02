import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'youtube_music_service.dart';
import 'youtube_resolver_service.dart';
import '../../features/player/domain/entities/track.dart';

final apiServiceProvider = Provider<ApiService>((ref) {
  final music = YoutubeMusicService();
  final resolver = ref.read(youtubeResolverServiceProvider);
  ref.onDispose(music.close);
  return ApiService(music, resolver);
});

/// Facade lokal untuk semua kebutuhan konten.
///
/// Tidak ada HTTP ke backend FastAPI. Metadata diambil dari YouTube Music
/// InnerTube, stream di-resolve langsung di perangkat.
class ApiService {
  ApiService(this._music, this._resolver);

  final YoutubeMusicService _music;
  final YoutubeResolverService _resolver;

  Future<List<Track>> search(
    String query, {
    String source = 'youtube',
    int limit = 20,
  }) async {
    try {
      final results = await _music.search(
        query,
        filter: 'songs',
        limit: limit,
      );
      return results.map(Track.fromJson).toList();
    } catch (error) {
      throw Exception('Gagal mencari lagu: $error');
    }
  }

  Future<List<dynamic>> searchArtistsOrAlbums(
    String query,
    String filter, {
    String source = 'youtube',
    int limit = 20,
  }) async {
    try {
      return await _music.search(query, filter: filter, limit: limit);
    } catch (error) {
      throw Exception('Gagal mencari $filter: $error');
    }
  }

  Future<Map<String, dynamic>> getArtistDetails(String artistId) async {
    try {
      return await _music.getArtist(artistId);
    } catch (error) {
      throw Exception('Gagal memuat artis: $error');
    }
  }

  Future<Map<String, dynamic>> getAlbumDetails(String albumId) async {
    try {
      return await _music.getAlbum(albumId);
    } catch (error) {
      throw Exception('Gagal memuat album: $error');
    }
  }

  Future<Map<String, dynamic>> getPlaylistDetails(String playlistId) async {
    try {
      return await _music.getPlaylist(playlistId);
    } catch (error) {
      throw Exception('Gagal memuat playlist: $error');
    }
  }

  Future<List<dynamic>> getUpNext(String videoId) async {
    try {
      return await _music.getUpNext(videoId);
    } catch (error) {
      throw Exception('Gagal memuat rekomendasi: $error');
    }
  }

  Future<Map<String, dynamic>> resolve(
    String sourceId, {
    String source = 'youtube',
    String quality = 'medium',
  }) async {
    if (source != 'youtube' && source != 'ytmusic') {
      throw UnimplementedError('Resolve belum tersedia untuk $source');
    }
    try {
      final data = await _resolver.resolve(sourceId, quality: quality);
      final streamUrl = data['stream_url'];
      if (streamUrl is! String || streamUrl.isEmpty) {
        throw Exception('stream_url kosong');
      }
      return data;
    } catch (error) {
      throw Exception('Gagal resolve stream YouTube: $error');
    }
  }
}
