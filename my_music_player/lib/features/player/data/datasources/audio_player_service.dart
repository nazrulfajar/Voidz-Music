import 'dart:async';
import 'dart:io';
import 'package:audio_session/audio_session.dart';
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:just_audio/just_audio.dart';
import 'package:just_audio_background/just_audio_background.dart';
import '../../../../core/network/local_proxy_server.dart';
import '../../../../core/utils/cache_dir_helper.dart';

final audioPlayerServiceProvider = Provider<AudioPlayerService>((ref) {
  final service = AudioPlayerService();
  ref.onDispose(() => service.dispose());
  return service;
});

class AudioPlayerService {
  // Transparent 1x1 PNG to hide white largeIcon box (Infinix MediaStyle placeholder)
  static String? transparentArtPath;
  final AudioPlayer _player;
  ConcatenatingAudioSource? _playlist;
  AudioSession? _session;
  StreamSubscription<AudioInterruptionEvent>? _interruptionSub;
  StreamSubscription<void>? _becomingNoisySub;
  bool _wasPlayingBeforeInterruption = false;
  double _volumeBeforeDuck = 1.0;

  /// Callback to check if audio focus handling is enabled (from AppSettings)
  bool Function()? _audioFocusEnabledCheck;

  // Ponytail: buffer kecil untuk local file agar seek/play instant & tidak lag; network tetap lancar
  AudioPlayerService()
      : _player = AudioPlayer(
          audioLoadConfiguration: const AudioLoadConfiguration(
            androidLoadControl: AndroidLoadControl(
              minBufferDuration: Duration(seconds: 8),
              maxBufferDuration: Duration(seconds: 20),
              backBufferDuration: Duration(seconds: 3),
            ),
            darwinLoadControl: DarwinLoadControl(
              preferredForwardBufferDuration: Duration(seconds: 8),
            ),
          ),
        );

  AudioPlayer get player => _player;

  Stream<int?> get currentIndexStream => _player.currentIndexStream;

  void setAudioFocusCheck(bool Function() check) {
    _audioFocusEnabledCheck = check;
  }

  Future<void> init() async {
    try {
      _session = await AudioSession.instance;
      await _session!.configure(const AudioSessionConfiguration.music());

      _interruptionSub = _session!.interruptionEventStream.listen((event) {
        final enabled = _audioFocusEnabledCheck?.call() ?? true;
        if (!enabled) return;
        if (event.begin) {
          switch (event.type) {
            case AudioInterruptionType.duck:
              _volumeBeforeDuck = _player.volume;
              _player.setVolume(_volumeBeforeDuck * 0.5);
              break;
            case AudioInterruptionType.pause:
            case AudioInterruptionType.unknown:
              _wasPlayingBeforeInterruption = _player.playing;
              _player.pause();
              break;
          }
        } else {
          switch (event.type) {
            case AudioInterruptionType.duck:
              _player.setVolume(_volumeBeforeDuck);
              break;
            case AudioInterruptionType.pause:
            case AudioInterruptionType.unknown:
              if (_wasPlayingBeforeInterruption) {
                _player.play();
              }
              break;
          }
        }
      });

      _becomingNoisySub = _session!.becomingNoisyEventStream.listen((_) {
        // Always pause on headset unplug to avoid speaker leak
        _player.pause();
      });

      // Activate session
      await _session!.setActive(true);
    } catch (e) {
      print('AudioSession init failed: $e');
    }
  }

  Future<void> startPlaylist(List<AudioSource> sources,
      {int initialIndex = 0}) async {
    try {
      _playlist = ConcatenatingAudioSource(
        children: sources,
        useLazyPreparation: true,
        shuffleOrder: DefaultShuffleOrder(),
      );
      await _player.setAudioSource(_playlist!,
          initialIndex: initialIndex, preload: true);
    } catch (e) {
      print("Error setting audio source: \$e");
      rethrow;
    }
  }

  Future<void> appendToPlaylist(AudioSource source) async {
    if (_playlist != null) {
      await _playlist!.add(source);
    }
  }

  Future<void> clearUpcoming() async {
    if (_playlist != null && _player.currentIndex != null) {
      final nextIdx = _player.currentIndex! + 1;
      if (nextIdx < _playlist!.length) {
        await _playlist!.removeRange(nextIdx, _playlist!.length);
      }
    }
  }

  Future<void> moveInPlaylist(int oldIndex, int newIndex) async {
    if (_playlist != null) {
      await _playlist!.move(oldIndex, newIndex);
    }
  }

  Future<void> removeFromPlaylist(int index) async {
    if (_playlist != null && index >= 0 && index < _playlist!.length) {
      await _playlist!.removeAt(index);
    }
  }

  /// Premium: resolve artUri — ponytail tanpa File.existsSync di main thread (lag local).
  /// Prioritas: local file → remote https → transparent. Untuk local, langsung Uri.file tanpa stat.
  Uri? _resolveArtUri({String? localPath, String? remoteUrl}) {
    // 1. Local file cached — langsung file, tidak stat (Image/FileImage akan handle miss via errorBuilder)
    if (localPath != null && localPath.isNotEmpty) {
      try {
        if (localPath.startsWith('/')) {
          return Uri.file(localPath);
        }
        if (localPath.startsWith('http://') ||
            localPath.startsWith('https://')) {
          return Uri.parse(localPath);
        }
      } catch (_) {}
    }
    // 2. Remote thumbnail_url
    if (remoteUrl != null && remoteUrl.isNotEmpty) {
      final t = remoteUrl.trim();
      if (t.startsWith('http://') || t.startsWith('https://')) {
        try {
          return Uri.parse(t);
        } catch (_) {}
      } else if (t.startsWith('/')) {
        // Tanpa stat — langsung file
        try {
          return Uri.file(t);
        } catch (_) {}
      }
    }
    // 3. Fallback transparan 1x1 hanya jika benar-benar tidak ada art
    if (transparentArtPath != null) {
      try {
        return Uri.file(transparentArtPath!);
      } catch (_) {}
    }
    return null;
  }

  /// Async cache thumb remote ke file lokal untuk next playback offline — fire & forget
  void _ensureThumbCached(String sourceId, String remoteUrl) {
    // Jangan block UI; cek file exists async di background
    Future.microtask(() async {
      try {
        final cacheDir = await getCacheDir();
        final thumbName = buildThumbFileName(sourceId, remoteUrl);
        final thumbPath = '${cacheDir.path}/$thumbName';
        final f = File(thumbPath);
        if (await f.exists() && await f.length() > 1000) return;
        // Download thumb — pakai Dio ringan
        final dio = Dio(BaseOptions(
            connectTimeout: const Duration(seconds: 10),
            receiveTimeout: const Duration(seconds: 15)));
        await dio.download(remoteUrl, thumbPath);
      } catch (_) {}
    });
  }

  AudioSource createAudioSourceFromTrack(String url, dynamic track,
      {Map<String, String>? headers, bool isLocal = false}) {
    final String id = track.sourceId as String;
    final String title = track.title as String;
    final String? artist = track.artist as String?;
    final String? album = track.album as String?;
    final int durationMs = (track.durationMs as int?) ?? 0;
    final String? localThumb = track.localThumbnailPath as String?;
    final String? remoteThumb = track.thumbnailUrl as String?;
    Uri? art = _resolveArtUri(localPath: localThumb, remoteUrl: remoteThumb);
    // Jika masih remote dan belum ada file lokal, trigger background cache — tanpa existsSync blok
    if (remoteThumb != null && remoteThumb.isNotEmpty) {
      final needsCache = localThumb == null || localThumb.isEmpty;
      if (needsCache && art != null && art.scheme.startsWith('http')) {
        _ensureThumbCached(id, remoteThumb);
      }
    }
    final mediaItem = MediaItem(
      id: id,
      title: title,
      artist: artist ?? 'Unknown',
      album: album,
      duration: durationMs > 0 ? Duration(milliseconds: durationMs) : null,
      artUri: art,
    );
    if (isLocal) {
      return AudioSource.file(url, tag: mediaItem);
    } else {
      final proxiedUrl =
          LocalProxyServer.instance.addUrl(url, headers: headers);
      return AudioSource.uri(Uri.parse(proxiedUrl), tag: mediaItem);
    }
  }

  AudioSource createAudioSource(String url,
      {required String id,
      required String title,
      String? artist,
      String? album,
      String? artUri,
      Duration? duration,
      Map<String, String>? headers,
      bool isLocal = false}) {
    Uri? art;
    // artUri param bisa berupa local path atau remote https — pakai resolver sama
    if (artUri != null && artUri.isNotEmpty) {
      final t = artUri.trim();
      if (t.startsWith('http://') || t.startsWith('https://')) {
        try {
          art = Uri.parse(t);
        } catch (_) {}
        _ensureThumbCached(id, t);
      } else if (t.startsWith('/')) {
        art = _resolveArtUri(localPath: t, remoteUrl: null);
      } else {
        art = _resolveArtUri(localPath: null, remoteUrl: t);
      }
    }
    art ??= _resolveArtUri(localPath: null, remoteUrl: null);
    final mediaItem = MediaItem(
      id: id,
      title: title,
      artist: artist ?? 'Unknown',
      album: album,
      duration: duration,
      artUri: art,
    );

    if (isLocal) {
      return AudioSource.file(
        url,
        tag: mediaItem,
      );
    } else {
      // Use our LocalProxyServer to fetch the stream, bypassing ExoPlayer's HTTP limitations!
      final proxiedUrl =
          LocalProxyServer.instance.addUrl(url, headers: headers);

      return AudioSource.uri(
        Uri.parse(proxiedUrl),
        tag: mediaItem,
      );
    }
  }

  Future<void> play() async => await _player.play();

  Future<void> pause() async => await _player.pause();

  Future<void> stop() async => await _player.stop();

  Future<void> seek(Duration position) async => await _player.seek(position);

  Future<void> setRepeatMode(LoopMode mode) async =>
      await _player.setLoopMode(mode);

  Future<void> setShuffleModeEnabled(bool enabled) async =>
      await _player.setShuffleModeEnabled(enabled);

  Future<void> setVolume(double volume) async =>
      await _player.setVolume(volume);

  int _fadeId = 0; // cancelable token for overlapping fades (manual vs auto)

  Future<void> _fadeVolume(
      {required double from,
      required double to,
      required int steps,
      required int stepMs}) async {
    final id = ++_fadeId;
    for (int i = 0; i <= steps; i++) {
      if (id != _fadeId) return; // cancelled by newer fade
      final t = i / steps;
      final curved = from + (to - from) * (t * t); // exponential
      await _player.setVolume(curved.clamp(0.0, 1.0));
      await Future.delayed(Duration(milliseconds: stepMs));
      if (!_player.playing && id == _fadeId) break;
    }
  }

  /// Premium crossfade: cancelable, no silence gap, single volume timeline
  Future<void> crossfadeToNext(int seconds) async {
    if (seconds <= 0) {
      if (_player.hasNext) await _player.seekToNext();
      return;
    }
    const steps = 20;
    final half = seconds / 2;
    final stepMs = (half * 1000 / steps).round().clamp(30, 400);
    // Fade out
    await _fadeVolume(
        from: _player.volume, to: 0.0, steps: steps, stepMs: stepMs);
    if (_player.hasNext) {
      await _player.seekToNext();
    } else {
      await _player.seek(Duration.zero);
    }
    await Future.delayed(const Duration(milliseconds: 60));
    // Fade in
    await _fadeVolume(from: 0.0, to: 1.0, steps: steps, stepMs: stepMs);
    await _player.setVolume(1.0);
  }

  Future<void> crossfadeToPrevious(int seconds) async {
    if (seconds <= 0) {
      if (_player.hasPrevious) await _player.seekToPrevious();
      return;
    }
    const steps = 20;
    final half = seconds / 2;
    final stepMs = (half * 1000 / steps).round().clamp(30, 400);
    await _fadeVolume(
        from: _player.volume, to: 0.0, steps: steps, stepMs: stepMs);
    if (_player.position.inSeconds > 3) {
      await _player.seek(Duration.zero);
    } else if (_player.hasPrevious) {
      await _player.seekToPrevious();
    }
    await _fadeVolume(from: 0.0, to: 1.0, steps: steps, stepMs: stepMs);
    await _player.setVolume(1.0);
  }

  /// Auto crossfade when position nears end — cancelable via _fadeId
  StreamSubscription<Duration>? _autoCrossfadeSub;
  void enableAutoCrossfade(int Function() crossfadeSecondsProvider) {
    _autoCrossfadeSub?.cancel();
    Duration? lastDuration;
    _player.durationStream.listen((d) => lastDuration = d);
    _autoCrossfadeSub = _player.positionStream.listen((pos) async {
      final dur = lastDuration ?? _player.duration;
      if (dur == null) return;
      final seconds = crossfadeSecondsProvider();
      if (seconds <= 0) return;
      final remaining = dur - pos;
      if (remaining.inMilliseconds > 0 &&
          remaining.inMilliseconds <= seconds * 1000 &&
          remaining.inMilliseconds > (seconds * 1000 - 600) &&
          _player.playing &&
          _player.hasNext) {
        // Use shared fade token so manual crossfade cancels auto
        final id = ++_fadeId;
        const steps = 12;
        final stepMs =
            (remaining.inMilliseconds / steps).round().clamp(40, 500);
        for (int i = steps; i >= 2; i--) {
          if (id != _fadeId) return;
          final vol = (i / steps) * (i / steps);
          await _player.setVolume(vol);
          await Future.delayed(Duration(milliseconds: stepMs));
          if (!_player.playing) break;
        }
        Future.delayed(Duration(milliseconds: (seconds * 500).round()),
            () async {
          if (id != _fadeId || !_player.playing) return;
          for (int i = 2; i <= steps; i++) {
            if (id != _fadeId) return;
            final vol = (i / steps) * (i / steps);
            await _player.setVolume(vol);
            await Future.delayed(Duration(milliseconds: stepMs));
          }
          if (id == _fadeId) await _player.setVolume(1.0);
        });
      }
    });
  }

  void dispose() {
    _interruptionSub?.cancel();
    _becomingNoisySub?.cancel();
    _autoCrossfadeSub?.cancel();
    _session?.setActive(false);
    _player.dispose();
  }
}
