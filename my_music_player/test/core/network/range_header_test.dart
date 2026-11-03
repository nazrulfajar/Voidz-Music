import 'package:flutter_test/flutter_test.dart';
import 'package:my_music_player/core/network/range_header.dart';

void main() {
  group('buildBoundedRange', () {
    test('defaults to the first bounded chunk', () {
      expect(buildBoundedRange(null), 'bytes=0-262143');
      expect(buildBoundedRange(''), 'bytes=0-262143');
    });

    test('bounds open-ended ranges', () {
      expect(buildBoundedRange('bytes=0-'), 'bytes=0-262143');
      expect(buildBoundedRange('bytes=1000-'), 'bytes=1000-263143');
    });

    test('keeps already-small ranges', () {
      expect(buildBoundedRange('bytes=0-1023'), 'bytes=0-1023');
      expect(buildBoundedRange('bytes=1000-2000'), 'bytes=1000-2000');
    });

    test('clamps oversized ranges', () {
      expect(buildBoundedRange('bytes=0-1048575'), 'bytes=0-262143');
      expect(buildBoundedRange('bytes=1000-999999'), 'bytes=1000-263143');
    });

    test('handles suffix ranges', () {
      expect(buildBoundedRange('bytes=-500'), 'bytes=0-499');
      expect(buildBoundedRange('bytes=-999999'), 'bytes=0-262143');
    });

    test('falls back for malformed headers', () {
      expect(buildBoundedRange('bytes=abc'), 'bytes=0-262143');
      expect(buildBoundedRange('items=0-1'), 'bytes=0-262143');
      expect(buildBoundedRange('bytes=10-5'), 'bytes=0-262143');
    });

    test('uses the first range when several are requested', () {
      expect(
        buildBoundedRange('bytes=0-1023,2000-3000'),
        'bytes=0-1023',
      );
    });

    test('honours a custom maximum', () {
      expect(buildBoundedRange('bytes=0-', maxBytes: 1024), 'bytes=0-1023');
    });
  });

  group('rangeStart', () {
    test('returns the first requested byte', () {
      expect(rangeStart('bytes=0-262143'), 0);
      expect(rangeStart('bytes=262144-524287'), 262144);
    });

    test('falls back to zero for malformed headers', () {
      expect(rangeStart('garbage'), 0);
    });
  });
}
