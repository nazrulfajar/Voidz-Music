import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:my_music_player/core/constants/enums.dart';
import 'package:my_music_player/features/player/domain/entities/track.dart';
import 'package:my_music_player/features/player/domain/queue/play_entry.dart';
import 'package:my_music_player/features/player/domain/queue/play_queue.dart';
import 'package:my_music_player/features/player/domain/queue/play_queue_snapshot.dart';

Track _track(String id) {
  return Track(
    sourceId: id,
    title: 'Track $id',
    durationMs: 1000,
    source: TrackSource.youtube,
  );
}

List<Track> _tracks(int count) {
  return [for (var i = 0; i < count; i++) _track('t$i')];
}

List<String> _ids(Iterable<Track> tracks) {
  return tracks.map((track) => track.sourceId).toList();
}

PlayEntry _entry(String id, {int originalIndex = 0, bool auto = false}) {
  return PlayEntry(
    track: _track(id),
    origin: auto ? QueueOrigin.auto : QueueOrigin.user,
    originalIndex: originalIndex,
  );
}

void main() {
  group('PlayQueue.start', () {
    test('selects a track that is already in the queue', () {
      final queue = PlayQueue(random: Random(1));
      final tracks = [_track('a'), _track('b'), _track('c')];

      queue.start(tracks[1], queue: tracks);

      expect(_ids(queue.tracks), ['a', 'b', 'c']);
      expect(queue.currentIndex, 1);
      expect(queue.currentTrack?.sourceId, 'b');
      expect(queue.shuffleEnabled, isFalse);
    });

    test('inserts the track at index 0 when it is not in the queue', () {
      final queue = PlayQueue(random: Random(1));

      queue.start(
        _track('d'),
        queue: [_track('a'), _track('b')],
      );

      expect(_ids(queue.tracks), ['d', 'a', 'b']);
      expect(queue.currentIndex, 0);
    });

    test('keeps current first and drops auto entries when shuffle is on', () {
      final queue = PlayQueue(random: Random(1));
      queue.start(_track('a'), queue: [_track('a'), _track('b')]);
      queue.appendAuto([_track('auto')]);
      queue.toggleShuffle();

      queue.start(
        _track('c'),
        queue: [_track('a'), _track('b'), _track('c'), _track('d')],
      );

      expect(queue.tracks.first.sourceId, 'c');
      expect(queue.currentIndex, 0);
      expect(queue.autoQueueIds, isEmpty);
      expect(_ids(queue.tracks).toSet(), {'a', 'b', 'c', 'd'});
    });
  });

  group('PlayQueue cap 500', () {
    test('start trims the oldest non-current entry', () {
      final queue = PlayQueue(random: Random(1));
      final tracks = _tracks(501);

      queue.start(tracks[250], queue: tracks);

      expect(queue.length, PlayQueue.maxEntries);
      expect(queue.currentTrack?.sourceId, 't250');
      expect(queue.tracks.first.sourceId, 't1');
      expect(queue.containsSourceId('t0'), isFalse);
    });

    test('enqueue evicts the oldest auto before touching users', () {
      final queue = PlayQueue(random: Random(1));
      final users = _tracks(499);
      queue.start(users.first, queue: users);
      queue.appendAuto([_track('auto0')]);
      expect(queue.length, PlayQueue.maxEntries);

      queue.enqueue(_track('new-user'));

      expect(queue.length, PlayQueue.maxEntries);
      expect(queue.autoQueueIds, isEmpty);
      expect(queue.containsSourceId('auto0'), isFalse);
      for (final user in users) {
        expect(queue.containsSourceId(user.sourceId), isTrue);
      }
      expect(queue.containsSourceId('new-user'), isTrue);
    });

    test('enqueue play-next under shuffle survives the cap', () {
      final queue = PlayQueue(random: Random(1));
      final users = _tracks(PlayQueue.maxEntries);
      queue.start(users.first, queue: users);
      queue.toggleShuffle();

      queue.enqueue(_track('play-next'), playNext: true);

      expect(queue.length, PlayQueue.maxEntries);
      expect(queue.containsSourceId('play-next'), isTrue);
      expect(queue.currentTrack?.sourceId, 't0');
    });

    test('appendAuto never truncates the user queue', () {
      final queue = PlayQueue(random: Random(1));
      final users = _tracks(PlayQueue.maxEntries);
      queue.start(users.first, queue: users);

      final added = queue.appendAuto(
        [for (var i = 0; i < 10; i++) _track('auto$i')],
      );

      expect(added, 0);
      expect(queue.length, PlayQueue.maxEntries);
      expect(queue.autoQueueIds, isEmpty);
      expect(_ids(queue.tracks), _ids(users));
    });

    test('fromSnapshot enforces the cap after restore', () {
      final entries = [
        for (var i = 0; i < 500; i++) _entry('u$i', originalIndex: i),
        _entry('auto0', originalIndex: 500, auto: true),
      ];
      final snapshot = PlayQueueSnapshot(
        entries: entries,
        currentIndex: 10,
        shuffleEnabled: false,
        repeatMode: RepeatMode.all,
        autoQueueIds: {'auto0'},
      );

      final queue = PlayQueue.fromSnapshot(snapshot, random: Random(1));

      expect(queue.length, PlayQueue.maxEntries);
      expect(queue.currentTrack?.sourceId, 'u10');
      expect(queue.containsSourceId('auto0'), isFalse);
    });
  });

  group('PlayQueue enqueue', () {
    test('dedups an earlier duplicate and keeps the current index correct', () {
      final queue = PlayQueue(random: Random(1));
      queue.start(
        _track('c'),
        queue: [_track('a'), _track('b'), _track('c')],
      );

      final result = queue.enqueue(_track('a'));

      expect(result.inserted, isTrue);
      expect(_ids(queue.tracks), ['b', 'c', 'a']);
      expect(queue.currentIndex, 1);
      expect(queue.currentTrack?.sourceId, 'c');
    });

    test('playNext inserts directly after the current track', () {
      final queue = PlayQueue(random: Random(1));
      queue.start(
        _track('b'),
        queue: [_track('a'), _track('b'), _track('c')],
      );

      final result = queue.enqueue(_track('d'), playNext: true);

      expect(result.insertIndex, 2);
      expect(_ids(queue.tracks), ['a', 'b', 'd', 'c']);
      expect(queue.currentIndex, 1);
    });

    test('enqueueAll keeps order for append and playNext', () {
      final append = PlayQueue(random: Random(1));
      append.enqueueAll([_track('a'), _track('b'), _track('c')]);
      expect(_ids(append.tracks), ['a', 'b', 'c']);

      final playNext = PlayQueue(random: Random(1));
      playNext.start(_track('a'), queue: [_track('a'), _track('b')]);
      playNext.enqueueAll([_track('c'), _track('d')], playNext: true);
      expect(_ids(playNext.tracks), ['a', 'c', 'd', 'b']);
    });
  });

  group('PlayQueue toggleShuffle', () {
    test('enabling keeps current first, drops auto, and shuffles users', () {
      final queue = PlayQueue(random: Random(1));
      queue.start(
        _track('b'),
        queue: [_track('a'), _track('b'), _track('c'), _track('d')],
      );
      queue.appendAuto([_track('auto1'), _track('auto2')]);

      final enabled = queue.toggleShuffle();

      expect(enabled, isTrue);
      expect(queue.currentIndex, 0);
      expect(queue.tracks.first.sourceId, 'b');
      expect(_ids(queue.tracks).toSet(), {'a', 'b', 'c', 'd'});
      expect(queue.autoQueueIds, isEmpty);
    });

    test('disabling restores originalIndex order and keeps current', () {
      final queue = PlayQueue(random: Random(1));
      queue.start(
        _track('b'),
        queue: [_track('a'), _track('b'), _track('c'), _track('d')],
      );
      queue.toggleShuffle();

      final enabled = queue.toggleShuffle();

      expect(enabled, isFalse);
      expect(_ids(queue.tracks), ['a', 'b', 'c', 'd']);
      expect(queue.currentTrack?.sourceId, 'b');
      expect(queue.currentIndex, 1);
    });

    test('keeps a current auto entry at the front when disabling', () {
      final queue = PlayQueue(random: Random(1));
      queue.start(
        _track('a'),
        queue: [_track('a'), _track('b'), _track('c')],
      );
      queue.appendAuto([_track('auto0')]);
      queue.select(queue.indexOfSourceId('auto0'));
      queue.toggleShuffle();

      final enabled = queue.toggleShuffle();

      expect(enabled, isFalse);
      expect(_ids(queue.tracks), ['auto0', 'a', 'b', 'c']);
      expect(queue.currentIndex, 0);
      expect(queue.currentTrack?.sourceId, 'auto0');
    });
  });

  group('PlayQueue reorder and removeAt', () {
    test('reorder forward adjusts the current index', () {
      final queue = PlayQueue(random: Random(1));
      queue.start(
        _track('b'),
        queue: [_track('a'), _track('b'), _track('c'), _track('d')],
      );

      final result = queue.reorder(0, 3);

      expect(result?.toIndex, 2);
      expect(_ids(queue.tracks), ['b', 'c', 'a', 'd']);
      expect(queue.currentIndex, 0);
      expect(queue.currentTrack?.sourceId, 'b');
    });

    test('reorder backward adjusts the current index', () {
      final queue = PlayQueue(random: Random(1));
      queue.start(
        _track('c'),
        queue: [_track('a'), _track('b'), _track('c'), _track('d')],
      );

      final result = queue.reorder(3, 1);

      expect(result?.toIndex, 1);
      expect(_ids(queue.tracks), ['a', 'd', 'b', 'c']);
      expect(queue.currentIndex, 3);
      expect(queue.currentTrack?.sourceId, 'c');
    });

    test('removing before current shifts the current index', () {
      final queue = PlayQueue(random: Random(1));
      queue.start(
        _track('c'),
        queue: [_track('a'), _track('b'), _track('c'), _track('d')],
      );

      final result = queue.removeAt(0);

      expect(result?.wasCurrent, isFalse);
      expect(result?.wasBeforeCurrent, isTrue);
      expect(queue.currentIndex, 1);
      expect(queue.currentTrack?.sourceId, 'c');
    });

    test('removing current reports the next track as current', () {
      final queue = PlayQueue(random: Random(1));
      queue.start(
        _track('b'),
        queue: [_track('a'), _track('b'), _track('c')],
      );

      final result = queue.removeAt(1);

      expect(result?.wasCurrent, isTrue);
      expect(result?.currentIndex, 1);
      expect(result?.currentTrack?.sourceId, 'c');
      expect(_ids(queue.tracks), ['a', 'c']);
    });

    test('removing the last current track falls back to the previous', () {
      final queue = PlayQueue(random: Random(1));
      queue.start(
        _track('c'),
        queue: [_track('a'), _track('b'), _track('c')],
      );

      final result = queue.removeAt(2);

      expect(result?.wasCurrent, isTrue);
      expect(result?.currentTrack?.sourceId, 'b');
      expect(queue.currentIndex, 1);
    });

    test('removing the only track clears the current', () {
      final queue = PlayQueue(random: Random(1));
      queue.start(_track('a'));

      final result = queue.removeAt(0);

      expect(result?.isEmpty, isTrue);
      expect(result?.currentTrack, isNull);
      expect(queue.currentIndex, -1);
    });

    test('removal during shuffle stays permanent after shuffle off', () {
      final queue = PlayQueue(random: Random(1));
      queue.start(
        _track('a'),
        queue: [_track('a'), _track('b'), _track('c')],
      );
      queue.toggleShuffle();
      final removedIndex = queue.indexOfSourceId('b');

      queue.removeAt(removedIndex);
      queue.toggleShuffle();

      expect(_ids(queue.tracks), ['a', 'c']);
      expect(queue.containsSourceId('b'), isFalse);
    });
  });

  group('PlayQueue snapshot', () {
    test('round-trips entries, current, shuffle, repeat, and auto ids', () {
      final queue = PlayQueue(random: Random(1));
      queue.start(
        _track('b'),
        queue: [_track('a'), _track('b'), _track('c')],
      );
      queue.appendAuto([_track('auto0')]);
      queue.cycleRepeat();

      final snapshot = queue.snapshot();
      final restored = PlayQueue.fromSnapshot(snapshot, random: Random(1));

      expect(restored.entries, snapshot.entries);
      expect(restored.currentIndex, snapshot.currentIndex);
      expect(restored.shuffleEnabled, snapshot.shuffleEnabled);
      expect(restored.repeatMode, snapshot.repeatMode);
      expect(restored.autoQueueIds, {'auto0'});
      expect(restored.cycleRepeat(), RepeatMode.one);
    });
  });

  group('PlayQueue nextUserIndex', () {
    test('returns the next user entry after a user current', () {
      final queue = PlayQueue(random: Random(1));
      queue.start(
        _track('b'),
        queue: [_track('a'), _track('b'), _track('c'), _track('d')],
      );

      expect(queue.nextUserIndex(), 2);
    });

    test('includes a user entry appended ahead of current', () {
      final queue = PlayQueue(random: Random(1));
      queue.start(
        _track('b'),
        queue: [_track('a'), _track('b'), _track('c'), _track('d')],
      );
      queue.enqueue(_track('next'), playNext: true);

      expect(queue.nextUserIndex(), 2);
      expect(queue.userTracks[2].sourceId, 'next');
    });

    test('returns the first user entry when current is auto', () {
      final queue = PlayQueue(random: Random(1));
      queue.start(
        _track('a'),
        queue: [_track('a'), _track('b')],
      );
      queue.appendAuto([_track('auto0')]);
      queue.select(queue.indexOfSourceId('auto0'));

      expect(queue.nextUserIndex(), 0);
    });

    test('returns -1 when there is no user entry', () {
      final queue = PlayQueue(random: Random(1));
      queue.appendAuto([_track('auto0')]);

      expect(queue.nextUserIndex(), -1);
    });
  });
}
