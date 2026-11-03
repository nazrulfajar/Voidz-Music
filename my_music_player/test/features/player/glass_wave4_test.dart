import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:my_music_player/core/constants/enums.dart';
import 'package:my_music_player/core/theme/app_colors.dart';
import 'package:my_music_player/core/theme/app_glass.dart';
import 'package:my_music_player/features/player/data/datasources/audio_player_service.dart';
import 'package:my_music_player/features/player/domain/entities/track.dart';
import 'package:my_music_player/features/player/presentation/providers/player_controller.dart';
import 'package:my_music_player/features/player/presentation/screens/player_screen.dart';
import 'package:my_music_player/features/player/presentation/widgets/queue_view.dart';
import 'package:my_music_player/features/player/presentation/widgets/sleep_timer_sheet.dart';
import 'package:my_music_player/features/settings/data/models/app_settings_model.dart';
import 'package:my_music_player/features/settings/presentation/providers/settings_provider.dart';
import 'package:my_music_player/shared/widgets/glass_background.dart';
import 'package:my_music_player/shared/widgets/glass_surface.dart';

import '../../helpers/pump_app.dart';
import 'presentation/providers/fakes.dart';

Track _track(String id) {
  return Track(
    sourceId: id,
    title: 'Track $id',
    artist: 'Artist $id',
    album: 'Album',
    durationMs: 200000,
    source: TrackSource.youtube,
  );
}

PlayerState _playerState({
  int queueLength = 2,
  int currentIndex = 0,
}) {
  final queue = List<Track>.generate(queueLength, (index) => _track('v$index'));
  return PlayerState(
    currentTrack: queue[currentIndex],
    currentQueue: queue,
    currentIndex: currentIndex,
    isPlaying: false,
    position: const Duration(seconds: 10),
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

Future<void> _pumpPlayer(
  WidgetTester tester, {
  PlayerState? state,
  Size surfaceSize = kTestSurfaceSize,
  double textScale = 1.0,
  bool disableAnimations = false,
  GlassQuality glassQuality = GlassQuality.blurred,
}) async {
  final screen = PlayerScreen(glassQuality: glassQuality);
  final player = disableAnimations
      ? Builder(
          builder: (context) => MediaQuery(
            data: MediaQuery.of(context).copyWith(disableAnimations: true),
            child: screen,
          ),
        )
      : screen;

  await pumpApp(
    tester,
    player,
    overrides: [
      appSettingsProvider.overrideWith(
        (ref) => const Stream<AppSettingsModel>.empty(),
      ),
      playerControllerProvider.overrideWith(
        (ref) => _StubPlayerController(ref, state ?? _playerState()),
      ),
    ],
    surfaceSize: surfaceSize,
    textScale: textScale,
  );
  await tester.pumpAndSettle();
}

Future<void> _pumpQueue(
  WidgetTester tester, {
  int queueLength = 3,
  int currentIndex = 0,
  double textScale = 1.0,
}) async {
  await pumpApp(
    tester,
    const Scaffold(body: QueueView()),
    overrides: [
      appSettingsProvider.overrideWith(
        (ref) => const Stream<AppSettingsModel>.empty(),
      ),
      playerControllerProvider.overrideWith(
        (ref) => _StubPlayerController(
          ref,
          _playerState(
            queueLength: queueLength,
            currentIndex: currentIndex,
          ),
        ),
      ),
    ],
    textScale: textScale,
  );
  await tester.pumpAndSettle();
}

Future<void> _pumpSleepSheet(
  WidgetTester tester, {
  double textScale = 1.0,
}) async {
  final audio = FakeAudioPlayerService();
  addTearDown(audio.disposeFake);

  await pumpApp(
    tester,
    ProviderScope(
      overrides: [
        audioPlayerServiceProvider.overrideWithValue(audio),
      ],
      child: const Scaffold(body: SleepTimerSheet()),
    ),
    textScale: textScale,
  );
}

void main() {
  group('Player glass material', () {
    testWidgets('360x640 paints aurora plus two blurred layers',
        (tester) async {
      await _pumpPlayer(tester);

      expect(find.byType(GlassBackground), findsOneWidget);
      expect(find.byType(BackdropFilter), findsNWidgets(2));
      expect(find.byKey(const Key('player-play-halo')), findsOneWidget);
      expect(find.byKey(const Key('player-dock-glass')), findsOneWidget);

      for (final key in const [
        Key('player-back-glass'),
        Key('player-more-glass'),
        Key('player-like-glass'),
      ]) {
        final surface = tester.widget<GlassSurface>(
          find.descendant(
            of: find.byKey(key),
            matching: find.byType(GlassSurface),
          ),
        );
        expect(surface.quality, GlassQuality.frosted, reason: '$key');
      }

      final surfaces =
          tester.widgetList<GlassSurface>(find.byType(GlassSurface)).toList();
      expect(surfaces, hasLength(5));
      expect(
        surfaces.where((surface) => surface.quality == GlassQuality.blurred),
        hasLength(2),
      );
      expect(tester.takeException(), isNull);
    });

    testWidgets('keeps the white 76dp play button inside a glass halo',
        (tester) async {
      final semantics = tester.ensureSemantics();
      try {
        await _pumpPlayer(tester);

        final play = find.bySemanticsLabel('Play');
        expect(tester.getSize(play), const Size(76, 76));
        expect(
          tester.getSize(find.byKey(const Key('player-play-halo'))),
          const Size(84, 84),
        );

        final button = find.ancestor(
          of: find.byIcon(Icons.play_arrow_rounded),
          matching: find.byType(IconButton),
        );
        expect(tester.getSize(button), const Size(76, 76));
        expect(
          tester
              .widget<IconButton>(button)
              .style
              ?.backgroundColor
              ?.resolve(<WidgetState>{}),
          AppColors.dark.accent,
        );
      } finally {
        semantics.dispose();
      }
    });

    testWidgets('915x412 keeps the TASK-039 two-column layout', (tester) async {
      final semantics = tester.ensureSemantics();
      try {
        await _pumpPlayer(tester, surfaceSize: const Size(915, 412));

        final artwork = tester.getRect(find.byType(DoubleTapArtwork));
        final play = tester.getRect(find.bySemanticsLabel('Play'));

        expect(artwork.right, lessThan(play.left));
        expect(play.size, const Size(76, 76));
        for (final label in const ['Lyrics', 'Queue (2)', 'Timer']) {
          final dock = tester.getRect(find.bySemanticsLabel(label));
          expect(dock.bottom, lessThanOrEqualTo(412), reason: label);
          expect(dock.height, greaterThanOrEqualTo(48), reason: label);
        }
        expect(find.byType(BackdropFilter), findsNWidgets(2));
        expect(tester.takeException(), isNull);
      } finally {
        semantics.dispose();
      }
    });

    testWidgets('disableAnimations drops the halo and dock blur',
        (tester) async {
      await _pumpPlayer(tester, disableAnimations: true);

      expect(find.byType(BackdropFilter), findsNothing);
      expect(find.byKey(const Key('player-play-halo')), findsOneWidget);
      expect(find.byKey(const Key('player-dock-glass')), findsOneWidget);
      expect(find.byType(GlassBackground), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('opaque quality removes every backdrop filter', (tester) async {
      await _pumpPlayer(tester, glassQuality: GlassQuality.opaque);

      expect(find.byType(BackdropFilter), findsNothing);
      for (final surface in tester.widgetList<GlassSurface>(
        find.byType(GlassSurface),
      )) {
        expect(surface.quality, GlassQuality.opaque);
      }
      expect(tester.takeException(), isNull);
    });

    testWidgets('200% text scale stays overflow-free with reachable play',
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
        expect(find.byType(GlassBackground), findsOneWidget);
      } finally {
        semantics.dispose();
      }
    });
  });

  group('Queue glass material', () {
    testWidgets('now playing and up-next rows are frosted without blur',
        (tester) async {
      await _pumpQueue(tester, queueLength: 3, currentIndex: 0);

      final nowPlaying = tester.widget<GlassSurface>(
        find.byKey(const Key('queue-now-playing')),
      );
      expect(nowPlaying.quality, GlassQuality.frosted);

      for (final index in const [1, 2]) {
        final row = tester.widget<GlassSurface>(
          find.byKey(Key('queue-up-next-glass-$index')),
        );
        expect(row.quality, GlassQuality.frosted, reason: '$index');
      }

      expect(find.byType(BackdropFilter), findsNothing);
      expect(find.text('NOW PLAYING'), findsOneWidget);
      expect(find.text('UP NEXT'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('queue sheet is one frosted chrome panel', (tester) async {
      final semantics = tester.ensureSemantics();
      try {
        await _pumpPlayer(
          tester,
          state: _playerState(queueLength: 3),
        );
        await tester.tap(find.bySemanticsLabel('Queue (3)'));
        await tester.pumpAndSettle();

        final sheet = find.byKey(const Key('queue-sheet-glass'));
        expect(sheet, findsOneWidget);
        expect(
          tester.widget<GlassSurface>(sheet).quality,
          GlassQuality.frosted,
        );
        expect(
          find.descendant(
            of: sheet,
            matching: find.byType(BackdropFilter),
          ),
          findsNothing,
        );
        expect(find.text('Queue'), findsOneWidget);
        expect(find.text('NOW PLAYING'), findsOneWidget);
        expect(
          find.byKey(const Key('queue-up-next-glass-1')),
          findsOneWidget,
        );
        expect(tester.takeException(), isNull);
      } finally {
        semantics.dispose();
      }
    });

    testWidgets('queue glass stays overflow-free at 200% text scale',
        (tester) async {
      await _pumpQueue(tester, queueLength: 3, textScale: 2.0);

      expect(tester.takeException(), isNull);
      expect(find.byKey(const Key('queue-now-playing')), findsOneWidget);
      expect(find.byType(BackdropFilter), findsNothing);
    });
  });

  group('Sleep timer glass material', () {
    testWidgets('sheet is one frosted chrome panel without row blur',
        (tester) async {
      await _pumpSleepSheet(tester);

      final panel = find.byKey(const Key('sleep-timer-sheet-glass'));
      expect(panel, findsOneWidget);
      expect(
        tester.widget<GlassSurface>(panel).quality,
        GlassQuality.frosted,
      );
      expect(find.byType(GlassSurface), findsOneWidget);
      expect(find.byType(BackdropFilter), findsNothing);
      expect(find.text('5 minutes'), findsOneWidget);
      expect(find.text('End of track'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('option rows stay overflow-free at 200% text scale',
        (tester) async {
      await _pumpSleepSheet(tester, textScale: 2.0);

      expect(tester.takeException(), isNull);
      expect(find.text('Sleep timer'), findsOneWidget);
      expect(find.byType(GlassSurface), findsOneWidget);
    });
  });
}
