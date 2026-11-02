import 'package:isar/isar.dart';

part 'playlist_model.g.dart';

@collection
class PlaylistModel {
  Id id = Isar.autoIncrement;
  
  @Index(unique: true)
  late String name;
  
  String? description;
  
  bool isSystem = false;
  
  late DateTime createdAt;
  late DateTime updatedAt;
}
