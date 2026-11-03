import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:my_music_player/core/constants/enums.dart';
import 'package:my_music_player/core/theme/app_colors.dart';
import 'package:my_music_player/core/theme/app_spacing.dart';
import 'package:my_music_player/core/theme/app_theme.dart';
import 'package:my_music_player/features/library/data/repositories/playlist_repository_impl.dart';
import 'package:my_music_player/features/library/domain/entities/playlist.dart';
import 'package:my_music_player/features/library/presentation/providers/playlist_detail_provider.dart';
import 'package:my_music_player/features/library/presentation/screens/playlist_detail_screen.dart';
import 'package:my_music_player/features/player/domain/entities/track.dart';
import 'package:my_music_player/features/player/presentation/providers/player_controller.dart';
import 'package:my_music_player/l10n/app_localizations.dart';

import '../../helpers/pump_app.dart';
import '../player/presentation/providers/fakes.dart';

const _updatedAgo = Duration(days: 2, minutes: 30);

class _RecordingPlaylistRepository extends FakePlaylistRepository {
  int? deletedPlaylistId;
  final List<String> removedTrackIds = [];

  @override
  Future<void> deletePlaylist(int id) async {
    deletedPlaylistId = id;
  }

  @override
  Future<void> removeTrackFromPlaylist(
    int playlistId,
    String trackSourceId,
  ) async {
    removedTrackIds.add(trackSourceId);
  }
}

/// Records the queue without touching just_audio/platform channels.
class _RecordingPlayerController extends PlayerController {
  _RecordingPlayerController(Ref ref, PlayerState initial)
      : super(
          FakeAudioPlayerService(),
          FakeApiService(),
          FakeTrackRepository(),
          FakeCacheDownloadService(),
          ref,
        ) {
    state = initial;
  }

  Track? lastTrack;
  List<Track>? lastQueue;
  int playTrackCalls = 0;

  @override
  Future<void> playTrack(Track track, {List<Track>? queue}) async {
    playTrackCalls++;
    lastTrack = track;
    lastQueue = queue == null ? null : List<Track>.of(queue);
    state = state.copyWith(
      currentTrack: track,
      currentQueue: queue ?? [track],
      currentIndex: 0,
      isPlaying: true,
    );
  }
}

class _Harness {
  _Harness(this.container, this.router, this.repository);

  final ProviderContainer container;
  final GoRouter router;
  final _RecordingPlaylistRepository repository;

  _RecordingPlayerController get player =>
      container.read(playerControllerProvider.notifier)
          as _RecordingPlayerController;
}

Playlist _userPlaylist({int trackCount = 24}) {
  return Playlist(
    id: 7,
    name: 'Late Night Drive',
    trackCount: trackCount,
    createdAt: DateTime.now().subtract(const Duration(days: 10)),
    updatedAt: DateTime.now().subtract(_updatedAgo),
  );
}

Playlist _systemPlaylist({int trackCount = 3}) {
  return Playlist(
    id: -1,
    name: 'Liked Songs',
    isSystem: true,
    trackCount: trackCount,
    createdAt: DateTime.now().subtract(const Duration(days: 10)),
    updatedAt: DateTime.now().subtract(_updatedAgo),
  );
}

List<Track> _tracks({int count = 24, int durationMs = 230000}) {
  return List<Track>.generate(
    count,
    (index) => Track(
      sourceId: 'v$index',
      title: index == 0 ? 'Blinding Lights' : 'Track ${index + 1}',
      artist: 'The Weeknd',
      durationMs: durationMs,
      source: TrackSource.youtube,
    ),
  );
}

Future<_Harness> _pumpDetail(
  WidgetTester tester, {
  required Playlist playlist,
  required List<Track> tracks,
  ThemeMode themeMode = ThemeMode.dark,
  double textScale = 1.0,
  PlayerState? playerState,
  Locale locale = const Locale('en'),
}) async {
  final repository = _RecordingPlaylistRepository();
  final container = ProviderContainer(
    overrides: [
      playlistRepositoryProvider.overrideWithValue(repository),
      playlistTracksProvider.overrideWith((ref, arg) async => tracks),
      playerControllerProvider.overrideWith(
        (ref) => _RecordingPlayerController(ref, playerState ?? PlayerState()),
      ),
    ],
  );
  addTearDown(container.dispose);

  final router = GoRouter(
    initialLocation: '/',
    routes: [
      GoRoute(
        path: '/',
        builder: (context, state) => const Scaffold(
          body: Center(child: Text('Library home')),
        ),
      ),
      GoRoute(
        path: '/detail',
        builder: (context, state) => PlaylistDetailScreen(playlist: playlist),
      ),
      GoRoute(
        path: '/search',
        builder: (context, state) => const Scaffold(
          body: Center(child: Text('Search screen')),
        ),
      ),
    ],
  );
  addTearDown(router.dispose);

  tester.view.devicePixelRatio = 1.0;
  tester.view.physicalSize = kTestSurfaceSize;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);

  await tester.pumpWidget(
    UncontrolledProviderScope(
      container: container,
      child: MaterialApp.router(
        debugShowCheckedModeBanner: false,
        theme: AppTheme.lightTheme,
        darkTheme: AppTheme.darkTheme,
        themeMode: themeMode,
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
  await tester.pump();
  router.push('/detail');
  await tester.pumpAndSettle();

  return _Harness(container, router, repository);
}

void main() {
  testWidgets('summary card shows overline, title, owner and relative meta',
      (tester) async {
    await _pumpDetail(
      tester,
      playlist: _userPlaylist(),
      tracks: _tracks(),
    );

    expect(find.text('PLAYLIST'), findsOneWidget);
    expect(find.text('Late Night Drive'), findsOneWidget);
    expect(find.text('You · 24 songs'), findsOneWidget);
    expect(find.text('1 hr 32 min · updated 2d ago'), findsOneWidget);
    expect(find.byType(BackdropFilter), findsNothing);
  });

  testWidgets('summary card is localized in Indonesian', (tester) async {
    await _pumpDetail(
      tester,
      playlist: _userPlaylist(),
      tracks: _tracks(),
      locale: const Locale('id'),
    );

    expect(find.text('PLAYLIST'), findsOneWidget);
    expect(find.text('Kamu · 24 lagu'), findsOneWidget);
    expect(find.text('1 jam 32 mnt · diperbarui 2h lalu'), findsOneWidget);
    expect(find.text('Putar semua'), findsOneWidget);
  });

  testWidgets('header exposes back and playlist options with 48dp targets',
      (tester) async {
    final semantics = tester.ensureSemantics();
    try {
      await _pumpDetail(
        tester,
        playlist: _userPlaylist(),
        tracks: _tracks(),
      );

      expect(find.text('Playlist'), findsOneWidget);

      final back = find.bySemanticsLabel('Back');
      expect(back, findsOneWidget);
      expect(tester.getSize(back).width, greaterThanOrEqualTo(48));
      expect(tester.getSize(back).height, greaterThanOrEqualTo(48));

      final options = find.bySemanticsLabel('Playlist options');
      expect(options, findsOneWidget);
      expect(tester.getSize(options).width, greaterThanOrEqualTo(48));
      expect(tester.getSize(options).height, greaterThanOrEqualTo(48));
    } finally {
      semantics.dispose();
    }
  });

  testWidgets('play all sends the full playlist as the queue', (tester) async {
    final harness = await _pumpDetail(
      tester,
      playlist: _userPlaylist(),
      tracks: _tracks(),
    );

    await tester.tap(find.text('Play all'));
    await tester.pump();

    expect(harness.player.playTrackCalls, 1);
    expect(harness.player.lastTrack?.sourceId, 'v0');
    expect(harness.player.lastQueue, hasLength(24));
    expect(
      harness.player.lastQueue!.map((track) => track.sourceId),
      List<String>.generate(24, (index) => 'v$index'),
    );
  });

  testWidgets('delete uses the token dialog and removes the playlist',
      (tester) async {
    final harness = await _pumpDetail(
      tester,
      playlist: _userPlaylist(),
      tracks: _tracks(),
    );

    await tester.tap(find.byKey(const Key('playlist-options')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Delete playlist'));
    await tester.pumpAndSettle();

    expect(find.text('Delete Playlist?'), findsOneWidget);
    final dialog = tester.widget<AlertDialog>(find.byType(AlertDialog));
    expect(dialog.backgroundColor, AppColors.dark.row);

    final deleteLabel = tester.widget<Text>(find.text('Delete'));
    expect(deleteLabel.style?.color, AppColors.dark.textPrimary);

    await tester.tap(find.widgetWithText(TextButton, 'Delete'));
    await tester.pumpAndSettle();

    expect(harness.repository.deletedPlaylistId, 7);
    expect(find.text('Library home'), findsOneWidget);
  });

  testWidgets('tracks use 72dp token rows and artist · duration meta',
      (tester) async {
    await _pumpDetail(
      tester,
      playlist: _userPlaylist(),
      tracks: _tracks(),
    );

    expect(find.text('TRACKS'), findsOneWidget);
    expect(find.text('Blinding Lights'), findsOneWidget);
    expect(find.text('The Weeknd · 3:50'), findsWidgets);
    expect(find.byTooltip('Track options'), findsWidgets);

    final row = find.byKey(const ValueKey('playlist-track-v0'));
    expect(row, findsOneWidget);
    expect(tester.getSize(row).height, 72);

    final rowRect = tester.getRect(row);
    expect(rowRect.left, AppSpacing.screenInset);
    expect(
      rowRect.right,
      kTestSurfaceSize.width - AppSpacing.screenInset,
    );
  });

  testWidgets('the playing row uses raised instead of the accent colour',
      (tester) async {
    final tracks = _tracks();
    await _pumpDetail(
      tester,
      playlist: _userPlaylist(),
      tracks: tracks,
      playerState: PlayerState(
        currentTrack: tracks.first,
        currentQueue: tracks,
        currentIndex: 0,
        isPlaying: true,
      ),
    );

    final playing = tester.widget<Material>(
      find.byKey(const ValueKey('playlist-track-v0')),
    );
    expect(playing.color, AppColors.dark.raised);
    expect(playing.color, isNot(AppColors.dark.accent));

    final title = tester.widget<Text>(find.text('Blinding Lights'));
    expect(title.style?.color, AppColors.dark.textPrimary);
  });

  testWidgets('user rows expose remove through the options menu',
      (tester) async {
    final harness = await _pumpDetail(
      tester,
      playlist: _userPlaylist(),
      tracks: _tracks(),
    );

    await tester.tap(find.byKey(const ValueKey('track-options-v0')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Remove from playlist'));
    await tester.pumpAndSettle();

    expect(harness.repository.removedTrackIds, ['v0']);
  });

  testWidgets('system auto-playlist has no fake owner, updated or reorder',
      (tester) async {
    await _pumpDetail(
      tester,
      playlist: _systemPlaylist(),
      tracks: _tracks(count: 3, durationMs: 200000),
    );

    expect(find.text('AUTO-PLAYLIST'), findsOneWidget);
    expect(find.text('Liked Songs'), findsOneWidget);
    expect(find.text('3 songs'), findsOneWidget);
    expect(find.text('10 min'), findsOneWidget);
    expect(find.textContaining('updated'), findsNothing);
    expect(find.textContaining('You ·'), findsNothing);
    expect(find.byType(ReorderableListView), findsNothing);
    expect(find.byType(SliverReorderableList), findsNothing);

    await tester.tap(find.byKey(const ValueKey('track-options-v0')));
    await tester.pumpAndSettle();
    expect(find.text('Remove from playlist'), findsNothing);
  });

  testWidgets('empty playlist shows AppEmptyState with a search action',
      (tester) async {
    await _pumpDetail(
      tester,
      playlist: _userPlaylist(trackCount: 0),
      tracks: const [],
    );

    expect(find.text('0 min'), findsOneWidget);
    expect(find.text('Playlist is empty'), findsOneWidget);
    expect(find.text('Search music'), findsOneWidget);

    await tester.ensureVisible(find.text('Search music'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Search music'));
    await tester.pumpAndSettle();
    expect(find.text('Search screen'), findsOneWidget);
  });

  testWidgets('screen survives text scale 2.0 without overflow',
      (tester) async {
    await _pumpDetail(
      tester,
      playlist: _userPlaylist(),
      tracks: _tracks(),
      textScale: 2.0,
    );

    expect(find.text('Late Night Drive'), findsOneWidget);
    expect(find.text('You · 24 songs'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
