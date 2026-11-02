import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:youtube_explode_dart/youtube_explode_dart.dart';

final youtubeResolverServiceProvider = Provider<YoutubeResolverService>((ref) {
  return YoutubeResolverService();
});

class YoutubeResolverService {
  Future<Map<String, dynamic>> resolve(String sourceId, {String quality = 'medium'}) async {
    final yt = YoutubeExplode();
    try {
      final manifest = await yt.videos.streams.getManifest(
        sourceId,
        ytClients: [
          YoutubeApiClient.ios,
        ],
      );

      final audioStreams = manifest.audioOnly;
      if (audioStreams.isEmpty) {
        throw Exception('No audio streams found for video $sourceId');
      }

      AudioOnlyStreamInfo selectedStream;
      if (quality == 'high') {
        selectedStream = audioStreams.withHighestBitrate();
      } else if (quality == 'low') {
        selectedStream = audioStreams.reduce((a, b) => a.bitrate.kiloBitsPerSecond < b.bitrate.kiloBitsPerSecond ? a : b);
      } else {
        // Medium: Try to find something close to 128kbps, or just take the middle one
        selectedStream = audioStreams.reduce((a, b) {
          final aDiff = (a.bitrate.kiloBitsPerSecond - 128).abs();
          final bDiff = (b.bitrate.kiloBitsPerSecond - 128).abs();
          return aDiff < bDiff ? a : b;
        });
      }

      return {
        'source_id': sourceId,
        'stream_url': selectedStream.url.toString(),
        'expires_at': DateTime.now().add(const Duration(hours: 5, minutes: 30)).toIso8601String(),
        'format': selectedStream.container.name,
        'bitrate_kbps': selectedStream.bitrate.kiloBitsPerSecond.round(),
        'file_size_bytes': selectedStream.size.totalBytes,
        'headers': <String, String>{
          'User-Agent': 'com.google.android.youtube/18.43.34 (Linux; U; Android 13; en_US; Pixel 7 Pro Build/TQ3A.230901.001)',
        },
      };
    } finally {
      yt.close();
    }
  }
}
