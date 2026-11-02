import 'package:flutter_test/flutter_test.dart';
import 'package:my_music_player/features/lyrics/utils/lrc_parser.dart';

void main() {
  group('LrcParser', () {
    test('parses timestamp and text', () {
      final parsed = LrcParser.parse('[00:01.50]Hello\n[00:03.00]World');

      expect(parsed.lines, hasLength(2));
      expect(
        parsed.lines.first.time,
        const Duration(seconds: 1, milliseconds: 500),
      );
      expect(parsed.lines.first.text, 'Hello');
      expect(parsed.lines.last.text, 'World');
    });

    test('sorts lines by time', () {
      final parsed = LrcParser.parse('[00:05.00]Later\n[00:01.00]Earlier');

      expect(parsed.lines.first.text, 'Earlier');
      expect(parsed.lines.last.text, 'Later');
    });

    test('returns the active line index', () {
      final parsed = LrcParser.parse('[00:01.00]One\n[00:05.00]Two');

      expect(parsed.getActiveLineIndex(Duration.zero), -1);
      expect(
        parsed.getActiveLineIndex(const Duration(seconds: 2)),
        0,
      );
      expect(
        parsed.getActiveLineIndex(const Duration(seconds: 6)),
        1,
      );
    });
  });
}
