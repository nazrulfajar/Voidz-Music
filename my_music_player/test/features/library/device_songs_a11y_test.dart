import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:my_music_player/core/constants/enums.dart';
import 'package:my_music_player/core/network/api_service.dart';
import 'package:my_music_player/core/theme/app_colors.dart';
import 'package:my_music_player/features/browse/domain/entities/browse_models.dart';
import 'package:my_music_player/features/browse/presentation/providers/browse_provider.dart';
import 'package:my_music_player/features/browse/presentation/screens/album_screen.dart';
import 'package:my_music_player/features/browse/presentation/screens/artist_screen.dart';
import 'package:my_music_player/features/browse/presentation/screens/playlist_screen.dart';
import 'package:my_music_player/features/cache/data/datasources/cache_download_service.dart';
import 'package:my_music_player/features/library/data/repositories/playlist_repository_impl.dart';
import 'package:my_music_player/features/library/presentation/screens/device_songs_screen.dart';
import 'package:my_music_player/features/player/data/datasources/audio_player_service.dart';
import 'package:my_music_player/features/player/data/repositories/queue_repository.dart';
import 'package:my_music_player/features/player/data/repositories/track_repository_impl.dart';
import 'package:my_music_player/features/player/domain/entities/track.dart';
import 'package:my_music_player/features/player/presentation/providers/device_songs_provider.dart';
import 'package:my_music_player/features/settings/data/models/app_settings_model.dart';
import 'package:my_music_player/features/settings/presentation/providers/settings_provider.dart';

import '../../helpers/pump_app.dart';
import '../player/presentation/providers/fakes.dart';

const _tracks = <Track>[
  Track(
    sourceId: 'device-1',
    title: 'Sunset Drive',
    artist: 'Nadia',
    album: 'Night Roads',
    durationMs: 215000,
    source: TrackSource.local,
    localAudioPath: '/music/sunset.mp3',
    fileSizeBytes: 5242880,
    audioFormat: 'mp3',
    bitrateKbps: 320,
    trackNumber: 1,
  ),
  Track(
    sourceId: 'device-2',
    title: 'Morning Light',
    artist: 'Nadia',
    album: 'Night Roads',
    durationMs: 188000,
    source: TrackSource.local,
    localAudioPath: '/music/morning.mp3',
    fileSizeBytes: 4194304,
    audioFormat: 'm4a',
    bitrateKbps: 256,
    trackNumber: 2,
  ),
];

const _album = AlbumDetails(
  browseId: 'album-1',
  title: 'Night Roads',
  artist: 'Nadia',
  year: '2026',
  trackCount: 2,
  tracks: _tracks,
);

const _artist = ArtistDetails(
  browseId: 'artist-1',
  name: 'Nadia',
  subscribers: '1,2 jt subscriber',
  topSongs: _tracks,
);

const _playlist = PlaylistDetails(
  browseId: 'playlist-1',
  title: 'Late Night',
  author: 'Nadia',
  trackCount: 2,
  tracks: _tracks,
);

void main() {
  late FakeAudioPlayerService audio;
  late FakeTrackRepository trackRepo;
  late FakeQueueRepository queueRepo;
  late FakeApiService api;
  late FakePlaylistRepository playlistRepo;
  late FakeCacheDownloadService cacheService;

  setUp(() {
    audio = FakeAudioPlayerService();
    trackRepo = FakeTrackRepository();
    queueRepo = FakeQueueRepository();
    api = FakeApiService();
    playlistRepo = FakePlaylistRepository();
    cacheService = FakeCacheDownloadService();
  });

  List<Override> overrides() => [
        audioPlayerServiceProvider.overrideWithValue(audio),
        apiServiceProvider.overrideWithValue(api),
        trackRepositoryProvider.overrideWithValue(trackRepo),
        cacheDownloadServiceProvider.overrideWithValue(cacheService),
        queueRepositoryProvider.overrideWithValue(queueRepo),
        playlistRepositoryProvider.overrideWithValue(playlistRepo),
        appSettingsProvider.overrideWith(
          (ref) => const Stream<AppSettingsModel>.empty(),
        ),
        deviceSongsProvider.overrideWith((ref) async => _tracks),
        albumDetailsProvider.overrideWith((ref, id) async => _album),
        artistDetailsProvider.overrideWith((ref, id) async => _artist),
        playlistDetailsProvider.overrideWith((ref, id) async => _playlist),
      ];

  Future<void> pumpScreen(
    WidgetTester tester,
    Widget screen, {
    ThemeMode themeMode = ThemeMode.dark,
    double textScale = 1.0,
    Locale locale = const Locale('id'),
  }) async {
    await pumpApp(
      tester,
      ProviderScope(overrides: overrides(), child: screen),
      themeMode: themeMode,
      textScale: textScale,
      locale: locale,
    );
    await tester.pumpAndSettle();
  }

  Future<void> pumpDevice(
    WidgetTester tester, {
    ThemeMode themeMode = ThemeMode.dark,
    double textScale = 1.0,
    Locale locale = const Locale('id'),
  }) {
    return pumpScreen(
      tester,
      const DeviceSongsScreen(),
      themeMode: themeMode,
      textScale: textScale,
      locale: locale,
    );
  }

  testWidgets('scan and track actions expose semantic labels and 48dp targets',
      (tester) async {
    final semantics = tester.ensureSemantics();
    try {
      await pumpDevice(tester);

      expect(find.bySemanticsLabel('Pindai ulang'), findsOneWidget);
      final scan = tester.getSemantics(find.bySemanticsLabel('Pindai ulang'));
      expect(scan.getSemanticsData().flagsCollection.isButton, isTrue);
      expect(scan.getSemanticsData().hasAction(SemanticsAction.tap), isTrue);

      for (final element
          in tester.elementList(find.bySemanticsLabel('Opsi lagu'))) {
        final size =
            tester.getSize(find.byElementPredicate((e) => e == element));
        expect(size.width, greaterThanOrEqualTo(48));
        expect(size.height, greaterThanOrEqualTo(48));
      }
      expect(find.bySemanticsLabel('Opsi lagu'), findsNWidgets(2));

      final scanSize = tester.getSize(find.bySemanticsLabel('Pindai ulang'));
      expect(scanSize.width, greaterThanOrEqualTo(48));
      expect(scanSize.height, greaterThanOrEqualTo(48));
    } finally {
      semantics.dispose();
    }
  });

  testWidgets('English locale localizes header, filters and scan actions',
      (tester) async {
    final semantics = tester.ensureSemantics();
    try {
      await pumpDevice(tester, locale: const Locale('en'));

      expect(find.text('Device songs'), findsOneWidget);
      expect(find.text('Songs • 2'), findsOneWidget);
      expect(find.text('Artists • 1'), findsOneWidget);
      expect(find.text('Albums • 1'), findsOneWidget);
      expect(find.bySemanticsLabel('Rescan'), findsOneWidget);
      expect(find.bySemanticsLabel('Track options'), findsNWidgets(2));
    } finally {
      semantics.dispose();
    }
  });

  testWidgets('drill-down back control is labeled and >= 48dp', (tester) async {
    final semantics = tester.ensureSemantics();
    try {
      await pumpDevice(tester);

      await tester.tap(find.text('Artis • 1'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Nadia').first);
      await tester.pumpAndSettle();

      expect(find.bySemanticsLabel('Kembali'), findsOneWidget);
      final size = tester.getSize(find.bySemanticsLabel('Kembali'));
      expect(size.width, greaterThanOrEqualTo(48));
      expect(size.height, greaterThanOrEqualTo(48));
    } finally {
      semantics.dispose();
    }
  });

  testWidgets('light theme uses the glass scaffold and text tokens',
      (tester) async {
    await pumpDevice(tester, themeMode: ThemeMode.light);

    final scaffold = tester.widget<Scaffold>(find.byType(Scaffold));
    expect(scaffold.backgroundColor, Colors.transparent);

    final heading = tester.widget<Text>(find.text('Lagu perangkat'));
    expect(heading.style?.color, AppColors.light.textPrimary);

    final trackTitle = tester.widget<Text>(find.text('Sunset Drive'));
    expect(trackTitle.style?.color, AppColors.light.textPrimary);

    final trackMeta = tester.widget<Text>(
      find.textContaining('Nadia • Night Roads').first,
    );
    expect(trackMeta.style?.color, AppColors.light.textSecondary);
  });

  testWidgets('renders at 200% text scale without overflow', (tester) async {
    for (final mode in [ThemeMode.dark, ThemeMode.light]) {
      await pumpDevice(tester, themeMode: mode, textScale: 2.0);
      expect(
        tester.takeException(),
        isNull,
        reason: 'device songs overflowed in $mode at 200% text scale',
      );
    }
  });

  final headerCases = <({String name, Widget screen, String heading})>[
    (
      name: 'album',
      screen: const AlbumScreen(albumId: 'album-1'),
      heading: 'Night Roads',
    ),
    (
      name: 'artist',
      screen: const ArtistScreen(artistId: 'artist-1'),
      heading: 'Nadia',
    ),
    (
      name: 'playlist',
      screen: const PlaylistScreen(playlistId: 'playlist-1'),
      heading: 'Late Night',
    ),
  ];

  for (final testCase in headerCases) {
    testWidgets(
        '${testCase.name} header uses tokens and survives 200% text scale',
        (tester) async {
      await pumpScreen(
        tester,
        testCase.screen,
        themeMode: ThemeMode.light,
        textScale: 2.0,
      );

      expect(tester.takeException(), isNull);
      final scaffold = tester.widget<Scaffold>(find.byType(Scaffold));
      expect(scaffold.backgroundColor, AppColors.light.background);

      final heading = tester.widget<Text>(find.text(testCase.heading).first);
      expect(heading.style?.color, AppColors.light.textPrimary);
    });
  }
}
