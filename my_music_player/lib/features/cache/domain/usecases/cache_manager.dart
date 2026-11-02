import 'dart:io';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/constants/enums.dart';
import '../../../../features/player/domain/entities/track.dart';
import '../../../../features/player/domain/repositories/track_repository.dart';
import '../../../../features/player/data/repositories/track_repository_impl.dart';

import '../../../settings/presentation/providers/settings_provider.dart';

final cacheManagerProvider = Provider<CacheManager>((ref) {
  final repo = ref.read(trackRepositoryProvider);
  final settings = ref.watch(appSettingsProvider).value;
  return CacheManager(repo, maxCacheSizeBytes: settings?.maxCacheSizeBytes ?? (1024 * 1024 * 1024));
});

class CacheManager {
  final TrackRepository _trackRepo;
  final int maxCacheSizeBytes;

  CacheManager(this._trackRepo, {required this.maxCacheSizeBytes});

  Future<void> checkAndEvictCache() async {
    final result = await _trackRepo.getAllCachedTracks();
    result.fold(
      (failure) => print('Failed to get cached tracks: \${failure.message}'),
      (tracks) async {
        int totalSize = 0;
        final unpinnedTracks = <Track>[];
        
        for (final track in tracks) {
          // Premium: realSize via file.length truth, fallback to fileSizeBytes
          int realSize = track.fileSizeBytes ?? 0;
          if (track.localAudioPath != null) {
            try {
              final f = File(track.localAudioPath!);
              if (await f.exists()) realSize = await f.length();
            } catch (_) {}
          }
          totalSize += realSize;
          if (!track.isPinned) {
            unpinnedTracks.add(track);
          }
        }
        
        if (totalSize > maxCacheSizeBytes) {
          print('Cache limit exceeded. Total: $totalSize, Max: $maxCacheSizeBytes. Evicting...');
          
          // Sort by last played ascending (oldest first)
          unpinnedTracks.sort((a, b) {
            final aTime = a.lastPlayedAt ?? DateTime.fromMillisecondsSinceEpoch(0);
            final bTime = b.lastPlayedAt ?? DateTime.fromMillisecondsSinceEpoch(0);
            return aTime.compareTo(bTime);
          });
          
          // Build realSize map for accurate decrement
          final sizeMap = <String, int>{};
          for (final t in unpinnedTracks) {
            int rs = t.fileSizeBytes ?? 0;
            if (t.localAudioPath != null) {
              try {
                final f = File(t.localAudioPath!);
                if (await f.exists()) rs = await f.length();
              } catch (_) {}
            }
            sizeMap[t.sourceId] = rs;
          }
          for (final track in unpinnedTracks) {
            if (totalSize <= maxCacheSizeBytes) break;
            await removeTrackFromCache(track);
            totalSize -= (sizeMap[track.sourceId] ?? track.fileSizeBytes ?? 0);
          }
        }
      },
    );
  }

  Future<void> removeTrackFromCache(Track track) async {
    // Never delete user-owned local files
    if (track.source == TrackSource.local) return;
    try {
      if (track.localAudioPath != null) {
        final audioFile = File(track.localAudioPath!);
        if (await audioFile.exists()) {
          await audioFile.delete();
        }
      }
      if (track.localThumbnailPath != null) {
        final thumbFile = File(track.localThumbnailPath!);
        if (await thumbFile.exists()) {
          await thumbFile.delete();
        }
      }
      
      final updatedTrack = track.copyWith(
        isCached: false,
        localAudioPath: null,
        localThumbnailPath: null,
        fileSizeBytes: null,
        cachedAt: null,
      );
      
      await _trackRepo.updateTrack(updatedTrack);
      print('Evicted track from cache: \${track.title}');
    } catch (e) {
      print('Failed to evict track \${track.sourceId}: \$e');
    }
  }
}
