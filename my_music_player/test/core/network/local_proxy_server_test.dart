import 'dart:async';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:my_music_player/core/network/local_proxy_server.dart';

void main() {
  late HttpServer upstream;

  setUp(() async {
    upstream = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
  });

  tearDown(() async {
    LocalProxyServer.instance.onResolveExpired = null;
    await upstream.close(force: true);
    await LocalProxyServer.instance.stop();
  });

  test('forwards resolver headers and the bounded range', () async {
    String? seenUserAgent;
    String? seenRange;
    final seen = Completer<void>();

    upstream.listen((request) async {
      seenUserAgent = request.headers.value('user-agent');
      seenRange = request.headers.value('range');
      request.response.statusCode = HttpStatus.partialContent;
      request.response.headers.set('content-range', 'bytes 0-1023/4096');
      request.response.headers.set('content-length', '1024');
      request.response.add(List<int>.filled(1024, 0));
      await request.response.close();
      if (!seen.isCompleted) seen.complete();
    });

    final proxy = LocalProxyServer.instance;
    await proxy.start();
    final proxyUrl = proxy.addUrl(
      'http://127.0.0.1:${upstream.port}/audio',
      headers: const {'User-Agent': 'vision-test-agent'},
    );

    final client = HttpClient();
    try {
      final request = await client.getUrl(Uri.parse(proxyUrl));
      request.headers.set('Range', 'bytes=0-1023');
      final response = await request.close();
      expect(response.statusCode, HttpStatus.partialContent);
      await response.drain<void>();
    } finally {
      client.close(force: true);
    }

    await seen.future;
    expect(seenUserAgent, 'vision-test-agent');
    expect(seenRange, 'bytes=0-1023');
  });

  test('re-resolves a 403 even when the requested offset is above 1 MiB',
      () async {
    var resolveCalls = 0;
    upstream.listen((request) async {
      final isRetry = request.uri.queryParameters['v'] == '2';
      if (isRetry) {
        request.response.statusCode = HttpStatus.partialContent;
        request.response.headers.set(
          'content-range',
          'bytes 1048576-1310719/2000000',
        );
        request.response.headers.set('content-length', '1024');
        request.response.add(List<int>.filled(1024, 0));
      } else {
        request.response.statusCode = HttpStatus.forbidden;
      }
      await request.response.close();
    });

    final proxy = LocalProxyServer.instance;
    await proxy.start();
    proxy.onResolveExpired = (expiredUrl) async {
      resolveCalls++;
      expect(expiredUrl, contains('/audio'));
      return 'http://127.0.0.1:${upstream.port}/audio?v=2';
    };

    final proxyUrl = proxy.addUrl(
      'http://127.0.0.1:${upstream.port}/audio',
    );

    final client = HttpClient();
    try {
      final request = await client.getUrl(Uri.parse(proxyUrl));
      request.headers.set('Range', 'bytes=1048576-1310719');
      final response = await request.close();
      expect(response.statusCode, HttpStatus.partialContent);
      await response.drain<void>();
    } finally {
      client.close(force: true);
    }

    expect(resolveCalls, 1);
  });
}
