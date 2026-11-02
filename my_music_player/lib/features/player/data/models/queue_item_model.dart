import 'package:isar/isar.dart';

part 'queue_item_model.g.dart';

@collection
class QueueItemModel {
  Id id = Isar.autoIncrement;

  // Manual relation since it's a singleton queue
  @Index()
  int queueStateId = 1;

  @Index()
  late String trackId;

  late int originalIndex;
  
  int? shuffledIndex;
}
