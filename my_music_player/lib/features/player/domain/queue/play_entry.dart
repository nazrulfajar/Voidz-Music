import 'package:my_music_player/features/player/domain/entities/track.dart';

/// Origin of a [PlayEntry]: added by the user or fetched by auto-queue.
enum QueueOrigin { user, auto }

/// A single [PlayQueue] item.
///
/// [originalIndex] is the entry position in the user order (before shuffle).
/// Auto entries keep an index so restore order is deterministic.
class PlayEntry {
  const PlayEntry({
    required this.track,
    required this.origin,
    required this.originalIndex,
  });

  /// Track played by this entry.
  final Track track;

  /// Where this entry came from.
  final QueueOrigin origin;

  /// Position in the original user order.
  final int originalIndex;

  /// Whether this entry came from auto-queue.
  bool get isAuto => origin == QueueOrigin.auto;

  /// Returns a copy with the given fields replaced.
  PlayEntry copyWith({
    Track? track,
    QueueOrigin? origin,
    int? originalIndex,
  }) {
    return PlayEntry(
      track: track ?? this.track,
      origin: origin ?? this.origin,
      originalIndex: originalIndex ?? this.originalIndex,
    );
  }

  @override
  bool operator ==(Object other) {
    return other is PlayEntry &&
        other.track == track &&
        other.origin == origin &&
        other.originalIndex == originalIndex;
  }

  @override
  int get hashCode => Object.hash(track, origin, originalIndex);

  @override
  String toString() {
    return 'PlayEntry(track: ${track.sourceId}, origin: $origin, '
        'originalIndex: $originalIndex)';
  }
}
