import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:just_audio/just_audio.dart';
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
import 'package:my_music_player/features/settings/data/models/app_settings_model.dart';
import 'package:my_music_player/features/settings/presentation/providers/settings_provider.dart';

import 'fakes.dart';

Track _track(String id) {
  return Track(
    sourceId: id,
    title: 'Track $id',
    durationMs: 1000,
    source: TrackSource.local,
    localAudioPath: 'C:/music/$id.mp3',
    isCached: true,
  );
}

List<String> _ids(Iterable<Track> tracks) {
  return tracks.map((track) => track.sourceId).toList();
}

void main() {
  late FakeAudioPlayerService audio;
  late FakeTrackRepository trackRepo;
  late FakeQueueRepository queueRepo;
  late FakeApiService api;
  late FakePlaylistRepository playlistRepo;
  late FakeCacheDownloadService cacheService;
  late ProviderContainer container;
  late PlayerController controller;

  setUp(() {
    audio = FakeAudioPlayerService();
    trackRepo = FakeTrackRepository();
    queueRepo = FakeQueueRepository();
    api = FakeApiService();
    playlistRepo = FakePlaylistRepository();
    cacheService = FakeCacheDownloadService();

    container = ProviderContainer(
      overrides: [
        audioPlayerServiceProvider.overrideWithValue(audio),
        apiServiceProvider.overrideWithValue(api),
        trackRepositoryProvider.overrideWithValue(trackRepo),
        cacheDownloadServiceProvider.overrideWithValue(cacheService),
        queueRepositoryProvider.overrideWithValue(queueRepo),
        playlistRepositoryProvider.overrideWithValue(playlistRepo),
        appSettingsProvider.overrideWith(
          (ref) => const Stream<AppSettingsModel>.empty(),
        ),
      ],
    );
    controller = container.read(playerControllerProvider.notifier);
  });

  tearDown(() async {
    container.dispose();
    await audio.disposeFake();
  });

  Future<void> seedQueue({
    required List<Track> tracks,
    required String? currentId,
    List<String>? playOrder,
    bool shuffle = false,
    RepeatMode repeat = RepeatMode.off,
    Set<String> autoIds = const {},
  }) async {
    for (final track in tracks) {
      trackRepo.tracks[track.sourceId] = track;
    }

    final order = playOrder ?? tracks.map((track) => track.sourceId).toList();
    queueRepo.items = [
      for (var position = 0; position < order.length; position++)
        QueueItemModel()
          ..queueStateId = 1
          ..trackId = order[position]
          ..originalIndex = tracks.indexWhere(
            (track) => track.sourceId == order[position],
          )
          ..shuffledIndex = shuffle ? position : null,
    ];
    queueRepo.state = QueueStateModel()
      ..id = 1
      ..currentTrackId = currentId
      ..currentPositionMs = 0
      ..shuffleEnabled = shuffle
      ..repeatMode = repeat
      ..autoQueueIds = autoIds.isEmpty ? null : autoIds.join(',')
      ..updatedAt = DateTime(2026, 1, 1);

    await controller.restoreQueueState();
  }

  Future<void> settle() => pumpEventQueue();

  group('removeFromQueue current (Q8)', () {
    test('advances playback to the next track through skipToQueueItem',
        () async {
      await seedQueue(
        tracks: [_track('a'), _track('b'), _track('c')],
        currentId: 'a',
      );
      expect(_ids(controller.state.currentQueue), ['a', 'b', 'c']);

      final playCallsBefore = audio.playCalls;
      await controller.removeFromQueue(0);
      await settle();

      expect(_ids(controller.state.currentQueue), ['b', 'c']);
      expect(controller.state.currentTrack?.sourceId, 'b');
      expect(controller.state.currentIndex, 0);
      expect(audio.startPlaylistCalls, 2);
      expect(audio.playCalls, playCallsBefore + 1);
    });

    test('stops and clears state when the last entry is removed', () async {
      await seedQueue(tracks: [_track('a')], currentId: 'a');

      await controller.removeFromQueue(0);
      await settle();

      expect(controller.state.currentQueue, isEmpty);
      expect(controller.state.currentTrack, isNull);
      expect(controller.state.currentIndex, -1);
      expect(audio.stopCalls, 1);
      expect(queueRepo.clearCalls, 1);
    });

    test('stops playback but keeps the queue when the last current is removed',
        () async {
      await seedQueue(
        tracks: [_track('a'), _track('b')],
        currentId: 'b',
      );

      await controller.removeFromQueue(1);
      await settle();

      expect(_ids(controller.state.currentQueue), ['a']);
      expect(controller.state.currentTrack, isNull);
      expect(controller.state.currentIndex, -1);
      expect(controller.state.isPlaying, isFalse);
      expect(audio.stopCalls, 1);
      expect(audio.player.sequenceLength, 0);
      expect(queueRepo.clearCalls, 0);
    });

    test('shuffle after stopping keeps no current and does not refill window',
        () async {
      await seedQueue(
        tracks: [_track('a'), _track('b')],
        currentId: 'b',
      );
      await controller.removeFromQueue(1);
      await settle();
      final appendsBefore = audio.appendToPlaylistCalls;

      await controller.toggleShuffle();
      await settle();

      expect(controller.state.currentTrack, isNull);
      expect(controller.state.currentIndex, -1);
      expect(audio.appendToPlaylistCalls, appendsBefore);
      expect(audio.player.sequenceLength, 0);
    });

    test('stops playback when the track after the removed one cannot resolve',
        () async {
      const broken = Track(
        sourceId: 'broken',
        title: 'Broken',
        durationMs: 1000,
        source: TrackSource.local,
      );
      await seedQueue(
        tracks: [_track('a'), broken],
        currentId: 'a',
      );

      await controller.removeFromQueue(0);
      await settle();

      expect(_ids(controller.state.currentQueue), ['broken']);
      expect(controller.state.currentTrack?.sourceId, 'broken');
      expect(controller.state.errorMessage, isNotNull);
      expect(audio.stopCalls, greaterThanOrEqualTo(1));
      expect(audio.player.sequenceLength, 0);
    });
  });

  group('shuffle (Q12)', () {
    test('shuffle ON puts current first and OFF restores original order',
        () async {
      await seedQueue(
        tracks: [_track('a'), _track('b'), _track('c')],
        currentId: 'b',
      );

      await controller.toggleShuffle();
      await settle();

      expect(controller.state.isShuffleEnabled, isTrue);
      expect(controller.state.currentTrack?.sourceId, 'b');
      expect(controller.state.currentQueue.first.sourceId, 'b');
      expect(controller.state.currentQueue.length, 3);

      await controller.toggleShuffle();
      await settle();

      expect(controller.state.isShuffleEnabled, isFalse);
      expect(_ids(controller.state.currentQueue), ['a', 'b', 'c']);
      expect(controller.state.currentIndex, 1);
    });

    test('removal while shuffled stays permanent after shuffle OFF', () async {
      await seedQueue(
        tracks: [_track('a'), _track('b'), _track('c')],
        currentId: 'a',
        shuffle: true,
      );

      await controller.removeFromQueue(1);
      await controller.toggleShuffle();
      await settle();

      expect(controller.state.isShuffleEnabled, isFalse);
      expect(_ids(controller.state.currentQueue), ['a', 'c']);
    });

    test('removing an earlier track drops it from the player window', () async {
      await seedQueue(
        tracks: [_track('a'), _track('b'), _track('c')],
        currentId: 'b',
      );
      expect(audio.player.sequenceLength, 3);

      await controller.removeFromQueue(0);
      await settle();

      expect(_ids(controller.state.currentQueue), ['b', 'c']);
      expect(controller.state.currentTrack?.sourceId, 'b');
      expect(controller.state.currentIndex, 0);
      expect(audio.removeFromPlaylistCalls, 1);
      expect(audio.player.sequenceLength, 2);
    });
  });

  group('cap', () {
    test('addAllToQueue never grows the queue beyond 500 entries', () async {
      await seedQueue(tracks: [_track('seed')], currentId: 'seed');
      final many = [for (var i = 0; i < 510; i++) _track('x$i')];

      await controller.addAllToQueue(many);
      await settle();

      expect(controller.state.currentQueue.length, 500);
      expect(controller.state.currentQueue.first.sourceId, 'seed');
    });
  });

  group('restoreQueueState', () {
    test('restores play order, shuffle, repeat, auto origin, and position',
        () async {
      await seedQueue(
        tracks: [_track('a'), _track('b'), _track('c')],
        currentId: 'a',
        playOrder: ['c', 'a', 'b'],
        shuffle: true,
        repeat: RepeatMode.all,
        autoIds: {'c'},
      );

      expect(_ids(controller.state.currentQueue), ['c', 'a', 'b']);
      expect(controller.state.currentIndex, 1);
      expect(controller.state.currentTrack?.sourceId, 'a');
      expect(controller.state.isShuffleEnabled, isTrue);
      expect(controller.state.loopMode, LoopMode.all);
      expect(audio.startPlaylistCalls, 1);
      expect(audio.playCalls, 0);
      expect(audio.player.sequenceLength, 3);
      expect(audio.player.currentIndex, 1);
      expect(audio.lastRepeatMode, LoopMode.all);

      await controller.saveQueueState();

      expect(queueRepo.lastItems?.map((item) => item.trackId), ['c', 'a', 'b']);
      expect(
        queueRepo.lastItems?.every((item) => item.shuffledIndex != null),
        isTrue,
      );
      expect(queueRepo.lastState?.autoQueueIds, 'c');
      expect(queueRepo.lastState?.currentTrackId, 'a');
    });

    test('restores a queue with no current track without starting playback',
        () async {
      await seedQueue(
        tracks: [_track('a'), _track('b')],
        currentId: null,
      );

      expect(_ids(controller.state.currentQueue), ['a', 'b']);
      expect(controller.state.currentIndex, -1);
      expect(controller.state.currentTrack, isNull);
      expect(audio.startPlaylistCalls, 0);
      expect(audio.player.sequenceLength, 0);
    });
  });
}
