import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:my_music_player/core/constants/enums.dart';
import 'package:my_music_player/core/network/api_service.dart';
import 'package:my_music_player/core/router/app_router.dart';
import 'package:my_music_player/core/theme/app_theme.dart';
import 'package:my_music_player/features/cache/data/datasources/cache_download_service.dart';
import 'package:my_music_player/features/cache/presentation/providers/cache_stats_provider.dart';
import 'package:my_music_player/features/library/data/repositories/playlist_repository_impl.dart';
import 'package:my_music_player/features/library/domain/entities/playlist.dart';
import 'package:my_music_player/features/library/presentation/providers/downloaded_provider.dart';
import 'package:my_music_player/features/library/presentation/providers/playlist_detail_provider.dart';
import 'package:my_music_player/features/library/presentation/providers/playlist_provider.dart';
import 'package:my_music_player/features/library/presentation/screens/library_screen.dart';
import 'package:my_music_player/features/library/presentation/screens/playlists_screen.dart';
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
import 'package:my_music_player/shared/widgets/playlist_mosaic_cover.dart';

import '../../helpers/pump_app.dart';
import '../player/presentation/providers/fakes.dart';

Track _track(
  String id, {
  int durationMs = 200000,
  bool isPinned = false,
  bool isCached = false,
}) {
  return Track(
    sourceId: id,
    title: 'Track $id',
    artist: 'Artist $id',
    durationMs: durationMs,
    source: TrackSource.local,
    localAudioPath: 'C:/music/$id.mp3',
    isPinned: isPinned,
    isCached: isCached,
  );
}

Playlist _liked({int trackCount = 2, int totalDurationMs = 0}) {
  return Playlist(
    id: -1,
    name: 'Liked Songs',
    isSystem: true,
    trackCount: trackCount,
    totalDurationMs: totalDurationMs,
    createdAt: DateTime(2026, 11, 2),
    updatedAt: DateTime(2026, 11, 2),
  );
}

Playlist _virtual(String name) {
  return Playlist(
    id: -1,
    name: name,
    isSystem: true,
    createdAt: DateTime(2026, 11, 2),
    updatedAt: DateTime(2026, 11, 2),
  );
}

Playlist _playlist(
  int id,
  String name, {
  int trackCount = 0,
  int totalDurationMs = 0,
}) {
  return Playlist(
    id: id,
    name: name,
    trackCount: trackCount,
    totalDurationMs: totalDurationMs,
    thumbnailUrls: const [],
    createdAt: DateTime(2026, 11, 2),
    updatedAt: DateTime(2026, 11, 2),
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
      ];

  List<Override> libraryOverrides({
    required List<Playlist> playlists,
    Map<String, List<Track>> playlistTracks = const {},
    List<Track> device = const [],
    List<Track> downloaded = const [],
    int usedBytes = 0,
    int maxBytes = 2 * 1024 * 1024 * 1024,
  }) {
    return [
      ...baseOverrides(),
      allPlaylistsProvider.overrideWith((ref) async => playlists),
      deviceSongsProvider.overrideWith((ref) async => device),
      downloadedTracksProvider.overrideWith((ref) async => downloaded),
      cacheStatsProvider.overrideWith(
        (ref) async => CacheStats(
          totalCachedTracks: downloaded.length,
          totalCacheSizeBytes: usedBytes,
          maxCacheSizeBytes: maxBytes,
          usagePercentage: maxBytes > 0 ? usedBytes / maxBytes : 0,
          pinnedTrackIds: const [],
        ),
      ),
      playlistTracksProvider.overrideWith(
        (ref, playlist) async => playlistTracks[playlist.name] ?? const [],
      ),
    ];
  }

  Future<ProviderContainer> pumpLibrary(
    WidgetTester tester, {
    List<Override> overrides = const [],
    String location = '/library',
    ThemeMode themeMode = ThemeMode.dark,
    double textScale = 1.0,
  }) async {
    tester.view.devicePixelRatio = 1.0;
    tester.view.physicalSize = const Size(360, 640);
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final container = ProviderContainer(overrides: overrides);
    addTearDown(container.dispose);
    final router = container.read(appRouterProvider);
    addTearDown(router.dispose);
    router.go(location);

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp.router(
          debugShowCheckedModeBanner: false,
          theme: AppTheme.lightTheme,
          darkTheme: AppTheme.darkTheme,
          themeMode: themeMode,
          routerConfig: router,
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

  testWidgets('hub links to Your playlists with count, row and 2-column grid',
      (tester) async {
    final playlists = [
      _liked(trackCount: 2),
      _virtual('Recently Played'),
      _virtual('Downloaded'),
      _playlist(
        1,
        'Late Night Drive',
        trackCount: 3,
        totalDurationMs: const Duration(minutes: 9).inMilliseconds,
      ),
      _playlist(2, 'Empty Mix'),
    ];
    final container = await pumpLibrary(
      tester,
      overrides: libraryOverrides(
        playlists: playlists,
        playlistTracks: {
          'Liked Songs': [_track('a'), _track('b')],
          'Late Night Drive': [_track('c'), _track('d'), _track('e')],
        },
      ),
    );
    expect(container, isNotNull);

    expect(find.text('Your Library'), findsOneWidget);
    expect(find.text('5 tracks'), findsOneWidget);

    await tester.tap(find.text('Custom playlists'));
    await tester.pumpAndSettle();

    expect(find.byType(PlaylistsScreen), findsOneWidget);
    expect(find.text('Your playlists'), findsOneWidget);
    expect(find.text('2 playlists'), findsOneWidget);
    expect(find.text('New playlist'), findsOneWidget);
    expect(find.text('YOUR PLAYLISTS'), findsOneWidget);
    expect(find.text('Late Night Drive'), findsOneWidget);
    expect(find.text('3 songs · 9 min'), findsOneWidget);
    expect(find.text('Empty Mix'), findsOneWidget);
    expect(find.text('0 songs · 0 min'), findsOneWidget);

    final grid = tester.widget<GridView>(find.byType(GridView));
    final delegate =
        grid.gridDelegate as SliverGridDelegateWithFixedCrossAxisCount;
    expect(delegate.crossAxisCount, 2);

    final covers = find.descendant(
      of: find.byType(PlaylistsScreen),
      matching: find.byType(PlaylistMosaicCover),
    );
    final coverSize = tester.getSize(covers.first);
    expect((coverSize.width - coverSize.height).abs(), lessThan(4));

    await tester.tap(find.byIcon(Icons.arrow_back_ios_new_rounded));
    await tester.pumpAndSettle();
    expect(find.byType(LibraryScreen), findsOneWidget);
  });

  testWidgets('playlist grid formats hours and minutes', (tester) async {
    await pumpLibrary(
      tester,
      location: '/playlists',
      overrides: libraryOverrides(
        playlists: [
          _liked(),
          _playlist(
            1,
            'Long Drive',
            trackCount: 5,
            totalDurationMs:
                const Duration(hours: 1, minutes: 32).inMilliseconds,
          ),
        ],
      ),
    );

    expect(find.text('1 playlist'), findsOneWidget);
    expect(find.text('5 songs · 1 hr 32 min'), findsOneWidget);
  });

  testWidgets('more menu offers New playlist and the row opens the dialog',
      (tester) async {
    await pumpLibrary(
      tester,
      location: '/playlists',
      overrides: libraryOverrides(
        playlists: [_liked(), _playlist(1, 'Focus Flow')],
      ),
    );

    expect(find.byIcon(Icons.more_horiz_rounded), findsOneWidget);
    await tester.tap(find.byIcon(Icons.more_horiz_rounded));
    await tester.pumpAndSettle();
    expect(find.text('New playlist'), findsWidgets);

    await tester.tap(find.text('New playlist').last);
    await tester.pumpAndSettle();
    expect(find.text('New Playlist'), findsOneWidget);
    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();

    await tester.tap(find.widgetWithText(InkWell, 'New playlist').first);
    await tester.pumpAndSettle();
    expect(find.text('New Playlist'), findsOneWidget);
    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();
  });

  testWidgets('hub shows cache usage, recently played and recap links',
      (tester) async {
    await pumpLibrary(
      tester,
      overrides: libraryOverrides(
        playlists: [
          _liked(trackCount: 2),
          _virtual('Recently Played'),
          _virtual('Downloaded'),
        ],
        playlistTracks: {
          'Liked Songs': [_track('a'), _track('b')],
        },
        usedBytes: (1.2 * 1024 * 1024 * 1024).round(),
        maxBytes: 2 * 1024 * 1024 * 1024,
      ),
    );

    expect(find.text('Downloaded cache'), findsOneWidget);
    expect(find.text('1.2 GB / 2 GB'), findsOneWidget);
    expect(find.text('Device songs'), findsOneWidget);
    expect(find.text('Listening recap'), findsOneWidget);
    expect(find.text('Recently played'), findsOneWidget);

    await tester.tap(find.text('Recently played'));
    await tester.pumpAndSettle();
    expect(find.byType(RecentlyPlayedScreen), findsOneWidget);
  });

  testWidgets('header total deduplicates tracks across library sources',
      (tester) async {
    await pumpLibrary(
      tester,
      overrides: libraryOverrides(
        playlists: [
          _liked(trackCount: 2),
          _virtual('Recently Played'),
          _virtual('Downloaded'),
          _playlist(1, 'Focus Flow', trackCount: 2),
        ],
        playlistTracks: {
          'Liked Songs': [_track('a'), _track('b')],
          'Focus Flow': [_track('b'), _track('c')],
        },
        device: [_track('c'), _track('d')],
        downloaded: [_track('d'), _track('e')],
      ),
    );

    expect(find.text('5 tracks'), findsOneWidget);
  });

  testWidgets('hub has no playlist grid and no full playlist list',
      (tester) async {
    await pumpLibrary(
      tester,
      overrides: libraryOverrides(
        playlists: [
          _liked(),
          _virtual('Recently Played'),
          _virtual('Downloaded'),
          _playlist(1, 'Late Night Drive', trackCount: 3),
        ],
      ),
    );

    expect(find.text('Late Night Drive'), findsNothing);
    expect(find.text('PLAYLISTS'), findsNothing);
    expect(find.byType(GridView), findsNothing);
    expect(find.text('Your playlists'), findsNothing);
  });

  testWidgets('pinned section only appears when tracks exist and plays queue',
      (tester) async {
    final container = await pumpLibrary(
      tester,
      overrides: libraryOverrides(
        playlists: [
          _liked(trackCount: 2),
          _virtual('Recently Played'),
          _virtual('Downloaded'),
        ],
        playlistTracks: {
          'Liked Songs': [_track('a'), _track('b')],
        },
        device: [
          _track('pinned-1', isPinned: true, isCached: true),
          _track('pinned-2', isPinned: true, isCached: true),
          _track('local-1'),
        ],
      ),
    );

    expect(find.text('PINNED OFFLINE TRACKS'), findsOneWidget);
    expect(find.text('Track pinned-1'), findsOneWidget);

    await tester.tap(find.text('Track pinned-1'));
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 50)),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 600));

    expect(
      container
          .read(playerControllerProvider)
          .currentQueue
          .map((track) => track.sourceId)
          .toList(),
      ['pinned-1', 'pinned-2'],
    );
  });

  testWidgets('hub omits the pinned header when nothing is pinned',
      (tester) async {
    await pumpLibrary(
      tester,
      overrides: libraryOverrides(
        playlists: [
          _liked(trackCount: 2),
          _virtual('Recently Played'),
          _virtual('Downloaded'),
        ],
        playlistTracks: {
          'Liked Songs': [_track('a'), _track('b')],
        },
        device: [_track('local-1')],
      ),
    );

    expect(find.text('PINNED OFFLINE TRACKS'), findsNothing);
  });

  testWidgets('hub and playlists survive 200% text scale in both themes',
      (tester) async {
    final playlists = [
      _liked(trackCount: 2),
      _virtual('Recently Played'),
      _virtual('Downloaded'),
      _playlist(
        1,
        'Late Night Drive',
        trackCount: 3,
        totalDurationMs: const Duration(minutes: 92).inMilliseconds,
      ),
    ];

    for (final mode in [ThemeMode.dark, ThemeMode.light]) {
      final overrides = libraryOverrides(
        playlists: playlists,
        playlistTracks: {
          'Liked Songs': [_track('a'), _track('b')],
        },
      );

      await pumpApp(
        tester,
        ProviderScope(
          overrides: overrides,
          child: const LibraryScreen(),
        ),
        themeMode: mode,
        textScale: 2.0,
      );
      await tester.pumpAndSettle();
      expect(
        tester.takeException(),
        isNull,
        reason: 'library hub overflowed in $mode at 200% text scale',
      );

      await pumpApp(
        tester,
        ProviderScope(
          overrides: overrides,
          child: const PlaylistsScreen(),
        ),
        themeMode: mode,
        textScale: 2.0,
      );
      await tester.pumpAndSettle();
      expect(
        tester.takeException(),
        isNull,
        reason: 'playlists screen overflowed in $mode at 200% text scale',
      );
    }

    final scaffold = tester.widget<Scaffold>(
      find.descendant(
        of: find.byType(PlaylistsScreen),
        matching: find.byType(Scaffold),
      ),
    );
    expect(scaffold.backgroundColor, Colors.transparent);
  });
}
