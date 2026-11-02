import 'package:isar/isar.dart';
import 'package:my_music_player/core/constants/enums.dart';

part 'track_model.g.dart';

@collection
class TrackModel {
  Id id = Isar.autoIncrement;

  @Index(unique: true, replace: true, composite: [CompositeIndex('source')])
  late String sourceId;

  late String title;
  
  String artist = 'Unknown Artist';
  
  String? album;
  
  late int durationMs;
  
  String? thumbnailUrl;
  
  String? localThumbnailPath;

  @enumerated
  late TrackSource source;

  String? streamUrl;
  
  DateTime? streamUrlExpiresAt;
  
  String? localAudioPath;

  @Index()
  bool isCached = false;

  @Index()
  bool isLiked = false;

  bool isPinned = false;

  int? fileSizeBytes;
  
  String? audioFormat;
  
  int? bitrateKbps;
  
  String? cachedQuality;

  String? cacheEtag; // For checksum / dedup verification
  
  DateTime? cachedAt;

  @Index()
  DateTime? lastPlayedAt;

  int playCount = 0;

  int? trackNumber;
  int? discNumber;
  int? year;

  late DateTime createdAt;
   
  late DateTime updatedAt;
}
