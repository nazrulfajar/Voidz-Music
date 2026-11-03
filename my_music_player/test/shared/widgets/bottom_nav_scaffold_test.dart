import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:my_music_player/core/constants/enums.dart';
import 'package:my_music_player/core/theme/app_theme.dart';
import 'package:my_music_player/features/player/domain/entities/track.dart';
import 'package:my_music_player/features/player/presentation/providers/player_controller.dart';
import 'package:my_music_player/features/player/presentation/widgets/mini_player.dart';
import 'package:my_music_player/features/settings/data/models/app_settings_model.dart';
import 'package:my_music_player/features/settings/presentation/providers/settings_provider.dart';
import 'package:my_music_player/l10n/app_localizations.dart';
import 'package:my_music_player/shared/widgets/app_bottom_nav.dart';
import 'package:my_music_player/shared/widgets/app_chrome.dart';
import 'package:my_music_player/shared/widgets/app_chrome_insets.dart';
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

/// List with the same dynamic reservation used by real pages, so the test can
/// prove the last row scrolls fully above the measured chrome.
class _ScrollProbePage extends StatelessWidget {
  const _ScrollProbePage();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: ListView.builder(
        key: const Key('probe-list'),
        padding: EdgeInsets.only(
          bottom: AppChromeInsets.bottomOf(context),
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
      GoRoute(
        path: '/detail',
        builder: (context, state) => const _BranchPage('detail-page'),
      ),
      GoRoute(
        path: '/settings',
        builder: (context, state) => const _BranchPage('settings-page'),
      ),
      GoRoute(
        path: '/player',
        builder: (context, state) => const _BranchPage('player-page'),
      ),
      GoRoute(
        path: '/lyrics',
        builder: (context, state) => const _BranchPage('lyrics-page'),
      ),
    ],
  );
}

Future<({ProviderContainer container, GoRouter router})> _pumpShell(
  WidgetTester tester, {
  Size surfaceSize = kTestSurfaceSize,
  double textScale = 1.0,
  bool withTrack = false,
  Widget home = const _BranchPage('home-page'),
  Locale? locale,
  String initialLocation = '/',
  List<Override> overrides = const [],
}) async {
  tester.view.devicePixelRatio = 1.0;
  tester.view.physicalSize = surfaceSize;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);

  final container = ProviderContainer(
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
      ...overrides,
    ],
  );
  addTearDown(container.dispose);

  final router = _shellRouter(home: home);
  addTearDown(router.dispose);
  router.go(initialLocation);

  await tester.pumpWidget(
    UncontrolledProviderScope(
      container: container,
      child: MaterialApp.router(
        debugShowCheckedModeBanner: false,
        theme: AppTheme.darkTheme,
        locale: locale,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        routerConfig: router,
        builder: (context, child) {
          return MediaQuery(
            data: MediaQuery.of(context).copyWith(
              textScaler: TextScaler.linear(textScale),
            ),
            child: AppChrome(
              router: router,
              miniPlayer: withTrack ? const MiniPlayer() : null,
              child: child ?? const SizedBox.shrink(),
            ),
          );
        },
      ),
    ),
  );
  await tester.pumpAndSettle();
  return (container: container, router: router);
}

void main() {
  group('chrome mode', () {
    test('only the three tab roots own navigation chrome', () {
      expect(appChromeModeFor('/'), AppChromeMode.tabRoot);
      expect(appChromeModeFor('/search'), AppChromeMode.tabRoot);
      expect(appChromeModeFor('/library'), AppChromeMode.tabRoot);
    });

    test('detail and canonical deep links keep the mini player only', () {
      expect(appChromeModeFor('/settings'), AppChromeMode.detail);
      expect(appChromeModeFor('/artist/abc'), AppChromeMode.detail);
      expect(appChromeModeFor('/album/abc'), AppChromeMode.detail);
      expect(appChromeModeFor('/playlist/abc'), AppChromeMode.detail);
      expect(appChromeModeFor('/downloaded'), AppChromeMode.detail);
      expect(appChromeModeFor('/browse'), AppChromeMode.detail);
    });

    test('playback surfaces are immersive', () {
      expect(appChromeModeFor('/player'), AppChromeMode.immersive);
      expect(appChromeModeFor('/lyrics'), AppChromeMode.immersive);
      expect(appChromeModeFor('/queue'), AppChromeMode.immersive);
    });
  });

  testWidgets('360x640 tab root uses the bottom navigation', (tester) async {
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

  testWidgets('915x412 tab root uses a 64dp navigation rail', (tester) async {
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
  });

  testWidgets('detail routes hide navigation but keep the mini-player',
      (tester) async {
    final shell = await _pumpShell(tester, withTrack: true);

    shell.router.push('/detail');
    await tester.pumpAndSettle();

    expect(find.text('detail-page'), findsOneWidget);
    expect(find.byType(AppBottomNav), findsNothing);
    expect(find.byType(NavigationRail), findsNothing);
    expect(find.byType(MiniPlayer), findsOneWidget);
    expect(
      shell.container.read(playerControllerProvider).currentTrack?.sourceId,
      'v0',
      reason: 'navigation must not interrupt playback',
    );
  });

  testWidgets('915x412 detail hides the rail as well as the pill',
      (tester) async {
    final shell = await _pumpShell(
      tester,
      surfaceSize: const Size(915, 412),
      withTrack: true,
    );

    shell.router.push('/detail');
    await tester.pumpAndSettle();

    expect(find.text('detail-page'), findsOneWidget);
    expect(find.byType(NavigationRail), findsNothing);
    expect(find.byType(AppBottomNav), findsNothing);
    expect(find.byType(MiniPlayer), findsOneWidget);
  });

  testWidgets('settings keeps the mini-player without navigation',
      (tester) async {
    final shell = await _pumpShell(tester, withTrack: true);

    shell.router.push('/settings');
    await tester.pumpAndSettle();

    expect(find.text('settings-page'), findsOneWidget);
    expect(find.byType(AppBottomNav), findsNothing);
    expect(find.byType(MiniPlayer), findsOneWidget);
  });

  testWidgets('canonical deep link opens detail with the mini-player',
      (tester) async {
    await _pumpShell(
      tester,
      withTrack: true,
      initialLocation: '/detail',
    );

    expect(find.text('detail-page'), findsOneWidget);
    expect(find.byType(AppBottomNav), findsNothing);
    expect(find.byType(MiniPlayer), findsOneWidget);
  });

  testWidgets('mini-player lyrics action opens the immersive lyrics route',
      (tester) async {
    final shell = await _pumpShell(tester, withTrack: true);

    await tester.tap(find.byIcon(Icons.lyrics_outlined));
    await tester.pumpAndSettle();

    expect(find.text('lyrics-page'), findsOneWidget);
    expect(find.byType(AppBottomNav), findsNothing);
    expect(find.byType(MiniPlayer), findsNothing);
    expect(shell.router.canPop(), isTrue);
  });

  testWidgets('player is immersive: no navigation and no mini-player',
      (tester) async {
    final shell = await _pumpShell(tester, withTrack: true);

    shell.router.push('/player');
    await tester.pumpAndSettle();

    expect(find.text('player-page'), findsOneWidget);
    expect(find.byType(AppBottomNav), findsNothing);
    expect(find.byType(MiniPlayer), findsNothing);
    expect(
      AppChromeInsets.bottomOf(tester.element(find.text('player-page'))),
      0,
    );
  });

  testWidgets('tab root shows no mini-player when nothing is playing',
      (tester) async {
    await _pumpShell(tester);

    expect(find.byType(MiniPlayer), findsNothing);
    expect(find.byType(AppBottomNav), findsOneWidget);
  });

  testWidgets('mini-player exposes open and progress semantics',
      (tester) async {
    final semantics = tester.ensureSemantics();
    try {
      await _pumpShell(tester, withTrack: true);

      expect(
        find.bySemanticsLabel(RegExp('Open player')),
        findsOneWidget,
      );
      final progress = find.bySemanticsLabel('Playback position');
      expect(progress, findsOneWidget);
      expect(tester.getSemantics(progress).value, '0:10 / 3:50');
    } finally {
      semantics.dispose();
    }
  });

  testWidgets('chrome insets fit 360x640 without a permanent reserve',
      (tester) async {
    await _pumpShell(
      tester,
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

  testWidgets('bottom chrome stays inside the screen at 360x640',
      (tester) async {
    await _pumpShell(tester, withTrack: true);

    final miniPlayer = tester.getRect(find.byType(MiniPlayer));
    final bottomNav = tester.getRect(find.byType(AppBottomNav));

    expect(bottomNav.bottom, lessThanOrEqualTo(kTestSurfaceSize.height));
    expect(miniPlayer.bottom, lessThanOrEqualTo(bottomNav.top));
  });

  testWidgets('915x412 rail keeps full Indonesian labels at textScale 2.0',
      (tester) async {
    await _pumpShell(
      tester,
      surfaceSize: const Size(915, 412),
      textScale: 2.0,
      locale: const Locale('id'),
    );

    expect(tester.takeException(), isNull);
    expect(find.byType(NavigationRail), findsOneWidget);
    for (final label in ['Beranda', 'Cari', 'Library']) {
      final paragraph = tester.renderObject<RenderParagraph>(
        find.text(label).first,
      );
      expect(paragraph.didExceedMaxLines, isFalse, reason: label);
    }
  });

  testWidgets('360x640 at textScale 2.0 keeps full navigation labels',
      (tester) async {
    await _pumpShell(tester, textScale: 2.0);

    expect(tester.takeException(), isNull);
    for (final label in ['Home', 'Search', 'Library']) {
      final paragraph = tester.renderObject<RenderParagraph>(
        find.text(label).first,
      );
      expect(paragraph.didExceedMaxLines, isFalse, reason: label);
    }
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
