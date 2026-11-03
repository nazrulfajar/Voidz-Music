import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:my_music_player/core/constants/enums.dart';
import 'package:my_music_player/core/providers/connectivity_provider.dart';
import 'package:my_music_player/core/theme/app_colors.dart';
import 'package:my_music_player/core/theme/app_glass.dart';
import 'package:my_music_player/core/theme/app_theme.dart';
import 'package:my_music_player/features/home/domain/entities/daily_mix.dart';
import 'package:my_music_player/features/home/presentation/providers/home_provider.dart';
import 'package:my_music_player/features/home/presentation/providers/mood_mix_provider.dart';
import 'package:my_music_player/features/home/presentation/screens/home_screen.dart';
import 'package:my_music_player/features/home/presentation/widgets/mix_card.dart';
import 'package:my_music_player/features/player/domain/entities/track.dart';
import 'package:my_music_player/features/player/presentation/providers/player_controller.dart';
import 'package:my_music_player/features/player/presentation/widgets/mini_player.dart';
import 'package:my_music_player/features/settings/data/models/app_settings_model.dart';
import 'package:my_music_player/features/settings/presentation/providers/settings_provider.dart';
import 'package:my_music_player/l10n/app_localizations.dart';
import 'package:my_music_player/shared/widgets/app_bottom_nav.dart';
import 'package:my_music_player/shared/widgets/app_chrome.dart';
import 'package:my_music_player/shared/widgets/bottom_nav_scaffold.dart';
import 'package:my_music_player/shared/widgets/glass_background.dart';
import 'package:my_music_player/shared/widgets/glass_surface.dart';

import '../../helpers/pump_app.dart';
import '../../features/player/presentation/providers/fakes.dart';

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

PlayerState _playerState() {
  final queue = List<Track>.generate(2, (index) => _track(sourceId: 'v$index'));
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

class _RouteStub extends StatelessWidget {
  const _RouteStub(this.label);

  final String label;

  @override
  Widget build(BuildContext context) {
    return Scaffold(body: Center(child: Text(label)));
  }
}

GoRouter _shellRouter() {
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
                builder: (context, state) => const _BranchPage('home-page'),
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
  bool disableAnimations = false,
  GlassQuality glassQuality = GlassQuality.blurred,
}) async {
  final router = _shellRouter();
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
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        routerConfig: router,
        builder: (context, child) {
          final media = MediaQuery.of(context);
          return MediaQuery(
            data: media.copyWith(disableAnimations: disableAnimations),
            child: AppChrome(
              router: router,
              miniPlayer: withTrack ? MiniPlayer(quality: glassQuality) : null,
              glassQuality: glassQuality,
              child: child ?? const SizedBox.shrink(),
            ),
          );
        },
      ),
    ),
    surfaceSize: surfaceSize,
    textScale: textScale,
  );
  await tester.pumpAndSettle();
}

Future<void> _pumpHome(
  WidgetTester tester, {
  List<Track> recentlyPlayed = const <Track>[],
  double textScale = 1.0,
  bool disableAnimations = false,
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
        path: '/downloaded',
        builder: (context, state) => const _RouteStub('downloaded-route'),
      ),
      GoRoute(
        path: '/device-songs',
        builder: (context, state) => const _RouteStub('device-songs-route'),
      ),
      GoRoute(
        path: '/daily-mix/:mood',
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
        moodMixProvider.overrideWith(
          (ref, mood) async => DailyMix(mood: mood),
        ),
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
        debugShowCheckedModeBanner: false,
        theme: AppTheme.darkTheme,
        routerConfig: router,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
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

void main() {
  group('GlassBackground', () {
    testWidgets('paints the dark gradient and exactly two blooms',
        (tester) async {
      await pumpApp(
        tester,
        const GlassBackground(
          child: SizedBox.expand(key: Key('glass-background-child')),
        ),
      );

      final base = tester.widget<ColoredBox>(
        find.byKey(const Key('glass-background-base')),
      );
      expect(base.color, AppGlass.dark.backgroundBase);

      final gradientBox = tester.widget<DecoratedBox>(
        find.byKey(const Key('glass-background-gradient')),
      );
      final gradient =
          (gradientBox.decoration as BoxDecoration).gradient! as LinearGradient;
      expect(gradient.colors, AppGlass.dark.gradientStops);

      expect(find.byKey(const Key('glass-bloom-white')), findsOneWidget);
      expect(find.byKey(const Key('glass-bloom-cold')), findsOneWidget);

      final white = _bloomGradient(tester, const Key('glass-bloom-white'));
      expect(white.colors.first, AppGlass.dark.bloomWhite);
      expect(white.colors.last.a, 0);

      final cold = _bloomGradient(tester, const Key('glass-bloom-cold'));
      expect(cold.colors.first, AppGlass.dark.bloomCold);
      expect(cold.colors.last.a, 0);

      expect(
        find.descendant(
          of: find.byType(GlassBackground),
          matching: find.byType(RepaintBoundary),
        ),
        findsWidgets,
      );
      expect(find.byKey(const Key('glass-background-child')), findsOneWidget);
      expect(find.byType(BackdropFilter), findsNothing);
      expect(tester.binding.transientCallbackCount, 0);
      expect(tester.takeException(), isNull);
    });

    testWidgets('resolves the provisional light gradient', (tester) async {
      await pumpApp(
        tester,
        const GlassBackground(),
        themeMode: ThemeMode.light,
      );

      final base = tester.widget<ColoredBox>(
        find.byKey(const Key('glass-background-base')),
      );
      expect(base.color, AppGlass.light.backgroundBase);

      final gradientBox = tester.widget<DecoratedBox>(
        find.byKey(const Key('glass-background-gradient')),
      );
      final gradient =
          (gradientBox.decoration as BoxDecoration).gradient! as LinearGradient;
      expect(gradient.colors, AppGlass.light.gradientStops);
    });

    testWidgets('does not overflow at text scale 2.0', (tester) async {
      await pumpApp(
        tester,
        const GlassBackground(
          child: Padding(
            padding: EdgeInsets.all(16),
            child: Text(
              'A long glass background child that wraps without overflowing '
              'at two hundred percent text scale.',
            ),
          ),
        ),
        textScale: 2.0,
      );

      expect(tester.takeException(), isNull);
      expect(find.textContaining('A long glass background'), findsOneWidget);
    });
  });

  group('Shell glass chrome', () {
    testWidgets('360x640 uses two blurred chrome layers and aurora base',
        (tester) async {
      await _pumpShell(tester, withTrack: true);

      expect(find.byType(GlassBackground), findsOneWidget);
      expect(find.byType(AppBottomNav), findsOneWidget);
      expect(find.byType(GlassSurface), findsNWidgets(2));
      expect(find.byType(BackdropFilter), findsNWidgets(2));

      for (final surface in tester.widgetList<GlassSurface>(
        find.byType(GlassSurface),
      )) {
        expect(surface.quality, GlassQuality.blurred);
      }

      final searchLabel = tester.widget<Text>(find.text('Search'));
      expect(searchLabel.style?.color, AppColors.dark.textSecondary);

      expect(tester.takeException(), isNull);
    });

    testWidgets('915x412 rail keeps two chrome layers and TASK-039 geometry',
        (tester) async {
      await _pumpShell(
        tester,
        surfaceSize: const Size(915, 412),
        withTrack: true,
      );

      expect(find.byType(NavigationRail), findsOneWidget);
      expect(find.byType(AppBottomNav), findsNothing);
      expect(
        tester.getSize(find.byKey(const Key('app-navigation-rail'))),
        const Size(AppShellLayout.railWidth, AppShellLayout.railMaxHeight),
      );
      expect(find.byType(GlassSurface), findsNWidgets(2));
      expect(find.byType(BackdropFilter), findsNWidgets(2));
      expect(tester.takeException(), isNull);
    });

    testWidgets('disableAnimations drops shell blur without hiding chrome',
        (tester) async {
      await _pumpShell(
        tester,
        withTrack: true,
        disableAnimations: true,
      );

      expect(find.byType(BackdropFilter), findsNothing);
      expect(find.byType(AppBottomNav), findsOneWidget);
      expect(find.byType(MiniPlayer), findsOneWidget);
      expect(find.byType(GlassSurface), findsNWidgets(2));
      expect(tester.takeException(), isNull);
    });

    testWidgets('opaque shell quality removes every backdrop filter',
        (tester) async {
      await _pumpShell(
        tester,
        withTrack: true,
        glassQuality: GlassQuality.opaque,
      );

      expect(find.byType(BackdropFilter), findsNothing);
      for (final surface in tester.widgetList<GlassSurface>(
        find.byType(GlassSurface),
      )) {
        expect(surface.quality, GlassQuality.opaque);
      }
      expect(tester.takeException(), isNull);
    });

    testWidgets('shell stays overflow-free at 200% text scale', (tester) async {
      await _pumpShell(tester, withTrack: true, textScale: 2.0);

      expect(tester.takeException(), isNull);
      expect(find.byType(GlassBackground), findsOneWidget);
    });
  });

  group('Home glass cards', () {
    testWidgets('uses glass material within the blur cap', (tester) async {
      await _pumpHome(tester, recentlyPlayed: <Track>[_track()]);

      expect(find.byKey(const Key('home-continue-glass')), findsOneWidget);
      expect(find.byKey(const Key('home-settings-glass')), findsOneWidget);
      expect(find.byKey(const Key('home-recent-t1')), findsOneWidget);

      final surfaces = tester
          .widgetList<GlassSurface>(
            find.byType(GlassSurface),
          )
          .toList();
      expect(surfaces, hasLength(10));
      expect(
        surfaces.where((surface) => surface.quality == GlassQuality.blurred),
        hasLength(1),
      );
      expect(
        surfaces.where((surface) => surface.quality == GlassQuality.frosted),
        hasLength(9),
      );

      // One content-card blur at most; rows and the settings circle are
      // frosted so the shell chrome stays inside the 2-3 layer cap.
      expect(find.byType(BackdropFilter), findsOneWidget);
      expect(
        find.descendant(
          of: find.byKey(const Key('home-recent-t1')),
          matching: find.byType(BackdropFilter),
        ),
        findsNothing,
      );
      expect(
        find.descendant(
          of: find.byKey(const Key('home-settings-glass')),
          matching: find.byType(BackdropFilter),
        ),
        findsNothing,
      );
      expect(
        find.descendant(
          of: find.byType(MixCard).first,
          matching: find.byType(BackdropFilter),
        ),
        findsNothing,
      );
      expect(tester.takeException(), isNull);
    });

    testWidgets('Home drops every blur when animations are disabled',
        (tester) async {
      await _pumpHome(
        tester,
        recentlyPlayed: <Track>[_track()],
        disableAnimations: true,
      );

      expect(find.byType(BackdropFilter), findsNothing);
      expect(find.byType(GlassSurface), findsNWidgets(10));
      expect(tester.takeException(), isNull);
    });

    testWidgets('populated Home at 200% text scale has no overflow',
        (tester) async {
      await _pumpHome(
        tester,
        recentlyPlayed: <Track>[_track()],
        textScale: 2.0,
      );

      expect(tester.takeException(), isNull);
      expect(find.byType(MixCard), findsNWidgets(5));
      expect(find.byKey(const Key('home-settings-glass')), findsOneWidget);
    });
  });

  group('Glass chip tokens', () {
    test('dark selected and subtle chips match DESIGN_SYSTEM §0.2', () {
      expect(AppGlass.dark.chipSelectedFill, const Color(0x26FFFFFF));
      expect(AppGlass.dark.chipSelectedBorder, const Color(0x4DFFFFFF));
      expect(AppGlass.dark.chipSubtleFill, const Color(0x0DFFFFFF));
      expect(AppGlass.dark.chipSubtleBorder, const Color(0x14FFFFFF));
    });

    test('light selected and subtle chips expose provisional values', () {
      expect(AppGlass.light.chipSelectedFill, const Color(0xD9FFFFFF));
      expect(AppGlass.light.chipSelectedBorder, const Color(0x2E0A1018));
      expect(AppGlass.light.chipSubtleFill, const Color(0xCCFFFFFF));
      expect(AppGlass.light.chipSubtleBorder, const Color(0x1A0A1018));
      expect(AppGlass.light.provisional, isTrue);
    });
  });
}

RadialGradient _bloomGradient(WidgetTester tester, Key key) {
  final bloom = tester.widget<DecoratedBox>(
    find.descendant(
      of: find.byKey(key),
      matching: find.byType(DecoratedBox),
    ),
  );
  return (bloom.decoration as BoxDecoration).gradient! as RadialGradient;
}
