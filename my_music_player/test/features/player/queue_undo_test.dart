import 'package:flutter/material.dart' hide RepeatMode;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:my_music_player/core/constants/enums.dart';
import 'package:my_music_player/core/network/api_service.dart';
import 'package:my_music_player/features/cache/data/datasources/cache_download_service.dart';
import 'package:my_music_player/features/library/data/repositories/playlist_repository_impl.dart';
import 'package:my_music_player/features/player/data/datasources/audio_player_service.dart';
import 'package:my_music_player/features/player/data/models/queue_item_model.dart';
import 'package:my_music_player/features/player/data/models/queue_state_model.dart';
import 'package:my_music_player/features/player/data/repositories/queue_repository.dart';
import 'package:my_music_player/features/player/data/repositories/track_repository_impl.dart';
import 'package:my_music_player/features/player/domain/entities/track.dart';
import 'package:my_music_player/features/player/presentation/providers/player_controller.dart';
import 'package:my_music_player/features/player/presentation/widgets/queue_view.dart';
import 'package:my_music_player/features/settings/presentation/providers/settings_provider.dart';
import 'package:my_music_player/shared/widgets/app_list_tile.dart';

import '../../helpers/pump_app.dart';
import 'presentation/providers/fakes.dart';

Track _track(String id) {
  return Track(
    sourceId: id,
    title: 'Track $id',
    artist: 'Artist $id',
    durationMs: 180000,
    source: TrackSource.local,
    localAudioPath: 'C:/music/$id.mp3',
    isCached: true,
  );
}

List<String> _ids(Iterable<Track> tracks) {
  return tracks.map((track) => track.sourceId).toList();
}

/// Seeds the real controller through the persisted queue so clear/undo use the
/// production `PlayQueue` paths (not a state-only test double).
class _QueueHost extends ConsumerStatefulWidget {
  const _QueueHost();

  @override
  ConsumerState<_QueueHost> createState() => _QueueHostState();
}

class _QueueHostState extends ConsumerState<_QueueHost> {
  @override
  void initState() {
    super.initState();
    ref.read(playerControllerProvider.notifier).restoreQueueState();
  }

  @override
  Widget build(BuildContext context) => const QueueView();
}

class _QueueHarness {
  const _QueueHarness(this.controller, this.audio);

  final PlayerController controller;
  final FakeAudioPlayerService audio;
}

Future<_QueueHarness> _pumpQueue(
  WidgetTester tester, {
  required List<Track> tracks,
  required int currentIndex,
  double textScale = 1.0,
}) async {
  final audio = FakeAudioPlayerService();
  final trackRepo = FakeTrackRepository();
  final queueRepo = FakeQueueRepository();
  final api = FakeApiService();
  final playlistRepo = FakePlaylistRepository();
  final cacheService = FakeCacheDownloadService();
  addTearDown(audio.disposeFake);

  for (final track in tracks) {
    trackRepo.tracks[track.sourceId] = track;
  }
  queueRepo.items = [
    for (var position = 0; position < tracks.length; position++)
      QueueItemModel()
        ..queueStateId = 1
        ..trackId = tracks[position].sourceId
        ..originalIndex = position
        ..shuffledIndex = null,
  ];
  queueRepo.state = QueueStateModel()
    ..id = 1
    ..currentTrackId = tracks[currentIndex].sourceId
    ..currentPositionMs = 0
    ..shuffleEnabled = false
    ..repeatMode = RepeatMode.off
    ..updatedAt = DateTime(2026, 1, 1);

  late PlayerController controller;
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
          controller = PlayerController(
            audio,
            api,
            trackRepo,
            cacheService,
            ref,
          );
          return controller;
        }),
      ],
      child: const Scaffold(body: _QueueHost()),
    ),
    textScale: textScale,
  );
  await tester.pumpAndSettle();

  return _QueueHarness(controller, audio);
}

void main() {
  testWidgets('Clear asks for confirmation with the track count',
      (tester) async {
    final harness = await _pumpQueue(
      tester,
      tracks: [_track('a'), _track('b'), _track('c'), _track('d')],
      currentIndex: 1,
    );

    await tester.tap(find.text('Clear'));
    await tester.pumpAndSettle();

    expect(find.text('Clear queue?'), findsOneWidget);
    final dialog = find.byType(AlertDialog);
    expect(
      find.descendant(
        of: dialog,
        matching: find.textContaining('2 songs'),
      ),
      findsOneWidget,
    );
    expect(
      find.descendant(of: dialog, matching: find.byIcon(Icons.delete_outline)),
      findsOneWidget,
      reason: 'the destructive action must be visually marked',
    );

    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();

    expect(find.text('Clear queue?'), findsNothing);
    expect(_ids(harness.controller.state.currentQueue), ['a', 'b', 'c', 'd']);
    expect(harness.controller.state.currentIndex, 1);
    expect(harness.controller.state.currentTrack?.sourceId, 'b');
  });

  testWidgets('Undo restores the exact up-next order without restarting',
      (tester) async {
    final harness = await _pumpQueue(
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
    await harness.audio.player.seek(const Duration(seconds: 42));
    final playCallsBefore = harness.audio.playCalls;
    final startPlaylistCallsBefore = harness.audio.startPlaylistCalls;

    await tester.tap(find.text('Clear'));
    await tester.pumpAndSettle();
    final confirm = find.descendant(
      of: find.byType(AlertDialog),
      matching: find.byType(TextButton),
    );
    await tester.tap(confirm.last);
    await tester.pumpAndSettle();

    expect(_ids(harness.controller.state.currentQueue), ['a', 'b', 'c']);
    expect(harness.controller.state.currentIndex, 2);
    expect(find.text('Undo'), findsOneWidget);

    await tester.tap(find.text('Undo'));
    await tester.pumpAndSettle();

    expect(
      _ids(harness.controller.state.currentQueue),
      ['a', 'b', 'c', 'd', 'e'],
    );
    expect(harness.controller.state.currentIndex, 2);
    expect(harness.controller.state.currentTrack?.sourceId, 'c');
    expect(harness.audio.playCalls, playCallsBefore);
    expect(harness.audio.startPlaylistCalls, startPlaylistCallsBefore);
    expect(harness.audio.player.position, const Duration(seconds: 42));

    await tester.pump(const Duration(seconds: 5));
  });

  testWidgets('Clear is disabled when there is no up-next', (tester) async {
    await _pumpQueue(
      tester,
      tracks: [_track('a'), _track('b')],
      currentIndex: 1,
    );

    final clear = tester.widget<TextButton>(
      find.widgetWithText(TextButton, 'Clear'),
    );
    expect(clear.onPressed, isNull);
  });

  testWidgets('track tile announces now playing with icon and label',
      (tester) async {
    final semantics = tester.ensureSemantics();
    await pumpApp(
      tester,
      const Scaffold(
        body: AppTrackTile(
          title: 'Track a',
          subtitle: 'Artist a',
          isPlaying: true,
          isCached: true,
        ),
      ),
      textScale: 2.0,
    );
    await tester.pumpAndSettle();

    expect(find.text('Now playing'), findsOneWidget);
    expect(find.bySemanticsLabel(RegExp('Now playing')), findsWidgets);
    expect(find.bySemanticsLabel(RegExp('Downloaded')), findsWidgets);
    expect(tester.takeException(), isNull);
    semantics.dispose();
  });

  testWidgets('queue confirmation stays overflow-free at 200% text scale',
      (tester) async {
    await _pumpQueue(
      tester,
      tracks: [_track('a'), _track('b'), _track('c')],
      currentIndex: 0,
      textScale: 2.0,
    );

    await tester.tap(find.text('Clear'));
    await tester.pumpAndSettle();

    expect(find.text('Clear queue?'), findsOneWidget);
    expect(tester.takeException(), isNull);

    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();
  });
}
