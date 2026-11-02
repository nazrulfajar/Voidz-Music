import 'package:isar/isar.dart';

part 'playlist_track_model.g.dart';

@collection
class PlaylistTrackModel {
  Id id = Isar.autoIncrement;
  
  @Index(composite: [CompositeIndex('trackSourceId')], unique: true, replace: true)
  late int playlistId;
  
  late String trackSourceId;
  
  @Index()
  late int orderIndex;
  
  late DateTime addedAt;
}
