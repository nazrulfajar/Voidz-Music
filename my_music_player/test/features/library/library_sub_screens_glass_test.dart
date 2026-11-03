import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:my_music_player/core/constants/enums.dart';
import 'package:my_music_player/core/network/api_service.dart';
import 'package:my_music_player/core/theme/app_glass.dart';
import 'package:my_music_player/features/cache/data/datasources/cache_download_service.dart';
import 'package:my_music_player/features/library/data/repositories/playlist_repository_impl.dart';
import 'package:my_music_player/features/library/domain/entities/playlist.dart';
import 'package:my_music_player/features/library/presentation/providers/downloaded_provider.dart';
import 'package:my_music_player/features/library/presentation/providers/playlist_detail_provider.dart';
import 'package:my_music_player/features/library/presentation/providers/playlist_provider.dart';
import 'package:my_music_player/features/library/presentation/screens/device_songs_screen.dart';
import 'package:my_music_player/features/library/presentation/screens/downloaded_screen.dart';
import 'package:my_music_player/features/library/presentation/screens/playlist_detail_screen.dart';
import 'package:my_music_player/features/library/presentation/screens/playlists_screen.dart';
import 'package:my_music_player/features/library/presentation/screens/recently_played_screen.dart';
import 'package:my_music_player/features/player/data/datasources/audio_player_service.dart';
import 'package:my_music_player/features/player/data/repositories/queue_repository.dart';
import 'package:my_music_player/features/player/data/repositories/track_repository_impl.dart';
import 'package:my_music_player/features/player/domain/entities/track.dart';
import 'package:my_music_player/features/player/presentation/providers/device_songs_provider.dart';
import 'package:my_music_player/features/settings/data/models/app_settings_model.dart';
import 'package:my_music_player/features/settings/presentation/providers/settings_provider.dart';
import 'package:my_music_player/shared/widgets/glass_surface.dart';

import '../../helpers/pump_app.dart';
import '../player/presentation/providers/fakes.dart';

Track _track(String id, {bool cached = false}) {
  return Track(
    sourceId: id,
    title: 'Track $id',
    artist: 'Artist $id',
    album: 'Album $id',
    durationMs: 200000,
    source: TrackSource.local,
    localAudioPath: 'C:/music/$id.mp3',
    fileSizeBytes: 2 * 1024 * 1024,
    isCached: cached,
  );
}

Playlist _playlist(int id) {
  return Playlist(
    id: id,
    name: 'Focus Flow',
    trackCount: 2,
    createdAt: DateTime(2026, 11, 3),
    updatedAt: DateTime(2026, 11, 3),
  );
}

void main() {
  late FakeAudioPlayerService audio;
  late FakePlaylistRepository repo;

  setUp(() {
    audio = FakeAudioPlayerService();
    repo = FakePlaylistRepository();
  });

  tearDown(() async {
    await audio.disposeFake();
  });

  List<Override> baseOverrides({
    List<Track> device = const [],
    List<Track> downloaded = const [],
    List<Playlist> playlists = const [],
    List<Track> playlistTracks = const [],
  }) {
    return [
      audioPlayerServiceProvider.overrideWithValue(audio),
      apiServiceProvider.overrideWithValue(FakeApiService()),
      trackRepositoryProvider.overrideWithValue(FakeTrackRepository()),
      cacheDownloadServiceProvider.overrideWithValue(
        FakeCacheDownloadService(),
      ),
      queueRepositoryProvider.overrideWithValue(FakeQueueRepository()),
      playlistRepositoryProvider.overrideWithValue(repo),
      appSettingsProvider.overrideWith(
        (ref) => Stream.value(AppSettingsModel()),
      ),
      deviceSongsProvider.overrideWith((ref) async => device),
      downloadedTracksProvider.overrideWith((ref) async => downloaded),
      allPlaylistsProvider.overrideWith((ref) async => playlists),
      playlistTracksProvider.overrideWith(
        (ref, playlist) async => playlistTracks,
      ),
    ];
  }

  Future<void> pumpScreen(
    WidgetTester tester,
    Widget screen, {
    required List<Override> overrides,
    double textScale = 1.0,
    bool disableAnimations = false,
  }) async {
    final container = ProviderContainer(overrides: overrides);
    addTearDown(container.dispose);

    Widget child = screen;
    if (disableAnimations) {
      child = Builder(
        builder: (context) => MediaQuery(
          data: MediaQuery.of(context).copyWith(disableAnimations: true),
          child: screen,
        ),
      );
    }

    await pumpApp(
      tester,
      UncontrolledProviderScope(container: container, child: child),
      textScale: textScale,
    );
    await tester.pumpAndSettle();
  }

  void expectTransparentScaffold(WidgetTester tester) {
    expect(
      tester.widget<Scaffold>(find.byType(Scaffold).first).backgroundColor,
      Colors.transparent,
    );
  }

  testWidgets('device songs uses a blurred search field and frosted rows',
      (tester) async {
    await pumpScreen(
      tester,
      const DeviceSongsScreen(),
      overrides: baseOverrides(device: [_track('a'), _track('b')]),
    );

    expectTransparentScaffold(tester);

    final field = find.byKey(const Key('device-songs-search-glass'));
    expect(field, findsOneWidget);
    expect(tester.widget<GlassSurface>(field).quality, GlassQuality.blurred);
    expect(
      find.descendant(of: field, matching: find.byType(BackdropFilter)),
      findsOneWidget,
    );

    final row = find.byKey(const ValueKey('device-song-glass-a'));
    expect(row, findsOneWidget);
    expect(tester.widget<GlassSurface>(row).quality, GlassQuality.frosted);
    expect(
      find.descendant(of: row, matching: find.byType(BackdropFilter)),
      findsNothing,
    );

    final chips = find.byType(ChoiceChip);
    expect(chips, findsNWidgets(3));
    final selected = tester.widget<ChoiceChip>(chips.first);
    expect(selected.selected, isTrue);
    expect(selected.selectedColor, AppGlass.dark.chipSelectedFill);
    final subtle = tester.widget<ChoiceChip>(chips.at(1));
    expect(subtle.selected, isFalse);
    expect(subtle.backgroundColor, AppGlass.dark.chipSubtleFill);

    // Cap: one blurred layer on the screen.
    expect(find.byType(BackdropFilter), findsOneWidget);
  });

  testWidgets('downloaded storage summary is the only blur layer',
      (tester) async {
    await pumpScreen(
      tester,
      const DownloadedScreen(),
      overrides: baseOverrides(downloaded: [_track('a', cached: true)]),
    );

    expectTransparentScaffold(tester);

    final storage = find.byKey(const Key('downloaded-storage-glass'));
    expect(storage, findsOneWidget);
    expect(tester.widget<GlassSurface>(storage).quality, GlassQuality.blurred);
    expect(
      find.descendant(of: storage, matching: find.byType(BackdropFilter)),
      findsOneWidget,
    );

    final row = find.byKey(const ValueKey('downloaded-row-glass-a'));
    expect(row, findsOneWidget);
    expect(tester.widget<GlassSurface>(row).quality, GlassQuality.frosted);
    expect(
      find.descendant(of: row, matching: find.byType(BackdropFilter)),
      findsNothing,
    );
    expect(find.byType(BackdropFilter), findsOneWidget);
  });

  testWidgets('playlists cards are frosted and never blur', (tester) async {
    await pumpScreen(
      tester,
      const PlaylistsScreen(),
      overrides: baseOverrides(playlists: [_playlist(1)]),
    );

    expectTransparentScaffold(tester);

    final newRow = find.byKey(const Key('playlists-new-glass'));
    expect(newRow, findsOneWidget);
    expect(tester.widget<GlassSurface>(newRow).quality, GlassQuality.frosted);

    final card = find.byKey(const ValueKey('playlists-card-glass-1'));
    expect(card, findsOneWidget);
    expect(tester.widget<GlassSurface>(card).quality, GlassQuality.frosted);

    expect(find.byType(BackdropFilter), findsNothing);
  });

  testWidgets('playlist detail keeps the scrolling surface frosted',
      (tester) async {
    await pumpScreen(
      tester,
      PlaylistDetailScreen(playlist: _playlist(7)),
      overrides: baseOverrides(
        playlistTracks: [_track('a'), _track('b')],
      ),
    );

    expectTransparentScaffold(tester);

    final summary = find.byKey(const Key('playlist-summary'));
    expect(summary, findsOneWidget);
    expect(tester.widget<GlassSurface>(summary).quality, GlassQuality.frosted);

    final rowMaterial = find.byKey(const ValueKey('playlist-track-a'));
    expect(rowMaterial, findsOneWidget);
    final rowGlass = find.ancestor(
      of: rowMaterial,
      matching: find.byType(GlassSurface),
    );
    expect(rowGlass, findsOneWidget);
    expect(tester.widget<GlassSurface>(rowGlass).quality, GlassQuality.frosted);

    expect(find.byType(BackdropFilter), findsNothing);
  });

  testWidgets('recently played summary blurs and rows stay frosted',
      (tester) async {
    repo
      ..recentTracks = [_track('a'), _track('b')]
      ..recentCount = 2;

    await pumpScreen(
      tester,
      const RecentlyPlayedScreen(),
      overrides: baseOverrides(),
    );

    expectTransparentScaffold(tester);

    final summary = find.byKey(const Key('recently-played-summary-glass'));
    expect(summary, findsOneWidget);
    expect(tester.widget<GlassSurface>(summary).quality, GlassQuality.blurred);
    expect(
      find.descendant(of: summary, matching: find.byType(BackdropFilter)),
      findsOneWidget,
    );

    final row = find.byKey(const ValueKey('recently-played-row-glass-a'));
    expect(row, findsOneWidget);
    expect(tester.widget<GlassSurface>(row).quality, GlassQuality.frosted);
    expect(
      find.descendant(of: row, matching: find.byType(BackdropFilter)),
      findsNothing,
    );
    expect(find.byType(BackdropFilter), findsOneWidget);
  });

  testWidgets('disableAnimations removes the device songs blur',
      (tester) async {
    await pumpScreen(
      tester,
      const DeviceSongsScreen(),
      overrides: baseOverrides(device: [_track('a')]),
      disableAnimations: true,
    );
    expect(find.byType(BackdropFilter), findsNothing);
    expect(
      find.byKey(const Key('device-songs-search-glass')),
      findsOneWidget,
    );
  });

  testWidgets('disableAnimations removes the downloaded blur', (tester) async {
    await pumpScreen(
      tester,
      const DownloadedScreen(),
      overrides: baseOverrides(downloaded: [_track('a', cached: true)]),
      disableAnimations: true,
    );
    expect(find.byType(BackdropFilter), findsNothing);
    expect(find.byKey(const Key('downloaded-storage-glass')), findsOneWidget);
  });

  testWidgets('disableAnimations removes the recently played blur',
      (tester) async {
    repo
      ..recentTracks = [_track('a')]
      ..recentCount = 1;
    await pumpScreen(
      tester,
      const RecentlyPlayedScreen(),
      overrides: baseOverrides(),
      disableAnimations: true,
    );
    expect(find.byType(BackdropFilter), findsNothing);
    expect(
      find.byKey(const Key('recently-played-summary-glass')),
      findsOneWidget,
    );
  });

  testWidgets('device songs survives 200% text scale', (tester) async {
    await pumpScreen(
      tester,
      const DeviceSongsScreen(),
      overrides: baseOverrides(device: [_track('a')]),
      textScale: 2.0,
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('downloaded survives 200% text scale', (tester) async {
    await pumpScreen(
      tester,
      const DownloadedScreen(),
      overrides: baseOverrides(downloaded: [_track('a', cached: true)]),
      textScale: 2.0,
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('playlists survives 200% text scale', (tester) async {
    await pumpScreen(
      tester,
      const PlaylistsScreen(),
      overrides: baseOverrides(playlists: [_playlist(1)]),
      textScale: 2.0,
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('playlist detail survives 200% text scale', (tester) async {
    await pumpScreen(
      tester,
      PlaylistDetailScreen(playlist: _playlist(7)),
      overrides: baseOverrides(playlistTracks: [_track('a')]),
      textScale: 2.0,
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('recently played survives 200% text scale', (tester) async {
    repo
      ..recentTracks = [_track('a')]
      ..recentCount = 1;
    await pumpScreen(
      tester,
      const RecentlyPlayedScreen(),
      overrides: baseOverrides(),
      textScale: 2.0,
    );
    expect(tester.takeException(), isNull);
  });
}
