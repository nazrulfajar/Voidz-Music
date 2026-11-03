import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:my_music_player/core/constants/enums.dart' show TrackSource;
import 'package:my_music_player/core/router/app_router.dart';
import 'package:my_music_player/core/theme/app_theme.dart';
import 'package:my_music_player/features/lyrics/domain/entities/lyrics.dart';
import 'package:my_music_player/features/lyrics/presentation/providers/lyrics_provider.dart';
import 'package:my_music_player/features/lyrics/presentation/screens/lyrics_screen.dart';
import 'package:my_music_player/features/player/domain/entities/track.dart';
import 'package:my_music_player/features/player/presentation/providers/player_controller.dart';
import 'package:my_music_player/features/player/presentation/screens/player_screen.dart';
import 'package:my_music_player/features/player/presentation/widgets/mini_player.dart';
import 'package:my_music_player/l10n/app_localizations.dart';
import 'package:my_music_player/shared/widgets/app_bottom_nav.dart';
import 'package:my_music_player/shared/widgets/app_chrome.dart';

import '../../features/player/presentation/providers/fakes.dart';

class _StubPlayerController extends PlayerController {
  _StubPlayerController(Ref ref)
      : super(
          FakeAudioPlayerService(),
          FakeApiService(),
          FakeTrackRepository(),
          FakeCacheDownloadService(),
          ref,
        ) {
    const track = Track(
      sourceId: 'router-track',
      title: 'Blinding Lights',
      artist: 'The Weeknd',
      durationMs: 200000,
      source: TrackSource.youtube,
    );
    state = PlayerState(
      currentTrack: track,
      currentQueue: const [track],
      currentIndex: 0,
      duration: const Duration(seconds: 200),
    );
  }
}

void main() {
  testWidgets('the real router applies immersive chrome to /player',
      (tester) async {
    tester.view.devicePixelRatio = 1.0;
    tester.view.physicalSize = const Size(360, 640);
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final container = ProviderContainer(
      overrides: [
        playerControllerProvider.overrideWith(
          (ref) => _StubPlayerController(ref),
        ),
      ],
    );
    addTearDown(container.dispose);
    final router = container.read(appRouterProvider);
    addTearDown(router.dispose);
    router.go('/player');

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp.router(
          theme: AppTheme.darkTheme,
          routerConfig: router,
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          builder: (context, child) => AppChrome(
            router: router,
            miniPlayer: const MiniPlayer(),
            child: child ?? const SizedBox.shrink(),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byType(PlayerScreen), findsOneWidget);
    expect(find.byType(MiniPlayer), findsNothing);
    expect(find.byType(AppBottomNav), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('the real router applies immersive chrome to /lyrics',
      (tester) async {
    tester.view.devicePixelRatio = 1.0;
    tester.view.physicalSize = const Size(360, 640);
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final container = ProviderContainer(
      overrides: [
        playerControllerProvider.overrideWith(
          (ref) => _StubPlayerController(ref),
        ),
        currentLyricsProvider.overrideWith(
          (ref) async => Lyrics(
            sourceId: 'router-track',
            type: LyricsType.synced,
            syncedLyrics: '[00:00.00]Streetlights blur into the rain',
          ),
        ),
      ],
    );
    addTearDown(container.dispose);
    final router = container.read(appRouterProvider);
    addTearDown(router.dispose);
    router.go('/lyrics');

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp.router(
          theme: AppTheme.darkTheme,
          routerConfig: router,
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          builder: (context, child) => AppChrome(
            router: router,
            miniPlayer: const MiniPlayer(),
            child: child ?? const SizedBox.shrink(),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byType(LyricsScreen), findsOneWidget);
    expect(find.byType(MiniPlayer), findsNothing);
    expect(find.byType(AppBottomNav), findsNothing);
    expect(find.text('LYRICS'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
