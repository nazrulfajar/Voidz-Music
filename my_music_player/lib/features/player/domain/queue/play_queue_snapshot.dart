import 'package:my_music_player/core/constants/enums.dart';
import 'package:my_music_player/features/player/domain/queue/play_entry.dart';

/// Immutable [PlayQueue] state used for persistence and tests.
class PlayQueueSnapshot {
  const PlayQueueSnapshot({
    required this.entries,
    required this.currentIndex,
    required this.shuffleEnabled,
    required this.repeatMode,
    this.autoQueueIds = const {},
  });

  /// Entries in play order (not original order).
  final List<PlayEntry> entries;

  /// Index of the current entry in [entries].
  final int currentIndex;

  /// Whether shuffle was enabled when the snapshot was taken.
  final bool shuffleEnabled;

  /// Repeat mode at snapshot time.
  final RepeatMode repeatMode;

  /// Source ids that came from auto-queue.
  final Set<String> autoQueueIds;
}
