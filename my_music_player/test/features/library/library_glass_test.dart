import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:my_music_player/core/constants/enums.dart';
import 'package:my_music_player/core/network/api_service.dart';
import 'package:my_music_player/core/providers/connectivity_provider.dart';
import 'package:my_music_player/core/theme/app_colors.dart';
import 'package:my_music_player/core/theme/app_glass.dart';
import 'package:my_music_player/features/cache/data/datasources/cache_download_service.dart';
import 'package:my_music_player/features/cache/presentation/providers/cache_stats_provider.dart';
import 'package:my_music_player/features/library/data/repositories/playlist_repository_impl.dart';
import 'package:my_music_player/features/library/domain/entities/playlist.dart';
import 'package:my_music_player/features/library/presentation/providers/playlist_provider.dart';
import 'package:my_music_player/features/library/presentation/screens/library_screen.dart';
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

Playlist _virtual(String name, {int trackCount = 0}) {
  return Playlist(
    id: -1,
    name: name,
    isSystem: true,
    trackCount: trackCount,
    createdAt: DateTime(2026, 11, 3),
    updatedAt: DateTime(2026, 11, 3),
  );
}

Playlist _playlist(int id, String name, {int trackCount = 0}) {
  return Playlist(
    id: id,
    name: name,
    trackCount: trackCount,
    createdAt: DateTime(2026, 11, 3),
    updatedAt: DateTime(2026, 11, 3),
  );
}

Track _pinnedTrack(String id) {
  return Track(
    sourceId: id,
    title: 'Track $id',
    artist: 'Artist $id',
    durationMs: 200000,
    source: TrackSource.local,
    localAudioPath: 'C:/music/$id.mp3',
    isPinned: true,
  );
}

List<Playlist> _emptyLibrary() => [
      _virtual('Liked Songs'),
      _virtual('Recently Played'),
      _virtual('Downloaded'),
    ];

List<Playlist> _libraryWithData() => [
      _virtual('Liked Songs', trackCount: 2),
      _virtual('Recently Played', trackCount: 1),
      _virtual('Downloaded', trackCount: 1),
      _playlist(1, 'Focus Flow', trackCount: 3),
    ];

List<Override> _overrides({
  required List<Playlist> playlists,
  List<Track> device = const [],
}) {
  return [
    audioPlayerServiceProvider.overrideWithValue(FakeAudioPlayerService()),
    apiServiceProvider.overrideWithValue(FakeApiService()),
    trackRepositoryProvider.overrideWithValue(FakeTrackRepository()),
    cacheDownloadServiceProvider.overrideWithValue(
      FakeCacheDownloadService(),
    ),
    queueRepositoryProvider.overrideWithValue(FakeQueueRepository()),
    playlistRepositoryProvider.overrideWithValue(FakePlaylistRepository()),
    appSettingsProvider.overrideWith(
      (ref) => Stream.value(AppSettingsModel()),
    ),
    connectivityProvider.overrideWith((ref) => Stream.value(true)),
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
        totalCacheSizeBytes: device.isEmpty ? 0 : 1024 * 1024,
        maxCacheSizeBytes: 2 * 1024 * 1024 * 1024,
        usagePercentage: device.isEmpty ? 0 : 0.0005,
        pinnedTrackIds: const [],
      ),
    ),
  ];
}

Future<void> _pumpLibrary(
  WidgetTester tester, {
  required List<Override> overrides,
  double textScale = 1.0,
  bool disableAnimations = false,
}) async {
  final container = ProviderContainer(overrides: overrides);
  addTearDown(container.dispose);

  const screen = LibraryScreen();
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
    UncontrolledProviderScope(
      container: container,
      child: child,
    ),
    textScale: textScale,
  );
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('library hub uses glass cards over the aurora', (tester) async {
    await _pumpLibrary(
      tester,
      overrides: _overrides(
        playlists: _libraryWithData(),
        device: [_pinnedTrack('device-1')],
      ),
    );

    expect(
      tester.widget<Scaffold>(find.byType(Scaffold)).backgroundColor,
      Colors.transparent,
    );

    final likedFinder = find.byKey(const Key('library-liked-glass'));
    expect(
      tester.widget<GlassSurface>(likedFinder).quality,
      GlassQuality.blurred,
    );
    expect(
      find.descendant(
        of: likedFinder,
        matching: find.byType(BackdropFilter),
      ),
      findsOneWidget,
    );
    expect(tester.getSize(likedFinder).height, greaterThanOrEqualTo(104));

    final linkFinder = find.ancestor(
      of: find.text('Downloaded cache'),
      matching: find.byType(GlassSurface),
    );
    expect(linkFinder, findsOneWidget);
    expect(
      tester.widget<GlassSurface>(linkFinder).quality,
      GlassQuality.frosted,
    );
    expect(
      find.descendant(
        of: linkFinder,
        matching: find.byType(BackdropFilter),
      ),
      findsNothing,
    );
    expect(tester.getSize(linkFinder).height, greaterThanOrEqualTo(56));

    final pinnedFinder = find.byKey(
      const ValueKey('library-pinned-glass-device-1'),
    );
    expect(
      tester.widget<GlassSurface>(pinnedFinder).quality,
      GlassQuality.frosted,
    );
    expect(
      find.descendant(
        of: pinnedFinder,
        matching: find.byType(BackdropFilter),
      ),
      findsNothing,
    );
    expect(tester.getSize(pinnedFinder).height, greaterThanOrEqualTo(72));

    final recentFinder = find.byKey(const Key('library-recent-glass'));
    expect(
      tester.widget<GlassSurface>(recentFinder).quality,
      GlassQuality.frosted,
    );
    expect(
      find.descendant(
        of: recentFinder,
        matching: find.byType(BackdropFilter),
      ),
      findsNothing,
    );
    expect(tester.getSize(recentFinder).height, greaterThanOrEqualTo(64));

    final recapFinder = find.ancestor(
      of: find.text('Listening recap'),
      matching: find.byType(GlassSurface),
    );
    expect(recapFinder, findsOneWidget);
    expect(
      tester.widget<GlassSurface>(recapFinder).quality,
      GlassQuality.frosted,
    );

    // The hero Liked card is the only Library glass layer with blur.
    expect(find.byType(BackdropFilter), findsOneWidget);
  });

  testWidgets('first run keeps one CTA on a glass panel', (tester) async {
    await _pumpLibrary(
      tester,
      overrides: _overrides(playlists: _emptyLibrary()),
    );

    expect(
      tester.widget<Scaffold>(find.byType(Scaffold)).backgroundColor,
      Colors.transparent,
    );

    final panelFinder = find.byKey(const Key('app-state-panel'));
    expect(
      tester.widget<GlassSurface>(panelFinder).quality,
      GlassQuality.blurred,
    );
    expect(
      find.descendant(
        of: panelFinder,
        matching: find.byType(BackdropFilter),
      ),
      findsOneWidget,
    );

    expect(find.text('Scan device'), findsOneWidget);
    expect(find.byType(FilledButton), findsOneWidget);
    expect(find.text('Liked Songs'), findsNothing);
    expect(find.text('Downloaded cache'), findsNothing);
    expect(find.text('Recently played'), findsNothing);
    expect(find.text('Listening recap'), findsNothing);

    final cta = tester.getSize(find.byType(FilledButton));
    expect(cta.height, greaterThanOrEqualTo(48));
    expect(cta.width, greaterThanOrEqualTo(48));
  });

  testWidgets('disableAnimations removes every library backdrop filter',
      (tester) async {
    await _pumpLibrary(
      tester,
      overrides: _overrides(
        playlists: _libraryWithData(),
        device: [_pinnedTrack('device-1')],
      ),
      disableAnimations: true,
    );

    expect(find.byType(BackdropFilter), findsNothing);

    final likedFinder = find.byKey(const Key('library-liked-glass'));
    final surface = tester.widget<Container>(
      find
          .descendant(
            of: likedFinder,
            matching: find.byType(Container),
          )
          .first,
    );
    final decoration = surface.decoration! as BoxDecoration;
    expect(
      decoration.color,
      AppGlass.dark.card.frostedFill(AppColors.dark.surface),
    );
    expect(find.text('Liked Songs'), findsOneWidget);
  });

  testWidgets('library glass survives text scale 2.0', (tester) async {
    await _pumpLibrary(
      tester,
      overrides: _overrides(
        playlists: _libraryWithData(),
        device: [_pinnedTrack('device-1')],
      ),
      textScale: 2.0,
    );

    expect(tester.takeException(), isNull);
    expect(find.text('Liked Songs'), findsOneWidget);
    expect(find.byKey(const Key('library-recent-glass')), findsOneWidget);
    expect(
      find.byKey(const ValueKey('library-pinned-glass-device-1')),
      findsOneWidget,
    );
  });
}
