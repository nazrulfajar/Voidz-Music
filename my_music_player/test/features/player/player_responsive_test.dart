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
  PlayerState? state,
}) async {
  await pumpApp(
    tester,
    _playerApp(state ?? _playerState()),
    surfaceSize: surfaceSize,
    textScale: textScale,
  );
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('quality badge hugs its content with 16dp side padding',
      (tester) async {
    await _pumpPlayer(tester);

    final label = find.textContaining('kbps');
    final badge =
        find.ancestor(of: label, matching: find.byType(Container)).first;
    final badgeRect = tester.getRect(badge);
    final labelRect = tester.getRect(label);
    expect(labelRect.left - badgeRect.left, 17);
    expect(badgeRect.right - labelRect.right, 17);
    expect(find.text('320 kbps · AAC'), findsOneWidget);

    await tester.pumpWidget(const SizedBox.shrink());
    final state = _playerState();
    await _pumpPlayer(
      tester,
      state: state.copyWith(
        currentTrack: state.currentTrack!.copyWith(bitrateKbps: null),
      ),
    );
    final shortBadge = find
        .ancestor(
          of: find.text('AAC'),
          matching: find.byType(Container),
        )
        .first;
    expect(tester.getSize(shortBadge).width, lessThan(badgeRect.width));
    expect(tester.takeException(), isNull);
  });

  testWidgets('long title and artist each stay on one line without album',
      (tester) async {
    final state = _playerState();
    final track = state.currentTrack!.copyWith(
      title: 'A very long song title that cannot fit on a small phone screen',
      artist: 'The Weeknd featuring Daft Punk and a very long artist name',
    );
    await _pumpPlayer(
      tester,
      state: state.copyWith(currentTrack: track),
      textScale: 2,
    );

    for (final value in [track.title, track.artist]) {
      final text = tester.widget<Text>(find.text(value));
      expect(text.maxLines, 1, reason: value);
      expect(text.overflow, TextOverflow.ellipsis, reason: value);
    }
    expect(find.text(track.album!), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('missing quality does not render an empty badge', (tester) async {
    final state = _playerState();
    await _pumpPlayer(
      tester,
      state: state.copyWith(
        currentTrack: state.currentTrack!.copyWith(
          audioFormat: ' ',
          bitrateKbps: 0,
        ),
      ),
    );

    expect(find.textContaining('kbps'), findsNothing);
    expect(find.text(''), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('long quality stays bounded at 200% text scale', (tester) async {
    final state = _playerState();
    await _pumpPlayer(
      tester,
      state: state.copyWith(
        currentTrack: state.currentTrack!.copyWith(
          audioFormat: 'An unusually long audio format description',
        ),
      ),
      textScale: 2,
    );

    final label = find.textContaining('kbps');
    expect(tester.widget<Text>(label).maxLines, 1);
    final badge =
        find.ancestor(of: label, matching: find.byType(Container)).first;
    expect(tester.getSize(badge).width, lessThanOrEqualTo(360 - 48));
    expect(tester.takeException(), isNull);
  });

  testWidgets('412x915 follows reference insets and artwork spacing',
      (tester) async {
    tester.view.padding = const FakeViewPadding(top: 44, bottom: 34);
    addTearDown(tester.view.resetPadding);
    await _pumpPlayer(tester, surfaceSize: const Size(412, 915));

    final artwork = tester.getRect(find.byType(DoubleTapArtwork));
    final header = tester.getRect(find.byKey(const Key('player-back-glass')));
    final badge = tester.getRect(
      find
          .ancestor(
            of: find.textContaining('kbps'),
            matching: find.byType(Container),
          )
          .first,
    );
    expect(artwork.width, 312);
    expect(artwork.center.dx, 206);
    expect(artwork.top - header.bottom, greaterThanOrEqualTo(40));
    expect(badge.top - artwork.bottom, 40);
    expect(tester.getTopLeft(find.text('Track v0')).dx, 24);
    expect(tester.getTopLeft(find.text('The Weeknd')).dx, 24);
    expect(tester.getTopLeft(find.text('1:42')).dx, 24);

    final dockIcon = tester.getRect(find.byIcon(Icons.lyrics_outlined));
    final dockLabel = tester.getRect(find.text('Lyrics'));
    expect(dockIcon.right, lessThan(dockLabel.left));
    expect(dockIcon.center.dy, closeTo(dockLabel.center.dy, 1));
    expect(tester.takeException(), isNull);
  });

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
      expect(
          tester.getSize(find.byType(Slider)).height, greaterThanOrEqualTo(48));
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

  testWidgets('320x900 keeps narrow portrait artwork square', (tester) async {
    await _pumpPlayer(tester, surfaceSize: const Size(320, 900));

    final artwork = tester.getSize(find.byType(DoubleTapArtwork));
    expect(artwork.width, 272);
    expect(artwork.height, artwork.width);
    expect(tester.takeException(), isNull);
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

      final viewport = tester.getRect(find.byType(SingleChildScrollView));
      final seek = tester.getRect(find.byType(Slider));
      expect(seek.left - viewport.left, greaterThanOrEqualTo(8));
      expect(viewport.right - seek.right, greaterThanOrEqualTo(8));

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
