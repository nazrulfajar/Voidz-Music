import 'package:isar/isar.dart';
import 'package:my_music_player/core/constants/enums.dart';

part 'app_settings_model.g.dart';

@collection
class AppSettingsModel {
  Id id = 1; // Singleton

  String backendBaseUrl =
      'http://10.0.2.2:8000'; // Emulator default; ubah di Settings untuk device fisik

  bool enableYoutubeSource = true;

  bool enableJamendoSource = true;

  @enumerated
  AudioQuality preferredAudioQuality = AudioQuality.medium;

  int maxCacheSizeBytes = 1073741824; // 1GB default

  bool autoCacheEnabled = true;

  bool wifiOnlyDownload = false;

  bool resumeOnStartup = true;

  bool audioFocusPause = true;

  int crossfadeSeconds = 0; // 0 gapless, 2/4/6/8/12 premium crossfade

  // Migration helper: track if cache has been migrated to new location
  bool cacheMigratedToSupportDir = false;
}
