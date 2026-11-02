import 'package:isar/isar.dart';
import 'package:my_music_player/core/constants/enums.dart';

part 'queue_state_model.g.dart';

@collection
class QueueStateModel {
  Id id = 1; // Singleton

  String? currentTrackId;
  
  int currentPositionMs = 0;
  
  bool shuffleEnabled = false;

  @enumerated
  RepeatMode repeatMode = RepeatMode.off;
  
  String? queueSource;

  // Persist auto-queue sourceIds as CSV (for restore filtering in LoopMode.all)
  String? autoQueueIds;
  
  late DateTime updatedAt;
}
