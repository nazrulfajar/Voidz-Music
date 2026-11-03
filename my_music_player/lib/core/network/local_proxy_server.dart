import 'dart:async';
import 'dart:collection';
import 'dart:io';
import 'dart:math';
import 'package:dio/dio.dart';
import 'package:logger/logger.dart';
import 'range_header.dart';

class _ProxyTarget {
  _ProxyTarget(this.url, this.headers);

  String url;
  final Map<String, String> headers;
}

class LocalProxyServer {
  static LocalProxyServer? _instance;
  HttpServer? _server;
  int _port = 8080;
  int get port => _port;

  // LRU map: keep insertion order, evict oldest not currently playing
  final LinkedHashMap<String, _ProxyTarget> _urlMap = LinkedHashMap();
  String? _currentPlayingToken;

  // Singleton Dio for connection reuse
  final Dio _dio = Dio(BaseOptions(
    connectTimeout: const Duration(seconds: 15),
    receiveTimeout: const Duration(minutes: 5),
  ));

  final Logger _log = Logger(printer: SimplePrinter(printTime: false));

  // Fallback for callers that do not pass resolver headers.
  static const _fallbackUserAgent =
      'com.google.android.youtube/20.10.38 (Linux; U; Android 11) gzip';

  // Callback to resolve fresh URL on 403/410
  Future<String?> Function(String expiredUrl)? onResolveExpired;

  static LocalProxyServer get instance {
    _instance ??= LocalProxyServer._();
    return _instance!;
  }

  LocalProxyServer._();

  Future<void> start() async {
    if (_server != null) return;

    try {
      _server = await HttpServer.bind(InternetAddress.loopbackIPv4, 8080);
      _port = _server!.port;
    } on SocketException {
      // Fallback to OS-assigned port if 8080 busy
      _server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
      _port = _server!.port;
    }
    _log.i('LocalProxyServer started on port $_port');

    _server!.listen((HttpRequest request) async {
      try {
        final token = request.uri.queryParameters['token'];
        final target = token == null ? null : _urlMap[token];
        if (token == null || target == null) {
          request.response.statusCode = HttpStatus.notFound;
          await request.response.close();
          return;
        }

        _currentPlayingToken = token;
        final dio = _dio;

        final headers = <String, dynamic>{
          ...target.headers,
          'Accept-Encoding': 'identity',
          'Connection': 'keep-alive',
        };
        if (!headers.keys.any((key) => key.toLowerCase() == 'user-agent')) {
          headers['User-Agent'] = _fallbackUserAgent;
        }

        // googlevideo returns 403 for open-ended or oversized ranges.
        // Always send a bounded range, even when ExoPlayer omits one.
        final range = buildBoundedRange(request.headers.value('range'));
        headers['Range'] = range;

        _log.i('LocalProxyServer fetching: ${target.url}');

        Response<ResponseBody> response = await dio.get<ResponseBody>(
          target.url,
          options: Options(
            headers: headers,
            responseType: ResponseType.stream,
            validateStatus: (status) => true,
          ),
        );

        // 403/410 can mean an expired URL, a stale IP-bound URL, or a
        // preview cap. Try one fresh URL at the same offset; if the cap is
        // the cause the retry will fail too and the player handles it.
        if ((response.statusCode == 403 || response.statusCode == 410) &&
            onResolveExpired != null) {
          _log.w(
              'LocalProxyServer got ${response.statusCode}, trying re-resolve...');
          try {
            // Drain the rejected body before reusing the connection.
            try {
              await response.data?.stream.drain<void>();
            } catch (_) {}
            final freshUrl = await onResolveExpired!(target.url);
            if (freshUrl != null && freshUrl != target.url) {
              target.url = freshUrl;
              response = await dio.get<ResponseBody>(
                target.url,
                options: Options(
                  headers: headers,
                  responseType: ResponseType.stream,
                  validateStatus: (status) => true,
                ),
              );
              _log.i('LocalProxyServer retry status: ${response.statusCode}');
            }
          } catch (e) {
            _log.e('LocalProxyServer re-resolve failed: $e');
          }
        }

        _log.i('LocalProxyServer received status: ${response.statusCode}');

        request.response.statusCode = response.statusCode ?? 200;

        response.headers.forEach((name, values) {
          final lower = name.toLowerCase();
          if (lower == 'content-type' ||
              lower == 'content-length' ||
              lower == 'content-range' ||
              lower == 'accept-ranges' ||
              lower == 'cache-control' ||
              lower == 'expires') {
            request.response.headers.set(name, values.first);
          }
        });

        if (response.data != null) {
          await response.data!.stream.cast<List<int>>().pipe(request.response);
        } else {
          await request.response.close();
        }
        _log.d('LocalProxyServer finished streaming for $token');
      } catch (e) {
        _log.e('LocalProxyServer error: $e');
        try {
          request.response.statusCode = HttpStatus.internalServerError;
          await request.response.close();
        } catch (_) {}
      }
    });
  }

  Future<void> stop() async {
    try {
      await _server?.close(force: true);
    } catch (_) {}
    _server = null;
  }

  void dispose() {
    try {
      _dio.close(force: true);
    } catch (_) {}
    _urlMap.clear();
    _server?.close(force: true);
    _server = null;
  }

  String addUrl(String url, {Map<String, String>? headers}) {
    // Secure random token
    final rand = Random.secure();
    final token =
        '${DateTime.now().millisecondsSinceEpoch}_${rand.nextInt(1 << 32)}_${url.hashCode}';
    _urlMap[token] = _ProxyTarget(
      url,
      headers == null ? const {} : Map<String, String>.from(headers),
    );

    // LRU eviction keep 20, never evict currently playing
    if (_urlMap.length > 20) {
      final keys = _urlMap.keys.toList();
      for (final k in keys) {
        if (_urlMap.length <= 20) break;
        if (k == _currentPlayingToken) continue;
        _urlMap.remove(k);
      }
      // If still over (all are current), remove oldest anyway
      while (_urlMap.length > 20) {
        _urlMap.remove(_urlMap.keys.first);
      }
    }

    return 'http://127.0.0.1:$_port/?token=$token';
  }

  /// Update URL for existing token (used after re-resolve)
  void updateUrl(String token, String newUrl) {
    final target = _urlMap[token];
    if (target != null) {
      target.url = newUrl;
    }
  }
}
