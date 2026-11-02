import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shimmer/shimmer.dart';

import 'package:my_music_player/core/constants/enums.dart' show TrackSource;
import 'package:my_music_player/core/errors/failures.dart';
import 'package:my_music_player/core/providers/connectivity_provider.dart';
import 'package:my_music_player/core/theme/app_colors.dart';
import 'package:my_music_player/core/theme/app_theme.dart';
import 'package:my_music_player/features/cache/presentation/providers/cache_stats_provider.dart';
import 'package:my_music_player/features/home/domain/entities/daily_mix.dart';
import 'package:my_music_player/features/home/presentation/providers/home_provider.dart';
import 'package:my_music_player/features/home/presentation/providers/mood_mix_provider.dart';
import 'package:my_music_player/features/home/presentation/screens/home_screen.dart';
import 'package:my_music_player/features/library/domain/entities/playlist.dart';
import 'package:my_music_player/features/library/presentation/providers/playlist_provider.dart';
import 'package:my_music_player/features/library/presentation/screens/device_songs_screen.dart';
import 'package:my_music_player/features/library/presentation/screens/library_screen.dart';
import 'package:my_music_player/features/lyrics/domain/entities/lyrics.dart';
import 'package:my_music_player/features/lyrics/presentation/providers/lyrics_provider.dart';
import 'package:my_music_player/features/lyrics/presentation/widgets/lyrics_view.dart';
import 'package:my_music_player/features/player/domain/entities/track.dart';
import 'package:my_music_player/features/player/presentation/providers/device_songs_provider.dart';
import 'package:my_music_player/features/player/presentation/providers/player_controller.dart';
import 'package:my_music_player/features/player/presentation/screens/player_screen.dart';
import 'package:my_music_player/features/search/presentation/providers/search_provider.dart';
import 'package:my_music_player/features/search/presentation/screens/search_screen.dart';
import 'package:my_music_player/features/settings/data/models/app_settings_model.dart';
import 'package:my_music_player/features/settings/presentation/providers/settings_provider.dart';
import 'package:my_music_player/shared/widgets/app_empty_state.dart';
import 'package:my_music_player/shared/widgets/shimmer_loading.dart';

import '../../helpers/pump_app.dart';
import '../../features/player/presentation/providers/fakes.dart';

const _track = Track(
  sourceId: 'state-track',
  title: 'Blinding Lights',
  artist: 'The Weeknd',
  album: 'After Hours',
  durationMs: 200000,
  source: TrackSource.youtube,
);

PlayerState _playerState({String? errorMessage}) {
  return PlayerState(
    currentTrack: _track,
    currentQueue: const [_track],
    currentIndex: 0,
    duration: const Duration(seconds: 200),
    errorMessage: errorMessage,
  );
}

class _StubPlayerController extends PlayerController {
  // The real constructor takes five dependencies before `ref`; a super
  // parameter cannot be combined with that explicit invocation.
  // ignore: use_super_parameters
  _StubPlayerController(Ref containerRef, PlayerState initial)
      : super(
          FakeAudioPlayerService(),
          FakeApiService(),
          FakeTrackRepository(),
          FakeCacheDownloadService(),
          containerRef,
        ) {
    state = initial;
  }
}

class _RecordingPlayerController extends _StubPlayerController {
  _RecordingPlayerController(super.ref, super.initial);

  int playCalls = 0;
  Track? playedTrack;
  List<Track>? playedQueue;

  @override
  Future<void> playTrack(Track track, {List<Track>? queue}) async {
    playCalls++;
    playedTrack = track;
    playedQueue = queue;
    state = state.clearError();
  }
}

class _NoopScanController extends DeviceScanController {
  _NoopScanController(super.ref);

  @override
  Future<void> checkPermissionStatus() async {}

  @override
  Future<void> scan() async {}
}

class _PermissionScanController extends DeviceScanController {
  _PermissionScanController(super.ref) {
    state = const DeviceScanState(permissionDenied: true);
  }

  int scans = 0;

  @override
  Future<void> checkPermissionStatus() async {}

  @override
  Future<void> scan() async {
    scans++;
  }
}

Widget _panel(AppStateVariant variant, {String? actionLabel}) {
  return Scaffold(
    body: AppStatePanel(
      variant: variant,
      title: 'Panel title',
      message: 'Panel body message',
      actionLabel: actionLabel,
      onAction: actionLabel == null ? null : () {},
    ),
  );
}

void main() {
  group('AppStatePanel', () {
    for (final variant in AppStateVariant.values) {
      testWidgets('${variant.name} uses the shared panel geometry',
          (tester) async {
        await pumpApp(tester, _panel(variant, actionLabel: 'Try again'));

        final panel = tester.widget<Container>(
          find.byKey(const Key('app-state-panel')),
        );
        final decoration = panel.decoration! as BoxDecoration;
        expect(decoration.color, AppColors.dark.surface);
        expect(decoration.borderRadius, BorderRadius.circular(24));
        expect(
          (decoration.border! as Border).top.color,
          AppColors.dark.border,
        );

        expect(
          tester.getSize(find.byKey(const Key('app-state-panel-circle'))),
          const Size(72, 72),
        );

        if (variant != AppStateVariant.loading) {
          final title = tester.widget<Text>(find.text('Panel title'));
          expect(title.style?.fontSize, 20);
          expect(title.style?.fontWeight, FontWeight.w600);
          expect(title.style?.color, AppColors.dark.textPrimary);

          final body = tester.widget<Text>(find.text('Panel body message'));
          expect(body.style?.fontSize, 14);
          expect(body.style?.color, AppColors.dark.textSecondary);

          final cta = find.widgetWithText(FilledButton, 'Try again');
          expect(cta, findsOneWidget);
          expect(tester.getSize(cta).height, greaterThanOrEqualTo(48));
        }
      });
    }

    testWidgets('CTA is optional', (tester) async {
      await pumpApp(tester, _panel(AppStateVariant.empty));

      expect(find.byType(FilledButton), findsNothing);
      expect(find.text('Panel title'), findsOneWidget);
    });

    testWidgets('all variants survive 360x640 at text scale 2.0',
        (tester) async {
      for (final variant in AppStateVariant.values) {
        await pumpApp(
          tester,
          _panel(variant, actionLabel: 'Try again'),
          textScale: 2.0,
        );

        expect(
          tester.takeException(),
          isNull,
          reason: '${variant.name} overflowed at 200% text scale',
        );
        expect(find.byKey(const Key('app-state-panel')), findsOneWidget);
      }
    });

    testWidgets('light theme resolves panel tokens', (tester) async {
      await pumpApp(
        tester,
        _panel(AppStateVariant.empty),
        themeMode: ThemeMode.light,
      );

      final panel = tester.widget<Container>(
        find.byKey(const Key('app-state-panel')),
      );
      final decoration = panel.decoration! as BoxDecoration;
      expect(decoration.color, AppColors.light.surface);
      expect(
        tester.widget<Text>(find.text('Panel title')).style?.color,
        AppColors.light.textPrimary,
      );
    });
  });

  group('AppErrorState', () {
    final cases = <({String label, Object cause, String code})>[
      (
        label: 'network',
        cause: const NetworkFailure('raw network detail'),
        code: 'ERR-NET-01',
      ),
      (
        label: 'resolver',
        cause: const ResolverFailure('raw resolver detail'),
        code: 'ERR-RES-01',
      ),
      (
        label: 'unknown',
        cause: StateError('raw app detail'),
        code: 'ERR-APP-01',
      ),
    ];

    for (final testCase in cases) {
      testWidgets('maps ${testCase.label} failures to ${testCase.code}',
          (tester) async {
        await pumpApp(
          tester,
          Scaffold(
            body: AppErrorState(
              error: 'Check your connection and try again.',
              cause: testCase.cause,
              onRetry: () {},
            ),
          ),
        );

        expect(find.text(testCase.code), findsOneWidget);
        expect(
            find.text('Check your connection and try again.'), findsOneWidget);
        expect(find.textContaining('raw '), findsNothing);
        expect(find.textContaining('StateError'), findsNothing);
        expect(find.textContaining('Exception'), findsNothing);
        expect(find.widgetWithText(FilledButton, 'Retry'), findsOneWidget);
      });
    }

    testWidgets('explicit code wins over the cause mapping', (tester) async {
      await pumpApp(
        tester,
        Scaffold(
          body: AppErrorState(
            error: 'Offline',
            code: 'ERR-NET-01',
            cause: StateError('ignored'),
            onRetry: () {},
          ),
        ),
      );

      expect(find.text('ERR-NET-01'), findsOneWidget);
      expect(find.text('ERR-APP-01'), findsNothing);
    });

    testWidgets('error panel survives text scale 2.0', (tester) async {
      await pumpApp(
        tester,
        Scaffold(
          body: AppErrorState(
            error: 'Check your connection and try again.',
            cause: const NetworkFailure('raw'),
            onRetry: () {},
          ),
        ),
        textScale: 2.0,
      );

      expect(tester.takeException(), isNull);
      expect(find.text('ERR-NET-01'), findsOneWidget);
    });
  });

  group('AppOfflineBanner', () {
    testWidgets('renders 380x72, r20 and raised surface', (tester) async {
      await pumpApp(
        tester,
        const Scaffold(body: Center(child: AppOfflineBanner())),
        surfaceSize: const Size(420, 400),
      );

      final banner = find.byKey(const Key('app-offline-banner'));
      expect(banner, findsOneWidget);
      expect(tester.getSize(banner), const Size(380, 72));

      final container = tester.widget<Container>(banner);
      final decoration = container.decoration! as BoxDecoration;
      expect(decoration.color, AppColors.dark.raised);
      expect(decoration.borderRadius, BorderRadius.circular(20));
      expect(find.text('You\'re offline'), findsOneWidget);
    });

    testWidgets('home shows the banner only when offline', (tester) async {
      Future<void> pumpHome({required bool online}) async {
        await tester.pumpWidget(const SizedBox.shrink());
        await pumpApp(
          tester,
          ProviderScope(
            overrides: [
              connectivityProvider.overrideWith(
                (ref) => Stream<bool>.value(online),
              ),
              recentlyPlayedProvider.overrideWith((ref) async => <Track>[]),
              moodMixProvider.overrideWith(
                (ref, mood) async => DailyMix(mood: mood),
              ),
              playerControllerProvider.overrideWith(
                (ref) => _StubPlayerController(ref, PlayerState()),
              ),
              appSettingsProvider.overrideWith(
                (ref) => const Stream<AppSettingsModel>.empty(),
              ),
            ],
            child: const HomeScreen(),
          ),
        );
        await tester.pumpAndSettle();
      }

      await pumpHome(online: false);
      expect(find.byKey(const Key('app-offline-banner')), findsOneWidget);

      await pumpHome(online: true);
      expect(find.byKey(const Key('app-offline-banner')), findsNothing);
    });

    testWidgets('library shows the banner only when offline', (tester) async {
      Future<void> pumpLibrary({required bool online}) async {
        await tester.pumpWidget(const SizedBox.shrink());
        await pumpApp(
          tester,
          ProviderScope(
            overrides: [
              connectivityProvider.overrideWith(
                (ref) => Stream<bool>.value(online),
              ),
              allPlaylistsProvider.overrideWith(
                (ref) async => const <Playlist>[],
              ),
              libraryTrackTotalProvider.overrideWith((ref) async => 0),
              deviceSongsProvider.overrideWith((ref) async => const <Track>[]),
              cacheStatsProvider.overrideWith(
                (ref) async => CacheStats(
                  totalCachedTracks: 0,
                  totalCacheSizeBytes: 0,
                  maxCacheSizeBytes: 1024 * 1024,
                  usagePercentage: 0,
                  pinnedTrackIds: const <String>[],
                ),
              ),
            ],
            child: const LibraryScreen(),
          ),
        );
        await tester.pumpAndSettle();
      }

      await pumpLibrary(online: false);
      expect(find.byKey(const Key('app-offline-banner')), findsOneWidget);

      await pumpLibrary(online: true);
      expect(find.byKey(const Key('app-offline-banner')), findsNothing);
    });
  });

  group('screen states', () {
    testWidgets('search offline uses one panel and no banner', (tester) async {
      await pumpApp(
        tester,
        ProviderScope(
          overrides: [
            connectivityProvider.overrideWith(
              (ref) => Stream<bool>.value(false),
            ),
            searchQueryProvider.overrideWith((ref) => ''),
            searchFilterProvider.overrideWith((ref) => 'top'),
            searchResultsProvider.overrideWith((ref) async => <dynamic>[]),
          ],
          child: const SearchScreen(),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('You\'re offline'), findsOneWidget);
      expect(
        find.text('Search is available when connected'),
        findsOneWidget,
      );
      expect(find.byKey(const Key('app-offline-banner')), findsNothing);
    });

    testWidgets('search error hides raw exceptions and shows the code',
        (tester) async {
      await pumpApp(
        tester,
        ProviderScope(
          overrides: [
            connectivityProvider.overrideWith(
              (ref) => Stream<bool>.value(true),
            ),
            searchQueryProvider.overrideWith((ref) => 'daft punk'),
            searchFilterProvider.overrideWith((ref) => 'songs'),
            searchResultsProvider.overrideWith(
              (ref) async => throw StateError('boom-raw-secret'),
            ),
          ],
          child: const SearchScreen(),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('ERR-APP-01'), findsOneWidget);
      expect(find.textContaining('boom-raw-secret'), findsNothing);
      expect(find.widgetWithText(FilledButton, 'Retry'), findsOneWidget);
    });

    testWidgets('device permission shows a panel with a labelled CTA',
        (tester) async {
      late _PermissionScanController controller;
      await pumpApp(
        tester,
        ProviderScope(
          overrides: [
            deviceSongsProvider.overrideWith((ref) async => const <Track>[]),
            deviceScanControllerProvider.overrideWith((ref) {
              controller = _PermissionScanController(ref);
              return controller;
            }),
            playerControllerProvider.overrideWith(
              (ref) => _StubPlayerController(ref, PlayerState()),
            ),
            appSettingsProvider.overrideWith(
              (ref) => const Stream<AppSettingsModel>.empty(),
            ),
          ],
          child: const DeviceSongsScreen(),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Allow access to audio'), findsOneWidget);
      expect(
        find.textContaining('permission to scan audio files'),
        findsOneWidget,
      );
      expect(
        find.text('You can change this in system settings.'),
        findsOneWidget,
      );

      final cta = find.widgetWithText(FilledButton, 'Allow access');
      expect(cta, findsOneWidget);
      expect(tester.getSize(cta).height, greaterThanOrEqualTo(48));

      await tester.tap(cta);
      await tester.pump();
      expect(controller.scans, 1);
      expect(tester.takeException(), isNull);
    });

    testWidgets('device error hides raw exceptions', (tester) async {
      await pumpApp(
        tester,
        ProviderScope(
          overrides: [
            deviceSongsProvider.overrideWith(
              (ref) async => throw StateError('device-raw-secret'),
            ),
            deviceScanControllerProvider.overrideWith(
              (ref) => _NoopScanController(ref),
            ),
            playerControllerProvider.overrideWith(
              (ref) => _StubPlayerController(ref, PlayerState()),
            ),
            appSettingsProvider.overrideWith(
              (ref) => const Stream<AppSettingsModel>.empty(),
            ),
          ],
          child: const DeviceSongsScreen(),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('ERR-APP-01'), findsOneWidget);
      expect(find.textContaining('device-raw-secret'), findsNothing);
    });

    testWidgets('lyrics not found uses the panel and retries once',
        (tester) async {
      var loads = 0;
      await pumpApp(
        tester,
        ProviderScope(
          overrides: [
            appSettingsProvider.overrideWith(
              (ref) => const Stream<AppSettingsModel>.empty(),
            ),
            playerControllerProvider.overrideWith(
              (ref) => _StubPlayerController(ref, _playerState()),
            ),
            currentLyricsProvider.overrideWith((ref) async {
              loads++;
              return Lyrics(
                sourceId: _track.sourceId,
                type: LyricsType.notFound,
              );
            }),
          ],
          child: const Scaffold(body: LyricsView()),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(AppStatePanel), findsOneWidget);
      expect(find.text('No lyrics found'), findsOneWidget);
      expect(
        find.textContaining('Instrumental tracks never show lyrics'),
        findsOneWidget,
      );
      expect(
        find.text('Playback continues without lyrics.'),
        findsOneWidget,
      );

      final before = loads;
      await tester.tap(find.widgetWithText(FilledButton, 'Retry'));
      await tester.pumpAndSettle();
      expect(loads, greaterThan(before));
      expect(tester.takeException(), isNull);
    });

    testWidgets('player playback error shows Retry and plays once',
        (tester) async {
      late _RecordingPlayerController controller;
      await pumpApp(
        tester,
        ProviderScope(
          overrides: [
            appSettingsProvider.overrideWith(
              (ref) => const Stream<AppSettingsModel>.empty(),
            ),
            playerControllerProvider.overrideWith((ref) {
              controller = _RecordingPlayerController(
                ref,
                _playerState(errorMessage: 'raw resolver failure'),
              );
              return controller;
            }),
          ],
          child: const PlayerScreen(),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Playback failed'), findsOneWidget);
      expect(find.text('Couldn\'t resolve the stream.'), findsOneWidget);
      expect(find.textContaining('raw resolver failure'), findsNothing);
      expect(find.byType(SnackBar), findsNothing);

      final retry = find.widgetWithText(FilledButton, 'Retry');
      expect(retry, findsOneWidget);
      expect(tester.getSize(retry).height, greaterThanOrEqualTo(48));

      await tester.ensureVisible(retry);
      await tester.pumpAndSettle();
      await tester.tap(retry);
      await tester.pump();

      expect(controller.playCalls, 1);
      expect(controller.playedTrack, _track);
      expect(controller.playedQueue, const [_track]);
      expect(find.byType(SnackBar), findsNothing);
    });

    testWidgets('player error card survives text scale 2.0', (tester) async {
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
                _playerState(errorMessage: 'raw failure'),
              ),
            ),
          ],
          child: const PlayerScreen(),
        ),
        textScale: 2.0,
      );
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(find.text('Playback failed'), findsOneWidget);
    });
  });

  group('loading skeleton', () {
    testWidgets('tiles follow the final content shape', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.darkTheme,
          home: const Scaffold(body: ShimmerSection(itemCount: 2)),
        ),
      );

      expect(
        tester.getSize(find.byKey(const Key('shimmer-track-artwork')).first),
        const Size(46, 46),
      );
      expect(
        tester.getSize(find.byKey(const Key('shimmer-track-line')).first),
        const Size(180, 10),
      );
      expect(
        tester.getSize(find.byKey(const Key('shimmer-track-subline')).first),
        const Size(120, 8),
      );
    });

    testWidgets('shimmer is static when animations are disabled',
        (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.darkTheme,
          home: const MediaQuery(
            data: MediaQueryData(disableAnimations: true),
            child: Scaffold(body: ShimmerSection(itemCount: 2)),
          ),
        ),
      );

      expect(find.byType(Shimmer), findsNothing);
      expect(find.byType(ShimmerSection), findsOneWidget);

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.darkTheme,
          home: const MediaQuery(
            data: MediaQueryData(disableAnimations: false),
            child: Scaffold(body: ShimmerSection(itemCount: 2)),
          ),
        ),
      );
      await tester.pump();

      expect(find.byType(Shimmer), findsWidgets);
    });
  });
}
