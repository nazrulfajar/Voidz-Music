import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:isar/isar.dart';
import '../../../../core/providers/isar_provider.dart';
import '../../../../core/constants/enums.dart';
import '../../data/models/app_settings_model.dart';
import '../../../../features/cache/domain/usecases/cache_manager.dart';
import '../../../../features/library/presentation/providers/downloaded_provider.dart';
import '../../../../core/network/dio_client.dart';
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

  Future<void> updateBackendUrl(String url) async {
    await _updateSettings((settings) => settings.backendBaseUrl = url);
    _ref.read(dioProvider).options.baseUrl = url;
  }

  Future<void> toggleYoutubeSource(bool enabled) async {
    await _updateSettings((settings) => settings.enableYoutubeSource = enabled);
  }

  Future<void> toggleJamendoSource(bool enabled) async {
    await _updateSettings((settings) => settings.enableJamendoSource = enabled);
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
