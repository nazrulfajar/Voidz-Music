import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:my_music_player/core/constants/enums.dart';
import 'package:my_music_player/features/player/domain/entities/track.dart';
import 'package:my_music_player/features/player/presentation/providers/player_controller.dart';
import 'package:my_music_player/features/player/presentation/screens/player_screen.dart';
import 'package:my_music_player/features/settings/data/models/app_settings_model.dart';
import 'package:my_music_player/features/settings/presentation/providers/settings_provider.dart';

import '../../helpers/pump_app.dart';
import 'presentation/providers/fakes.dart';

const _transportLabels = <String>[
  'Shuffle',
  'Previous',
  'Play',
  'Next',
  'Repeat',
];

Track _track(String id) {
  return Track(
    sourceId: id,
    title: 'Track $id',
    artist: 'The Weeknd',
    album: 'Starboy',
    durationMs: 230000,
    source: TrackSource.youtube,
    audioFormat: 'AAC',
    bitrateKbps: 320,
  );
}

PlayerState _playerState() {
  final queue = List<Track>.generate(2, (index) => _track('v$index'));
  return PlayerState(
    currentTrack: queue.first,
    currentQueue: queue,
    currentIndex: 0,
    isPlaying: false,
    position: const Duration(seconds: 102),
    duration: const Duration(seconds: 230),
  );
}

class _StubPlayerController extends PlayerController {
  _StubPlayerController(Ref ref, PlayerState initial)
      : super(
          FakeAudioPlayerService(),
          FakeApiService(),
          FakeTrackRepository(),
          FakeCacheDownloadService(),
          ref,
        ) {
    state = initial;
  }
}

Widget _playerApp(PlayerState state) {
  return ProviderScope(
    overrides: [
      appSettingsProvider.overrideWith(
        (ref) => const Stream<AppSettingsModel>.empty(),
      ),
      playerControllerProvider.overrideWith(
        (ref) => _StubPlayerController(ref, state),
      ),
    ],
    child: const PlayerScreen(),
  );
}

Future<void> _pumpPlayer(
  WidgetTester tester, {
  Size surfaceSize = kTestSurfaceSize,
  double textScale = 1.0,
}) async {
  await pumpApp(
    tester,
    _playerApp(_playerState()),
    surfaceSize: surfaceSize,
    textScale: textScale,
  );
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('360x640 keeps the transport row above the fold', (tester) async {
    final semantics = tester.ensureSemantics();
    try {
      await _pumpPlayer(tester);

      for (final label in _transportLabels) {
        final rect = tester.getRect(find.bySemanticsLabel(label));
        expect(rect.top, greaterThanOrEqualTo(0), reason: label);
        expect(
          rect.bottom,
          lessThanOrEqualTo(kTestSurfaceSize.height),
          reason: '$label must stay inside the initial viewport',
        );
      }

      final playRect = tester.getRect(find.bySemanticsLabel('Play'));
      expect(playRect.width, 76);
      expect(playRect.height, 76);
    } finally {
      semantics.dispose();
    }
  });

  testWidgets('360x640 artwork is height-aware and at most 190dp',
      (tester) async {
    await _pumpPlayer(tester);

    final artwork = tester.getSize(find.byType(DoubleTapArtwork));
    expect(artwork.width, lessThanOrEqualTo(190));
    expect(artwork.height, lessThanOrEqualTo(190));
    expect(artwork.width, greaterThanOrEqualTo(160));
  });

  testWidgets('915x412 uses two columns and never scrolls horizontally',
      (tester) async {
    final semantics = tester.ensureSemantics();
    try {
      await _pumpPlayer(tester, surfaceSize: const Size(915, 412));

      expect(tester.takeException(), isNull);

      final artwork = tester.getRect(find.byType(DoubleTapArtwork));
      final play = tester.getRect(find.bySemanticsLabel('Play'));

      expect(
        artwork.right,
        lessThan(play.left),
        reason: 'artwork sits in the left column',
      );
      expect(play.height, 76);

      for (final label in const ['Lyrics', 'Queue (2)', 'Timer']) {
        final dock = tester.getRect(find.bySemanticsLabel(label));
        expect(
          dock.bottom,
          lessThanOrEqualTo(412),
          reason: '$label must sit above the bottom edge',
        );
        expect(dock.height, greaterThanOrEqualTo(48), reason: label);
      }

      for (final scrollable in tester.widgetList<Scrollable>(
        find.byType(Scrollable),
      )) {
        expect(
          scrollable.axisDirection,
          anyOf(AxisDirection.up, AxisDirection.down),
          reason: 'the player must not scroll horizontally',
        );
      }
    } finally {
      semantics.dispose();
    }
  });

  testWidgets('915x412 landscape dock respects the bottom safe area',
      (tester) async {
    tester.view.padding = const FakeViewPadding(bottom: 24);
    addTearDown(tester.view.resetPadding);
    final semantics = tester.ensureSemantics();
    try {
      await _pumpPlayer(tester, surfaceSize: const Size(915, 412));

      for (final label in const ['Lyrics', 'Queue (2)', 'Timer']) {
        final dock = tester.getRect(find.bySemanticsLabel(label));
        expect(
          dock.bottom,
          lessThanOrEqualTo(412 - 24),
          reason: '$label must clear the gesture bar',
        );
        expect(dock.height, greaterThanOrEqualTo(48), reason: label);
      }
    } finally {
      semantics.dispose();
    }
  });

  testWidgets('360x640 at textScale 2.0 has no overflow and reachable play',
      (tester) async {
    final semantics = tester.ensureSemantics();
    try {
      await _pumpPlayer(tester, textScale: 2.0);

      expect(tester.takeException(), isNull);

      final play = find.bySemanticsLabel('Play');
      await tester.ensureVisible(play);
      await tester.pumpAndSettle();

      final rect = tester.getRect(play);
      expect(rect.height, greaterThanOrEqualTo(48));
      expect(rect.bottom, lessThanOrEqualTo(kTestSurfaceSize.height));
    } finally {
      semantics.dispose();
    }
  });

  testWidgets('915x412 at textScale 2.0 has no overflow', (tester) async {
    await _pumpPlayer(
      tester,
      surfaceSize: const Size(915, 412),
      textScale: 2.0,
    );

    expect(tester.takeException(), isNull);
    expect(
      tester.getSize(find.byType(DoubleTapArtwork)).width,
      greaterThanOrEqualTo(160),
    );
  });

  testWidgets('600x360 landscape keeps two columns without overflow',
      (tester) async {
    final semantics = tester.ensureSemantics();
    try {
      await _pumpPlayer(tester, surfaceSize: const Size(600, 360));

      expect(tester.takeException(), isNull);

      final artwork = tester.getRect(find.byType(DoubleTapArtwork));
      final play = tester.getRect(find.bySemanticsLabel('Play'));

      expect(artwork.right, lessThan(play.left));
      expect(play.height, 76);

      for (final label in const ['Lyrics', 'Queue (2)', 'Timer']) {
        final dock = tester.getRect(find.bySemanticsLabel(label));
        expect(
          dock.bottom,
          lessThanOrEqualTo(360),
          reason: '$label must sit above the bottom edge',
        );
        expect(dock.height, greaterThanOrEqualTo(48), reason: label);
      }
    } finally {
      semantics.dispose();
    }
  });

  testWidgets('412x915 portrait keeps a single column', (tester) async {
    final semantics = tester.ensureSemantics();
    try {
      await _pumpPlayer(tester, surfaceSize: const Size(412, 915));

      final artwork = tester.getRect(find.byType(DoubleTapArtwork));
      final play = tester.getRect(find.bySemanticsLabel('Play'));

      expect(
        play.top,
        greaterThan(artwork.bottom),
        reason: 'portrait stacks the controls below the artwork',
      );
      expect(tester.takeException(), isNull);
    } finally {
      semantics.dispose();
    }
  });
}
