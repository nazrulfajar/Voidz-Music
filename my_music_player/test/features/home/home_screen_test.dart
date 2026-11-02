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
import 'package:my_music_player/features/home/presentation/providers/home_provider.dart';
import 'package:my_music_player/features/home/presentation/screens/home_screen.dart';
import 'package:my_music_player/features/player/data/repositories/track_repository_impl.dart';
import 'package:my_music_player/features/player/domain/entities/track.dart';
import 'package:my_music_player/features/player/domain/repositories/track_repository.dart';
import 'package:my_music_player/features/player/presentation/providers/player_controller.dart';
import 'package:my_music_player/features/settings/presentation/providers/settings_provider.dart';

import '../../helpers/pump_app.dart';
import '../player/presentation/providers/fakes.dart';

class _MockTrackRepository extends Mock implements TrackRepository {}

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
    double textScale = 1.0,
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
          path: '/library/device-songs',
          builder: (context, state) => const _RouteStub('device-songs-route'),
        ),
        GoRoute(
          path: '/daily-mix',
          builder: (context, state) => const _RouteStub('daily-mix-route'),
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
          connectivityProvider.overrideWith(
            (ref) => Stream<bool>.value(true),
          ),
          playerControllerProvider.overrideWith(
            (ref) => PlayerController(
              FakeAudioPlayerService(),
              FakeApiService(),
              FakeTrackRepository(),
              FakeCacheDownloadService(),
              ref,
            ),
          ),
          appSettingsProvider.overrideWith((ref) => const Stream.empty()),
        ],
        child: MaterialApp.router(
          theme: AppTheme.darkTheme,
          routerConfig: router,
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

  testWidgets('empty daily mix offers a device scan action', (tester) async {
    await pumpHome(tester);

    expect(
      find.widgetWithText(FilledButton, 'Scan device songs'),
      findsOneWidget,
    );

    await tester.ensureVisible(find.text('Scan device songs'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Scan device songs'));
    await tester.pumpAndSettle();

    expect(find.text('device-songs-route'), findsOneWidget);
  });

  testWidgets('hides the recently played header when nothing was played',
      (tester) async {
    await pumpHome(tester);

    expect(find.text('RECENTLY PLAYED'), findsNothing);
    expect(find.text('No recently played tracks'), findsOneWidget);
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

  testWidgets('empty home renders at 200% text scale without overflow',
      (tester) async {
    await pumpHome(tester, textScale: 2.0);

    expect(tester.takeException(), isNull);
    expect(find.text('Search music'), findsOneWidget);
    expect(find.text('Scan device songs'), findsOneWidget);
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
