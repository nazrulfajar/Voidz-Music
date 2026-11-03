import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:my_music_player/core/constants/enums.dart';
import 'package:my_music_player/core/theme/app_spacing.dart';
import 'package:my_music_player/core/theme/app_theme.dart';
import 'package:my_music_player/features/player/domain/entities/track.dart';
import 'package:my_music_player/features/player/presentation/providers/player_controller.dart';
import 'package:my_music_player/features/player/presentation/widgets/mini_player.dart';
import 'package:my_music_player/features/settings/data/models/app_settings_model.dart';
import 'package:my_music_player/features/settings/presentation/providers/settings_provider.dart';
import 'package:my_music_player/l10n/app_localizations.dart';
import 'package:my_music_player/shared/widgets/app_bottom_nav.dart';
import 'package:my_music_player/shared/widgets/app_empty_state.dart';
import 'package:my_music_player/shared/widgets/bottom_nav_scaffold.dart';

import '../../helpers/pump_app.dart';
import '../../features/player/presentation/providers/fakes.dart';

Track _track(String id) {
  return Track(
    sourceId: id,
    title: 'Track $id',
    artist: 'The Weeknd',
    durationMs: 230000,
    source: TrackSource.youtube,
  );
}

PlayerState _playerState() {
  final queue = List<Track>.generate(2, (index) => _track('v$index'));
  return PlayerState(
    currentTrack: queue.first,
    currentQueue: queue,
    currentIndex: 0,
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

class _BranchPage extends StatelessWidget {
  const _BranchPage(this.label);

  final String label;

  @override
  Widget build(BuildContext context) {
    return Scaffold(body: Center(child: Text(label)));
  }
}

/// List with the same bottom reservation used by real pages, so the test can
/// prove the last row scrolls fully above the floating mini-player.
class _ScrollProbePage extends StatelessWidget {
  const _ScrollProbePage();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: ListView.builder(
        key: const Key('probe-list'),
        padding: const EdgeInsets.only(
          bottom: AppSpacing.bottomPlayerPadding,
        ),
        itemCount: 12,
        itemBuilder: (context, index) {
          final isLast = index == 11;
          return Container(
            key: isLast ? const Key('probe-last') : ValueKey('probe-$index'),
            height: 120,
            alignment: Alignment.center,
            child: Text('Probe row $index'),
          );
        },
      ),
    );
  }
}

GoRouter _shellRouter({
  Widget home = const _BranchPage('home-page'),
}) {
  return GoRouter(
    initialLocation: '/',
    routes: [
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) {
          return BottomNavScaffold(navigationShell: navigationShell);
        },
        branches: [
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/',
                builder: (context, state) => home,
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/search',
                builder: (context, state) => const _BranchPage('search-page'),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/library',
                builder: (context, state) => const _BranchPage('library-page'),
              ),
            ],
          ),
        ],
      ),
    ],
  );
}

Future<void> _pumpShell(
  WidgetTester tester, {
  Size surfaceSize = kTestSurfaceSize,
  double textScale = 1.0,
  bool withTrack = false,
  Widget home = const _BranchPage('home-page'),
  Locale? locale,
}) async {
  final router = _shellRouter(home: home);
  addTearDown(router.dispose);

  await pumpApp(
    tester,
    ProviderScope(
      overrides: [
        appSettingsProvider.overrideWith(
          (ref) => const Stream<AppSettingsModel>.empty(),
        ),
        playerControllerProvider.overrideWith(
          (ref) => _StubPlayerController(
            ref,
            withTrack ? _playerState() : PlayerState(),
          ),
        ),
      ],
      child: MaterialApp.router(
        debugShowCheckedModeBanner: false,
        theme: AppTheme.darkTheme,
        locale: locale,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        routerConfig: router,
      ),
    ),
    surfaceSize: surfaceSize,
    textScale: textScale,
  );
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('360x640 shell uses the bottom navigation', (tester) async {
    await _pumpShell(tester);

    expect(find.byType(NavigationRail), findsNothing);
    expect(find.byType(AppBottomNav), findsOneWidget);
    expect(find.text('home-page'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('bottom navigation labels follow the app locale', (tester) async {
    await _pumpShell(tester, locale: const Locale('en'));
    expect(find.text('Home'), findsOneWidget);
    expect(find.text('Search'), findsOneWidget);
    expect(find.text('Library'), findsOneWidget);

    await _pumpShell(tester, locale: const Locale('id'));
    expect(find.text('Beranda'), findsOneWidget);
    expect(find.text('Cari'), findsOneWidget);
    expect(find.text('Library'), findsOneWidget);
    expect(find.text('Home'), findsNothing);
    expect(find.text('Search'), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('915x412 shell uses a 64dp navigation rail', (tester) async {
    await _pumpShell(tester, surfaceSize: const Size(915, 412));

    expect(find.byType(NavigationRail), findsOneWidget);
    expect(find.byType(AppBottomNav), findsNothing);
    expect(tester.getSize(find.byType(NavigationRail)).width, 64);
    expect(
      tester.getSize(find.byKey(const Key('app-navigation-rail'))).height,
      AppShellLayout.railMaxHeight,
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('915x412 mini-player starts to the right of the rail',
      (tester) async {
    await _pumpShell(
      tester,
      surfaceSize: const Size(915, 412),
      withTrack: true,
    );

    final rail = tester.getRect(
      find.byKey(const Key('app-navigation-rail')),
    );
    final miniPlayer = tester.getRect(find.byType(MiniPlayer));

    expect(rail.right, lessThanOrEqualTo(miniPlayer.left));
    expect(miniPlayer.bottom, lessThanOrEqualTo(412));
    expect(
      AppShellLayout.railBottomChromeHeight,
      lessThanOrEqualTo(AppSpacing.bottomPlayerPadding),
    );
  });

  testWidgets('915x412 rail content scrolls clear of the mini-player',
      (tester) async {
    await _pumpShell(
      tester,
      surfaceSize: const Size(915, 412),
      withTrack: true,
      home: const _ScrollProbePage(),
    );

    final scrollable = tester.state<ScrollableState>(
      find.byType(Scrollable).first,
    );
    scrollable.position.jumpTo(scrollable.position.maxScrollExtent);
    await tester.pumpAndSettle();

    final last = tester.getRect(find.byKey(const Key('probe-last')));
    final miniPlayer = tester.getRect(find.byType(MiniPlayer));

    expect(
      last.bottom,
      lessThanOrEqualTo(miniPlayer.top),
      reason: 'last row must scroll fully above the mini-player',
    );
    expect(last.top, greaterThanOrEqualTo(0));
  });

  testWidgets('360x640 bottom chrome stays inside the reserved padding',
      (tester) async {
    await _pumpShell(tester, withTrack: true);

    final miniPlayer = tester.getRect(find.byType(MiniPlayer));
    final bottomNav = tester.getRect(find.byType(AppBottomNav));

    expect(bottomNav.bottom, lessThanOrEqualTo(kTestSurfaceSize.height));
    expect(
      miniPlayer.top,
      greaterThanOrEqualTo(
        kTestSurfaceSize.height - AppSpacing.bottomPlayerPadding,
      ),
    );
    expect(
      AppShellLayout.bottomChromeHeight,
      lessThanOrEqualTo(AppSpacing.bottomPlayerPadding),
    );
  });

  testWidgets('915x412 at textScale 2.0 has no overflow', (tester) async {
    await _pumpShell(
      tester,
      surfaceSize: const Size(915, 412),
      textScale: 2.0,
    );

    expect(tester.takeException(), isNull);
    expect(find.byType(NavigationRail), findsOneWidget);
  });

  testWidgets('empty state panel compacts below 600dp height', (tester) async {
    await pumpApp(
      tester,
      const Scaffold(
        body: AppEmptyState(
          icon: Icons.inbox_rounded,
          title: 'Nothing here',
          subtitle: 'Try another search.',
          actionLabel: 'Search',
          onAction: _noop,
        ),
      ),
      surfaceSize: const Size(360, 500),
    );

    final circle = tester.getSize(
      find.byKey(const Key('app-state-panel-circle')),
    );
    expect(circle.width, 56);
    expect(tester.takeException(), isNull);
  });

  testWidgets('empty state panel keeps full geometry at 640dp height',
      (tester) async {
    await pumpApp(
      tester,
      const Scaffold(
        body: AppEmptyState(
          icon: Icons.inbox_rounded,
          title: 'Nothing here',
          subtitle: 'Try another search.',
          actionLabel: 'Search',
          onAction: _noop,
        ),
      ),
    );

    final circle = tester.getSize(
      find.byKey(const Key('app-state-panel-circle')),
    );
    expect(circle.width, 72);
  });

  testWidgets('compact empty state at textScale 2.0 has no overflow',
      (tester) async {
    await pumpApp(
      tester,
      const Scaffold(
        body: AppEmptyState(
          icon: Icons.inbox_rounded,
          title: 'Nothing here',
          subtitle: 'Try another search.',
          actionLabel: 'Search',
          onAction: _noop,
        ),
      ),
      surfaceSize: const Size(360, 500),
      textScale: 2.0,
    );

    expect(tester.takeException(), isNull);
    final action = tester.getSize(find.widgetWithText(FilledButton, 'Search'));
    expect(action.height, greaterThanOrEqualTo(48));
  });
}

void _noop() {}
