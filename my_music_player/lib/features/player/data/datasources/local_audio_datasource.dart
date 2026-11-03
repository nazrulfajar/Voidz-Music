import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:path_provider/path_provider.dart';
import '../../../../core/constants/enums.dart';
import '../../domain/entities/track.dart';

final localAudioDataSourceProvider = Provider<LocalAudioDataSource>((ref) {
  return LocalAudioDataSource();
});

class LocalAudioDataSource {
  static const _channel =
      MethodChannel('io.github.nazrulfajar.voidzmusic/media');

  Future<bool> checkAndRequestPermission({bool retryRequest = false}) async {
    if (!Platform.isAndroid) return false;
    try {
      var status = await Permission.audio.status;
      if (status.isGranted) return true;
      status = await Permission.audio.request();
      if (status.isGranted) return true;
      if (status.isPermanentlyDenied) return false;
      var s2 = await Permission.storage.status;
      if (s2.isGranted) return true;
      s2 = await Permission.storage.request();
      return s2.isGranted;
    } catch (_) {
      return false;
    }
  }

  Future<bool> hasPermission() async {
    if (!Platform.isAndroid) return false;
    try {
      if (await Permission.audio.isGranted) return true;
      if (await Permission.storage.isGranted) return true;
      return false;
    } catch (_) {
      return false;
    }
  }

  int _computeBitrateKbps(int sizeBytes, int durationMs) {
    if (durationMs <= 0 || sizeBytes <= 0) return 0;
    // kbps = (bytes * 8 / seconds) / 1000 ; seconds = durationMs/1000
    return ((sizeBytes * 8000) / durationMs).round().clamp(32, 1411);
  }

  Future<String?> _saveArtwork(int albumId, String sourceId) async {
    try {
      final Uint8List? bytes = await _channel
          .invokeMethod<Uint8List>('queryArtwork', {'albumId': albumId});
      if (bytes == null || bytes.isEmpty) return null;
      if (bytes.length < 3000) return null; // skip tiny broken
      final dir = await getApplicationSupportDirectory();
      final thumbDir = Directory('${dir.path}/thumbs_local');
      if (!await thumbDir.exists()) await thumbDir.create(recursive: true);
      final file = File('${thumbDir.path}/$sourceId.jpg');
      await file.writeAsBytes(bytes, flush: true);
      return file.path;
    } catch (_) {
      return null;
    }
  }

  /// Scan device via native MediaStore channel (ponytail: no on_audio_query dependency)
  /// Optimized: tidak blok UI dengan File.existsSync per-lagu & tidak fetch artwork sync.
  /// Artwork hanya pakai cache yang sudah ada; yang belum akan di-fetch lazy di background.
  Future<List<Track>> scanDeviceSongs() async {
    // MediaStore hanya ada di Android. iOS memakai streaming + cache dulu.
    if (!Platform.isAndroid) return [];
    final hasPerm = await hasPermission();
    if (!hasPerm) {
      final granted = await checkAndRequestPermission();
      if (!granted) return [];
    }

    try {
      final List<dynamic> raw = await _channel.invokeMethod('querySongs');
      final tracks = <Track>[];
      // Cache thumb dir — pakai sync exists untuk avoid await per-loop
      String? thumbDirPath;
      try {
        final dir = await getApplicationSupportDirectory();
        thumbDirPath = '${dir.path}/thumbs_local';
        final thumbDir = Directory(thumbDirPath);
        if (!thumbDir.existsSync()) thumbDir.createSync(recursive: true);
      } catch (_) {}

      // Pre-collect albumIds yang butuh artwork agar bisa di-fetch background (tidak blok scan)
      final pendingArtworks =
          <int, String>{}; // albumId -> sourceId (first occurrence)

      for (final item in raw) {
        if (item is! Map) continue;
        final m = Map<String, dynamic>.from(item as Map);
        final id = (m['_id'] as int?) ?? 0;
        final path = (m['_data'] as String?) ?? '';
        if (path.isEmpty) continue;
        // Skip existsSync yang berat — MediaStore sudah filter IS_MUSIC & duration >30s.
        // Stale path akan difilter di provider/repo, tidak perlu blok loop.
        final rawTitle = (m['title'] as String?) ?? '';
        final display = (m['display_name'] as String?) ?? '';
        final displayWoExt = display.contains('.')
            ? display.substring(0, display.lastIndexOf('.'))
            : display;
        final title = rawTitle.trim().isEmpty ? displayWoExt : rawTitle.trim();
        final rawArtist = (m['artist'] as String?) ?? '';
        final artist = (rawArtist.trim().isEmpty || rawArtist == '<unknown>')
            ? 'Unknown Artist'
            : rawArtist.trim();
        final rawAlbum = (m['album'] as String?) ?? '';
        final album = (rawAlbum.trim().isEmpty || rawAlbum == '<unknown>')
            ? null
            : rawAlbum.trim();
        final albumId = (m['album_id'] as int?) ?? 0;
        final dur = (m['duration'] as int?) ?? 0;
        if (dur < 30000) continue;
        final size = (m['size'] as int?) ?? 0;
        final ext = (m['file_extension'] as String?) ??
            (path.contains('.') ? path.split('.').last.toLowerCase() : 'mp3');
        final rawTrack = (m['track'] as int?) ?? 0;
        final rawYear = (m['year'] as int?) ?? 0;
        int? trackNumber;
        int? discNumber;
        if (rawTrack != 0) {
          if (rawTrack >= 1000) {
            discNumber = rawTrack ~/ 1000;
            trackNumber = rawTrack % 1000;
            if (trackNumber == 0) trackNumber = rawTrack;
          } else {
            trackNumber = rawTrack;
          }
        }
        final sourceId = 'local_${id}_${path.hashCode.abs()}';
        final bitrate = _computeBitrateKbps(size, dur);

        // Fast-path thumb: pakai cache saja (sync check murah), jangan invoke MethodChannel di loop
        String? thumbPath;
        if (albumId != 0 && thumbDirPath != null) {
          final cachedPath = '$thumbDirPath/$sourceId.jpg';
          final cachedFile = File(cachedPath);
          // existsSync murah (stat cache) — tidak pakai await length
          if (cachedFile.existsSync()) {
            try {
              if (cachedFile.lengthSync() > 3000) thumbPath = cachedPath;
            } catch (_) {
              // ignore, treat as missing
            }
          }
          if (thumbPath == null) {
            // Queue untuk fetch background (hanya sekali per albumId untuk hemat channel call)
            pendingArtworks.putIfAbsent(albumId, () => sourceId);
          }
        }

        tracks.add(Track(
          sourceId: sourceId,
          title: title.isEmpty ? displayWoExt : title,
          artist: artist,
          album: album,
          durationMs: dur,
          thumbnailUrl: null,
          localThumbnailPath: thumbPath,
          source: TrackSource.local,
          localAudioPath: path,
          isCached: true,
          isPinned: true,
          fileSizeBytes: size,
          audioFormat: ext.toLowerCase(),
          bitrateKbps: bitrate == 0 ? null : bitrate,
          trackNumber: trackNumber,
          discNumber: discNumber,
          year: (rawYear != 0) ? rawYear : null,
          cachedAt: DateTime.now(),
        ));
      }

      // Fire & forget: fetch missing artworks di background tanpa blok scan return
      if (pendingArtworks.isNotEmpty && thumbDirPath != null) {
        // jangan await — biar scan return langsung, UI tidak lag
        // ignore: unawaited_futures
        _prefetchArtworks(pendingArtworks, thumbDirPath);
      }

      return tracks;
    } on MissingPluginException {
      return [];
    } catch (e) {
      print('scanDeviceSongs error: $e');
      return [];
    }
  }

  /// Prefetch artwork yang belum cached — throttle 3 concurrent, low priority
  Future<void> _prefetchArtworks(
      Map<int, String> pending, String thumbDirPath) async {
    // Batasi agar tidak membanjiri MethodChannel
    const maxConcurrent = 3;
    final entries = pending.entries.toList();
    for (int i = 0; i < entries.length; i += maxConcurrent) {
      final batch = entries.skip(i).take(maxConcurrent);
      await Future.wait(batch.map((e) async {
        try {
          final bytes = await _channel
              .invokeMethod<Uint8List>('queryArtwork', {'albumId': e.key});
          if (bytes == null || bytes.length < 3000) return;
          final file = File('$thumbDirPath/${e.value}.jpg');
          if (file.existsSync()) return; // sudah diisi oleh scan lain
          await file.writeAsBytes(bytes, flush: true);
        } catch (_) {}
      }));
      // kecil delay agar main thread breath
      await Future.delayed(const Duration(milliseconds: 80));
    }
  }

  Future<Uint8List?> queryArtworkBytes(int albumId) async {
    try {
      return await _channel
          .invokeMethod<Uint8List>('queryArtwork', {'albumId': albumId});
    } catch (_) {
      return null;
    }
  }
}
