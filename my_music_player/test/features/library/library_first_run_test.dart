import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:my_music_player/core/constants/enums.dart';
import 'package:my_music_player/core/network/api_service.dart';
import 'package:my_music_player/core/providers/connectivity_provider.dart';
import 'package:my_music_player/core/theme/app_theme.dart';
import 'package:my_music_player/features/cache/data/datasources/cache_download_service.dart';
import 'package:my_music_player/features/cache/presentation/providers/cache_stats_provider.dart';
import 'package:my_music_player/features/library/data/repositories/playlist_repository_impl.dart';
import 'package:my_music_player/features/library/domain/entities/playlist.dart';
import 'package:my_music_player/features/library/presentation/providers/playlist_provider.dart';
import 'package:my_music_player/features/library/presentation/screens/device_songs_screen.dart';
import 'package:my_music_player/features/library/presentation/screens/library_screen.dart';
import 'package:my_music_player/features/player/data/datasources/audio_player_service.dart';
import 'package:my_music_player/features/player/data/repositories/queue_repository.dart';
import 'package:my_music_player/features/player/data/repositories/track_repository_impl.dart';
import 'package:my_music_player/features/player/domain/entities/track.dart';
import 'package:my_music_player/features/player/presentation/providers/device_songs_provider.dart';
import 'package:my_music_player/features/settings/data/models/app_settings_model.dart';
import 'package:my_music_player/features/settings/presentation/providers/settings_provider.dart';
import 'package:my_music_player/l10n/app_localizations.dart';

import '../../helpers/pump_app.dart';
import '../player/presentation/providers/fakes.dart';

class _RouteStub extends StatelessWidget {
  const _RouteStub(this.label);

  final String label;

  @override
  Widget build(BuildContext context) {
    return Scaffold(body: Center(child: Text(label)));
  }
}

class _FixedScanController extends DeviceScanController {
  _FixedScanController(super.ref, DeviceScanState initial) {
    state = initial;
  }
}

Playlist _virtual(String name, {int trackCount = 0}) {
  return Playlist(
    id: -1,
    name: name,
    isSystem: true,
    trackCount: trackCount,
    createdAt: DateTime(2026, 11, 2),
    updatedAt: DateTime(2026, 11, 2),
  );
}

Playlist _playlist(int id, String name, {int trackCount = 0}) {
  return Playlist(
    id: id,
    name: name,
    trackCount: trackCount,
    createdAt: DateTime(2026, 11, 2),
    updatedAt: DateTime(2026, 11, 2),
  );
}

Track _track(String id) {
  return Track(
    sourceId: id,
    title: 'Track $id',
    artist: 'Artist $id',
    durationMs: 200000,
    source: TrackSource.local,
    localAudioPath: 'C:/music/$id.mp3',
  );
}

void main() {
  late FakePlaylistRepository playlistRepo;
  late FakeAudioPlayerService audio;
  late FakeTrackRepository tracks;

  setUp(() {
    playlistRepo = FakePlaylistRepository();
    audio = FakeAudioPlayerService();
    tracks = FakeTrackRepository();
  });

  tearDown(() async {
    await audio.disposeFake();
  });

  List<Override> baseOverrides() => [
        audioPlayerServiceProvider.overrideWithValue(audio),
        apiServiceProvider.overrideWithValue(FakeApiService()),
        trackRepositoryProvider.overrideWithValue(tracks),
        cacheDownloadServiceProvider.overrideWithValue(
          FakeCacheDownloadService(),
        ),
        queueRepositoryProvider.overrideWithValue(FakeQueueRepository()),
        playlistRepositoryProvider.overrideWithValue(playlistRepo),
        appSettingsProvider.overrideWith(
          (ref) => const Stream<AppSettingsModel>.empty(),
        ),
        connectivityProvider.overrideWith(
          (ref) => Stream<bool>.value(true),
        ),
      ];

  List<Override> libraryOverrides({
    required List<Playlist> playlists,
    List<Track> device = const [],
    int trackTotal = 0,
    int cachedTracks = 0,
    int usedBytes = 0,
    int maxBytes = 2 * 1024 * 1024 * 1024,
    DevicePermissionStatus permission = DevicePermissionStatus.granted,
  }) {
    return [
      ...baseOverrides(),
      allPlaylistsProvider.overrideWith((ref) async => playlists),
      deviceSongsProvider.overrideWith((ref) async => device),
      libraryTrackTotalProvider.overrideWith((ref) async => trackTotal),
      devicePermissionStatusProvider.overrideWith((ref) async => permission),
      cacheStatsProvider.overrideWith(
        (ref) async => CacheStats(
          totalCachedTracks: cachedTracks,
          totalCacheSizeBytes: usedBytes,
          maxCacheSizeBytes: maxBytes,
          usagePercentage: maxBytes > 0 ? usedBytes / maxBytes : 0,
          pinnedTrackIds: const [],
        ),
      ),
    ];
  }

  Future<ProviderContainer> pumpLibrary(
    WidgetTester tester, {
    required List<Override> overrides,
    double textScale = 1.0,
    Locale? locale,
  }) async {
    tester.view.devicePixelRatio = 1.0;
    tester.view.physicalSize = const Size(360, 640);
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final container = ProviderContainer(overrides: overrides);
    addTearDown(container.dispose);
    final router = GoRouter(
      initialLocation: '/library',
      routes: [
        GoRoute(
          path: '/library',
          builder: (context, state) => const LibraryScreen(),
          routes: [
            GoRoute(
              path: 'device-songs',
              builder: (context, state) =>
                  const _RouteStub('device-songs-route'),
            ),
          ],
        ),
        GoRoute(
          path: '/search',
          builder: (context, state) => const _RouteStub('search-route'),
        ),
      ],
    );
    addTearDown(router.dispose);

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp.router(
          debugShowCheckedModeBanner: false,
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
    );
    await tester.pumpAndSettle();
    return container;
  }

  List<Playlist> emptyLibrary() => [
        _virtual('Liked Songs'),
        _virtual('Recently Played'),
        _virtual('Downloaded'),
      ];

  testWidgets('first run shows one scan CTA and hides empty shelves',
      (tester) async {
    await pumpLibrary(
      tester,
      overrides: libraryOverrides(playlists: emptyLibrary()),
    );

    expect(find.text('Your Library'), findsOneWidget);
    expect(find.text('Scan device'), findsOneWidget);
    expect(find.text('Search music'), findsNothing);
    expect(find.byType(FilledButton), findsOneWidget);
    expect(find.text('0 tracks'), findsNothing);
    expect(find.text('Liked Songs'), findsNothing);
    expect(find.text('Downloaded cache'), findsNothing);
    expect(find.text('Custom playlists'), findsNothing);
    expect(find.text('Device songs'), findsNothing);
    expect(find.text('Recently played'), findsNothing);
    expect(find.text('Listening recap'), findsNothing);

    final cta = tester.getSize(find.byType(FilledButton));
    expect(cta.height, greaterThanOrEqualTo(48));
    expect(cta.width, greaterThanOrEqualTo(48));

    await tester.tap(find.text('Scan device'));
    await tester.pumpAndSettle();
    expect(find.text('device-songs-route'), findsOneWidget);
  });

  testWidgets('first-run CTA and empty copy follow the app locale',
      (tester) async {
    for (final (locale, scanLabel, emptyTitle) in [
      (const Locale('en'), 'Scan device', 'Your library is empty'),
      (const Locale('id'), 'Pindai perangkat', 'Library kamu kosong'),
    ]) {
      await pumpLibrary(
        tester,
        locale: locale,
        overrides: libraryOverrides(playlists: emptyLibrary()),
      );

      expect(
        find.text(emptyTitle),
        findsOneWidget,
        reason: '$locale empty title',
      );
      expect(
        find.text(scanLabel),
        findsOneWidget,
        reason: '$locale scan CTA',
      );
      expect(find.text('Search music'), findsNothing, reason: '$locale');
    }
  });

  testWidgets('permanently denied permission switches the CTA to search',
      (tester) async {
    await pumpLibrary(
      tester,
      overrides: libraryOverrides(
        playlists: emptyLibrary(),
        permission: DevicePermissionStatus.permanentlyDenied,
      ),
    );

    expect(find.text('Search music'), findsOneWidget);
    expect(find.text('Scan device'), findsNothing);
    expect(find.byType(FilledButton), findsOneWidget);

    await tester.tap(find.text('Search music'));
    await tester.pumpAndSettle();
    expect(find.text('search-route'), findsOneWidget);
  });

  testWidgets('non first run keeps the existing library shelves',
      (tester) async {
    await pumpLibrary(
      tester,
      overrides: libraryOverrides(
        playlists: [
          _virtual('Liked Songs', trackCount: 2),
          _virtual('Recently Played', trackCount: 1),
          _virtual('Downloaded', trackCount: 1),
          _playlist(1, 'Focus Flow', trackCount: 3),
        ],
        device: [_track('device-1')],
        trackTotal: 5,
        cachedTracks: 1,
        usedBytes: 1024 * 1024,
      ),
    );

    expect(find.text('Scan device'), findsNothing);
    expect(find.text('Search music'), findsNothing);
    expect(find.text('5 tracks'), findsOneWidget);
    expect(find.text('Liked Songs'), findsOneWidget);
    expect(find.text('Downloaded cache'), findsOneWidget);
    expect(find.text('Custom playlists'), findsOneWidget);
    expect(find.text('Device songs'), findsOneWidget);
    expect(find.text('Recently played'), findsOneWidget);
    expect(find.text('Listening recap'), findsOneWidget);
  });

  testWidgets('library returns to normal when data appears without a flag',
      (tester) async {
    var playlists = emptyLibrary();
    var device = <Track>[];
    final container = await pumpLibrary(
      tester,
      overrides: [
        ...baseOverrides(),
        allPlaylistsProvider.overrideWith((ref) async => playlists),
        deviceSongsProvider.overrideWith((ref) async => device),
        libraryTrackTotalProvider.overrideWith(
          (ref) async => device.isEmpty ? 0 : 5,
        ),
        devicePermissionStatusProvider.overrideWith(
          (ref) async => DevicePermissionStatus.granted,
        ),
        cacheStatsProvider.overrideWith(
          (ref) async => CacheStats(
            totalCachedTracks: device.isEmpty ? 0 : 1,
            totalCacheSizeBytes: 0,
            maxCacheSizeBytes: 2 * 1024 * 1024 * 1024,
            usagePercentage: 0,
            pinnedTrackIds: const [],
          ),
        ),
      ],
    );

    expect(find.text('Scan device'), findsOneWidget);
    expect(find.text('Device songs'), findsNothing);

    playlists = [
      _virtual('Liked Songs', trackCount: 1),
      _virtual('Recently Played', trackCount: 0),
      _virtual('Downloaded', trackCount: 0),
      _playlist(1, 'Focus Flow', trackCount: 1),
    ];
    device = [_track('device-1')];
    container.invalidate(allPlaylistsProvider);
    container.invalidate(deviceSongsProvider);
    await tester.pumpAndSettle();

    expect(find.text('Scan device'), findsNothing);
    expect(find.text('Custom playlists'), findsOneWidget);
    expect(find.text('Device songs'), findsOneWidget);
  });

  testWidgets('first run renders at 200% text scale without overflow',
      (tester) async {
    await pumpLibrary(
      tester,
      overrides: libraryOverrides(playlists: emptyLibrary()),
      textScale: 2.0,
    );

    expect(tester.takeException(), isNull);
    expect(find.text('Scan device'), findsOneWidget);
    expect(find.byType(FilledButton), findsOneWidget);
  });

  group('device songs empty states', () {
    Future<void> pumpDevice(
      WidgetTester tester, {
      required DeviceScanState scanState,
    }) async {
      tester.view.devicePixelRatio = 1.0;
      tester.view.physicalSize = const Size(360, 640);
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final router = GoRouter(
        initialLocation: '/device',
        routes: [
          GoRoute(
            path: '/device',
            builder: (context, state) => const DeviceSongsScreen(),
          ),
          GoRoute(
            path: '/search',
            builder: (context, state) => const _RouteStub('search-route'),
          ),
        ],
      );
      addTearDown(router.dispose);

      await pumpApp(
        tester,
        ProviderScope(
          overrides: [
            ...baseOverrides(),
            deviceSongsProvider.overrideWith((ref) async => const <Track>[]),
            deviceScanControllerProvider.overrideWith(
              (ref) => _FixedScanController(ref, scanState),
            ),
          ],
          child: MaterialApp.router(
            debugShowCheckedModeBanner: false,
            theme: AppTheme.darkTheme,
            routerConfig: router,
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
          ),
        ),
      );
      await tester.pumpAndSettle();
    }

    testWidgets('scan with zero results shows message and search CTA',
        (tester) async {
      await pumpDevice(
        tester,
        scanState: const DeviceScanState(scanCompleted: true),
      );

      expect(find.text('No songs found on device'), findsOneWidget);
      expect(find.text('Search music'), findsOneWidget);

      await tester.tap(find.text('Search music'));
      await tester.pumpAndSettle();
      expect(find.text('search-route'), findsOneWidget);
    });

    testWidgets('denied permission explains and offers settings',
        (tester) async {
      await pumpDevice(
        tester,
        scanState: const DeviceScanState(
          permissionDenied: true,
          permanentlyDenied: true,
        ),
      );

      expect(find.text('Allow access to audio'), findsOneWidget);
      expect(find.text('Open settings'), findsOneWidget);
      expect(
        find.text('You can change this in system settings.'),
        findsOneWidget,
      );
    });
  });
}
