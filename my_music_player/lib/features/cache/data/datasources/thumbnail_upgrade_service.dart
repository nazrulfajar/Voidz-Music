import 'dart:io';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:logger/logger.dart';

import '../../../../core/constants/enums.dart';
import '../../../../core/utils/artwork_url.dart';
import '../../../../core/utils/cache_dir_helper.dart';
import '../../../player/data/repositories/track_repository_impl.dart';
import '../../../player/domain/entities/track.dart';
import '../../../player/domain/repositories/track_repository.dart';
import 'thumbnail_artwork_store.dart';

/// Upgrades legacy 120 px artwork of downloaded YouTube tracks to display size.
final thumbnailUpgradeServiceProvider =
    Provider<ThumbnailUpgradeService>((ref) {
  final dio = Dio(
    BaseOptions(
      connectTimeout: const Duration(seconds: 15),
      receiveTimeout: const Duration(seconds: 30),
      validateStatus: (status) => status != null && status < 400,
    ),
  );
  return ThumbnailUpgradeService(
    trackRepository: ref.read(trackRepositoryProvider),
    store: ThumbnailArtworkStore(
      cacheDirectory: getCacheDir,
      downloader: (url, path) => dio.download(url, path),
    ),
  );
});

Future<bool> _hasConnection() async {
  try {
    final results = await Connectivity().checkConnectivity();
    return results.any((result) => result != ConnectivityResult.none);
  } catch (_) {
    return false;
  }
}

/// Refreshes legacy downloaded artwork gradually, without touching audio.
///
/// Runs at most once per instance (one app session), only while online, and
/// refreshes at most [maxPerSession] entries. A failed refresh leaves the
/// database pointing at the old file.
class ThumbnailUpgradeService {
  ThumbnailUpgradeService({
    required TrackRepository trackRepository,
    required ThumbnailArtworkStore store,
    Future<bool> Function()? isOnline,
    this.maxPerSession = 3,
  })  : _trackRepository = trackRepository,
        _store = store,
        _isOnline = isOnline ?? _hasConnection;

  final TrackRepository _trackRepository;
  final ThumbnailArtworkStore _store;
  final Future<bool> Function() _isOnline;
  final int maxPerSession;
  final Logger _log = Logger();

  bool _ranThisSession = false;

  /// Returns how many thumbnails were refreshed.
  Future<int> upgradeLegacyThumbnails() async {
    if (_ranThisSession) return 0;
    _ranThisSession = true;

    try {
      if (!await _isOnline()) return 0;

      final cached = await _trackRepository.getAllCachedTracks();
      var tracks = const <Track>[];
      cached.fold(
        (failure) => _log.w(
          'Thumbnail upgrade: cache lookup failed: ${failure.message}',
        ),
        (value) => tracks = value,
      );
      if (tracks.isEmpty) return 0;

      var attempts = 0;
      var upgraded = 0;
      for (final track in tracks) {
        if (attempts >= maxPerSession) break;
        if (!await _needsUpgrade(track)) continue;
        attempts++;
        if (await _upgradeTrack(track)) upgraded++;
      }
      return upgraded;
    } catch (error, stackTrace) {
      _log.w(
        'Thumbnail upgrade skipped',
        error: error,
        stackTrace: stackTrace,
      );
      return 0;
    }
  }

  Future<bool> _upgradeTrack(Track track) async {
    final thumbnailUrl = track.thumbnailUrl;
    if (thumbnailUrl == null || thumbnailUrl.isEmpty) return false;
    final oldPath = track.localThumbnailPath;

    try {
      final newPath = await _store.storeThumbnail(
        sourceId: track.sourceId,
        thumbnailUrl: thumbnailUrl,
        width: maxCachedArtworkWidth,
      );
      if (newPath == null) {
        _log.d('Thumbnail refresh failed for ${track.sourceId}; keeping old');
        return false;
      }

      final update = await _trackRepository.updateTrack(
        track.copyWith(localThumbnailPath: newPath),
      );
      if (update.isLeft()) {
        _log.w('Thumbnail path update failed for ${track.sourceId}');
        return false;
      }

      await _deleteOfOldThumbnail(track, oldPath, newPath);
      return true;
    } catch (error, stackTrace) {
      _log.w(
        'Thumbnail upgrade failed for ${track.sourceId}',
        error: error,
        stackTrace: stackTrace,
      );
      return false;
    }
  }

  /// Deletes the replaced thumbnail only after the database points elsewhere.
  ///
  /// Audio is never touched, even if a corrupt track pointed both fields at
  /// the same file.
  Future<void> _deleteOfOldThumbnail(
    Track track,
    String? oldPath,
    String newPath,
  ) async {
    if (oldPath == null || oldPath.isEmpty || oldPath == newPath) return;
    if (oldPath == track.localAudioPath) return;
    try {
      final file = File(oldPath);
      if (await file.exists()) await file.delete();
    } catch (error) {
      _log.w('Old thumbnail cleanup failed for ${track.sourceId}: $error');
    }
  }

  Future<bool> _needsUpgrade(Track track) async {
    if (!track.isCached || track.source != TrackSource.youtube) return false;
    final thumbnailUrl = track.thumbnailUrl;
    if (thumbnailUrl == null || thumbnailUrl.isEmpty) return false;

    final path = track.localThumbnailPath;
    if (path == null || path.isEmpty) return true;
    if (!ThumbnailArtworkStore.usesCurrentName(path)) return true;
    return !await _isReadable(path);
  }

  Future<bool> _isReadable(String path) async {
    try {
      final file = File(path);
      return await file.exists() && await file.length() > minimumThumbnailBytes;
    } catch (_) {
      return false;
    }
  }
}
