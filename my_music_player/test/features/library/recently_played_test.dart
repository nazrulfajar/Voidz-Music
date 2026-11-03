import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:my_music_player/core/constants/enums.dart';
import 'package:my_music_player/core/network/api_service.dart';
import 'package:my_music_player/core/router/app_router.dart';
import 'package:my_music_player/core/theme/app_theme.dart';
import 'package:my_music_player/features/cache/data/datasources/cache_download_service.dart';
import 'package:my_music_player/features/library/data/repositories/playlist_repository_impl.dart';
import 'package:my_music_player/features/library/domain/entities/playlist.dart';
import 'package:my_music_player/features/library/presentation/providers/playlist_provider.dart';
import 'package:my_music_player/features/library/presentation/providers/recently_played_provider.dart';
import 'package:my_music_player/features/library/presentation/screens/library_screen.dart';
import 'package:my_music_player/features/library/presentation/screens/recently_played_screen.dart';
import 'package:my_music_player/features/player/data/datasources/audio_player_service.dart';
import 'package:my_music_player/features/player/data/repositories/queue_repository.dart';
import 'package:my_music_player/features/player/data/repositories/track_repository_impl.dart';
import 'package:my_music_player/features/player/domain/entities/track.dart';
import 'package:my_music_player/features/player/presentation/providers/device_songs_provider.dart';
import 'package:my_music_player/features/player/presentation/providers/player_controller.dart';
import 'package:my_music_player/features/settings/data/models/app_settings_model.dart';
import 'package:my_music_player/features/settings/presentation/providers/settings_provider.dart';
import 'package:my_music_player/l10n/app_localizations.dart';

import '../player/presentation/providers/fakes.dart';

Track _track(
  String id, {
  int durationMs = 200000,
  String? artist,
}) {
  return Track(
    sourceId: id,
    title: 'Track $id',
    artist: artist ?? 'Artist $id',
    durationMs: durationMs,
    source: TrackSource.local,
    localAudioPath: 'C:/music/$id.mp3',
    isCached: true,
  );
}

Playlist _recentVirtual() {
  return Playlist(
    id: -1,
    name: 'Recently Played',
    isSystem: true,
    trackCount: 1,
    createdAt: DateTime(2026, 11, 2),
    updatedAt: DateTime(2026, 11, 2),
  );
}

void main() {
  late FakePlaylistRepository repo;
  late FakeAudioPlayerService audio;
  late FakeTrackRepository tracks;
  late ProviderContainer container;

  ProviderContainer makeContainer({List<Override> extra = const []}) {
    return ProviderContainer(
      overrides: [
        audioPlayerServiceProvider.overrideWithValue(audio),
        apiServiceProvider.overrideWithValue(FakeApiService()),
        trackRepositoryProvider.overrideWithValue(tracks),
        cacheDownloadServiceProvider.overrideWithValue(
          FakeCacheDownloadService(),
        ),
        queueRepositoryProvider.overrideWithValue(FakeQueueRepository()),
        playlistRepositoryProvider.overrideWithValue(repo),
        appSettingsProvider.overrideWith(
          (ref) => const Stream<AppSettingsModel>.empty(),
        ),
        recentlyPlayedNowProvider.overrideWithValue(DateTime(2026, 11, 2, 12)),
        ...extra,
      ],
    );
  }

  setUp(() {
    repo = FakePlaylistRepository();
    audio = FakeAudioPlayerService();
    tracks = FakeTrackRepository();
    container = makeContainer();
  });

  tearDown(() async {
    container.dispose();
    await audio.disposeFake();
  });

  Future<void> pumpScreen(
    WidgetTester tester, {
    GoRouter? router,
  }) async {
    tester.view.devicePixelRatio = 1.0;
    tester.view.physicalSize = const Size(360, 640);
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final screenRouter = router ??
        GoRouter(
          initialLocation: '/',
          routes: [
            GoRoute(
              path: '/',
              builder: (context, state) => const RecentlyPlayedScreen(),
            ),
          ],
        );
    addTearDown(screenRouter.dispose);

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp.router(
          debugShowCheckedModeBanner: false,
          theme: AppTheme.darkTheme,
          darkTheme: AppTheme.darkTheme,
          themeMode: ThemeMode.dark,
          routerConfig: screenRouter,
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  List<String> queueIds() {
    return container
        .read(playerControllerProvider)
        .currentQueue
        .map((track) => track.sourceId)
        .toList();
  }

  Future<void> settlePlayback(WidgetTester tester) async {
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 50)),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 600));
  }

  testWidgets('library row opens the recently played route', (tester) async {
    repo
      ..recentTracks = [_track('a')]
      ..recentCount = 1;

    final routeContainer = makeContainer(
      extra: [
        allPlaylistsProvider.overrideWith(
          (ref) async => [_recentVirtual()],
        ),
        deviceSongsProvider.overrideWith((ref) async => const []),
      ],
    );
    addTearDown(routeContainer.dispose);
    final router = routeContainer.read(appRouterProvider);
    addTearDown(router.dispose);

    tester.view.devicePixelRatio = 1.0;
    tester.view.physicalSize = const Size(360, 640);
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    router.go('/library');
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: routeContainer,
        child: MaterialApp.router(
          debugShowCheckedModeBanner: false,
          theme: AppTheme.darkTheme,
          darkTheme: AppTheme.darkTheme,
          themeMode: ThemeMode.dark,
          routerConfig: router,
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byType(LibraryScreen), findsOneWidget);
    await tester.tap(find.text('Recently played'));
    await tester.pumpAndSettle();

    expect(find.byType(RecentlyPlayedScreen), findsOneWidget);
    expect(find.text('LISTENING HISTORY'), findsOneWidget);
    expect(find.byIcon(Icons.more_horiz_rounded), findsOneWidget);

    await tester.tap(find.byIcon(Icons.arrow_back_ios_new_rounded));
    await tester.pumpAndSettle();
    expect(find.byType(LibraryScreen), findsOneWidget);
  });

  testWidgets('summary shows the 30-day distinct count and track metadata',
      (tester) async {
    repo
      ..recentTracks = [
        _track('a', durationMs: 200000, artist: 'Artist A'),
        _track('b', durationMs: 61000, artist: 'Artist B'),
      ]
      ..recentCount = 2;

    await pumpScreen(tester);

    expect(find.text('LISTENING HISTORY'), findsOneWidget);
    expect(find.text('2 unique tracks'), findsOneWidget);
    expect(find.text('Last 30 days'), findsOneWidget);
    expect(find.text('2 unique tracks · last 30 days'), findsOneWidget);
    expect(find.text('Track a'), findsOneWidget);
    expect(find.text('Artist A'), findsOneWidget);
    expect(find.text('3:20'), findsOneWidget);
    expect(find.text('Track b'), findsOneWidget);
    expect(find.text('1:01'), findsOneWidget);
    expect(
      tester.getTopLeft(find.text('Track a')).dy,
      lessThan(tester.getTopLeft(find.text('Track b')).dy),
    );
    expect(
        repo.lastRecentNowSource, DateTime(2026, 11, 2, 12).toIso8601String());
  });

  testWidgets('tapping a track starts it with the recent list as queue',
      (tester) async {
    repo
      ..recentTracks = [_track('a'), _track('b')]
      ..recentCount = 2;

    await pumpScreen(tester);
    await tester.tap(find.text('Track b'));
    await settlePlayback(tester);

    expect(queueIds(), ['a', 'b']);
    expect(
      container.read(playerControllerProvider).currentTrack?.sourceId,
      'b',
    );
  });

  testWidgets('play recent starts the first track with the whole queue',
      (tester) async {
    repo
      ..recentTracks = [_track('a'), _track('b')]
      ..recentCount = 2;

    await pumpScreen(tester);
    await tester.tap(find.text('Play recent'));
    await settlePlayback(tester);

    expect(queueIds(), ['a', 'b']);
    expect(
      container.read(playerControllerProvider).currentTrack?.sourceId,
      'a',
    );
  });

  testWidgets('clear history confirms, clears the repo, and shows empty state',
      (tester) async {
    repo
      ..recentTracks = [_track('a')]
      ..recentCount = 1;

    await pumpScreen(tester);
    await tester.tap(find.byIcon(Icons.more_horiz_rounded));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Clear history'));
    await tester.pumpAndSettle();

    expect(find.text('Clear listening history?'), findsOneWidget);
    expect(find.textContaining('play counts'), findsOneWidget);

    await tester.tap(find.widgetWithText(FilledButton, 'Clear history'));
    await tester.pumpAndSettle();

    expect(repo.clearPlayHistoryCalls, 1);
    expect(find.text('No listening history'), findsOneWidget);
    expect(find.text('LISTENING HISTORY'), findsNothing);
    expect(find.text('Play recent'), findsNothing);
  });

  testWidgets('empty state offers search and skips the summary',
      (tester) async {
    final router = GoRouter(
      initialLocation: '/',
      routes: [
        GoRoute(
          path: '/',
          builder: (context, state) => const RecentlyPlayedScreen(),
        ),
        GoRoute(
          path: '/search',
          builder: (context, state) => const Scaffold(
            body: Text('Search destination'),
          ),
        ),
      ],
    );

    await pumpScreen(tester, router: router);

    expect(find.text('No listening history'), findsOneWidget);
    expect(find.text('LISTENING HISTORY'), findsNothing);
    expect(find.text('Play recent'), findsNothing);

    await tester.tap(find.text('Search music'));
    await tester.pumpAndSettle();
    expect(find.text('Search destination'), findsOneWidget);
  });
}
