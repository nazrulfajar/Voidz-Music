import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:my_music_player/core/network/youtube_resolver_service.dart';

void main() {
  group('parseVisitorData', () {
    test('parses the XSSI-prefixed sw.js_data payload', () {
      final visitorList = <dynamic>[
        for (var i = 0; i < 13; i++) null,
        'VISITOR_DATA',
      ];
      final raw = ")]}'\n${jsonEncode([
            [
              null,
              null,
              [
                [visitorList],
              ],
            ],
          ])}";

      expect(
        YoutubeResolverService.parseVisitorData(raw),
        'VISITOR_DATA',
      );
    });

    test('returns null for malformed or empty payloads', () {
      expect(YoutubeResolverService.parseVisitorData('not-json'), isNull);
      expect(
        YoutubeResolverService.parseVisitorData(
          ")]}'\n${jsonEncode([
                [
                  null,
                  null,
                  [
                    [
                      [for (var i = 0; i < 14; i++) null],
                    ],
                  ],
                ],
              ])}",
        ),
        isNull,
      );
    });
  });

  group('buildVisionOsClient', () {
    test('uses the VISIONOS identity and visitor data', () {
      final client = YoutubeResolverService.buildVisionOsClient('visitor-1');
      final context = client.payload['context'] as Map<String, dynamic>;
      final config = context['client'] as Map<String, dynamic>;

      expect(config['clientName'], 'VISIONOS');
      expect(config['clientVersion'], '1.02');
      expect(config['visitorData'], 'visitor-1');
      expect(config['userAgent'], visionOsUserAgent);
      expect(client.payload['contentCheckOk'], isTrue);
      expect(client.payload['racyCheckOk'], isTrue);
      expect(client.apiUrl, contains('/youtubei/v1/player'));
    });
  });

  group('streamExpiry', () {
    test('reads the expire query parameter', () {
      final url = Uri.parse(
        'https://rr1---sn.example.googlevideo.com/videoplayback'
        '?expire=1700000000&itag=140',
      );

      expect(
        YoutubeResolverService.streamExpiry(url).toUtc(),
        DateTime.fromMillisecondsSinceEpoch(1700000000 * 1000, isUtc: true),
      );
    });

    test('falls back to the historical ttl', () {
      final now = DateTime.utc(2026, 1, 1);

      expect(
        YoutubeResolverService.streamExpiry(
          Uri.parse('https://example.test/videoplayback'),
          now: now,
        ),
        now.add(const Duration(hours: 5, minutes: 30)),
      );
    });
  });
}
