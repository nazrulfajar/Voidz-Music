import 'dart:io';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/providers/isar_provider.dart';
import '../../../player/data/models/track_model.dart';
import '../../../settings/data/models/app_settings_model.dart';
import '../../../../core/constants/enums.dart';
import 'package:isar/isar.dart';

class CacheStats {
  final int totalCachedTracks;
  final int totalCacheSizeBytes;
  final int maxCacheSizeBytes;
  final double usagePercentage;
  final List<String> pinnedTrackIds;
  final DateTime? oldestCacheEntry;

  CacheStats({
    required this.totalCachedTracks,
    required this.totalCacheSizeBytes,
    required this.maxCacheSizeBytes,
    required this.usagePercentage,
    required this.pinnedTrackIds,
    this.oldestCacheEntry,
  });

  bool get isNearLimit => usagePercentage >= 0.9;
  bool get isOverLimit => totalCacheSizeBytes > maxCacheSizeBytes;
}

final cacheStatsProvider = FutureProvider<CacheStats>((ref) async {
  final isar = ref.watch(isarProvider);
  final settings = await isar.appSettingsModels.get(1);
  final maxBytes = settings?.maxCacheSizeBytes ?? (1024 * 1024 * 1024);

  final allCached = await isar.trackModels.where().isCachedEqualTo(true).findAll();
  // Exclude local device songs from cache stats
  final cachedTracks = allCached.where((t) => t.source != TrackSource.local).toList();
  int totalSize = 0;
  DateTime? oldest;
  final pinned = <String>[];
  for (final t in cachedTracks) {
    // Premium: truth via File.length(), fallback ke fileSizeBytes jika file hilang
    int realSize = t.fileSizeBytes ?? 0;
    if (t.localAudioPath != null) {
      try {
        final f = File(t.localAudioPath!);
        if (await f.exists()) realSize = await f.length();
      } catch (_) {}
    }
    totalSize += realSize;
    if (t.isPinned) pinned.add(t.sourceId);
    if (t.cachedAt != null) {
      if (oldest == null || t.cachedAt!.isBefore(oldest)) oldest = t.cachedAt;
    }
  }

  final usage = maxBytes > 0 ? totalSize / maxBytes : 0.0;

  return CacheStats(
    totalCachedTracks: cachedTracks.length,
    totalCacheSizeBytes: totalSize,
    maxCacheSizeBytes: maxBytes,
    usagePercentage: usage.clamp(0.0, 1.0),
    pinnedTrackIds: pinned,
    oldestCacheEntry: oldest,
  );
});
