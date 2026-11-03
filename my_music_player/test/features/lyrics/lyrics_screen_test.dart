import 'dart:ui' show Tristate;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:my_music_player/core/constants/enums.dart' show TrackSource;
import 'package:my_music_player/core/theme/app_theme.dart';
import 'package:my_music_player/features/lyrics/domain/entities/lyrics.dart';
import 'package:my_music_player/features/lyrics/presentation/providers/lyrics_provider.dart';
import 'package:my_music_player/features/lyrics/presentation/screens/lyrics_screen.dart';
import 'package:my_music_player/features/lyrics/presentation/widgets/lyrics_view.dart';
import 'package:my_music_player/features/player/domain/entities/track.dart';
import 'package:my_music_player/features/player/presentation/providers/player_controller.dart';
import 'package:my_music_player/features/settings/data/models/app_settings_model.dart';
import 'package:my_music_player/features/settings/presentation/providers/settings_provider.dart';
import 'package:my_music_player/l10n/app_localizations.dart';
import 'package:my_music_player/shared/widgets/app_empty_state.dart';

import '../../helpers/pump_app.dart';
import '../player/presentation/providers/fakes.dart';

const _track = Track(
  sourceId: 'lyrics-track',
  title: 'Blinding Lights',
  artist: 'The Weeknd',
  durationMs: 200000,
  source: TrackSource.youtube,
);

const _otherTrack = Track(
  sourceId: 'other-track',
  title: 'Save Your Tears',
  artist: 'The Weeknd',
  durationMs: 220000,
  source: TrackSource.youtube,
);

String _longSynced() {
  final buffer = StringBuffer();
  for (var i = 0; i < 40; i++) {
    final minute = (i ~/ 12).toString().padLeft(2, '0');
    final second = ((i % 12) * 5).toString().padLeft(2, '0');
    buffer.writeln('[$minute:$second.00]Line $i');
  }
  return buffer.toString();
}

final _synced = Lyrics(
  sourceId: 'lyrics-track',
  type: LyricsType.synced,
  syncedLyrics: _longSynced(),
);

final _plain = Lyrics(
  sourceId: 'lyrics-track',
  type: LyricsType.plain,
  plainLyrics: 'Streetlights blur into the rain',
);

final _notFound = Lyrics(
  sourceId: 'lyrics-track',
  type: LyricsType.notFound,
);

class _TestPlayerController extends PlayerController {
  _TestPlayerController(Ref ref)
      : super(
          FakeAudioPlayerService(),
          FakeApiService(),
          FakeTrackRepository(),
          FakeCacheDownloadService(),
          ref,
        ) {
    state = PlayerState(
      currentTrack: _track,
      currentQueue: const [_track, _otherTrack],
      currentIndex: 0,
      duration: const Duration(seconds: 200),
    );
  }

  Duration? lastSeek;

  @override
  Future<void> seek(Duration position) async {
    lastSeek = position;
    state = state.copyWith(position: position);
  }

  void setTrack(Track track, {Duration position = Duration.zero}) {
    state = PlayerState(
      currentTrack: track,
      currentQueue: [track],
      currentIndex: 0,
      position: position,
      duration: const Duration(seconds: 200),
    );
  }

  void setPosition(Duration position) {
    state = state.copyWith(position: position);
  }
}

Future<({_TestPlayerController controller, GoRouter router})> _pumpLyrics(
  WidgetTester tester, {
  Lyrics? lyrics,
  Object? error,
  double textScale = 1.0,
  bool disableAnimations = false,
  Size surfaceSize = kTestSurfaceSize,
  bool pushFromPlayer = false,
}) async {
  late _TestPlayerController controller;
  final router = GoRouter(
    initialLocation: pushFromPlayer ? '/player' : '/lyrics',
    routes: [
      GoRoute(
        path: '/player',
        builder: (context, state) => const Scaffold(
          body: Center(child: Text('player-route')),
        ),
      ),
      GoRoute(
        path: '/lyrics',
        builder: (context, state) => const LyricsScreen(),
      ),
    ],
  );
  addTearDown(router.dispose);

  await pumpApp(
    tester,
    ProviderScope(
      overrides: [
        appSettingsProvider.overrideWith(
          (ref) => const Stream<AppSettingsModel>.empty(),
        ),
        playerControllerProvider.overrideWith((ref) {
          controller = _TestPlayerController(ref);
          return controller;
        }),
        currentLyricsProvider.overrideWith((ref) async {
          // Recompute when the track changes, like the real provider.
          ref.watch(playerControllerProvider.select((s) => s.currentTrack));
          if (error != null) throw error;
          return lyrics ?? _synced;
        }),
      ],
      child: MaterialApp.router(
        theme: AppTheme.darkTheme,
        locale: const Locale('en'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        routerConfig: router,
        builder: (context, child) {
          final media = MediaQuery.of(context);
          return MediaQuery(
            data: media.copyWith(disableAnimations: disableAnimations),
            child: child!,
          );
        },
      ),
    ),
    textScale: textScale,
    surfaceSize: surfaceSize,
  );
  await tester.pumpAndSettle();
  if (pushFromPlayer) {
    router.push('/lyrics');
    await tester.pumpAndSettle();
  }
  return (controller: controller, router: router);
}

void main() {
  testWidgets('full-screen lyrics shows back, header and source footer',
      (tester) async {
    await _pumpLyrics(tester);

    expect(find.byType(LyricsScreen), findsOneWidget);
    expect(find.byType(LyricsView), findsOneWidget);
    expect(find.byIcon(Icons.arrow_back_rounded), findsOneWidget);
    expect(find.text('LYRICS'), findsOneWidget);
    expect(find.text('Blinding Lights'), findsOneWidget);
    expect(find.text('The Weeknd'), findsOneWidget);
    expect(find.text('Synced'), findsOneWidget);
    expect(find.text('Synced lyrics · LRCLIB'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('back returns to the previous route', (tester) async {
    final shell = await _pumpLyrics(tester, pushFromPlayer: true);

    expect(find.text('LYRICS'), findsOneWidget);
    await tester.tap(find.byIcon(Icons.arrow_back_rounded));
    await tester.pumpAndSettle();

    expect(find.text('player-route'), findsOneWidget);
    expect(shell.router.canPop(), isFalse);
  });

  testWidgets('plain lyrics hide the synced badge', (tester) async {
    await _pumpLyrics(tester, lyrics: _plain);

    expect(find.text('Streetlights blur into the rain'), findsOneWidget);
    expect(find.text('Synced'), findsNothing);
    expect(find.text('Lyrics · LRCLIB'), findsOneWidget);
  });

  testWidgets('missing lyrics use the shared empty panel', (tester) async {
    await _pumpLyrics(tester, lyrics: _notFound);

    expect(find.byType(AppStatePanel), findsOneWidget);
    expect(find.text('No lyrics found'), findsOneWidget);
  });

  testWidgets('empty synced LRC is not shown as a synced list', (tester) async {
    await _pumpLyrics(
      tester,
      lyrics: Lyrics(
        sourceId: 'lyrics-track',
        type: LyricsType.synced,
        syncedLyrics: '',
      ),
    );

    expect(find.byType(AppStatePanel), findsOneWidget);
    expect(find.text('Lyrics are empty'), findsOneWidget);
    expect(find.text('Synced'), findsNothing);
  });

  testWidgets('network error uses the retry state', (tester) async {
    await _pumpLyrics(tester, error: Exception('offline'));

    expect(find.text('Lyrics are unavailable right now.'), findsOneWidget);
    expect(find.text('Retry'), findsOneWidget);
  });

  testWidgets('tapping a line seeks to that line', (tester) async {
    final shell = await _pumpLyrics(tester);
    shell.controller.setPosition(const Duration(seconds: 0));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Line 0'));
    await tester.pump();

    expect(shell.controller.lastSeek, Duration.zero);

    await tester.tap(find.text('Line 3'));
    await tester.pump();

    expect(shell.controller.lastSeek, const Duration(seconds: 15));
  });

  testWidgets('active line semantics expose time and selected state',
      (tester) async {
    final semantics = tester.ensureSemantics();
    try {
      final shell = await _pumpLyrics(tester);
      shell.controller.setPosition(const Duration(seconds: 3));
      await tester.pumpAndSettle();

      final first = find.bySemanticsLabel(RegExp('0:00 — Line 0'));
      final second = find.bySemanticsLabel(RegExp('0:05 — Line 1'));
      expect(first, findsOneWidget);
      expect(second, findsOneWidget);
      expect(
        tester.getSemantics(first).flagsCollection.isSelected,
        Tristate.isTrue,
      );
      expect(
        tester.getSemantics(second).flagsCollection.isSelected,
        Tristate.isFalse,
      );
    } finally {
      semantics.dispose();
    }
  });

  testWidgets('active line auto-scrolls to roughly 40% of the viewport',
      (tester) async {
    final shell = await _pumpLyrics(tester);

    shell.controller.setPosition(const Duration(seconds: 65));
    await tester.pumpAndSettle();

    final listRect = tester.getRect(find.byType(ListView));
    final lineRect = tester.getRect(find.text('Line 13'));
    final ratio = (lineRect.top - listRect.top) / listRect.height;

    expect(ratio, closeTo(0.4, 0.08));
  });

  testWidgets('track change updates the header and resets the scroll',
      (tester) async {
    final shell = await _pumpLyrics(tester);
    shell.controller.setPosition(const Duration(seconds: 150));
    await tester.pumpAndSettle();

    final scrollable = tester.state<ScrollableState>(
      find.byType(Scrollable).first,
    );
    scrollable.position.jumpTo(scrollable.position.maxScrollExtent);
    await tester.pump();

    shell.controller.setTrack(_otherTrack);
    await tester.pumpAndSettle();

    expect(find.text('Save Your Tears'), findsOneWidget);
    expect(find.text('Blinding Lights'), findsNothing);
    final resetScrollable = tester.state<ScrollableState>(
      find.byType(Scrollable).first,
    );
    expect(resetScrollable.position.pixels, lessThan(200));
  });

  testWidgets('manual scroll postpones auto-scroll', (tester) async {
    final shell = await _pumpLyrics(tester);

    await tester.drag(find.byType(ListView), const Offset(0, -400));
    await tester.pumpAndSettle();
    final afterDrag = shell.controller.state.position;
    expect(afterDrag, Duration.zero);

    shell.controller.setPosition(const Duration(seconds: 150));
    await tester.pumpAndSettle();

    final scrollable = tester.state<ScrollableState>(
      find.byType(Scrollable).first,
    );
    final pausedOffset = scrollable.position.pixels;
    expect(pausedOffset, greaterThan(0));

    await tester.pump(const Duration(seconds: 5));
    await tester.pumpAndSettle();

    expect(scrollable.position.pixels, greaterThan(pausedOffset));
  });

  testWidgets('reduced motion removes lyric line animation', (tester) async {
    await _pumpLyrics(tester, disableAnimations: true);

    final style = tester.widget<AnimatedDefaultTextStyle>(
      find
          .ancestor(
            of: find.text('Line 0'),
            matching: find.byType(AnimatedDefaultTextStyle),
          )
          .first,
    );
    expect(style.duration, Duration.zero);
    expect(tester.takeException(), isNull);
  });

  testWidgets('lyrics screen is overflow-free at 200% text scale',
      (tester) async {
    await _pumpLyrics(tester, textScale: 2.0);

    expect(tester.takeException(), isNull);
    expect(find.text('LYRICS'), findsOneWidget);
  });
}
