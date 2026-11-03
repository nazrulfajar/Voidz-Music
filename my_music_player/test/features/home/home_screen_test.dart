import 'package:dartz/dartz.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:mocktail/mocktail.dart';
import 'package:my_music_player/core/constants/enums.dart';
import 'package:my_music_player/core/providers/connectivity_provider.dart';
import 'package:my_music_player/core/theme/app_colors.dart';
import 'package:my_music_player/core/theme/app_theme.dart';
import 'package:my_music_player/features/home/domain/entities/daily_mix.dart';
import 'package:my_music_player/features/home/presentation/providers/home_provider.dart';
import 'package:my_music_player/features/home/presentation/providers/mood_mix_provider.dart';
import 'package:my_music_player/features/home/presentation/screens/daily_mix_screen.dart';
import 'package:my_music_player/features/home/presentation/screens/home_screen.dart';
import 'package:my_music_player/features/home/presentation/widgets/mix_card.dart';
import 'package:my_music_player/features/player/data/repositories/track_repository_impl.dart';
import 'package:my_music_player/features/player/domain/entities/track.dart';
import 'package:my_music_player/features/player/domain/repositories/track_repository.dart';
import 'package:my_music_player/features/player/presentation/providers/player_controller.dart';
import 'package:my_music_player/features/settings/presentation/providers/settings_provider.dart';
import 'package:my_music_player/l10n/app_localizations.dart';

import '../../helpers/pump_app.dart';
import '../player/presentation/providers/fakes.dart';

class _MockTrackRepository extends Mock implements TrackRepository {}

class _RecordingPlayerController extends PlayerController {
  _RecordingPlayerController(Ref ref)
      : super(
          FakeAudioPlayerService(),
          FakeApiService(),
          FakeTrackRepository(),
          FakeCacheDownloadService(),
          ref,
        );

  Track? playedTrack;
  List<Track>? playedQueue;

  @override
  Future<void> playTrack(Track track, {List<Track>? queue}) async {
    playedTrack = track;
    playedQueue = queue;
  }
}

class _DynamicPlayerController extends _RecordingPlayerController {
  _DynamicPlayerController(Ref ref, PlayerState initial) : super(ref) {
    state = initial;
  }

  @override
  Future<void> togglePlayPause() async {
    state = state.copyWith(isPlaying: !state.isPlaying);
  }

  @override
  Future<void> playTrack(Track track, {List<Track>? queue}) async {
    await super.playTrack(track, queue: queue);
    state = PlayerState(
      currentTrack: track,
      currentQueue: queue ?? [track],
      currentIndex: 0,
      isPlaying: true,
      duration: Duration(milliseconds: track.durationMs),
    );
  }
}

class _RouteStub extends StatelessWidget {
  const _RouteStub(this.label);

  final String label;

  @override
  Widget build(BuildContext context) {
    return Scaffold(body: Center(child: Text(label)));
  }
}

Track _track({
  String sourceId = 't1',
  String title = 'Alpha',
  int durationMs = 200000,
}) {
  return Track(
    sourceId: sourceId,
    title: title,
    artist: 'Artist',
    durationMs: durationMs,
    source: TrackSource.youtube,
  );
}

void main() {
  Future<void> pumpHome(
    WidgetTester tester, {
    List<Track> recentlyPlayed = const <Track>[],
    List<Track> quickPicks = const <Track>[],
    PlayerState? playerState,
    double textScale = 1.0,
    Locale? locale,
  }) async {
    final router = GoRouter(
      initialLocation: '/',
      routes: [
        GoRoute(
          path: '/',
          builder: (context, state) => const HomeScreen(),
        ),
        GoRoute(
          path: '/settings',
          builder: (context, state) => const _RouteStub('settings-route'),
        ),
        GoRoute(
          path: '/search',
          builder: (context, state) => const _RouteStub('search-route'),
        ),
        GoRoute(
          path: '/device-songs',
          builder: (context, state) => const _RouteStub('device-songs-route'),
        ),
        GoRoute(
          path: '/daily-mix/:mood',
          builder: (context, state) => _RouteStub(
            'daily-mix-${state.pathParameters['mood']}-route',
          ),
        ),
      ],
    );
    addTearDown(router.dispose);

    await pumpApp(
      tester,
      ProviderScope(
        overrides: [
          recentlyPlayedProvider.overrideWith((ref) async => recentlyPlayed),
          quickPicksProvider.overrideWith((ref) async => quickPicks),
          moodMixProvider.overrideWith(
            (ref, mood) async => DailyMix(mood: mood),
          ),
          connectivityProvider.overrideWith(
            (ref) => Stream<bool>.value(true),
          ),
          playerControllerProvider.overrideWith(
            (ref) => playerState == null
                ? PlayerController(
                    FakeAudioPlayerService(),
                    FakeApiService(),
                    FakeTrackRepository(),
                    FakeCacheDownloadService(),
                    ref,
                  )
                : _DynamicPlayerController(ref, playerState),
          ),
          appSettingsProvider.overrideWith((ref) => const Stream.empty()),
        ],
        child: MaterialApp.router(
          theme: AppTheme.darkTheme,
          routerConfig: router,
          locale: locale,
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          builder: (context, child) {
            final media = MediaQuery.of(context);
            return MediaQuery(
              data: media.copyWith(
                textScaler: TextScaler.linear(textScale),
              ),
              child: child!,
            );
          },
        ),
      ),
      textScale: textScale,
    );
    await tester.pumpAndSettle();
  }

  testWidgets('settings button opens the settings route', (tester) async {
    await pumpHome(tester);

    await tester.tap(find.byIcon(Icons.settings_outlined));
    await tester.pumpAndSettle();

    expect(find.text('settings-route'), findsOneWidget);
  });

  testWidgets('empty continue listening offers a search action',
      (tester) async {
    await pumpHome(tester);

    expect(
      find.widgetWithText(FilledButton, 'Search music'),
      findsOneWidget,
    );

    await tester.tap(find.text('Search music'));
    await tester.pumpAndSettle();

    expect(find.text('search-route'), findsOneWidget);
  });

  testWidgets('daily mix renders the five mood cards', (tester) async {
    final semantics = tester.ensureSemantics();
    await pumpHome(tester);

    expect(find.byType(MixCard), findsNWidgets(5));
    for (final mood in DailyMixMood.values) {
      expect(find.text(mood.label), findsOneWidget);
    }
    expect(find.bySemanticsLabel('Daily Mix Energize'), findsOneWidget);

    semantics.dispose();
  });

  testWidgets('tapping a mood card opens its detail route', (tester) async {
    await pumpHome(tester);

    final card = find.byType(MixCard).first;
    await tester.ensureVisible(card);
    await tester.pumpAndSettle();
    await tester.tap(card);
    await tester.pumpAndSettle();

    expect(find.text('daily-mix-energize-route'), findsOneWidget);
  });

  testWidgets('empty home uses a compact panel with a single CTA',
      (tester) async {
    await pumpHome(tester);

    expect(find.text('RECENTLY PLAYED'), findsNothing);
    expect(find.text('CONTINUE LISTENING'), findsNothing);
    expect(find.text('No recently played tracks'), findsOneWidget);
    expect(find.widgetWithText(FilledButton, 'Search music'), findsOneWidget);
    expect(find.byType(FilledButton), findsOneWidget);

    final panel = tester.getSize(
      find.byKey(const Key('app-state-panel')),
    );
    expect(panel.height, lessThan(400));
  });

  testWidgets('shows recently played duration in textSecondary',
      (tester) async {
    await pumpHome(tester, recentlyPlayed: [_track()]);

    expect(find.text('RECENTLY PLAYED'), findsOneWidget);
    expect(find.text('Alpha'), findsWidgets);

    final duration = tester.widget<Text>(find.text('3:20'));
    expect(duration.style?.color, AppColors.dark.textSecondary);
  });

  testWidgets('icon-only controls expose semantic labels', (tester) async {
    final semantics = tester.ensureSemantics();

    await pumpHome(tester, recentlyPlayed: [_track()]);

    expect(find.bySemanticsLabel('Settings'), findsOneWidget);
    expect(find.bySemanticsLabel('Play Alpha'), findsOneWidget);

    semantics.dispose();
  });

  testWidgets('continue card switches to now listening and pauses in place',
      (tester) async {
    final semantics = tester.ensureSemantics();
    final track = _track();
    await pumpHome(
      tester,
      recentlyPlayed: [track],
      playerState: PlayerState(
        currentTrack: track,
        currentQueue: [track],
        currentIndex: 0,
        isPlaying: true,
        position: const Duration(seconds: 10),
        duration: const Duration(seconds: 200),
      ),
    );

    expect(find.text('NOW LISTENING'), findsOneWidget);
    expect(find.bySemanticsLabel('Pause Alpha'), findsOneWidget);

    await tester.tap(find.bySemanticsLabel('Pause Alpha'));
    await tester.pumpAndSettle();

    expect(find.text('CONTINUE LISTENING'), findsOneWidget);
    expect(find.bySemanticsLabel('Play Alpha'), findsOneWidget);
    semantics.dispose();
  });

  testWidgets('continue card follows the current track over recent history',
      (tester) async {
    await pumpHome(
      tester,
      recentlyPlayed: [_track()],
      playerState: PlayerState(
        currentTrack: _track(sourceId: 'live', title: 'Live Track'),
        currentQueue: [_track(sourceId: 'live', title: 'Live Track')],
        currentIndex: 0,
        isPlaying: true,
        duration: const Duration(seconds: 200),
      ),
    );

    expect(find.text('NOW LISTENING'), findsOneWidget);
    expect(find.text('Live Track'), findsWidgets);
  });

  testWidgets('finished playback falls back to continue listening and restarts',
      (tester) async {
    final semantics = tester.ensureSemantics();
    final track = _track(durationMs: 200000);
    await pumpHome(
      tester,
      recentlyPlayed: [track],
      playerState: PlayerState(
        currentTrack: track,
        currentQueue: [track],
        currentIndex: 0,
        isPlaying: true,
        position: const Duration(seconds: 200),
        duration: const Duration(seconds: 200),
      ),
    );

    expect(find.text('CONTINUE LISTENING'), findsOneWidget);
    expect(find.bySemanticsLabel('Play Alpha'), findsOneWidget);

    await tester.tap(find.bySemanticsLabel('Play Alpha'));
    await tester.pumpAndSettle();

    expect(find.text('NOW LISTENING'), findsOneWidget);
    semantics.dispose();
  });

  testWidgets('empty home renders at 200% text scale without overflow',
      (tester) async {
    await pumpHome(tester, textScale: 2.0);

    expect(tester.takeException(), isNull);
    expect(find.text('Search music'), findsOneWidget);
    expect(find.byType(MixCard), findsNWidgets(5));
  });

  testWidgets('populated home renders at 200% text scale without overflow',
      (tester) async {
    await pumpHome(
      tester,
      recentlyPlayed: [_track()],
      quickPicks: [_track(sourceId: 't2', title: 'Beta')],
      textScale: 2.0,
    );

    expect(tester.takeException(), isNull);
  });

  testWidgets('home copy follows the app locale', (tester) async {
    for (final (
          locale,
          emptyTitle,
          searchCta,
          downloaded,
          deviceSongs,
          onThisDevice,
        ) in [
      (
        const Locale('en'),
        'No recently played tracks',
        'Search music',
        'Downloaded',
        'Device songs',
        'On this device',
      ),
      (
        const Locale('id'),
        'Belum ada yang terakhir diputar',
        'Cari musik',
        'Terunduh',
        'Lagu lokal',
        'Di perangkat ini',
      ),
    ]) {
      await pumpHome(tester, locale: locale);

      expect(find.text(emptyTitle), findsOneWidget, reason: '$locale title');
      expect(find.text(searchCta), findsOneWidget, reason: '$locale CTA');
      expect(find.text(downloaded), findsOneWidget, reason: '$locale cache');
      expect(find.text(deviceSongs), findsOneWidget, reason: '$locale device');
      expect(find.text(onThisDevice), findsOneWidget, reason: '$locale meta');
      expect(find.text('DAILY MIX'), findsOneWidget, reason: '$locale mix');
    }
  });

  Future<_RecordingPlayerController> pumpDailyMix(
    WidgetTester tester, {
    required List<Track> tracks,
    double textScale = 1.0,
    Locale? locale,
  }) async {
    late _RecordingPlayerController controller;
    await tester.pumpWidget(const SizedBox.shrink());
    final router = GoRouter(
      initialLocation: '/daily-mix/energize',
      routes: [
        GoRoute(
          path: '/daily-mix/:mood',
          builder: (context, state) => DailyMixScreen(
            mood: DailyMixMood.fromSlug(state.pathParameters['mood'] ?? ''),
          ),
        ),
        GoRoute(
          path: '/search',
          builder: (context, state) => const _RouteStub('search-route'),
        ),
        GoRoute(
          path: '/device-songs',
          builder: (context, state) => const _RouteStub('device-songs-route'),
        ),
      ],
    );
    addTearDown(router.dispose);

    await pumpApp(
      tester,
      ProviderScope(
        overrides: [
          moodMixProvider.overrideWith(
            (ref, mood) async =>
                DailyMix(mood: mood, tracks: tracks, artworkUrls: const []),
          ),
          playerControllerProvider.overrideWith((ref) {
            controller = _RecordingPlayerController(ref);
            return controller;
          }),
          appSettingsProvider.overrideWith((ref) => const Stream.empty()),
        ],
        child: MaterialApp.router(
          theme: AppTheme.darkTheme,
          routerConfig: router,
          locale: locale,
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          builder: (context, child) {
            final media = MediaQuery.of(context);
            return MediaQuery(
              data: media.copyWith(
                textScaler: TextScaler.linear(textScale),
              ),
              child: child!,
            );
          },
        ),
      ),
      textScale: textScale,
    );
    await tester.pumpAndSettle();
    return controller;
  }

  testWidgets('daily mix detail lists tracks and plays all', (tester) async {
    final tracks = [_track(), _track(sourceId: 't2', title: 'Beta')];

    final controller = await pumpDailyMix(tester, tracks: tracks);

    expect(find.text('Energize'), findsOneWidget);
    expect(find.text('Alpha'), findsOneWidget);
    expect(find.text('Beta'), findsOneWidget);

    await tester.tap(find.text('Play all'));
    await tester.pump();

    expect(controller.playedTrack, tracks.first);
    expect(controller.playedQueue, tracks);
  });

  testWidgets('empty daily mix offers search and device scan actions',
      (tester) async {
    await pumpDailyMix(tester, tracks: const []);

    expect(find.text('No tracks for Energize'), findsOneWidget);
    expect(find.widgetWithText(FilledButton, 'Search'), findsOneWidget);
    expect(find.text('Scan device songs'), findsOneWidget);

    await tester.tap(find.text('Scan device songs'));
    await tester.pumpAndSettle();
    expect(find.text('device-songs-route'), findsOneWidget);
  });

  testWidgets('empty daily mix renders at 200% text scale without overflow',
      (tester) async {
    await pumpDailyMix(tester, tracks: const [], textScale: 2.0);

    expect(tester.takeException(), isNull);
  });

  testWidgets('daily mix meta follows the app locale', (tester) async {
    final tracks = [_track(), _track(sourceId: 't2', title: 'Beta')];

    for (final (locale, meta, playAll) in [
      (const Locale('en'), '2 tracks · Daily Mix', 'Play all'),
      (const Locale('id'), '2 lagu · Daily Mix', 'Putar semua'),
    ]) {
      await pumpDailyMix(tester, tracks: tracks, locale: locale);

      expect(find.text(meta), findsOneWidget, reason: '$locale meta');
      expect(find.text(playAll), findsOneWidget, reason: '$locale action');
    }
  });

  test('quick picks come from the local repository', () async {
    final repository = _MockTrackRepository();
    final picks = [_track()];
    when(() => repository.getQuickPicksTracks(limit: any(named: 'limit')))
        .thenAnswer((_) async => Right(picks));

    final container = ProviderContainer(
      overrides: [
        trackRepositoryProvider.overrideWithValue(repository),
      ],
    );
    addTearDown(container.dispose);

    expect(await container.read(quickPicksProvider.future), picks);
    verify(() => repository.getQuickPicksTracks(limit: 16)).called(1);
  });
}
