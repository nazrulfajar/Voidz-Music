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

Future<GoRouter> _pumpPlayer(WidgetTester tester) async {
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
      ),
    ),
  );
  await tester.pumpAndSettle();
  return router;
}

void main() {
  testWidgets('horizontal swipe on Player opens full-screen lyrics',
      (tester) async {
    final router = await _pumpPlayer(tester);

    expect(find.byType(PlayerScreen), findsOneWidget);
    await tester.fling(
      find.byType(PlayerScreen),
      const Offset(320, 0),
      1200,
    );
    await tester.pumpAndSettle();

    expect(find.byType(LyricsScreen), findsOneWidget);
    expect(find.text('LYRICS'), findsOneWidget);
    expect(router.routerDelegate.currentConfiguration.last.matchedLocation,
        '/lyrics');
    expect(tester.takeException(), isNull);
  });

  testWidgets('horizontal swipe on Lyrics returns to Player', (tester) async {
    await _pumpPlayer(tester);
    await tester.fling(
      find.byType(PlayerScreen),
      const Offset(320, 0),
      1200,
    );
    await tester.pumpAndSettle();
    expect(find.byType(LyricsScreen), findsOneWidget);

    await tester.fling(
      find.byType(LyricsScreen),
      const Offset(-320, 0),
      1200,
    );
    await tester.pumpAndSettle();

    expect(find.byType(PlayerScreen), findsOneWidget);
    expect(find.byType(LyricsScreen), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('a small horizontal drag does not change route', (tester) async {
    await _pumpPlayer(tester);

    await tester.drag(find.byType(PlayerScreen), const Offset(40, 0));
    await tester.pumpAndSettle();

    expect(find.byType(PlayerScreen), findsOneWidget);
    expect(find.byType(LyricsScreen), findsNothing);
  });
}
