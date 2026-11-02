import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:my_music_player/core/constants/enums.dart';
import 'package:my_music_player/core/network/api_service.dart';
import 'package:my_music_player/features/cache/data/datasources/cache_download_service.dart';
import 'package:my_music_player/features/library/data/repositories/playlist_repository_impl.dart';
import 'package:my_music_player/features/player/data/datasources/audio_player_service.dart';
import 'package:my_music_player/features/player/data/repositories/queue_repository.dart';
import 'package:my_music_player/features/player/data/repositories/track_repository_impl.dart';
import 'package:my_music_player/features/player/domain/entities/track.dart';
import 'package:my_music_player/features/player/presentation/providers/player_controller.dart';
import 'package:my_music_player/features/player/presentation/widgets/queue_view.dart';
import 'package:my_music_player/features/settings/presentation/providers/settings_provider.dart';
import 'package:my_music_player/shared/widgets/app_empty_state.dart';

import '../../helpers/pump_app.dart';
import 'presentation/providers/fakes.dart';

Track _track(String id, {int durationMs = 180000}) {
  return Track(
    sourceId: id,
    title: 'Track $id',
    artist: 'Artist $id',
    durationMs: durationMs,
    source: TrackSource.youtube,
  );
}

/// Real controller shape with in-memory queue mutation so the widget test can
/// assert Clear/swipe effects without Isar or a platform player.
class _TestPlayerController extends PlayerController {
  _TestPlayerController(
    super.audioService,
    super.apiService,
    super.trackRepo,
    super.cacheDownloadService,
    super.ref,
    PlayerState seed,
  ) {
    state = seed;
  }

  final List<int> removedIndices = [];
  final List<(int, int)> reorders = [];
  int dismissCalls = 0;

  @override
  Future<void> removeFromQueue(int index) async {
    removedIndices.add(index);
    final queue = List<Track>.of(state.currentQueue);
    if (index < 0 || index >= queue.length) return;
    final wasCurrent = index == state.currentIndex;
    queue.removeAt(index);
    var newIndex = state.currentIndex;
    if (queue.isEmpty) {
      newIndex = -1;
    } else if (wasCurrent) {
      newIndex = index.clamp(0, queue.length - 1);
    } else if (index < state.currentIndex) {
      newIndex = state.currentIndex - 1;
    }
    state = PlayerState(
      currentTrack: newIndex < 0 ? null : queue[newIndex],
      currentQueue: queue,
      currentIndex: newIndex,
    );
  }

  @override
  Future<void> reorderQueue(int oldIndex, int newIndex) async {
    reorders.add((oldIndex, newIndex));
  }

  @override
  Future<void> dismissPlayer() async {
    dismissCalls++;
  }
}

Future<_TestPlayerController> _pumpQueue(
  WidgetTester tester, {
  List<Track>? tracks,
  int currentIndex = 0,
  ThemeMode themeMode = ThemeMode.dark,
  double textScale = 1.0,
}) async {
  final audio = FakeAudioPlayerService();
  final trackRepo = FakeTrackRepository();
  final queueRepo = FakeQueueRepository();
  final api = FakeApiService();
  final playlistRepo = FakePlaylistRepository();
  final cacheService = FakeCacheDownloadService();
  addTearDown(audio.disposeFake);

  final queue = tracks ?? [_track('a'), _track('b')];
  late _TestPlayerController controller;

  await pumpApp(
    tester,
    ProviderScope(
      overrides: [
        audioPlayerServiceProvider.overrideWithValue(audio),
        apiServiceProvider.overrideWithValue(api),
        trackRepositoryProvider.overrideWithValue(trackRepo),
        cacheDownloadServiceProvider.overrideWithValue(cacheService),
        queueRepositoryProvider.overrideWithValue(queueRepo),
        playlistRepositoryProvider.overrideWithValue(playlistRepo),
        appSettingsProvider.overrideWith((ref) => const Stream.empty()),
        playerControllerProvider.overrideWith((ref) {
          controller = _TestPlayerController(
            audio,
            api,
            trackRepo,
            cacheService,
            ref,
            PlayerState(
              currentTrack: queue.isEmpty ? null : queue[currentIndex],
              currentQueue: queue,
              currentIndex: queue.isEmpty ? -1 : currentIndex,
            ),
          );
          return controller;
        }),
      ],
      child: const Scaffold(body: QueueView()),
    ),
    themeMode: themeMode,
    textScale: textScale,
  );

  return controller;
}

void main() {
  testWidgets('queue header shows count and summed duration', (tester) async {
    await _pumpQueue(
      tester,
      tracks: [_track('a'), _track('b'), _track('c')],
    );

    expect(find.text('Queue'), findsOneWidget);
    expect(find.text('3 songs · 9 min'), findsOneWidget);
    expect(find.text('Clear'), findsOneWidget);
    expect(find.textContaining('Queue ('), findsNothing);
  });

  testWidgets('queue duration uses hours when the queue is long',
      (tester) async {
    await _pumpQueue(
      tester,
      tracks: [
        _track('a', durationMs: 46 * 60 * 1000),
        _track('b', durationMs: 46 * 60 * 1000),
      ],
    );

    expect(find.text('2 songs · 1 hr 32 min'), findsOneWidget);
  });

  testWidgets('clear removes only items after the current track',
      (tester) async {
    final controller = await _pumpQueue(
      tester,
      tracks: [
        _track('a'),
        _track('b'),
        _track('c'),
        _track('d'),
        _track('e'),
      ],
      currentIndex: 2,
    );

    await tester.tap(find.text('Clear'));
    await tester.pumpAndSettle();

    expect(controller.removedIndices, [4, 3]);
    expect(
      controller.state.currentQueue.map((track) => track.title).toList(),
      ['Track a', 'Track b', 'Track c'],
    );
    expect(controller.state.currentTrack?.title, 'Track c');
    expect(controller.dismissCalls, 0);
  });

  testWidgets(
      'sections render current in NOW PLAYING and only later in UP NEXT',
      (tester) async {
    await _pumpQueue(
      tester,
      tracks: [
        _track('a'),
        _track('b'),
        _track('c'),
        _track('d'),
        _track('e'),
      ],
      currentIndex: 2,
    );

    expect(find.text('NOW PLAYING'), findsOneWidget);
    expect(find.text('UP NEXT'), findsOneWidget);
    expect(find.text('2 songs'), findsOneWidget);
    expect(find.text('Track c'), findsOneWidget);
    expect(find.text('Track d'), findsOneWidget);
    expect(find.text('Track e'), findsOneWidget);
    expect(find.text('Track a'), findsNothing);
    expect(find.text('Track b'), findsNothing);
    expect(find.text('Drag to reorder · Swipe to remove'), findsOneWidget);
  });

  testWidgets('now playing uses raised 48 artwork and up next uses 44',
      (tester) async {
    await _pumpQueue(
      tester,
      tracks: [_track('a'), _track('b')],
    );

    final nowPlaying = tester.getSize(
      find.byKey(const Key('queue-now-playing-artwork')),
    );
    expect(nowPlaying, const Size(48, 48));

    final upNext = tester.getSize(
      find.byKey(const Key('queue-up-next-artwork-1')),
    );
    expect(upNext, const Size(44, 44));

    expect(find.byType(BackdropFilter), findsNothing);
  });

  testWidgets('swipe on up next removes the backing queue index',
      (tester) async {
    final controller = await _pumpQueue(
      tester,
      tracks: [_track('a'), _track('b'), _track('c'), _track('d')],
      currentIndex: 1,
    );

    await tester.drag(find.text('Track c'), const Offset(-400, 0));
    await tester.pumpAndSettle();

    expect(controller.removedIndices, [2]);
  });

  testWidgets('reorder maps the up next section back to queue indices',
      (tester) async {
    final controller = await _pumpQueue(
      tester,
      tracks: [_track('a'), _track('b'), _track('c'), _track('d')],
      currentIndex: 1,
    );

    final list = tester.widget<SliverReorderableList>(
      find.byType(SliverReorderableList),
    );
    list.onReorderItem!(0, 1);

    expect(controller.reorders, [(2, 3)]);
  });

  testWidgets('queue handles text scale 2.0 without overflow', (tester) async {
    await _pumpQueue(
      tester,
      tracks: [_track('a'), _track('b'), _track('c')],
      currentIndex: 1,
      textScale: 2.0,
    );

    expect(tester.takeException(), isNull);
    expect(find.text('Queue'), findsOneWidget);
    expect(find.text('NOW PLAYING'), findsOneWidget);
  });

  testWidgets('empty queue uses the shared empty state panel', (tester) async {
    await _pumpQueue(tester, tracks: []);

    expect(find.byType(AppEmptyState), findsOneWidget);
    expect(find.text('Antrean kosong'), findsOneWidget);
  });
}
