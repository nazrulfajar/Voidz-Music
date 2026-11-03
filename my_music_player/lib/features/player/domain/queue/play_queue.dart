import 'dart:math';

import 'package:my_music_player/core/constants/enums.dart';
import 'package:my_music_player/features/player/domain/entities/track.dart';
import 'package:my_music_player/features/player/domain/queue/play_entry.dart';
import 'package:my_music_player/features/player/domain/queue/play_queue_snapshot.dart';

/// Result of a queue mutation. Playback is owned by the controller.
class QueueMutationResult {
  const QueueMutationResult({
    required this.inserted,
    required this.insertIndex,
    required this.currentIndex,
    required this.startedNewQueue,
  });

  /// Whether an entry was inserted (false for a duplicate/no-op).
  final bool inserted;

  /// Queue index where the mutation left the entry: the inserted/updated
  /// entry for `enqueue`, the selected current entry for `start`.
  final int insertIndex;

  /// Current queue index after the mutation.
  final int currentIndex;

  /// Whether the mutation replaced the whole queue.
  final bool startedNewQueue;
}

/// Result of `removeAt`; the controller uses it to choose the playback path.
class QueueRemoveResult {
  const QueueRemoveResult({
    required this.removed,
    required this.wasCurrent,
    required this.wasBeforeCurrent,
    required this.currentIndex,
    required this.currentTrack,
    required this.isEmpty,
  });

  /// Entry that was removed.
  final PlayEntry removed;

  /// Whether the removed entry was playing.
  final bool wasCurrent;

  /// Whether the removed entry was before the current entry.
  final bool wasBeforeCurrent;

  /// Current queue index after the removal.
  final int currentIndex;

  /// Track at [currentIndex] after the removal.
  final Track? currentTrack;

  /// Whether the queue has no entries left.
  final bool isEmpty;
}

/// Result of `reorder`; `toIndex` already uses remove+insert semantics.
class QueueReorderResult {
  const QueueReorderResult({
    required this.entry,
    required this.fromIndex,
    required this.toIndex,
    required this.currentIndex,
  });

  /// Entry that was moved.
  final PlayEntry entry;

  /// Original queue index.
  final int fromIndex;

  /// Final queue index after the move.
  final int toIndex;

  /// Current queue index after the move.
  final int currentIndex;
}

/// Single owner of queue order, index, shuffle, repeat, origin, and the cap.
///
/// This module is pure Dart: it knows nothing about `just_audio`, Isar,
/// Riverpod, or I/O.
class PlayQueue {
  PlayQueue({Random? random}) : _random = random ?? Random();

  static const int maxEntries = 500;

  final Random _random;
  final List<PlayEntry> _entries = [];
  int _currentIndex = -1;
  bool _shuffleEnabled = false;
  RepeatMode _repeatMode = RepeatMode.off;
  int _nextOriginalIndex = 0;

  /// Entries in play order.
  List<PlayEntry> get entries => List<PlayEntry>.unmodifiable(_entries);

  /// Number of entries in the queue.
  int get length => _entries.length;

  /// Whether the queue has no entries.
  bool get isEmpty => _entries.isEmpty;

  /// Whether the queue has at least one entry.
  bool get isNotEmpty => _entries.isNotEmpty;

  /// Index of the current entry, or -1 when the queue is empty or has no
  /// active entry (for example after removing the last playing track).
  int get currentIndex => _currentIndex;

  /// Whether shuffle is enabled.
  bool get shuffleEnabled => _shuffleEnabled;

  /// Current repeat mode.
  RepeatMode get repeatMode => _repeatMode;

  /// Entry at [currentIndex], or null when the queue is empty.
  PlayEntry? get currentEntry {
    if (_currentIndex < 0 || _currentIndex >= _entries.length) return null;
    return _entries[_currentIndex];
  }

  /// Track at [currentIndex], or null when the queue is empty.
  Track? get currentTrack => currentEntry?.track;

  /// Track of the last entry, used as the auto-queue seed.
  Track? get lastTrack => _entries.isEmpty ? null : _entries.last.track;

  /// Tracks in play order.
  List<Track> get tracks => [for (final entry in _entries) entry.track];

  /// Tracks that were added by the user, in play order.
  List<Track> get userTracks => [
        for (final entry in _entries)
          if (!entry.isAuto) entry.track,
      ];

  /// Source ids of every entry in the queue.
  Set<String> get sourceIds => {
        for (final entry in _entries) entry.track.sourceId,
      };

  /// Source ids of entries that came from auto-queue.
  Set<String> get autoQueueIds => {
        for (final entry in _entries)
          if (entry.isAuto) entry.track.sourceId,
      };

  /// Entry at [index], or null when out of range.
  PlayEntry? entryAt(int index) {
    if (index < 0 || index >= _entries.length) return null;
    return _entries[index];
  }

  /// Track at [index], or null when out of range.
  Track? trackAt(int index) => entryAt(index)?.track;

  /// Index of [sourceId], or -1 when it is not queued.
  int indexOfSourceId(String sourceId) {
    return _entries.indexWhere((entry) => entry.track.sourceId == sourceId);
  }

  /// Whether [sourceId] is already queued.
  bool containsSourceId(String sourceId) => indexOfSourceId(sourceId) != -1;

  /// Starts a new queue and discards the old one. Auto origin is cleared.
  ///
  /// Duplicate source ids are collapsed: queue identity is `sourceId`-based in
  /// `enqueue`, the snapshot mapper, and next-track selection.
  QueueMutationResult start(Track track, {List<Track>? queue}) {
    final source = queue ?? [track];
    final deduped = <Track>[];
    final seen = <String>{};
    for (final item in source) {
      if (seen.add(item.sourceId)) deduped.add(item);
    }

    var current = deduped.indexWhere((t) => t.sourceId == track.sourceId);
    if (current == -1) {
      deduped.insert(0, track);
      current = 0;
    }

    _entries.clear();
    for (var i = 0; i < deduped.length; i++) {
      _entries.add(
        PlayEntry(
          track: deduped[i],
          origin: QueueOrigin.user,
          originalIndex: i,
        ),
      );
    }
    _nextOriginalIndex = deduped.length;
    _currentIndex = current;

    if (_shuffleEnabled) {
      final currentEntry = _entries.removeAt(current);
      final rest = List<PlayEntry>.from(_entries)..shuffle(_random);
      _entries
        ..clear()
        ..add(currentEntry)
        ..addAll(rest);
      _currentIndex = 0;
    }

    _enforceCap();

    return QueueMutationResult(
      inserted: true,
      insertIndex: _currentIndex,
      currentIndex: _currentIndex,
      startedNewQueue: true,
    );
  }

  /// Adds one user track. Duplicate `sourceId` entries are removed first.
  QueueMutationResult enqueue(Track track, {bool playNext = false}) {
    if (_entries.isEmpty) return start(track);

    final existing = indexOfSourceId(track.sourceId);
    if (existing != -1) {
      if (existing == _currentIndex) {
        _entries[existing] = _entries[existing].copyWith(track: track);
        return QueueMutationResult(
          inserted: false,
          insertIndex: existing,
          currentIndex: _currentIndex,
          startedNewQueue: false,
        );
      }
      _removeEntryAt(existing);
    }

    final insertIndex = playNext
        ? (_currentIndex + 1).clamp(0, _entries.length)
        : _entries.length;
    var adjustedInsertIndex = insertIndex;
    if (playNext && _shuffleEnabled && _entries.length >= maxEntries) {
      // Make room before inserting: a play-next entry gets the smallest
      // non-current originalIndex, so the post-insert cap would evict it.
      final evictIndex = _evictionIndex();
      if (evictIndex != -1) {
        _removeEntryAt(evictIndex);
        if (evictIndex < insertIndex) adjustedInsertIndex--;
      }
    }
    final originalIndex = _nextInsertOriginalIndex(playNext: playNext);
    final entry = PlayEntry(
      track: track,
      origin: QueueOrigin.user,
      originalIndex: originalIndex,
    );
    _entries.insert(adjustedInsertIndex, entry);

    _enforceCap();
    if (!_shuffleEnabled) _reindexOriginal();

    final finalIndex = _entries.indexWhere(
      (entry) => entry.track.sourceId == track.sourceId,
    );
    return QueueMutationResult(
      inserted: finalIndex != -1,
      insertIndex: finalIndex,
      currentIndex: _currentIndex,
      startedNewQueue: false,
    );
  }

  /// Adds several user tracks at once.
  int enqueueAll(List<Track> tracks, {bool playNext = false}) {
    if (tracks.isEmpty) return 0;

    if (_entries.isEmpty) {
      start(tracks.first);
      final rest = tracks.skip(1).toList();
      for (final track in playNext ? rest.reversed : rest) {
        enqueue(track, playNext: playNext);
      }
      return _entries.length;
    }

    var inserted = 0;
    final ordered = playNext ? tracks.reversed : tracks;
    for (final track in ordered) {
      if (enqueue(track, playNext: playNext).inserted) inserted++;
    }
    return inserted;
  }

  /// Adds auto-queue tracks. The user queue is never truncated to make room:
  /// auto entries that do not fit are dropped instead.
  int appendAuto(List<Track> tracks) {
    final addedIds = <String>{};
    for (final track in tracks) {
      if (containsSourceId(track.sourceId)) continue;
      _entries.add(
        PlayEntry(
          track: track,
          origin: QueueOrigin.auto,
          originalIndex: _nextOriginalIndex++,
        ),
      );
      addedIds.add(track.sourceId);
    }
    if (addedIds.isEmpty) return 0;

    _enforceCap();
    if (!_shuffleEnabled) _reindexOriginal();

    return _entries
        .where((entry) => addedIds.contains(entry.track.sourceId))
        .length;
  }

  /// Removes an entry. The module never starts playback; the controller decides.
  QueueRemoveResult? removeAt(int index) {
    if (index < 0 || index >= _entries.length) return null;

    final wasCurrent = index == _currentIndex;
    final wasBeforeCurrent = index < _currentIndex;
    final removed = _entries[index];
    _removeEntryAt(index);

    if (!_shuffleEnabled) _reindexOriginal();

    return QueueRemoveResult(
      removed: removed,
      wasCurrent: wasCurrent,
      wasBeforeCurrent: wasBeforeCurrent,
      currentIndex: _currentIndex,
      currentTrack: currentTrack,
      isEmpty: _entries.isEmpty,
    );
  }

  /// Reorders using `ReorderableListView` semantics (newIndex is the insertion
  /// position before the item is removed).
  QueueReorderResult? reorder(int oldIndex, int newIndex) {
    if (oldIndex < 0 || oldIndex >= _entries.length) return null;
    if (newIndex < 0 || newIndex > _entries.length) return null;

    final adjustedNewIndex = oldIndex < newIndex ? newIndex - 1 : newIndex;
    if (adjustedNewIndex == oldIndex) {
      return QueueReorderResult(
        entry: _entries[oldIndex],
        fromIndex: oldIndex,
        toIndex: adjustedNewIndex,
        currentIndex: _currentIndex,
      );
    }

    final entry = _entries.removeAt(oldIndex);
    _entries.insert(adjustedNewIndex, entry);

    if (_currentIndex == oldIndex) {
      _currentIndex = adjustedNewIndex;
    } else if (oldIndex < _currentIndex && adjustedNewIndex >= _currentIndex) {
      _currentIndex--;
    } else if (oldIndex > _currentIndex && adjustedNewIndex <= _currentIndex) {
      _currentIndex++;
    }

    if (!_shuffleEnabled) _reindexOriginal();

    return QueueReorderResult(
      entry: entry,
      fromIndex: oldIndex,
      toIndex: adjustedNewIndex,
      currentIndex: _currentIndex,
    );
  }

  /// Selects [index] as current; returns false when out of range.
  bool select(int index) {
    if (index < 0 || index >= _entries.length) return false;
    _currentIndex = index;
    return true;
  }

  /// ON: current first, auto entries dropped, user entries shuffled.
  /// OFF: restore `originalIndex` order; a current auto entry stays first.
  bool toggleShuffle() {
    if (_entries.isEmpty) return _shuffleEnabled;

    final current = currentEntry;
    if (current == null) {
      if (!_shuffleEnabled) {
        final users = [
          for (final entry in _entries)
            if (!entry.isAuto) entry,
        ]..shuffle(_random);
        _entries
          ..clear()
          ..addAll(users);
        _shuffleEnabled = true;
      } else {
        final users = [
          for (final entry in _entries)
            if (!entry.isAuto) entry,
        ]..sort((a, b) => a.originalIndex.compareTo(b.originalIndex));
        _entries
          ..clear()
          ..addAll(users);
        _shuffleEnabled = false;
        _reindexOriginal();
      }
      return _shuffleEnabled;
    }

    if (!_shuffleEnabled) {
      final rest = [
        for (final entry in _entries)
          if (!entry.isAuto && !identical(entry, current)) entry,
      ]..shuffle(_random);

      _entries
        ..clear()
        ..add(current)
        ..addAll(rest);
      _currentIndex = 0;
      _shuffleEnabled = true;
    } else {
      final users = [
        for (final entry in _entries)
          if (!entry.isAuto) entry,
      ]..sort((a, b) => a.originalIndex.compareTo(b.originalIndex));

      if (current.isAuto) {
        _entries
          ..clear()
          ..add(current)
          ..addAll(users);
        _currentIndex = 0;
      } else {
        _entries
          ..clear()
          ..addAll(users);
        _currentIndex = _entries.indexWhere(
          (entry) => entry.track.sourceId == current.track.sourceId,
        );
        if (_currentIndex == -1) {
          _entries.insert(0, current);
          _currentIndex = 0;
        }
      }
      _shuffleEnabled = false;
      _reindexOriginal();
    }

    return _shuffleEnabled;
  }

  /// Cycles `off -> all -> one -> off` and returns the new mode.
  RepeatMode cycleRepeat() {
    _repeatMode = switch (_repeatMode) {
      RepeatMode.off => RepeatMode.all,
      RepeatMode.all => RepeatMode.one,
      RepeatMode.one => RepeatMode.off,
    };
    return _repeatMode;
  }

  /// Next index in the user-only list, wrapping around.
  ///
  /// [ahead] selects the nth entry after current; 0 is the current entry.
  /// Returns the first user entry when current is auto or not found.
  int nextUserIndex({int ahead = 1}) {
    final users = [
      for (final entry in _entries)
        if (!entry.isAuto) entry,
    ];
    if (users.isEmpty) return -1;

    final current = currentEntry;
    if (current == null || current.isAuto) return 0;

    final currentPosition = users.indexWhere(
      (entry) => entry.track.sourceId == current.track.sourceId,
    );
    if (currentPosition == -1) return 0;
    return (currentPosition + ahead) % users.length;
  }

  /// Replaces the track at [index]; returns false when out of range.
  bool replaceAt(int index, Track track) {
    final entry = entryAt(index);
    if (entry == null) return false;
    _entries[index] = entry.copyWith(track: track);
    return true;
  }

  /// Replaces the current track; returns false when the queue is empty.
  bool replaceCurrent(Track track) => replaceAt(_currentIndex, track);

  /// Replaces the entry with [sourceId]; returns false when it is not queued.
  bool replaceBySourceId(String sourceId, Track track) {
    final index = indexOfSourceId(sourceId);
    if (index == -1) return false;
    return replaceAt(index, track);
  }

  /// Removes every entry and resets the index. Shuffle and repeat are kept.
  void clear() {
    _entries.clear();
    _currentIndex = -1;
    _nextOriginalIndex = 0;
  }

  /// Captures the current state for persistence.
  PlayQueueSnapshot snapshot() {
    return PlayQueueSnapshot(
      entries: List<PlayEntry>.unmodifiable(_entries),
      currentIndex: _currentIndex,
      shuffleEnabled: _shuffleEnabled,
      repeatMode: _repeatMode,
      autoQueueIds: autoQueueIds,
    );
  }

  /// Builds a queue from a persisted snapshot.
  factory PlayQueue.fromSnapshot(
    PlayQueueSnapshot snapshot, {
    Random? random,
  }) {
    final queue = PlayQueue(random: random);
    queue.restore(snapshot);
    return queue;
  }

  /// Restores entries, current index, shuffle, and repeat from [snapshot].
  void restore(PlayQueueSnapshot snapshot) {
    final autoIds = <String>{
      ...snapshot.autoQueueIds,
      for (final entry in snapshot.entries)
        if (entry.isAuto) entry.track.sourceId,
    };

    _entries
      ..clear()
      ..addAll(
        snapshot.entries.map(
          (entry) => entry.copyWith(
            origin: autoIds.contains(entry.track.sourceId)
                ? QueueOrigin.auto
                : QueueOrigin.user,
          ),
        ),
      );

    _shuffleEnabled = snapshot.shuffleEnabled;
    _repeatMode = snapshot.repeatMode;
    if (_entries.isEmpty || snapshot.currentIndex < 0) {
      _currentIndex = -1;
    } else {
      _currentIndex = snapshot.currentIndex.clamp(0, _entries.length - 1);
    }
    _nextOriginalIndex = _entries.isEmpty
        ? 0
        : _entries
                .map((entry) => entry.originalIndex)
                .reduce((a, b) => a > b ? a : b) +
            1;

    _enforceCap();
  }

  int _nextInsertOriginalIndex({required bool playNext}) {
    if (!_shuffleEnabled) {
      return _entries.length;
    }

    final current = currentEntry;
    if (!playNext || current == null) return _nextOriginalIndex++;

    final insertAt = current.originalIndex + 1;
    for (var i = 0; i < _entries.length; i++) {
      final entry = _entries[i];
      if (entry.origin == QueueOrigin.user && entry.originalIndex >= insertAt) {
        _entries[i] = entry.copyWith(originalIndex: entry.originalIndex + 1);
      }
    }
    _nextOriginalIndex++;
    return insertAt;
  }

  void _reindexOriginal() {
    for (var i = 0; i < _entries.length; i++) {
      _entries[i] = _entries[i].copyWith(originalIndex: i);
    }
    _nextOriginalIndex = _entries.length;
  }

  void _removeEntryAt(int index) {
    _entries.removeAt(index);
    if (_entries.isEmpty) {
      _currentIndex = -1;
    } else if (index < _currentIndex) {
      _currentIndex--;
    } else if (index == _currentIndex) {
      _currentIndex = index < _entries.length ? index : -1;
    }
  }

  /// Hard cap: evict auto entries first, then the oldest non-current entry.
  /// The current entry is never evicted.
  void _enforceCap() {
    while (_entries.length > maxEntries) {
      final removeIndex = _evictionIndex();
      if (removeIndex == -1) break;
      _removeEntryAt(removeIndex);
    }
  }

  /// Index the cap should evict next, or -1 when nothing can be evicted.
  int _evictionIndex() {
    final autoIndex = _oldestIndexWhere((entry) => entry.isAuto);
    return autoIndex != -1 ? autoIndex : _oldestIndexWhere((_) => true);
  }

  int _oldestIndexWhere(bool Function(PlayEntry entry) test) {
    var bestIndex = -1;
    var bestOriginalIndex = 0;
    for (var i = 0; i < _entries.length; i++) {
      if (i == _currentIndex) continue;
      final entry = _entries[i];
      if (!test(entry)) continue;
      if (bestIndex == -1 || entry.originalIndex < bestOriginalIndex) {
        bestIndex = i;
        bestOriginalIndex = entry.originalIndex;
      }
    }
    return bestIndex;
  }
}
