import 'package:isar/isar.dart';

part 'search_history_model.g.dart';

@collection
class SearchHistoryModel {
  Id id = Isar.autoIncrement;

  @Index(unique: true, replace: true)
  late String query;

  late DateTime timestamp;
}
