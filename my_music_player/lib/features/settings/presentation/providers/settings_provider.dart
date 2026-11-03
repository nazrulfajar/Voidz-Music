import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:isar/isar.dart';
import '../../../../core/providers/isar_provider.dart';
import '../../../../core/constants/enums.dart';
import '../../../../core/theme/app_theme.dart';
import '../../data/models/app_settings_model.dart';
import '../../../../features/cache/domain/usecases/cache_manager.dart';
import '../../../../features/library/presentation/providers/downloaded_provider.dart';
import '../../../player/data/repositories/track_repository_impl.dart';

final appSettingsProvider = StreamProvider<AppSettingsModel>((ref) {
  final isar = ref.watch(isarProvider);

  // Watch for changes on the settings model (id = 1)
  return isar.appSettingsModels
      .watchObject(1, fireImmediately: true)
      .map((settings) {
    return settings ?? AppSettingsModel(); // Return default if null
  });
});

/// Theme applied by `MaterialApp`; follows the OS while settings load.
final themeModeProvider = Provider<ThemeMode>((ref) {
  final settings = ref.watch(appSettingsProvider).valueOrNull;
  return (settings?.appThemeMode ?? AppThemeMode.system).themeMode;
});

final settingsControllerProvider = Provider<SettingsController>((ref) {
  final isar = ref.watch(isarProvider);
  return SettingsController(ref, isar);
});

class SettingsController {
  final Ref _ref;
  final Isar _isar;

  SettingsController(this._ref, this._isar);

  Future<void> _updateSettings(
      void Function(AppSettingsModel settings) updateFn) async {
    await _isar.writeTxn(() async {
      var settings = await _isar.appSettingsModels.get(1);
      settings ??= AppSettingsModel();
      updateFn(settings);
      await _isar.appSettingsModels.put(settings);
    });
  }

  Future<void> toggleYoutubeSource(bool enabled) async {
    await _updateSettings((settings) => settings.enableYoutubeSource = enabled);
  }

  Future<void> setAudioQuality(AudioQuality quality) async {
    await _updateSettings(
        (settings) => settings.preferredAudioQuality = quality);
  }

  Future<void> setCacheLimitMb(int mb) async {
    final bytes = mb * 1024 * 1024;
    await _updateSettings((settings) => settings.maxCacheSizeBytes = bytes);
  }

  Future<void> toggleAutoCache(bool enabled) async {
    await _updateSettings((settings) => settings.autoCacheEnabled = enabled);
  }

  Future<void> toggleWifiOnly(bool enabled) async {
    await _updateSettings((settings) => settings.wifiOnlyDownload = enabled);
  }

  Future<void> toggleResumeOnStartup(bool enabled) async {
    await _updateSettings((settings) => settings.resumeOnStartup = enabled);
  }

  Future<void> toggleAudioFocusPause(bool enabled) async {
    await _updateSettings((settings) => settings.audioFocusPause = enabled);
  }

  Future<void> setCrossfade(int seconds) async {
    await _updateSettings((settings) => settings.crossfadeSeconds = seconds);
  }

  Future<void> setThemeMode(AppThemeMode mode) async {
    await _updateSettings((settings) => settings.appThemeMode = mode);
  }

  Future<void> setAppLanguageMode(AppLanguageMode mode) async {
    await _updateSettings((settings) => settings.appLanguageMode = mode);
  }

  Future<void> clearCache() async {
    final cacheManager = _ref.read(cacheManagerProvider);
    final trackRepo = _ref.read(trackRepositoryProvider);

    final result = await trackRepo.getAllCachedTracks();
    await result.fold(
      (failure) async {},
      (tracks) async {
        for (final track in tracks) {
          if (!track.isPinned) {
            await cacheManager.removeTrackFromCache(track);
          }
        }
        _ref.invalidate(downloadedTracksProvider);
      },
    );
  }
}
