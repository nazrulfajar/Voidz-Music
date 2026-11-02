import 'package:isar/isar.dart';

part 'play_history_model.g.dart';

@collection
class PlayHistoryModel {
  Id id = Isar.autoIncrement;
  
  @Index()
  late String trackSourceId;
  
  @Index()
  late DateTime playedAt;
}
