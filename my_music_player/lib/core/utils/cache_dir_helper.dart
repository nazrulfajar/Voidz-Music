import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:isar/isar.dart';
import 'app_logger.dart';
import '../../features/settings/data/models/app_settings_model.dart';
import '../../features/player/data/models/track_model.dart';

/// Returns the premium cache directory: SupportDir/audio (excluded from backup)
/// Falls back to Documents/music_cache for migration.
Future<Directory> getCacheDir() async {
  try {
    final supportDir = await getApplicationSupportDirectory();
    final dir = Directory('${supportDir.path}/audio');
    if (!await dir.exists()) {
      await dir.create(recursive: true);
    }
    return dir;
  } catch (_) {
    final docDir = await getApplicationDocumentsDirectory();
    final dir = Directory('${docDir.path}/music_cache');
    if (!await dir.exists()) {
      await dir.create(recursive: true);
    }
    return dir;
  }
}

/// Migrates old Documents/music_cache files to new Support/audio
Future<void> migrateCacheIfNeeded(Isar isar) async {
  try {
    final settings = await isar.appSettingsModels.get(1);
    if (settings?.cacheMigratedToSupportDir == true) return;

    final docDir = await getApplicationDocumentsDirectory();
    final supportDir = await getApplicationSupportDirectory();
    final oldDir = Directory('${docDir.path}/music_cache');
    final newDir = Directory('${supportDir.path}/audio');

    if (!await oldDir.exists()) {
      // No old cache, just mark migrated
      await isar.writeTxn(() async {
        var s = await isar.appSettingsModels.get(1);
        s ??= AppSettingsModel();
        s.cacheMigratedToSupportDir = true;
        await isar.appSettingsModels.put(s);
      });
      return;
    }

    if (!await newDir.exists()) {
      await newDir.create(recursive: true);
    }

    final files = await oldDir.list().toList();
    for (final f in files) {
      if (f is File) {
        final name = f.path.split('/').last.split('\\').last;
        final newPath = '${newDir.path}/$name';
        final newFile = File(newPath);
        if (!await newFile.exists()) {
          try {
            await f.rename(newPath);
          } catch (_) {
            try {
              await f.copy(newPath);
              await f.delete();
            } catch (_) {}
          }
        }
      }
    }

    // Update DB localAudioPath / localThumbnailPath
    final tracks = await isar.trackModels.where().isCachedEqualTo(true).findAll();
    await isar.writeTxn(() async {
      for (final m in tracks) {
        if (m.localAudioPath != null && m.localAudioPath!.contains('music_cache')) {
          m.localAudioPath = m.localAudioPath!.replaceAll('music_cache', 'audio').replaceAll(docDir.path, supportDir.path);
        }
        if (m.localThumbnailPath != null && m.localThumbnailPath!.contains('music_cache')) {
          m.localThumbnailPath = m.localThumbnailPath!.replaceAll('music_cache', 'audio').replaceAll(docDir.path, supportDir.path);
        }
        await isar.trackModels.put(m);
      }
      var s = await isar.appSettingsModels.get(1);
      s ??= AppSettingsModel();
      s.cacheMigratedToSupportDir = true;
      await isar.appSettingsModels.put(s);
    });
    appLogger.d('Cache migrated to ${newDir.path}');
  } catch (e) {
    appLogger.d('Cache migration failed (non-fatal): $e');
  }
}

/// Builds format-aware filename to keep multiple qualities (Spotify keeps 96/160/320)
String buildCacheFileName(String sourceId, String? audioFormat, String? extOverride) {
  final fmt = (audioFormat ?? 'opus').toLowerCase();
  final ext = extOverride ?? fmt;
  // e.g., abc123_opus.webm, abc123_aac.m4a
  return '${sourceId}_$fmt.$ext';
}

/// Builds thumbnail filename — consistent across download service & player
String buildThumbFileName(String sourceId, String? thumbnailUrl) {
  if (thumbnailUrl == null) return '${sourceId}_thumb.jpg';
  final urlWithoutQuery = thumbnailUrl.split('?').first;
  String thumbExt = 'jpg';
  if (urlWithoutQuery.contains('.')) {
    final ext = urlWithoutQuery.split('.').last.toLowerCase();
    if (ext.length <= 4 && !ext.contains('-') && !ext.contains('/')) {
      thumbExt = ext;
    }
  }
  return '${sourceId}_thumb.$thumbExt';
}

/// Premium threshold: <100KB dianggap corrupt (naik dari 50KB)
bool isCorruptFileSize(int bytes) => bytes < 100000;
bool isExistingFileCorruptSync(File f) {
  try {
    if (!f.existsSync()) return true;
    return f.lengthSync() < 100000;
  } catch (_) {
    return true;
  }
}

/// Legacy path helper — hanya untuk migrasi/cleanup, jangan pakai untuk file baru
Future<String> buildLegacyCachePath(String sourceId, String ext) async {
  final docDir = await getApplicationDocumentsDirectory();
  return '${docDir.path}/music_cache/$sourceId.$ext';
}
