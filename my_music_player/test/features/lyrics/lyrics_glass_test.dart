import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:my_music_player/core/constants/enums.dart' show TrackSource;
import 'package:my_music_player/core/theme/app_theme.dart';
import 'package:my_music_player/features/lyrics/domain/entities/lyrics.dart';
import 'package:my_music_player/features/lyrics/presentation/providers/lyrics_provider.dart';
import 'package:my_music_player/features/lyrics/presentation/screens/lyrics_screen.dart';
import 'package:my_music_player/features/player/domain/entities/track.dart';
import 'package:my_music_player/features/player/presentation/providers/player_controller.dart';
import 'package:my_music_player/features/player/presentation/screens/player_screen.dart';
import 'package:my_music_player/features/settings/data/models/app_settings_model.dart';
import 'package:my_music_player/features/settings/presentation/providers/settings_provider.dart';
import 'package:my_music_player/l10n/app_localizations.dart';
import 'package:my_music_player/shared/widgets/glass_background.dart';

import '../../helpers/pump_app.dart';
import '../player/presentation/providers/fakes.dart';

const _track = Track(
  sourceId: 'lyrics-track',
  title: 'Blinding Lights',
  artist: 'The Weeknd',
  durationMs: 200000,
  source: TrackSource.youtube,
);

final _synced = Lyrics(
  sourceId: 'lyrics-track',
  type: LyricsType.synced,
  syncedLyrics: '[00:00.00]Streetlights blur into the rain\n'
      '[00:05.00]The night keeps calling me home',
);

class _StubPlayerController extends PlayerController {
  _StubPlayerController(Ref ref)
      : super(
          FakeAudioPlayerService(),
          FakeApiService(),
          FakeTrackRepository(),
          FakeCacheDownloadService(),
          ref,
        ) {
    state = PlayerState(
      currentTrack: _track,
      currentQueue: const [_track],
      currentIndex: 0,
      position: const Duration(seconds: 6),
      duration: const Duration(seconds: 200),
    );
  }
}

Future<void> _pumpPlayer(
  WidgetTester tester, {
  double textScale = 1.0,
  bool disableAnimations = false,
}) async {
  final router = GoRouter(
    initialLocation: '/player',
    routes: [
      GoRoute(
        path: '/player',
        builder: (context, state) => const PlayerScreen(),
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
        playerControllerProvider.overrideWith(
          (ref) => _StubPlayerController(ref),
        ),
        currentLyricsProvider.overrideWith((ref) async => _synced),
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
  );
  await tester.pumpAndSettle();
}

Future<void> _openLyrics(WidgetTester tester) async {
  final semantics = tester.ensureSemantics();
  try {
    await tester.tap(find.bySemanticsLabel('Lyrics'));
    await tester.pumpAndSettle();
  } finally {
    semantics.dispose();
  }
}

void main() {
  testWidgets('dock lyrics opens the full-screen lyrics route', (tester) async {
    await _pumpPlayer(tester);
    await _openLyrics(tester);

    expect(find.byType(LyricsScreen), findsOneWidget);
    expect(find.byType(BackdropFilter), findsNothing);
    expect(find.text('LYRICS'), findsOneWidget);
    expect(find.text('Blinding Lights'), findsOneWidget);
    expect(find.text('The Weeknd'), findsOneWidget);
    expect(find.text('Synced lyrics · LRCLIB'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('lyrics screen is a full-height glass surface', (tester) async {
    await _pumpPlayer(tester);
    await _openLyrics(tester);

    expect(find.byType(GlassBackground), findsOneWidget);
    expect(find.byType(BackdropFilter), findsNothing);
    expect(tester.getSize(find.byType(LyricsScreen)).height, 640);
    expect(tester.takeException(), isNull);
  });

  testWidgets('disableAnimations keeps the lyrics screen readable',
      (tester) async {
    await _pumpPlayer(tester, disableAnimations: true);
    await _openLyrics(tester);

    expect(find.byType(BackdropFilter), findsNothing);
    expect(find.byType(LyricsScreen), findsOneWidget);
    expect(find.text('LYRICS'), findsOneWidget);
    expect(find.text('Synced lyrics · LRCLIB'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('lyrics screen survives 200% text scale', (tester) async {
    await _pumpPlayer(tester, textScale: 2.0);
    await _openLyrics(tester);

    expect(tester.takeException(), isNull);
    expect(find.byType(LyricsScreen), findsOneWidget);
    expect(find.text('LYRICS'), findsOneWidget);
  });
}
