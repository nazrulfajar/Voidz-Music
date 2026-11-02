import 'dart:async';
import 'dart:collection';
import 'dart:io';
import 'dart:math';
import 'package:dio/dio.dart';

class LocalProxyServer {
  static LocalProxyServer? _instance;
  HttpServer? _server;
  int _port = 8080;
  int get port => _port;

  // LRU map: keep insertion order, evict oldest not currently playing
  final LinkedHashMap<String, String> _urlMap = LinkedHashMap();
  String? _currentPlayingToken;

  // Singleton Dio for connection reuse
  final Dio _dio = Dio(BaseOptions(
    connectTimeout: const Duration(seconds: 15),
    receiveTimeout: const Duration(minutes: 5),
  ));

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
    print('LocalProxyServer started on port $_port');

    _server!.listen((HttpRequest request) async {
      try {
        final token = request.uri.queryParameters['token'];
        if (token == null || !_urlMap.containsKey(token)) {
          request.response.statusCode = HttpStatus.notFound;
          await request.response.close();
          return;
        }

        _currentPlayingToken = token;
        var targetUrl = _urlMap[token]!;
        final dio = _dio;

        final headers = <String, dynamic>{
          'User-Agent':
              'com.google.android.youtube/18.43.34 (Linux; U; Android 13; en_US; Pixel 7 Pro Build/TQ3A.230901.001)',
          'Accept-Encoding': 'identity',
          'Connection': 'keep-alive',
        };

        if (request.headers.value('range') != null) {
          headers['Range'] = request.headers.value('range');
        } else {
          headers['Range'] = 'bytes=0-';
        }

        print('LocalProxyServer fetching: $targetUrl');

        Response<ResponseBody> response = await dio.get<ResponseBody>(
          targetUrl,
          options: Options(
            headers: headers,
            responseType: ResponseType.stream,
            validateStatus: (status) => true,
          ),
        );

        // 403/410 -> try re-resolve once via callback
        if ((response.statusCode == 403 || response.statusCode == 410) &&
            onResolveExpired != null) {
          print('LocalProxyServer got ${response.statusCode}, trying re-resolve...');
          try {
            final freshUrl = await onResolveExpired!(targetUrl);
            if (freshUrl != null && freshUrl != targetUrl) {
              _urlMap[token] = freshUrl;
              targetUrl = freshUrl;
              response = await dio.get<ResponseBody>(
                targetUrl,
                options: Options(
                  headers: headers,
                  responseType: ResponseType.stream,
                  validateStatus: (status) => true,
                ),
              );
              print('LocalProxyServer retry status: ${response.statusCode}');
            }
          } catch (e) {
            print('LocalProxyServer re-resolve failed: $e');
          }
        }

        print('LocalProxyServer received status: ${response.statusCode}');

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
        print('LocalProxyServer finished streaming for $token');
      } catch (e) {
        print('LocalProxyServer error: $e');
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

  String addUrl(String url) {
    // Secure random token
    final rand = Random.secure();
    final token =
        '${DateTime.now().millisecondsSinceEpoch}_${rand.nextInt(1 << 32)}_${url.hashCode}';
    _urlMap[token] = url;

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
    if (_urlMap.containsKey(token)) {
      _urlMap[token] = newUrl;
    }
  }
}
