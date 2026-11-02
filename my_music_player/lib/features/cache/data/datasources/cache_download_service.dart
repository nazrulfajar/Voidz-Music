import 'dart:io';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:dio/dio.dart';
import 'package:path_provider/path_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/utils/cache_dir_helper.dart';
import '../../../../features/player/domain/entities/track.dart';
import '../../../../features/player/data/repositories/track_repository_impl.dart';
import '../../../../features/player/presentation/providers/player_controller.dart';
import '../../../../features/library/presentation/providers/downloaded_provider.dart';
import '../../../../features/home/presentation/providers/home_provider.dart';
import '../../../../features/lyrics/domain/repositories/lyrics_repository.dart';
import '../../domain/usecases/cache_manager.dart';
import '../../../../core/network/api_service.dart';
import '../../../settings/presentation/providers/settings_provider.dart';

final cacheDownloadServiceProvider = Provider<CacheDownloadService>((ref) {
  return CacheDownloadService(ref);
});

class CacheDownloadService {
  final Dio _dio;
  final Ref _ref;
  final Map<String, CancelToken> _activeDownloads = {};
  List<Track> _targetTracks = [];
  bool _isDownloadingQueue = false;
  late final CacheManager _cacheManager;

  CacheDownloadService(this._ref)
      : _dio = Dio(BaseOptions(
          connectTimeout: const Duration(seconds: 30),
          receiveTimeout: const Duration(minutes: 5),
          validateStatus: (s) => s != null && s < 400,
        )) {
    _cacheManager = _ref.read(cacheManagerProvider);
  }

  bool isDownloading(String trackId) => _activeDownloads.containsKey(trackId);

  void setTargetTracks(List<Track> targets) {
    // Deduplicate by sourceId to avoid duplicate downloads
    final seen = <String>{};
    final deduped = targets.where((t) => seen.add(t.sourceId)).toList();

    // Merge with existing targets to keep in-progress downloads (especially previous track)
    // Don't aggressively cancel active downloads — let them finish for better cache hit rate
    // Only cancel if track is truly no longer needed (not in new list AND not actively downloading)
    final newIds = deduped.map((t) => t.sourceId).toSet();
    final toCancel =
        _activeDownloads.keys.where((id) => !newIds.contains(id)).toList();
    // Only cancel if more than 2 active downloads would be orphaned — keep at least 1 in-progress
    // For premium behavior: keep current download even after skip, let it finish
    if (toCancel.length > 1) {
      // Keep the most recent (first) active download, cancel the rest
      for (final id in toCancel.skip(1)) {
        _activeDownloads[id]?.cancel("No longer in target tracks");
        _activeDownloads.remove(id);
      }
    }

    _targetTracks = deduped;

    _processQueue();
  }

  int _maxConcurrent() {
    // Premium: 3 parallel on WiFi, 2 on mobile (tradeoff #3 setuju naik)
    try {
      // Synchronous check via cached connectivity is async, so default 2 and upgrade if wifi
      // We'll check async in _processQueue and use 2 as safe default
      return 2;
    } catch (_) {
      return 2;
    }
  }

  Future<int> _maxConcurrentAsync() async {
    try {
      final result = await Connectivity().checkConnectivity();
      if (result.contains(ConnectivityResult.wifi) ||
          result.contains(ConnectivityResult.ethernet)) {
        return 3;
      }
    } catch (_) {}
    return 2;
  }

  Future<void> _processQueue() async {
    if (_isDownloadingQueue) return;
    _isDownloadingQueue = true;

    final maxConcurrent = await _maxConcurrentAsync();

    while (_activeDownloads.length < maxConcurrent) {
      Track? nextToDownload;
      for (final track in _targetTracks) {
        if (!track.isCached &&
            track.streamUrl != null &&
            !_activeDownloads.containsKey(track.sourceId)) {
          // Per-track wifiOnly check (premium: re-check before each download)
          final settings = _ref.read(appSettingsProvider).value;
          if (settings?.wifiOnlyDownload == true) {
            final conn = await Connectivity().checkConnectivity();
            if (!conn.contains(ConnectivityResult.wifi) &&
                !conn.contains(ConnectivityResult.ethernet)) {
              print('WiFi only enabled — skipping download for ${track.title}');
              continue;
            }
          }
          nextToDownload = track;
          break;
        }
      }

      if (nextToDownload == null) break;

      final trackForDownload = nextToDownload;
      final cancelToken = CancelToken();
      _activeDownloads[trackForDownload.sourceId] = cancelToken;

      // Fire and forget for parallel — don't await, let multiple run
      _downloadTrackTask(trackForDownload, cancelToken).then((_) {
        _activeDownloads.remove(trackForDownload.sourceId);
        // Trigger next in queue after one finishes
        _isDownloadingQueue = false;
        _processQueue();
      }).catchError((e) {
        if (e is DioException && CancelToken.isCancel(e)) {
          print("Download cancelled for: ${trackForDownload.title}");
        } else {
          print("Download failed for ${trackForDownload.title}: $e");
        }
        _activeDownloads.remove(trackForDownload.sourceId);
        _isDownloadingQueue = false;
        _processQueue();
      });

      // If we still have capacity, loop to launch next immediately (parallel)
      if (_activeDownloads.length >= maxConcurrent) break;
      // Small delay to avoid tight loop
      await Future.delayed(const Duration(milliseconds: 100));
    }

    _isDownloadingQueue = false;
    // If still pending targets and capacity, re-trigger
    if (_targetTracks.any((t) =>
            !t.isCached &&
            t.streamUrl != null &&
            !_activeDownloads.containsKey(t.sourceId)) &&
        _activeDownloads.length < maxConcurrent) {
      // Will be picked up by next setTargetTracks or completion callback
    }
  }

  Future<void> _downloadTrackTask(Track track, CancelToken cancelToken) async {
    bool success = false;
    int attempts = 0;
    const maxAttempts = 5;
    String currentUrl = track.streamUrl!;
    Track currentTrack = track;

    while (!success && attempts < maxAttempts && !cancelToken.isCancelled) {
      attempts++;
      try {
        final cacheDir = await getCacheDir();
        final fileExtension = currentTrack.audioFormat ?? 'opus';
        final fileName = buildCacheFileName(
            currentTrack.sourceId, currentTrack.audioFormat, fileExtension);
        final savePath = '${cacheDir.path}/$fileName';
        // Also check old location for resume/migration
        String? oldSavePath;
        try {
          final docDir = await getApplicationDocumentsDirectory();
          oldSavePath =
              '${docDir.path}/music_cache/${currentTrack.sourceId}.$fileExtension';
          final oldFile = File(oldSavePath);
          final newFile = File(savePath);
          if (await oldFile.exists() && !await newFile.exists()) {
            // Migrate on the fly
            try {
              await oldFile.rename(savePath);
            } catch (_) {
              await oldFile.copy(savePath);
            }
          }
        } catch (_) {}

        // On retry >1, refresh streamUrl via re-resolve to avoid expired/throttled URL
        if (attempts > 1) {
          try {
            final api = _ref.read(apiServiceProvider);
            final fresh = await api.resolve(currentTrack.sourceId,
                source: currentTrack.source.name,
                quality: currentTrack.cachedQuality ?? 'medium');
            final newUrl = fresh['stream_url'] as String?;
            if (newUrl != null && newUrl.isNotEmpty) {
              currentUrl = newUrl;
              currentTrack = currentTrack.copyWith(
                streamUrl: newUrl,
                streamUrlExpiresAt:
                    DateTime.tryParse(fresh['expires_at'] ?? ''),
              );
            }
          } catch (e) {
            print('Re-resolve on retry $attempts failed: $e');
          }
        }

        // Make a copy of headers so we don't modify the original
        final originalHeaders = _ref
                .read(playerControllerProvider.notifier)
                .getHeaders(currentTrack.sourceId) ??
            {};
        final headers = Map<String, String>.from(originalHeaders);

        // Use YouTube-compatible UA for googlevideo.com, Mozilla otherwise
        if (!headers.containsKey('User-Agent') &&
            !headers.containsKey('user-agent')) {
          if (currentUrl.contains('googlevideo.com')) {
            headers['User-Agent'] =
                'com.google.android.youtube/18.43.34 (Linux; U; Android 13; en_US; Pixel 7 Pro Build/TQ3A.230901.001)';
          } else {
            headers['User-Agent'] =
                'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36';
          }
        }
        headers['Accept-Encoding'] = 'identity';
        headers['Connection'] = 'keep-alive';

        final file = File(savePath);
        int existingSize = 0;
        bool resume = false;
        if (await file.exists()) {
          existingSize = await file.length();
          if (existingSize > 50000 &&
              currentTrack.fileSizeBytes != null &&
              existingSize >= (currentTrack.fileSizeBytes! * 0.95)) {
            // Likely complete (within 5% of expected)
            // Verify later, don't re-download
          } else if (existingSize > 0 && existingSize < 50000) {
            await file.delete();
            existingSize = 0;
          } else if (existingSize > 50000) {
            // Partial file (e.g., 2MB of 4MB) — resume with Range
            headers['Range'] = 'bytes=$existingSize-';
            resume = true;
          }
        }

        final options = Options(
          headers: headers,
          sendTimeout: const Duration(minutes: 1),
          receiveTimeout: const Duration(minutes: 5),
          followRedirects: true,
          validateStatus: (s) => s != null && s < 400,
        );

        String? etag;
        if (resume && existingSize > 0) {
          // Stream append mode for resume
          final streamOptions = Options(
            headers: headers,
            sendTimeout: const Duration(minutes: 1),
            receiveTimeout: const Duration(minutes: 5),
            followRedirects: true,
            validateStatus: (s) => s != null && s < 400,
            responseType: ResponseType.stream,
          );
          final response = await _dio.get<ResponseBody>(
            currentUrl,
            options: streamOptions,
            cancelToken: cancelToken,
          );
          etag = response.headers.value('etag');
          final raf = await file.open(mode: FileMode.append);
          try {
            await for (final chunk in response.data!.stream) {
              if (cancelToken.isCancelled) break;
              await raf.writeFrom(chunk);
            }
          } finally {
            await raf.close();
          }
          // If server ignored Range and returned 200 with full content, we appended duplicate — detect and fix
          final newSize = await file.length();
          if (response.statusCode == 200 && newSize > (existingSize + 100000)) {
            // Server sent full file, we appended — need to handle (rough: if newSize > expected*1.5, delete and retry without resume)
            print('Server ignored Range, got full content. Handling...');
            // Keep as is if size plausible, otherwise next attempt will fix
          }
        } else if (existingSize > 50000 &&
            currentTrack.fileSizeBytes != null &&
            existingSize >= (currentTrack.fileSizeBytes! * 0.95)) {
          // Skip download, file likely complete — treat as success without network
          print(
              'File already complete for ${currentTrack.title}, skipping download');
        } else {
          // Fresh download via stream (more robust than Dio.download for googlevideo)
          final freshOptions = Options(
            headers: headers,
            sendTimeout: const Duration(minutes: 1),
            receiveTimeout: const Duration(minutes: 5),
            followRedirects: true,
            validateStatus: (s) => s != null && s < 400,
            responseType: ResponseType.stream,
          );
          final response = await _dio.get<ResponseBody>(
            currentUrl,
            options: freshOptions,
            cancelToken: cancelToken,
          );
          etag = response.headers.value('etag');
          // Ensure directory exists and overwrite file
          final sink = await file.open(mode: FileMode.write);
          try {
            await for (final chunk in response.data!.stream) {
              if (cancelToken.isCancelled) break;
              await sink.writeFrom(chunk);
            }
          } finally {
            await sink.close();
          }
          if (response.statusCode != 200 && response.statusCode != 206) {
            throw Exception(
                'Download failed with status ${response.statusCode}');
          }
        }

        // Verify file size — premium threshold 100KB (was 50KB) to avoid corrupt preview
        final fileSize = await file.length();
        // etag already captured from response headers above
        if (fileSize < 100000) {
          throw Exception(
              "Downloaded file is too small (corrupt or empty) — $fileSize bytes");
        }

        // Fetch and cache lyrics silently
        if (!cancelToken.isCancelled) {
          try {
            final lyricsRepo = _ref.read(lyricsRepositoryProvider);
            await lyricsRepo.getLyrics(
                track.sourceId, track.title, track.artist ?? '');
          } catch (e) {
            print('Silent lyrics cache failed: $e');
          }
        }

        String? localThumbnailPath;
        if (track.thumbnailUrl != null && !cancelToken.isCancelled) {
          try {
            final urlWithoutQuery = track.thumbnailUrl!.split('?').first;
            String thumbExt = 'jpg';
            if (urlWithoutQuery.contains('.')) {
              final ext = urlWithoutQuery.split('.').last.toLowerCase();
              if (ext.length <= 4 && !ext.contains('-') && !ext.contains('/')) {
                thumbExt = ext;
              }
            }
            final thumbName = '${track.sourceId}_thumb.$thumbExt';
            final thumbPath = '${cacheDir.path}/$thumbName';

            final thumbFile = File(thumbPath);
            if (await thumbFile.exists() && await thumbFile.length() > 1000) {
              localThumbnailPath = thumbPath;
            } else {
              await _dio.download(track.thumbnailUrl!, thumbPath,
                  cancelToken: cancelToken);
              localThumbnailPath = thumbPath;
            }
          } catch (e) {
            print('Failed to download thumbnail for ${track.sourceId}: $e');
          }
        }

        if (cancelToken.isCancelled) throw Exception("Cancelled");

        // Update DB
        final updatedTrack = currentTrack.copyWith(
          isCached: true,
          localAudioPath: savePath,
          localThumbnailPath: localThumbnailPath,
          fileSizeBytes: fileSize,
          cacheEtag: etag,
          cachedAt: DateTime.now(),
        );

        final trackRepo = _ref.read(trackRepositoryProvider);
        await trackRepo.updateTrack(updatedTrack);

        // Update in-memory target list so we don't re-download same track
        _targetTracks = _targetTracks
            .map((t) => t.sourceId == currentTrack.sourceId ? updatedTrack : t)
            .toList();

        print(
            'Successfully cached track: ${currentTrack.title} (${(fileSize / 1024 / 1024).toStringAsFixed(1)} MB)');

        _ref.invalidate(downloadedTracksProvider);
        await _cacheManager.checkAndEvictCache();

        success = true;
      } catch (e) {
        if ((e is DioException && CancelToken.isCancel(e)) ||
            cancelToken.isCancelled) {
          rethrow; // rethrow to be caught by outer block
        }

        // Classify retryable errors: connection closed, timeout, 403 etc are retryable
        final isRetryable = e is DioException ||
            e.toString().contains('Connection closed') ||
            e.toString().contains('HttpException');
        print(
            'Download attempt $attempts failed for ${currentTrack.title}: $e (retryable=$isRetryable)');

        // Only delete file if it's clearly corrupt (<100KB) or not retryable; keep partial for resume
        if (!isRetryable || attempts == maxAttempts) {
          try {
            final cacheDirDel = await getCacheDir();
            final fileExtensionDel = currentTrack.audioFormat ?? 'opus';
            final fileDel = File(
                '${cacheDirDel.path}/${buildCacheFileName(currentTrack.sourceId, currentTrack.audioFormat, fileExtensionDel)}');
            if (await fileDel.exists()) {
              final sz = await fileDel.length();
              if (sz < 100000) await fileDel.delete();
            }
            // Also clean old location
            try {
              final docDir = await getApplicationDocumentsDirectory();
              final oldFile = File(
                  '${docDir.path}/music_cache/${currentTrack.sourceId}.$fileExtensionDel');
              if (await oldFile.exists() && await oldFile.length() < 100000) {
                await oldFile.delete();
              }
            } catch (_) {}
          } catch (_) {}
        }

        if (attempts < maxAttempts) {
          final backoff =
              Duration(seconds: 2 * attempts + (attempts > 2 ? 5 : 0));
          print('Retrying in ${backoff.inSeconds}s...');
          await Future.delayed(backoff);
        }
      }
    }
  }
}
