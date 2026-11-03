import 'package:flutter_test/flutter_test.dart';
import 'package:my_music_player/core/constants/enums.dart';
import 'package:my_music_player/features/player/data/mappers/queue_snapshot_mapper.dart';
import 'package:my_music_player/features/player/data/models/queue_item_model.dart';
import 'package:my_music_player/features/player/data/models/queue_state_model.dart';
import 'package:my_music_player/features/player/domain/entities/track.dart';
import 'package:my_music_player/features/player/domain/queue/play_entry.dart';
import 'package:my_music_player/features/player/domain/queue/play_queue_snapshot.dart';

Track _track(String id) {
  return Track(
    sourceId: id,
    title: 'Track $id',
    durationMs: 1000,
    source: TrackSource.youtube,
  );
}

PlayEntry _entry(String id, {required int originalIndex, bool auto = false}) {
  return PlayEntry(
    track: _track(id),
    origin: auto ? QueueOrigin.auto : QueueOrigin.user,
    originalIndex: originalIndex,
  );
}

QueueItemModel _item(String id,
    {required int originalIndex, int? shuffledIndex}) {
  return QueueItemModel()
    ..queueStateId = 1
    ..trackId = id
    ..originalIndex = originalIndex
    ..shuffledIndex = shuffledIndex;
}

QueueStateModel _state({
  String? currentTrackId,
  bool shuffleEnabled = false,
  RepeatMode repeatMode = RepeatMode.off,
  String? autoQueueIds,
}) {
  return QueueStateModel()
    ..id = 1
    ..currentTrackId = currentTrackId
    ..shuffleEnabled = shuffleEnabled
    ..repeatMode = repeatMode
    ..autoQueueIds = autoQueueIds
    ..updatedAt = DateTime.utc(2026, 11, 2);
}

void main() {
  group('QueueSnapshotMapper', () {
    test('maps a snapshot to Isar models', () {
      final snapshot = PlayQueueSnapshot(
        entries: [
          _entry('u1', originalIndex: 0),
          _entry('a1', originalIndex: 1, auto: true),
          _entry('u2', originalIndex: 2),
        ],
        currentIndex: 1,
        shuffleEnabled: true,
        repeatMode: RepeatMode.all,
        autoQueueIds: {'a1'},
      );

      final items = QueueSnapshotMapper.toItemModels(snapshot);
      final state = QueueSnapshotMapper.toStateModel(
        snapshot,
        currentPositionMs: 1234,
      );

      expect(items.map((item) => item.trackId), ['u1', 'a1', 'u2']);
      expect(items.map((item) => item.originalIndex), [0, 1, 2]);
      expect(items.map((item) => item.shuffledIndex), [0, 1, 2]);
      expect(state.currentTrackId, 'a1');
      expect(state.currentPositionMs, 1234);
      expect(state.shuffleEnabled, isTrue);
      expect(state.repeatMode, RepeatMode.all);
      expect(state.autoQueueIds, 'a1');
      expect(state.queueSource, 'queue:3');
    });

    test('round-trips a snapshot through the old schema', () {
      final snapshot = PlayQueueSnapshot(
        entries: [
          _entry('u1', originalIndex: 0),
          _entry('a1', originalIndex: 1, auto: true),
          _entry('u2', originalIndex: 2),
        ],
        currentIndex: 2,
        shuffleEnabled: true,
        repeatMode: RepeatMode.one,
        autoQueueIds: {'a1'},
      );
      final tracksById = {
        for (final entry in snapshot.entries) entry.track.sourceId: entry.track,
      };

      final restored = QueueSnapshotMapper.toSnapshot(
        items: QueueSnapshotMapper.toItemModels(snapshot),
        state: QueueSnapshotMapper.toStateModel(
          snapshot,
          currentPositionMs: 0,
        ),
        tracksById: tracksById,
      );

      expect(restored.entries, snapshot.entries);
      expect(restored.currentIndex, 2);
      expect(restored.shuffleEnabled, isTrue);
      expect(restored.repeatMode, RepeatMode.one);
      expect(restored.autoQueueIds, {'a1'});
    });

    test('writes null shuffledIndex when shuffle is off', () {
      final snapshot = PlayQueueSnapshot(
        entries: [_entry('u1', originalIndex: 0)],
        currentIndex: 0,
        shuffleEnabled: false,
        repeatMode: RepeatMode.off,
      );

      final items = QueueSnapshotMapper.toItemModels(snapshot);

      expect(items.single.shuffledIndex, isNull);
    });

    test('falls back to originalIndex for legacy data without shuffledIndex',
        () {
      final items = [
        _item('u2', originalIndex: 2),
        _item('u1', originalIndex: 0),
        _item('u3', originalIndex: 1),
      ];
      final tracksById = {
        for (final id in ['u1', 'u2', 'u3']) id: _track(id),
      };

      final snapshot = QueueSnapshotMapper.toSnapshot(
        items: items,
        state: _state(
          currentTrackId: 'u3',
          shuffleEnabled: true,
        ),
        tracksById: tracksById,
      );

      expect(
        snapshot.entries.map((entry) => entry.track.sourceId),
        ['u1', 'u3', 'u2'],
      );
      expect(snapshot.currentIndex, 1);
    });

    test('skips items whose track is missing', () {
      final items = [
        _item('known', originalIndex: 0),
        _item('missing', originalIndex: 1),
      ];

      final snapshot = QueueSnapshotMapper.toSnapshot(
        items: items,
        state: _state(currentTrackId: 'known'),
        tracksById: {'known': _track('known')},
      );

      expect(snapshot.entries, hasLength(1));
      expect(snapshot.entries.single.track.sourceId, 'known');
      expect(snapshot.currentIndex, 0);
    });

    test('deduplicates repeated track ids from legacy rows', () {
      final items = [
        _item('a', originalIndex: 0),
        _item('b', originalIndex: 1),
        _item('a', originalIndex: 2),
      ];

      final snapshot = QueueSnapshotMapper.toSnapshot(
        items: items,
        state: _state(currentTrackId: 'b'),
        tracksById: {'a': _track('a'), 'b': _track('b')},
      );

      expect(
        snapshot.entries.map((entry) => entry.track.sourceId),
        ['a', 'b'],
      );
      expect(snapshot.currentIndex, 1);
    });

    test('keeps no current entry when the state has no current track id', () {
      final snapshot = QueueSnapshotMapper.toSnapshot(
        items: [
          _item('a', originalIndex: 0),
          _item('b', originalIndex: 1),
        ],
        state: _state(),
        tracksById: {'a': _track('a'), 'b': _track('b')},
      );

      expect(snapshot.currentIndex, -1);
      expect(snapshot.entries, hasLength(2));
    });

    test('round-trips a snapshot with no current entry', () {
      final snapshot = PlayQueueSnapshot(
        entries: [
          _entry('a', originalIndex: 0),
          _entry('b', originalIndex: 1),
        ],
        currentIndex: -1,
        shuffleEnabled: false,
        repeatMode: RepeatMode.off,
      );

      final restored = QueueSnapshotMapper.toSnapshot(
        items: QueueSnapshotMapper.toItemModels(snapshot),
        state: QueueSnapshotMapper.toStateModel(
          snapshot,
          currentPositionMs: 0,
        ),
        tracksById: {
          for (final entry in snapshot.entries)
            entry.track.sourceId: entry.track,
        },
      );

      expect(restored.currentIndex, -1);
      expect(restored.entries, snapshot.entries);
    });

    test('parses and ignores empty auto queue CSV values', () {
      expect(QueueSnapshotMapper.parseAutoQueueIds(null), isEmpty);
      expect(QueueSnapshotMapper.parseAutoQueueIds(''), isEmpty);
      expect(QueueSnapshotMapper.parseAutoQueueIds('a,,b'), {'a', 'b'});
    });
  });
}
