import 'package:isar/isar.dart';
import 'package:my_music_player/core/constants/enums.dart';

part 'app_settings_model.g.dart';

@collection
class AppSettingsModel {
  Id id = 1; // Singleton

  String backendBaseUrl = ''; // Legacy serverless; tidak dipakai

  bool enableYoutubeSource = true;

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

  /// Persisted as an ordinal. Isar's generated deserializer falls back to the
  /// first enum value ([AppThemeMode.system]) for unknown ordinals.
  @enumerated
  AppThemeMode appThemeMode = AppThemeMode.system;

  /// Persisted as an ordinal. Isar's generated deserializer falls back to the
  /// first enum value ([AppLanguageMode.system]) for unknown ordinals.
  @enumerated
  AppLanguageMode appLanguageMode = AppLanguageMode.system;
}
