import 'dart:io';

import '../../../../core/utils/artwork_url.dart';

/// Minimum size a downloaded artwork must have to be considered valid.
const int minimumThumbnailBytes = 1000;

/// Downloads an artwork URL into [path].
typedef ThumbnailDownloader = Future<void> Function(String url, String path);

/// Resolves the directory where cached artwork lives.
typedef CacheDirectoryResolver = Future<Directory> Function();

/// Stores cache artwork atomically under a width-tagged filename.
///
/// A download is written to `<target>.part`, validated, then renamed into
/// place, so a failed refresh can never truncate or remove a thumbnail the
/// database still points at.
class ThumbnailArtworkStore {
  ThumbnailArtworkStore({
    required this.cacheDirectory,
    required this.downloader,
  });

  final CacheDirectoryResolver cacheDirectory;
  final ThumbnailDownloader downloader;

  /// Builds the on-disk name used for artwork cached at [width].
  static String thumbnailFileName(
    String sourceId,
    int width,
    String extension,
  ) {
    return '${sourceId}_thumb_w$width.$extension';
  }

  /// Derives the file extension from [url], defaulting to `jpg`.
  static String thumbnailExtension(String url) {
    final urlWithoutQuery = url.split('?').first;
    if (urlWithoutQuery.contains('.')) {
      final extension = urlWithoutQuery.split('.').last.toLowerCase();
      if (extension.length <= 4 &&
          !extension.contains('-') &&
          !extension.contains('/')) {
        return extension;
      }
    }
    return 'jpg';
  }

  /// Whether [path] already uses the width-tagged naming convention.
  static bool usesCurrentName(
    String path, {
    int width = maxCachedArtworkWidth,
  }) {
    final name = path.split(RegExp(r'[/\\]')).last;
    return name.contains('_thumb_w$width.');
  }

  /// Downloads [thumbnailUrl] as a [width]-sized square artwork.
  ///
  /// Returns the final path on success, or `null` when the download fails or
  /// produces an unusably small file. A pre-existing valid file is reused
  /// without hitting the network. The caller's old thumbnail is never deleted
  /// here; only the temporary `.part` file of a failed attempt is removed.
  Future<String?> storeThumbnail({
    required String sourceId,
    required String thumbnailUrl,
    int width = maxCachedArtworkWidth,
  }) async {
    File? partial;
    try {
      final directory = await cacheDirectory();
      final extension = thumbnailExtension(thumbnailUrl);
      final target = File(
        '${directory.path}${Platform.pathSeparator}'
        '${thumbnailFileName(sourceId, width, extension)}',
      );
      if (await _isValid(target)) return target.path;

      partial = File('${target.path}.part');
      await _deleteIfExists(partial);
      await downloader(youtubeArtworkUrl(thumbnailUrl, width), partial.path);
      if (!await _isValid(partial)) return null;

      // The target only reaches this branch when it is absent or unusable;
      // replace it now that a validated download exists.
      await _deleteIfExists(target);
      await partial.rename(target.path);
      return target.path;
    } catch (_) {
      return null;
    } finally {
      if (partial != null) {
        await _deleteIfExists(partial);
      }
    }
  }

  Future<bool> _isValid(File file) async {
    try {
      return await file.exists() && await file.length() > minimumThumbnailBytes;
    } catch (_) {
      return false;
    }
  }

  Future<void> _deleteIfExists(File file) async {
    try {
      if (await file.exists()) {
        await file.delete();
      }
    } catch (_) {
      // Best effort: a stale temp file must never fail the refresh.
    }
  }
}
