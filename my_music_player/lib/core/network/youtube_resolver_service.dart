import 'dart:convert';
import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:youtube_explode_dart/youtube_explode_dart.dart';

final youtubeResolverServiceProvider = Provider<YoutubeResolverService>((ref) {
  final service = YoutubeResolverService();
  ref.onDispose(service.close);
  return service;
});

/// User agent for the VISIONOS InnerTube client.
///
/// The client is a first-class InnerTube client that still returns full-range
/// audio URLs without a PO token. The movie-style UA is part of the client
/// identity, so keep it in sync with [YoutubeResolverService.buildVisionOsClient].
const String visionOsUserAgent =
    'Mozilla/5.0 (Macintosh; Intel Mac OS X 15_7_3) AppleWebKit/605.1.15 '
    '(KHTML, like Gecko) Version/26.0 Safari/605.1.15';

/// Resolver stream YouTube murni Dart.
///
/// Memakai beberapa client InnerTube secara berurutan. Resolver berjalan
/// on-device dan bekerja di Android maupun iOS.
class YoutubeResolverService {
  YoutubeResolverService();

  static const _visionApiUrl =
      'https://www.youtube.com/youtubei/v1/player?prettyPrint=false';
  static const _visitorDataUrl = 'https://www.youtube.com/sw.js_data';
  static const _visitorDataTtl = Duration(hours: 1);

  /// Client fallback lama. Client `androidSdkless`/`ios` hanya dipakai jika
  /// VISIONOS gagal; URL dari client ini bisa dibatasi ~1 MiB oleh YouTube.
  static final _fallbackClients = <YoutubeApiClient>[
    YoutubeApiClient.androidSdkless,
    YoutubeApiClient.ios,
  ];

  final HttpClient _visitorClient = HttpClient();
  String? _visitorData;
  DateTime? _visitorDataAt;

  Future<Map<String, dynamic>> resolve(
    String sourceId, {
    String quality = 'medium',
  }) async {
    final videoId = _extractVideoId(sourceId);
    if (videoId.isEmpty) {
      throw Exception('Source ID YouTube tidak valid: $sourceId');
    }

    final errors = <String>[];
    final visitor = await _fetchVisitorData();
    if (visitor != null) {
      final result = await _tryResolve(
        videoId,
        buildVisionOsClient(visitor),
        quality,
        errors,
      );
      if (result != null) return result;

      // Visitor data can be stale after an app update or an IP change.
      final refreshed = await _fetchVisitorData(force: true);
      if (refreshed != null && refreshed != visitor) {
        final retry = await _tryResolve(
          videoId,
          buildVisionOsClient(refreshed),
          quality,
          errors,
        );
        if (retry != null) return retry;
      }
    }

    for (final client in _fallbackClients) {
      final result = await _tryResolve(videoId, client, quality, errors);
      if (result != null) return result;
    }

    final detail = errors.isEmpty ? 'unknown error' : errors.join(' | ');
    throw Exception('Gagal resolve stream YouTube: $detail');
  }

  Future<Map<String, dynamic>?> _tryResolve(
    String videoId,
    YoutubeApiClient client,
    String quality,
    List<String> errors,
  ) async {
    final yt = YoutubeExplode();
    try {
      final manifest = await yt.videos.streams.getManifest(
        videoId,
        ytClients: [client],
        requireWatchPage: false,
      );
      final audioStreams = manifest.audioOnly.toList();
      if (audioStreams.isEmpty) {
        errors.add('${_clientLabel(client)}: tidak ada audio stream');
        return null;
      }

      final selected = _selectStream(audioStreams, quality);
      final url = selected.url;
      return {
        'source_id': videoId,
        'stream_url': url.toString(),
        'expires_at': streamExpiry(url).toIso8601String(),
        'format': _formatLabel(selected),
        'bitrate_kbps': selected.bitrate.kiloBitsPerSecond.round(),
        'file_size_bytes': selected.size.totalBytes,
        'headers': <String, String>{
          'User-Agent': _userAgentFor(client),
          'Accept-Encoding': 'identity',
        },
      };
    } catch (error) {
      errors.add('${_clientLabel(client)}: $error');
      return null;
    } finally {
      yt.close();
    }
  }

  /// Builds the VISIONOS InnerTube client with [visitorData].
  ///
  /// Visible for tests. Mirrors the yt-dlp client definition.
  static YoutubeApiClient buildVisionOsClient(String visitorData) =>
      YoutubeApiClient({
        'context': {
          'client': {
            'clientName': 'VISIONOS',
            'clientVersion': '1.02',
            'deviceMake': 'Apple',
            'deviceModel': 'RealityDevice17,1',
            'osName': 'visionOS',
            'osVersion': '26.5.23O471',
            'userAgent': visionOsUserAgent,
            'hl': 'en',
            'gl': 'US',
            'utcOffsetMinutes': 0,
            'visitorData': visitorData,
          },
        },
        'contentCheckOk': true,
        'racyCheckOk': true,
      }, _visionApiUrl);

  /// Parses the visitor data returned by `https://www.youtube.com/sw.js_data`.
  ///
  /// Visible for tests. The response starts with the `)]}'` XSSI prefix.
  static String? parseVisitorData(String raw) {
    var text = raw;
    if (text.startsWith(")]}'")) text = text.substring(4);
    try {
      final data = jsonDecode(text) as List<dynamic>;
      final value = data[0][2][0][0][13];
      return value is String && value.isNotEmpty ? value : null;
    } catch (_) {
      return null;
    }
  }

  /// Returns the URL expiry from the `expire` query parameter.
  ///
  /// Falls back to the historical 5.5 hour TTL when the URL does not have one.
  static DateTime streamExpiry(Uri url, {DateTime? now}) {
    final expire = int.tryParse(url.queryParameters['expire'] ?? '');
    if (expire != null) {
      return DateTime.fromMillisecondsSinceEpoch(expire * 1000, isUtc: true);
    }
    return (now ?? DateTime.now()).add(const Duration(hours: 5, minutes: 30));
  }

  Future<String?> _fetchVisitorData({bool force = false}) async {
    final isFresh = _visitorDataAt != null &&
        DateTime.now().difference(_visitorDataAt!) < _visitorDataTtl;
    if (!force && _visitorData != null && isFresh) return _visitorData;

    try {
      final request = await _visitorClient
          .getUrl(Uri.parse(_visitorDataUrl))
          .timeout(const Duration(seconds: 10));
      request.headers
        ..set(HttpHeaders.userAgentHeader, visionOsUserAgent)
        ..set(HttpHeaders.contentTypeHeader, 'application/json');
      final response =
          await request.close().timeout(const Duration(seconds: 10));
      if (response.statusCode != HttpStatus.ok) return _visitorData;
      final text = await response.transform(utf8.decoder).join();
      final parsed = parseVisitorData(text);
      if (parsed != null) {
        _visitorData = parsed;
        _visitorDataAt = DateTime.now();
      }
    } catch (_) {}
    return _visitorData;
  }

  void close() {
    _visitorClient.close(force: true);
  }

  static String _clientLabel(YoutubeApiClient client) {
    final context = client.payload['context'];
    final config = context is Map ? context['client'] : null;
    final name = config is Map ? config['clientName'] : null;
    final version = config is Map ? config['clientVersion'] : null;
    return '$name/$version';
  }

  static String _userAgentFor(YoutubeApiClient client) {
    final context = client.payload['context'];
    final config = context is Map ? context['client'] : null;
    final userAgent = config is Map ? config['userAgent'] : null;
    return userAgent is String && userAgent.isNotEmpty
        ? userAgent
        : visionOsUserAgent;
  }

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
