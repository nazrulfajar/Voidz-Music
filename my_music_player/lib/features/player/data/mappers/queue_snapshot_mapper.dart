import 'package:my_music_player/features/player/data/models/queue_item_model.dart';
import 'package:my_music_player/features/player/data/models/queue_state_model.dart';
import 'package:my_music_player/features/player/domain/entities/track.dart';
import 'package:my_music_player/features/player/domain/queue/play_entry.dart';
import 'package:my_music_player/features/player/domain/queue/play_queue_snapshot.dart';

/// Translates a queue snapshot to and from the legacy Isar schema.
///
/// The mapper only translates; validation, dedup, and the cap stay in
/// `PlayQueue`.
class QueueSnapshotMapper {
  const QueueSnapshotMapper._();

  /// Builds a snapshot from Isar models. `shuffledIndex` is the play order;
  /// legacy rows without it fall back to `originalIndex`.
  static PlayQueueSnapshot toSnapshot({
    required List<QueueItemModel> items,
    required QueueStateModel state,
    required Map<String, Track> tracksById,
  }) {
    final ordered = List<QueueItemModel>.from(items)
      ..sort((a, b) {
        final aOrder = _orderKey(a, state.shuffleEnabled);
        final bOrder = _orderKey(b, state.shuffleEnabled);
        return aOrder.compareTo(bOrder);
      });

    final autoIds = parseAutoQueueIds(state.autoQueueIds);
    final entries = <PlayEntry>[];
    final seen = <String>{};
    for (final item in ordered) {
      final track = tracksById[item.trackId];
      if (track == null || !seen.add(item.trackId)) continue;
      entries.add(
        PlayEntry(
          track: track,
          origin: autoIds.contains(item.trackId)
              ? QueueOrigin.auto
              : QueueOrigin.user,
          originalIndex: item.originalIndex,
        ),
      );
    }

    var currentIndex = -1;
    if (state.currentTrackId != null) {
      currentIndex = entries.indexWhere(
        (entry) => entry.track.sourceId == state.currentTrackId,
      );
    }
    if (entries.isNotEmpty && currentIndex == -1) currentIndex = 0;

    return PlayQueueSnapshot(
      entries: entries,
      currentIndex: currentIndex,
      shuffleEnabled: state.shuffleEnabled,
      repeatMode: state.repeatMode,
      autoQueueIds: {
        for (final entry in entries)
          if (entry.isAuto) entry.track.sourceId,
      },
    );
  }

  /// Maps a snapshot to Isar item rows in play order.
  static List<QueueItemModel> toItemModels(PlayQueueSnapshot snapshot) {
    final items = <QueueItemModel>[];
    for (var i = 0; i < snapshot.entries.length; i++) {
      final entry = snapshot.entries[i];
      items.add(
        QueueItemModel()
          ..queueStateId = 1
          ..trackId = entry.track.sourceId
          ..originalIndex = entry.originalIndex
          ..shuffledIndex = snapshot.shuffleEnabled ? i : null,
      );
    }
    return items;
  }

  /// Maps a snapshot to the singleton queue state row.
  static QueueStateModel toStateModel(
    PlayQueueSnapshot snapshot, {
    required int currentPositionMs,
    DateTime? updatedAt,
  }) {
    final autoIds = {
      for (final entry in snapshot.entries)
        if (entry.isAuto) entry.track.sourceId,
    };
    final current = snapshot.currentIndex >= 0 &&
            snapshot.currentIndex < snapshot.entries.length
        ? snapshot.entries[snapshot.currentIndex].track.sourceId
        : null;

    return QueueStateModel()
      ..id = 1
      ..currentTrackId = current
      ..currentPositionMs = currentPositionMs
      ..shuffleEnabled = snapshot.shuffleEnabled
      ..repeatMode = snapshot.repeatMode
      ..autoQueueIds = autoIds.isEmpty ? null : autoIds.join(',')
      ..queueSource = snapshot.entries.isNotEmpty
          ? 'queue:${snapshot.entries.length}'
          : null
      ..updatedAt = updatedAt ?? DateTime.now();
  }

  /// Parses the legacy `autoQueueIds` CSV, ignoring empty values.
  static Set<String> parseAutoQueueIds(String? csv) {
    if (csv == null || csv.isEmpty) return {};
    return csv.split(',').where((id) => id.isNotEmpty).toSet();
  }

  static int _orderKey(QueueItemModel item, bool shuffleEnabled) {
    if (shuffleEnabled) return item.shuffledIndex ?? item.originalIndex;
    return item.originalIndex;
  }
}
