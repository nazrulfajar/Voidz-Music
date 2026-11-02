import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:youtube_explode_dart/youtube_explode_dart.dart';

final youtubeResolverServiceProvider = Provider<YoutubeResolverService>((ref) {
  final service = YoutubeResolverService();
  ref.onDispose(service.close);
  return service;
});

/// Resolver stream YouTube murni Dart.
///
/// Memakai beberapa client InnerTube secara berurutan. Resolver berjalan
/// on-device dan bekerja di Android maupun iOS.
class YoutubeResolverService {
  YoutubeResolverService();

  static const _userAgent =
      'com.google.android.youtube/20.10.38 (Linux; U; Android 11) gzip';

  /// Client yang saat ini menghasilkan audio-only stream tanpa PO token.
  /// Urutan: paling stabil dulu, lalu fallback.
  static final _clients = <YoutubeApiClient>[
    YoutubeApiClient.androidSdkless,
    YoutubeApiClient.androidVr,
    YoutubeApiClient.ios,
  ];

  Future<Map<String, dynamic>> resolve(
    String sourceId, {
    String quality = 'medium',
  }) async {
    final videoId = _extractVideoId(sourceId);
    if (videoId.isEmpty) {
      throw Exception('Source ID YouTube tidak valid: $sourceId');
    }

    final errors = <String>[];
    for (final client in _clients) {
      final yt = YoutubeExplode();
      try {
        final manifest = await yt.videos.streams.getManifest(
          videoId,
          ytClients: [client],
        );
        final audioStreams = manifest.audioOnly.toList();
        if (audioStreams.isEmpty) {
          errors.add('${client.apiUrl}: tidak ada audio stream');
          continue;
        }

        final selected = _selectStream(audioStreams, quality);
        final url = selected.url.toString();
        if (url.isEmpty) {
          errors.add('stream URL kosong');
          continue;
        }

        return {
          'source_id': videoId,
          'stream_url': url,
          'expires_at': DateTime.now()
              .add(const Duration(hours: 5, minutes: 30))
              .toIso8601String(),
          'format': _formatLabel(selected),
          'bitrate_kbps': selected.bitrate.kiloBitsPerSecond.round(),
          'file_size_bytes': selected.size.totalBytes,
          'headers': <String, String>{
            'User-Agent': _userAgent,
            'Accept-Encoding': 'identity',
          },
        };
      } catch (error) {
        errors.add(error.toString());
      } finally {
        yt.close();
      }
    }

    final detail = errors.isEmpty ? 'unknown error' : errors.join(' | ');
    throw Exception('Gagal resolve stream YouTube: $detail');
  }

  void close() {}

  static AudioOnlyStreamInfo _selectStream(
    List<AudioOnlyStreamInfo> streams,
    String quality,
  ) {
    switch (quality) {
      case 'high':
        return streams.withHighestBitrate();
      case 'low':
        return streams.reduce(
          (a, b) =>
              a.bitrate.kiloBitsPerSecond < b.bitrate.kiloBitsPerSecond ? a : b,
        );
      default:
        return streams.reduce((a, b) {
          final aDiff = (a.bitrate.kiloBitsPerSecond - 128).abs();
          final bDiff = (b.bitrate.kiloBitsPerSecond - 128).abs();
          return aDiff < bDiff ? a : b;
        });
    }
  }

  static String _formatLabel(AudioOnlyStreamInfo stream) {
    final container = stream.container.name.toLowerCase();
    if (container.contains('webm')) return 'Opus';
    if (container.contains('mp4') || container.contains('m4a')) return 'AAC';
    if (container.contains('mp3')) return 'MP3';
    return container.toUpperCase();
  }

  static String _extractVideoId(String input) {
    final trimmed = input.trim();
    if (!trimmed.contains('://') && !trimmed.contains('/')) return trimmed;
    final uri = Uri.tryParse(trimmed);
    if (uri == null) return trimmed;
    if (uri.host.contains('youtu.be')) {
      return uri.pathSegments.isEmpty ? '' : uri.pathSegments.first;
    }
    final v = uri.queryParameters['v'];
    if (v != null && v.isNotEmpty) return v;
    return uri.pathSegments.isEmpty ? '' : uri.pathSegments.last;
  }
}
