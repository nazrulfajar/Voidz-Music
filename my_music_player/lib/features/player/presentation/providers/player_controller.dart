import 'dart:async';
import 'dart:io';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:permission_handler/permission_handler.dart';
import '../../../../core/network/local_proxy_server.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:just_audio/just_audio.dart';
import 'package:just_audio_background/just_audio_background.dart';
import '../../data/datasources/audio_player_service.dart';
import '../../domain/entities/track.dart';

import '../../../../core/network/api_service.dart';
import '../../domain/repositories/track_repository.dart';
import '../../data/repositories/track_repository_impl.dart';

import '../../../cache/data/datasources/cache_download_service.dart';
import '../../data/models/queue_state_model.dart';
import '../../data/models/queue_item_model.dart';
import '../../data/repositories/queue_repository.dart';
import '../../../cache/domain/cache_policy.dart';
import '../../../../core/constants/enums.dart';
import '../../../../core/providers/connectivity_provider.dart';
import '../../../settings/presentation/providers/settings_provider.dart';
import '../../../library/presentation/providers/playlist_provider.dart';
import '../../../library/presentation/providers/playlist_detail_provider.dart';
import '../../../library/data/repositories/playlist_repository_impl.dart';
import '../../../home/presentation/providers/home_provider.dart';
import 'sleep_timer_provider.dart';

final playerControllerProvider =
    StateNotifierProvider<PlayerController, PlayerState>((ref) {
  final audioService = ref.read(audioPlayerServiceProvider);
  final apiService = ref.read(apiServiceProvider);
  final trackRepo = ref.read(trackRepositoryProvider);
  final cacheDownloadService = ref.read(cacheDownloadServiceProvider);
  return PlayerController(
      audioService, apiService, trackRepo, cacheDownloadService, ref);
});

class PlayerState {
  final Track? currentTrack;
  final List<Track> currentQueue;
  final int currentIndex;
  final bool isPlaying;
  final Duration position;
  final Duration duration;
  final LoopMode loopMode;
  final bool isShuffleEnabled;
  final String? errorMessage;

  PlayerState({
    this.currentTrack,
    this.currentQueue = const [],
    this.currentIndex = -1,
    this.isPlaying = false,
    this.position = Duration.zero,
    this.duration = Duration.zero,
    this.loopMode = LoopMode.off,
    this.isShuffleEnabled = false,
    this.errorMessage,
  });

  PlayerState copyWith({
    Track? currentTrack,
    List<Track>? currentQueue,
    int? currentIndex,
    bool? isPlaying,
    Duration? position,
    Duration? duration,
    LoopMode? loopMode,
    bool? isShuffleEnabled,
    String? errorMessage,
  }) {
    return PlayerState(
      currentTrack: currentTrack ?? this.currentTrack,
      currentQueue: currentQueue ?? this.currentQueue,
      currentIndex: currentIndex ?? this.currentIndex,
      isPlaying: isPlaying ?? this.isPlaying,
      position: position ?? this.position,
      duration: duration ?? this.duration,
      loopMode: loopMode ?? this.loopMode,
      isShuffleEnabled: isShuffleEnabled ?? this.isShuffleEnabled,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }

  PlayerState clearError() {
    return PlayerState(
      currentTrack: currentTrack,
      currentQueue: currentQueue,
      currentIndex: currentIndex,
      isPlaying: isPlaying,
      position: position,
      duration: duration,
      loopMode: loopMode,
      isShuffleEnabled: isShuffleEnabled,
      errorMessage: null,
    );
  }
}

class PlayerController extends StateNotifier<PlayerState> {
  final AudioPlayerService _audioService;
  final ApiService _apiService;
  final TrackRepository _trackRepo;
  final CacheDownloadService _cacheDownloadService;
  final Ref _ref;

  List<Track> _originalQueue = [];
  List<Track> _currentQueue = [];
  int _currentIndex = -1;
  bool _isResolvingNext = false;
  bool _isFetchingUpNext = false;
  int _queueSessionId = 0;
  // Tracks the source IDs that were auto-fetched (not part of the user's original queue)
  final Set<String> _autoQueueSourceIds = {};
  final Map<String, Map<String, String>> _trackHeaders = {};
  Timer? _saveDebounce;
  final List<StreamSubscription> _subscriptions = [];
  int _consecutiveResolveFailures = 0;
  static const int _maxQueueSize = 500;

  PlayerController(this._audioService, this._apiService, this._trackRepo,
      this._cacheDownloadService, this._ref)
      : super(PlayerState()) {
    _initStreams();
    // Wire audio focus check to AudioPlayerService
    _audioService.setAudioFocusCheck(() {
      final settings = _ref.read(appSettingsProvider).value;
      return settings?.audioFocusPause ?? true;
    });
    // Init audio session (fire and forget)
    _audioService.init();
    // Enable auto crossfade for gapless queue (reads live setting)
    _audioService.enableAutoCrossfade(() {
      final s = _ref.read(appSettingsProvider).value;
      return s?.crossfadeSeconds.clamp(0, 12) ?? 0;
    });
    // Wire proxy 403 re-resolve
    LocalProxyServer.instance.onResolveExpired = (expiredUrl) async {
      try {
        // Find track that owns this expired URL
        Track? owner;
        for (final t in _currentQueue) {
          if (t.streamUrl == expiredUrl) {
            owner = t;
            break;
          }
        }
        owner ??= state.currentTrack;
        if (owner == null) return null;
        final settings = _ref.read(appSettingsProvider).value;
        final quality = settings?.preferredAudioQuality.name ?? 'medium';
        final data = await _apiService.resolve(owner.sourceId,
            source: owner.source.name, quality: quality);
        final newUrl = data['stream_url'] as String?;
        if (newUrl != null) {
          // Update track headers & track in queue
          final rawHeaders = data['headers'];
          if (rawHeaders != null) {
            _trackHeaders[owner.sourceId] = rawHeaders.map<String, String>(
                (k, v) => MapEntry(k.toString(), v.toString()));
          }
          // Update queue entry with fresh url
          final idx =
              _currentQueue.indexWhere((t) => t.sourceId == owner!.sourceId);
          if (idx != -1) {
            _currentQueue[idx] = _currentQueue[idx].copyWith(
              streamUrl: newUrl,
              streamUrlExpiresAt: DateTime.tryParse(data['expires_at'] ?? ''),
            );
          }
          return newUrl;
        }
      } catch (e) {
        print('Proxy re-resolve failed: $e');
      }
      return null;
    };
    _ref.listen(appSettingsProvider, (previous, next) {
      if (previous?.value?.preferredAudioQuality !=
          next.value?.preferredAudioQuality) {
        _onAudioQualityChanged();
      }
    });
  }

  Future<void> _onAudioQualityChanged() async {
    if (_currentQueue.isEmpty || _currentIndex < 0) return;

    // Clear cached stream URLs from memory for upcoming un-cached tracks
    for (int i = _currentIndex + 1; i < _currentQueue.length; i++) {
      if (!_currentQueue[i].isCached) {
        _currentQueue[i] = _currentQueue[i]
            .copyWith(streamUrl: null, streamUrlExpiresAt: null);
      }
    }

    // Clear upcoming tracks in just_audio playlist
    await _audioService.clearUpcoming();

    // Re-resolve and append upcoming tracks with new quality
    _queueSessionId++;
    _isResolvingNext = false;
    _resolveAndAppendNextTrack();
  }

  void _initStreams() {
    _subscriptions.add(_audioService.player.playingStream.listen((playing) {
      state = state.copyWith(isPlaying: playing);
    }));

    _subscriptions
        .add(_audioService.player.playerStateStream.listen((playerState) {
      // Premium: LoopOne sudah ditangani just_audio LoopMode.one — jangan restart manual
      // LoopOff completed → biarkan pause, jangan seek0+play (bug sebelumnya)
      if (playerState.processingState == ProcessingState.completed &&
          state.loopMode == LoopMode.one &&
          _audioService.player.position == Duration.zero) {
        _audioService.player.seek(Duration.zero);
        _audioService.player.play();
      }
    }));

    _subscriptions.add(_audioService.player.playbackEventStream
        .listen((event) {}, onError: (Object e, StackTrace stackTrace) async {
      print('Playback event error: $e');
      // Try to re-resolve current track on 403/network error
      final current = state.currentTrack;
      if (current != null && e.toString().contains('403')) {
        try {
          final fresh = await _resolveTrack(current);
          if (fresh != null && fresh.streamUrl != null) {
            // Re-create source with fresh URL — premium: full MediaItem
            final isLocal = fresh.isCached && fresh.localAudioPath != null;
            final uri = isLocal ? fresh.localAudioPath! : fresh.streamUrl!;
            final source = _audioService.createAudioSourceFromTrack(uri, fresh,
                headers: _trackHeaders[fresh.sourceId], isLocal: isLocal);
            // Keep queue in sync
            if (_currentIndex >= 0 && _currentIndex < _currentQueue.length) {
              _currentQueue[_currentIndex] = fresh;
            }
            await _audioService.player.setAudioSource(source);
            await _audioService.player.play();
            state = state.clearError();
            return;
          }
        } catch (_) {}
      }
      state = state.copyWith(
          errorMessage:
              'Network error: Please check your internet connection.');
    }));

    // Throttle position update ke 200ms untuk hindari rebuild flood (lag local)
    Duration _lastPos = Duration.zero;
    DateTime _lastPosTime = DateTime.fromMillisecondsSinceEpoch(0);
    _subscriptions.add(_audioService.player.positionStream.listen((pos) {
      final now = DateTime.now();
      if (pos.inMilliseconds - _lastPos.inMilliseconds < 200 &&
          now.difference(_lastPosTime).inMilliseconds < 200) {
        return;
      }
      _lastPos = pos;
      _lastPosTime = now;
      state = state.copyWith(position: pos);
    }));

    _subscriptions.add(_audioService.player.durationStream.listen((dur) {
      if (dur != null) {
        state = state.copyWith(duration: dur);
      }
    }));

    _subscriptions.add(_audioService.player.loopModeStream.listen((mode) {
      state = state.copyWith(loopMode: mode);
    }));

    // We manage shuffle manually
    // _audioService.player.shuffleModeEnabledStream.listen((enabled) {
    //   state = state.copyWith(isShuffleEnabled: enabled);
    // });

    _subscriptions
        .add(_audioService.player.sequenceStateStream.listen((sequenceState) async {
      if (sequenceState == null) return;
      final currentSource = sequenceState.currentSource;
      if (currentSource == null) return;

      final tag = currentSource.tag;
      if (tag is MediaItem) {
        final sourceId = tag.id;
        final index = _currentQueue.indexWhere((t) => t.sourceId == sourceId);

        if (index != -1 && index != _currentIndex) {
          print(
              'DEBUG: sequenceStateStream - changing index from $_currentIndex to $index (sourceId: $sourceId)');
          _currentIndex = index;
          final newTrack = _currentQueue[index];
          state = state.copyWith(currentTrack: newTrack, currentIndex: index);

          // Premium konsisten: TrackModel update + PlayHistory log + queue save (survive hot restart)
          // Await agar tidak hilang saat hot restart langsung setelah auto-next
          await _recordPlayHistory(newTrack);
          _scheduleSaveQueue();

          // Resolve next track if needed
          _resolveAndAppendNextTrack();
        }
      }
    }));
  }

  void _scheduleSaveQueue() {
    _saveDebounce?.cancel();
    _saveDebounce = Timer(const Duration(milliseconds: 500), () {
      saveQueueState();
    });
  }

  Future<void> _ensureNotificationPermission() async {
    try {
      final status = await Permission.notification.status;
      if (status.isDenied) {
        await Permission.notification.request();
      }
    } catch (_) {}
  }

  // History & RecentlyPlayed konsisten dengan antrean & survive hot restart (ponytail: atomik + handle track baru)
  Future<void> _recordPlayHistory(Track track) async {
    final sourceId = track.sourceId;
    final source = track.source.name;
    // 1. Update playCount/lastPlayedAt — jika track belum di DB (search YT baru), buat dulu
    final updateRes = await _trackRepo.updateTrackPlayCount(sourceId, source);
    // Jika tidak ada model (track baru), save dengan playCount 1
    updateRes.fold((_) {}, (_) {});
    try {
      final check = await _trackRepo.getTrack(sourceId, source);
      final exists = check.fold((_) => false, (t) => t != null);
      if (!exists) {
        await _trackRepo.saveTrack(track.copyWith(playCount: 1, lastPlayedAt: DateTime.now()));
        // Coba update lagi untuk increment yang terlewat (first play sudah 1, tidak perlu increment lagi)
      } else {
        // Jika update gagal karena model null sebelumnya (misal save concurrent), pastikan lastPlayedAt sudah ter-set
        // updateTrackPlayCount sudah handle increment; jika track baru tadi sudah di-save, playCount sudah 1
      }
    } catch (_) {}
    // 2. PlayHistory (10000 limit) — untuk yearly Recap
    try {
      final plRepo = _ref.read(playlistRepositoryProvider);
      await plRepo.addToPlayHistory(sourceId);
    } catch (_) {}
    // 3. Invalidate semua consumer history/recently — konsisten antrean ↔ UI
    _ref.invalidate(allPlaylistsProvider);
    _ref.invalidate(playlistTracksProvider);
    _ref.invalidate(recentlyPlayedProvider);
    _ref.invalidate(quickPicksProvider);
  }

  // Backward compat overload dipakai unit test / legacy
  Future<void> _recordPlayHistoryById(String sourceId, String source) async {
    // Cari Track di queue dulu untuk handle creation
    final found = _currentQueue.where((t) => t.sourceId == sourceId).firstOrNull ?? state.currentTrack;
    if (found != null && found.sourceId == sourceId) {
      await _recordPlayHistory(found);
    } else {
      await _trackRepo.updateTrackPlayCount(sourceId, source);
      try {
        final plRepo = _ref.read(playlistRepositoryProvider);
        await plRepo.addToPlayHistory(sourceId);
      } catch (_) {}
      _ref.invalidate(allPlaylistsProvider);
      _ref.invalidate(playlistTracksProvider);
      _ref.invalidate(recentlyPlayedProvider);
    }
  }

  @override
  void dispose() {
    _saveDebounce?.cancel();
    for (final s in _subscriptions) {
      s.cancel();
    }
    _subscriptions.clear();
    LocalProxyServer.instance.onResolveExpired = null;
    super.dispose();
  }

  Future<void> playTrack(Track track, {List<Track>? queue}) async {
    await _ensureNotificationPermission();
    state = state.clearError();
    _queueSessionId++;
    _isResolvingNext = false;
    _isFetchingUpNext = false;

    _originalQueue = queue != null ? List<Track>.from(queue) : [track];

    if (state.isShuffleEnabled) {
      final remaining = _originalQueue
          .where((t) => t.sourceId != track.sourceId)
          .toList()
        ..shuffle();
      _currentQueue = [track, ...remaining];
      _currentIndex = 0;
    } else {
      _currentQueue = List.from(_originalQueue);
      _currentIndex =
          _currentQueue.indexWhere((t) => t.sourceId == track.sourceId);
      if (_currentIndex == -1) {
        _currentQueue.insert(0, track);
        _currentIndex = 0;
      }
    }
    // Clear auto-queue tracking whenever a new queue is started
    _autoQueueSourceIds.clear();

    state = state.copyWith(
      currentTrack: _currentQueue[_currentIndex],
      currentQueue: _currentQueue,
      currentIndex: _currentIndex,
    );

    final resolvedTrack = await _resolveTrack(track);
    if (resolvedTrack == null) {
      state = state.copyWith(
          errorMessage:
              'Failed to resolve "${track.title}". Please check your connection.');
      return;
    }

    _currentQueue[_currentIndex] = resolvedTrack;
    state = state.copyWith(
        currentTrack: resolvedTrack, currentQueue: List.from(_currentQueue));

    final isLocal =
        resolvedTrack.isCached && resolvedTrack.localAudioPath != null;
    final uri =
        isLocal ? resolvedTrack.localAudioPath! : resolvedTrack.streamUrl!;

    final source = _audioService.createAudioSourceFromTrack(uri, resolvedTrack,
        headers: _trackHeaders[resolvedTrack.sourceId], isLocal: isLocal);

    try {
      await _audioService.startPlaylist([source]);
      await _audioService.play();
    } catch (e) {
      print('Failed to play track: $e');
      state = state.copyWith(
          errorMessage:
              'Network error: Failed to stream track. Please check connection.');
      return;
    }

    // Trigger background cache download targets
    _updateCacheTargets();

    await _recordPlayHistory(resolvedTrack);

    _resolveAndAppendNextTrack();
    _scheduleSaveQueue();
  }

  Future<void> _updateCacheTargets() async {
    final settings = _ref.read(appSettingsProvider).value;
    final policy = _ref.read(cachePolicyProvider);
    // Single guard via CachePolicy — cache_download_service tidak lagi cek wifi
    if (settings != null) {
      final conn = await Connectivity().checkConnectivity();
      final results = conn.toList();
      // policy expects List<ConnectivityResult> or single
      final allow = policy.shouldAllowDownloadFromResults(
        autoCacheEnabled: settings.autoCacheEnabled,
        wifiOnly: settings.wifiOnlyDownload,
        results: results,
      );
      if (!allow) return;
    }

    final candidates = <Track>[];

    // Keep previous track if it was being downloaded (don't cancel mid-download)
    if (_currentIndex > 0) {
      final prev = _currentQueue[_currentIndex - 1];
      if (prev.streamUrl != null &&
          !prev.isCached &&
          _cacheDownloadService.isDownloading(prev.sourceId)) {
        candidates.add(prev);
      }
    }

    if (state.currentTrack != null &&
        _currentIndex >= 0 &&
        _currentIndex < _currentQueue.length) {
      final t = _currentQueue[_currentIndex];
      if (t.streamUrl != null && !t.isCached) candidates.add(t);
    }

    for (int i = 1; i <= 4; i++) {
      if (_currentIndex + i < _currentQueue.length) {
        final t = _currentQueue[_currentIndex + i];
        if (t.streamUrl != null && !t.isCached) candidates.add(t);
      }
    }

    // Dedup + policy skip (high-quality preserve) — single DB hit via batch
    final seen = <String>{};
    final deduped = candidates.where((t) => seen.add(t.sourceId)).toList();
    if (deduped.isEmpty) {
      _cacheDownloadService.setTargetTracks([]);
      return;
    }
    final ids = deduped.map((t) => t.sourceId).toList();
    final existingTracks = await _trackRepo.getTracksBySourceIds(ids);
    final existingMap = {for (final t in existingTracks) t.sourceId: t};

    final targets = <Track>[];
    for (final t in deduped) {
      final db = existingMap[t.sourceId];
      if (db != null && db.isCached) {
        // Policy: jika cachedQuality lebih tinggi dari pref, jangan overwrite
        final pref = settings?.preferredAudioQuality.name ?? 'medium';
        if (policy.shouldSkipDueToHigherQuality(
            cachedQuality: db.cachedQuality, prefQuality: pref)) {
          continue;
        }
        // Even if same quality but already cached, skip (avoid re-download)
        if (db.cachedQuality == pref || db.isCached) {
          // Only skip if DB indicates already cached with same/higher quality — but memory says not cached (stale)
          // We treat as already cached -> skip download
          continue;
        }
      }
      targets.add(t);
    }

    _cacheDownloadService.setTargetTracks(targets);
  }

  bool _needsResolve = false;

  Future<void> _resolveAndAppendNextTrack() async {
    _needsResolve = true;
    if (_isResolvingNext) return;
    _isResolvingNext = true;

    try {
      while (_needsResolve) {
        _needsResolve = false;
        final int sessionId = _queueSessionId;

        while (true) {
          if (sessionId != _queueSessionId) break;

          final int currentPlaylistLen =
              _audioService.player.sequence?.length ?? 0;
          final int playerIndex = _audioService.player.currentIndex ?? 0;

          // Keep exactly 2 tracks ahead to ensure the 'Next' button in notifications works reliably
          if (currentPlaylistLen > playerIndex + 2) {
            break;
          }
          if (state.loopMode == LoopMode.all) {
            final userQueueTracks = _currentQueue
                .where((t) => !_autoQueueSourceIds.contains(t.sourceId))
                .toList();

            if (userQueueTracks.isNotEmpty) {
              final currentTrackId = state.currentTrack?.sourceId;
              final currentPosInUser = userQueueTracks
                  .indexWhere((t) => t.sourceId == currentTrackId);

              // Premium: jika current adalah auto (pos -1), next = first user track, bukan offset
              final int nextUserIndex;
              if (currentPosInUser == -1) {
                nextUserIndex = 0;
              } else {
                final offset = currentPlaylistLen - playerIndex;
                nextUserIndex =
                    (currentPosInUser + offset) % userQueueTracks.length;
              }
              final nextUserTrack = userQueueTracks[nextUserIndex];

              final resolvedTrack = await _resolveTrack(nextUserTrack);
              if (sessionId != _queueSessionId) break;

              if (resolvedTrack != null) {
                _consecutiveResolveFailures = 0;
                final actualIdx = _currentQueue
                    .indexWhere((t) => t.sourceId == resolvedTrack.sourceId);
                if (actualIdx != -1) _currentQueue[actualIdx] = resolvedTrack;

                final isLocal = resolvedTrack.isCached &&
                    resolvedTrack.localAudioPath != null;
                final uri = isLocal
                    ? resolvedTrack.localAudioPath!
                    : resolvedTrack.streamUrl!;

                final source = _audioService.createAudioSourceFromTrack(
                    uri, resolvedTrack,
                    headers: _trackHeaders[resolvedTrack.sourceId],
                    isLocal: isLocal);
                await _audioService.appendToPlaylist(source);
                _updateCacheTargets();
                continue; // check again
              } else {
                _consecutiveResolveFailures++;
                print(
                    'Resolve failed (repeat-all) $_consecutiveResolveFailures/3');
                if (_consecutiveResolveFailures < 3) {
                  await Future.delayed(const Duration(seconds: 2));
                  continue;
                } else {
                  state = state.copyWith(
                      errorMessage:
                          '3 tracks failed to resolve — playback paused');
                  break;
                }
              }
            } else {
              break;
            }
          } else {
            // ── NORMAL / NO-REPEAT MODE ──
            final int nextIndex = currentPlaylistLen;
            if (nextIndex >= _currentQueue.length) {
              await _fetchAndAppendAutoQueue();
              if (sessionId != _queueSessionId) break;
            } else if (_currentQueue.length - nextIndex <= 2) {
              _fetchAndAppendAutoQueue(); // fire and forget
            }

            if (nextIndex >= _currentQueue.length) {
              _updateCacheTargets();
              break;
            }

            final nextTrack = _currentQueue[nextIndex];
            final resolvedTrack = await _resolveTrack(nextTrack);
            if (sessionId != _queueSessionId) break;

            if (resolvedTrack != null) {
              _consecutiveResolveFailures = 0;
              _currentQueue[nextIndex] = resolvedTrack;
              final isLocal = resolvedTrack.isCached &&
                  resolvedTrack.localAudioPath != null;
              final uri = isLocal
                  ? resolvedTrack.localAudioPath!
                  : resolvedTrack.streamUrl!;

              final source = _audioService.createAudioSourceFromTrack(
                  uri, resolvedTrack,
                  headers: _trackHeaders[resolvedTrack.sourceId],
                  isLocal: isLocal);
              await _audioService.appendToPlaylist(source);
              _updateCacheTargets();
              continue; // check again
            } else {
              _consecutiveResolveFailures++;
              print(
                  'Resolve failed for next track $nextIndex ($_consecutiveResolveFailures/3)');
              if (_consecutiveResolveFailures < 3) {
                // Skip this unplayable track and try next after 2s
                _currentQueue.removeAt(nextIndex);
                await Future.delayed(const Duration(seconds: 2));
                continue;
              } else {
                state = state.copyWith(
                    errorMessage:
                        '3 tracks failed to resolve — playback paused');
                break;
              }
            }
          }
        }
      }
    } catch (e) {
      print('Exception in _resolveAndAppendNextTrack: $e');
    } finally {
      _isResolvingNext = false;
    }
  }

  /// Premium: Add to Queue / Play Next — konsisten tanpa replace current
  Future<void> addToQueue(Track track, {bool playNext = false}) async {
    if (_currentQueue.isEmpty) {
      await playTrack(track);
      return;
    }
    // Cap 500 — evict oldest auto first if needed
    if (_currentQueue.length >= _maxQueueSize) {
      // Evict oldest auto-queue first
      int removed = 0;
      _currentQueue.removeWhere((t) {
        if (removed >= 1) return false;
        if (_autoQueueSourceIds.contains(t.sourceId)) {
          removed++;
          _autoQueueSourceIds.remove(t.sourceId);
          return true;
        }
        return false;
      });
      if (removed == 0 && _currentQueue.length >= _maxQueueSize) {
        // No auto to evict — drop oldest non-current
        final dropIdx = _currentIndex == 0 ? 1 : 0;
        if (dropIdx < _currentQueue.length) {
          final dropped = _currentQueue.removeAt(dropIdx);
          if (!state.isShuffleEnabled)
            _originalQueue.removeWhere((t) => t.sourceId == dropped.sourceId);
          if (dropIdx < _currentIndex) _currentIndex--;
        }
      }
    }

    // Dedup — konsisten kedua queue sekali saja
    _currentQueue.removeWhere((t) => t.sourceId == track.sourceId);
    _originalQueue.removeWhere((t) => t.sourceId == track.sourceId);

    final insertIdx = playNext
        ? (_currentIndex + 1).clamp(0, _currentQueue.length)
        : _currentQueue.length;
    _currentQueue.insert(insertIdx, track);
    if (!state.isShuffleEnabled) {
      _originalQueue.insert(insertIdx.clamp(0, _originalQueue.length), track);
    } else {
      // Shuffle ON: simpan Play Next setelah current di original juga (bukan tail) → restore tidak loss posisi
      final curId = state.currentTrack?.sourceId;
      final origIdx = curId != null
          ? _originalQueue.indexWhere((t) => t.sourceId == curId)
          : -1;
      final origInsert = playNext
          ? (origIdx == -1 ? _originalQueue.length : origIdx + 1)
          : _originalQueue.length;
      _originalQueue.insert(origInsert.clamp(0, _originalQueue.length), track);
    }

    state = state.copyWith(
        currentQueue: List.from(_currentQueue), currentIndex: _currentIndex);

    // Rebuild upcoming window if inserted within player window
    final playlistLen = _audioService.player.sequence?.length ?? 0;
    final withinWindow = insertIdx < playlistLen + 3;
    if (withinWindow) {
      try {
        await _audioService.clearUpcoming();
        _queueSessionId++;
        _isResolvingNext = false;
        _resolveAndAppendNextTrack();
      } catch (_) {}
    } else {
      _scheduleSaveQueue();
    }
    _scheduleSaveQueue();
  }

  Future<void> addAllToQueue(List<Track> tracks,
      {bool playNext = false}) async {
    for (final t in (playNext ? tracks.reversed : tracks)) {
      await addToQueue(t, playNext: playNext);
      // small yield to avoid blocking
      await Future.delayed(const Duration(milliseconds: 1));
    }
  }

  Future<void> _fetchAndAppendAutoQueue() async {
    if (_isFetchingUpNext) return;
    if (_currentQueue.isEmpty) return;
    // Premium tradeoff #5: Shuffle ON → auto-queue OFF (Spotify)
    if (state.isShuffleEnabled) return;

    _isFetchingUpNext = true;
    try {
      // Use the very last track in the queue as the seed to generate infinite recommendations.
      final seedTrack = _currentQueue.last;

      final upNextData = await _apiService.getUpNext(seedTrack.sourceId);

      if (upNextData.isNotEmpty) {
        final newTracks = upNextData
            .map((json) => Track.fromJson(json as Map<String, dynamic>))
            .toList();

        // Prevent duplicating tracks already in queue
        final existingIds = _currentQueue.map((t) => t.sourceId).toSet();
        final tracksToAdd = newTracks
            .where((t) => !existingIds.contains(t.sourceId))
            .take(10)
            .toList();

        if (tracksToAdd.isNotEmpty) {
          // Mark these as auto-queue so repeat logic can exclude them
          for (final t in tracksToAdd) {
            _autoQueueSourceIds.add(t.sourceId);
          }
          // Cap queue at 500 — evict oldest auto-queue first
          if (_currentQueue.length + tracksToAdd.length > _maxQueueSize) {
            final overflow =
                _currentQueue.length + tracksToAdd.length - _maxQueueSize;
            // Remove oldest auto-queue tracks
            int removed = 0;
            _currentQueue.removeWhere((t) {
              if (removed >= overflow) return false;
              if (_autoQueueSourceIds.contains(t.sourceId)) {
                removed++;
                _autoQueueSourceIds.remove(t.sourceId);
                return true;
              }
              return false;
            });
            if (removed < overflow) {
              // If still overflow (no auto-queue to evict), trim from end
              final keep = _maxQueueSize - tracksToAdd.length;
              if (keep >= 0 && _currentQueue.length > keep) {
                _currentQueue = _currentQueue.sublist(0, keep);
                if (_currentIndex >= _currentQueue.length)
                  _currentIndex = _currentQueue.length - 1;
              }
            }
          }
          _currentQueue.addAll(tracksToAdd);
          // Do NOT add to _originalQueue — auto-queue tracks are not part of user's queue
          state = state.copyWith(currentQueue: List.from(_currentQueue));
        }
      }
    } catch (e) {
      print('Failed to fetch auto queue: $e');
    } finally {
      _isFetchingUpNext = false;
    }
  }

  Future<Track?> _resolveTrack(Track track) async {
    // Local device songs: ponytail — jangan blok dengan File.exists per track (lag).
    // File stat dihapus; jika file hilang, playback akan fail dan akan di-clean next scan atau saat error.
    if (track.source == TrackSource.local) {
      if (track.localAudioPath != null && track.localAudioPath!.isNotEmpty) {
        return track;
      }
      return null;
    }

    final settings = _ref.read(appSettingsProvider).value;
    final prefQuality = settings?.preferredAudioQuality ?? AudioQuality.medium;
    final prefQualityStr = prefQuality.name;

    int qualityIndex(String? q) {
      if (q == 'high') return 2;
      if (q == 'medium') return 1;
      return 0; // low or null
    }

    bool shouldStreamOnly = false;

    // If the track is marked as cached, verify the file actually exists (async, non-blocking).
    if (track.isCached && track.localAudioPath != null) {
      final fileExists = await File(track.localAudioPath!).exists();
      if (fileExists) {
        final prefIdx = qualityIndex(prefQualityStr);
        final cacheIdx = qualityIndex(track.cachedQuality);
        if (prefIdx > cacheIdx) {
          try {
            await File(track.localAudioPath!).delete();
          } catch (e) {
            print("Failed to delete old cache: \$e");
          }
          // Clear memory cache flag to force streaming/re-downloading
          track = track.copyWith(isCached: false, localAudioPath: null);
        } else if (prefIdx < cacheIdx) {
          shouldStreamOnly = true;
          // Don't overwrite the high-quality DB entry! Just clear memory so it streams low quality
          track = track.copyWith(isCached: false, localAudioPath: null);
        } else {
          return track; // File exists and quality matches or is better
        }
      } else {
        // File is missing. Strip cache flags so we don't try to play a missing file.
        track = track.copyWith(isCached: false, localAudioPath: null);
        await _trackRepo.updateTrack(track);
      }
    }

    final isOnline = _ref.read(connectivityProvider).value ?? true;
    if (!isOnline) {
      print("Offline and track not cached");
      return null;
    }

    // Premium: pre-refresh if expires within 15m (YT Music behavior)
    if (track.streamUrl != null &&
        track.streamUrlExpiresAt != null &&
        track.streamUrlExpiresAt!
            .isAfter(DateTime.now().add(const Duration(minutes: 15)))) {
      return track;
    }
    // If expires within 15m, treat as stale and re-resolve in background but still return current if not yet expired
    final isExpiringSoon = track.streamUrl != null &&
        track.streamUrlExpiresAt != null &&
        track.streamUrlExpiresAt!.isAfter(DateTime.now()) &&
        track.streamUrlExpiresAt!
            .isBefore(DateTime.now().add(const Duration(minutes: 15)));
    if (isExpiringSoon) {
      // Fire-and-forget pre-refresh for next time
      _apiService
          .resolve(track.sourceId,
              source: track.source.name, quality: prefQualityStr)
          .then((fresh) {
        final idx =
            _currentQueue.indexWhere((t) => t.sourceId == track.sourceId);
        if (idx != -1) {
          _currentQueue[idx] = _currentQueue[idx].copyWith(
            streamUrl: fresh['stream_url'],
            streamUrlExpiresAt: DateTime.tryParse(fresh['expires_at'] ?? ''),
          );
        }
      }).catchError((_) {});
      return track; // Use current URL for now, fresh will be used next time
    }

    try {
      final resolveData = await _apiService.resolve(
        track.sourceId,
        source: track.source.name,
        quality: prefQualityStr,
      );
      final rawHeaders = resolveData['headers'];
      if (rawHeaders != null) {
        _trackHeaders[track.sourceId] = rawHeaders.map<String, String>(
            (key, value) => MapEntry(key.toString(), value.toString()));
      }

      final updatedTrack = track.copyWith(
        streamUrl: resolveData['stream_url'],
        streamUrlExpiresAt: DateTime.tryParse(resolveData['expires_at'] ?? ''),
        audioFormat: resolveData['format'],
        bitrateKbps: resolveData['bitrate_kbps'],
        fileSizeBytes: resolveData['file_size_bytes'],
        cachedQuality: prefQualityStr,
        isCached: false, // Reset cache flags in case the file was missing
        localAudioPath: null,
      );

      if (!shouldStreamOnly) {
        await _trackRepo.saveTrack(updatedTrack);
      }
      return updatedTrack;
    } catch (e) {
      print("Resolve error: $e");
      return null;
    }
  }

  Map<String, String>? getHeaders(String sourceId) {
    return _trackHeaders[sourceId];
  }

  Future<void> play() async => await _audioService.play();
  Future<void> pause() async => await _audioService.pause();
  Future<void> stop() async => await _audioService.stop();
  Future<void> seek(Duration position) async =>
      await _audioService.seek(position);

  Future<void> togglePlayPause() async {
    if (state.isPlaying) {
      await pause();
    } else {
      await play();
    }
  }

  Future<void> playNext() async {
    final raw = _ref.read(appSettingsProvider).value?.crossfadeSeconds ?? 0;
    final crossfade = raw.clamp(0, 12);
    print(
        'playNext crossfade=$crossfade (raw $raw) queueIdx=$_currentIndex len=${_currentQueue.length} hasNext=${_audioService.player.hasNext}');
    // Premium queue-aware: jangan andalkan player.hasNext saja (setelah restore player hanya punya current)
    if (_currentIndex < _currentQueue.length - 1) {
      if (_audioService.player.hasNext) {
        if (crossfade > 0) {
          await _audioService.crossfadeToNext(crossfade);
        } else {
          await _audioService.player.seekToNext();
        }
      } else {
        // Player window belum ada next (habis restore) → skip via queue
        await skipToQueueItem(_currentIndex + 1);
      }
      return;
    }
    // End of queue
    if (_currentQueue.isNotEmpty) {
      await _fetchAndAppendAutoQueue();
      if (_audioService.player.hasNext) {
        if (crossfade > 0) {
          await _audioService.crossfadeToNext(crossfade);
        } else {
          await _audioService.player.seekToNext();
        }
      } else if (_currentIndex < _currentQueue.length - 1) {
        // AutoQueue baru menambah queue
        await skipToQueueItem(_currentIndex + 1);
      } else {
        await _audioService.player.seek(Duration.zero);
      }
    }
  }

  Future<void> playPrevious() async {
    final raw = _ref.read(appSettingsProvider).value?.crossfadeSeconds ?? 0;
    final crossfade = raw.clamp(0, 12);
    print(
        'playPrevious crossfade=$crossfade queueIdx=$_currentIndex hasPrev=${_audioService.player.hasPrevious}');
    if (_audioService.player.position.inSeconds > 3) {
      await _audioService.player.seek(Duration.zero);
      return;
    }
    // Premium queue-aware: hasPrevious di player hanya true jika window ada prev
    if (_currentIndex > 0) {
      if (_audioService.player.hasPrevious) {
        if (crossfade > 0) {
          await _audioService.crossfadeToPrevious(crossfade);
        } else {
          await _audioService.player.seekToPrevious();
        }
      } else {
        // Setelah restore player cuma punya current → pakai queue
        await skipToQueueItem(_currentIndex - 1);
      }
    } else {
      await _audioService.player.seek(Duration.zero);
    }
  }

  Future<void> skipToQueueItem(int index) async {
    if (index < 0 || index >= _currentQueue.length) return;

    _queueSessionId++;
    _isResolvingNext = false;
    _isFetchingUpNext = false;

    state = state.clearError();
    _currentIndex = index;
    state = state.copyWith(
      currentTrack: _currentQueue[_currentIndex],
      currentIndex: _currentIndex,
    );

    final track = _currentQueue[_currentIndex];
    final resolvedTrack = await _resolveTrack(track);
    if (resolvedTrack == null) {
      state = state.copyWith(
          errorMessage:
              'Failed to resolve "${track.title}". Please check your connection.');
      return;
    }

    _currentQueue[_currentIndex] = resolvedTrack;
    state = state.copyWith(
        currentTrack: resolvedTrack, currentQueue: List.from(_currentQueue));

    final isLocal =
        resolvedTrack.isCached && resolvedTrack.localAudioPath != null;
    final uri =
        isLocal ? resolvedTrack.localAudioPath! : resolvedTrack.streamUrl!;

    final source = _audioService.createAudioSourceFromTrack(uri, resolvedTrack,
        headers: _trackHeaders[resolvedTrack.sourceId], isLocal: isLocal);

    try {
      await _audioService.startPlaylist([source]);
      await _audioService.play();
    } catch (e) {
      print('Failed to play track: $e');
      state = state.copyWith(
          errorMessage:
              'Network error: Failed to stream track. Please check connection.');
      return;
    }

    _updateCacheTargets();

    await _recordPlayHistory(resolvedTrack);

    _resolveAndAppendNextTrack();
    _scheduleSaveQueue();
  }

  Future<void> toggleRepeat() async {
    final nextMode = state.loopMode == LoopMode.off
        ? LoopMode.all
        : state.loopMode == LoopMode.all
            ? LoopMode.one
            : LoopMode.off;
    await _audioService.setRepeatMode(nextMode);
    _scheduleSaveQueue();
  }

  Future<void> toggleShuffle() async {
    final nextMode = !state.isShuffleEnabled;

    if (_originalQueue.isEmpty) return;

    if (nextMode) {
      final current = _currentQueue[_currentIndex];
      final remaining = _originalQueue
          .where((t) => t.sourceId != current.sourceId)
          .toList()
        ..shuffle();
      _currentQueue = [current, ...remaining];
      _currentIndex = 0;
    } else {
      final current = _currentQueue[_currentIndex];
      _currentQueue = List.from(_originalQueue);
      _currentIndex =
          _currentQueue.indexWhere((t) => t.sourceId == current.sourceId);
      if (_currentIndex == -1) {
        _currentQueue.insert(0, current);
        _currentIndex = 0;
      }
    }

    state = state.copyWith(
        isShuffleEnabled: nextMode,
        currentQueue: _currentQueue,
        currentIndex: _currentIndex);

    // Clear the upcoming tracks in the player's playlist and resolve the new next track.
    await _audioService.clearUpcoming();
    _isResolvingNext = false;
    _resolveAndAppendNextTrack();
    _scheduleSaveQueue();
  }

  Future<void> toggleLike() async {
    final currentTrack = state.currentTrack;
    if (currentTrack == null) return;

    final newStatus = !currentTrack.isLiked;
    final updatedTrack = currentTrack.copyWith(isLiked: newStatus);

    // Update state first for instant UI response
    state = state.copyWith(currentTrack: updatedTrack);

    // Also update in queue
    if (_currentIndex != -1 && _currentIndex < _currentQueue.length) {
      _currentQueue[_currentIndex] = updatedTrack;
    }

    // Save to DB
    await _trackRepo.updateTrack(updatedTrack);

    // Invalidate library providers so Liked Songs playlist UI updates
    _ref.invalidate(allPlaylistsProvider);
    _ref.invalidate(playlistTracksProvider);
  }

  /// Premium: swipe down mini-player dismiss — stop + clear queue & state + cancel sleep timer
  Future<void> dismissPlayer() async {
    try {
      await _audioService.stop();
    } catch (_) {}
    // Cancel sleep timer yang masih aktif
    try {
      _ref.read(sleepTimerProvider.notifier).cancelIfActive();
    } catch (_) {}
    _currentQueue.clear();
    _originalQueue.clear();
    _autoQueueSourceIds.clear();
    _currentIndex = -1;
    _queueSessionId++;
    _isResolvingNext = false;
    _isFetchingUpNext = false;
    state = PlayerState(
        isPlaying: false,
        currentQueue: [],
        currentIndex: -1,
        currentTrack: null);
    // clear persisted queue
    try {
      final queueRepo = _ref.read(queueRepositoryProvider);
      await queueRepo.clear();
    } catch (_) {}
  }

  Future<void> reorderQueue(int oldIndex, int newIndex) async {
    // ReorderableListView gives newIndex as insertion position in the original list.
    // For List remove/insert we need adjusted index when dragging forward.
    final adjustedNewIndex = oldIndex < newIndex ? newIndex - 1 : newIndex;

    // Update _currentQueue with adjusted index
    final track = _currentQueue.removeAt(oldIndex);
    _currentQueue.insert(adjustedNewIndex, track);

    // If we're not shuffling, _originalQueue is exactly _currentQueue
    if (!state.isShuffleEnabled) {
      _originalQueue = List.from(_currentQueue);
    }

    // Update _currentIndex
    if (_currentIndex == oldIndex) {
      _currentIndex = adjustedNewIndex;
    } else if (oldIndex < _currentIndex && adjustedNewIndex >= _currentIndex) {
      _currentIndex--;
    } else if (oldIndex > _currentIndex && adjustedNewIndex <= _currentIndex) {
      _currentIndex++;
    }

    state = state.copyWith(
      currentQueue: List.from(_currentQueue),
      currentIndex: _currentIndex,
    );

    // Player's ConcatenatingAudioSource only holds current + 2 ahead.
    // If reordered indices are within player's window, a direct move keeps hasNext true instantly.
    // Otherwise, rebuild upcoming via clear+re-resolve.
    final playlistLen = _audioService.player.sequence?.length ?? 0;
    final withinWindow =
        oldIndex < playlistLen && adjustedNewIndex < playlistLen;
    if (withinWindow) {
      try {
        await _audioService.moveInPlaylist(oldIndex, adjustedNewIndex);
      } catch (e) {
        print('reorderQueue move failed: $e — rebuilding');
        await _audioService.clearUpcoming();
        _isResolvingNext = false;
        _queueSessionId++;
        _resolveAndAppendNextTrack();
      }
    } else {
      try {
        await _audioService.clearUpcoming();
        _isResolvingNext = false;
        _queueSessionId++;
        _resolveAndAppendNextTrack();
      } catch (e) {
        print('reorderQueue rebuild failed: $e');
      }
    }
    _scheduleSaveQueue();
  }

  Future<void> removeFromQueue(int index) async {
    if (index < 0 || index >= _currentQueue.length) return;

    final removedTrack = _currentQueue.removeAt(index);

    if (!state.isShuffleEnabled) {
      _originalQueue.removeWhere((t) => t.sourceId == removedTrack.sourceId);
    }

    if (index < _currentIndex) {
      _currentIndex--;
    } else if (index == _currentIndex) {
      if (_currentIndex >= _currentQueue.length) {
        _currentIndex = _currentQueue.length - 1;
      }
    }

    state = state.copyWith(
      currentQueue: List.from(_currentQueue),
      currentIndex: _currentIndex,
    );

    // Player only holds current + 2 ahead — try direct remove if within window, else rebuild
    final playlistLen2 = _audioService.player.sequence?.length ?? 0;
    if (index > _currentIndex && index < playlistLen2) {
      try {
        await _audioService.removeFromPlaylist(index);
      } catch (e) {
        print('removeFromQueue direct remove failed: $e — rebuilding');
        await _audioService.clearUpcoming();
        _isResolvingNext = false;
        _queueSessionId++;
        _resolveAndAppendNextTrack();
      }
    } else if (index <= _currentIndex) {
      // Removing before or at current — current's playlist index shifts, rebuild to stay consistent
      try {
        await _audioService.clearUpcoming();
        _isResolvingNext = false;
        _queueSessionId++;
        _resolveAndAppendNextTrack();
        // Also try direct remove if it was upcoming
        if (index > _currentIndex && index < playlistLen2) {
          try {
            await _audioService.removeFromPlaylist(index);
          } catch (_) {}
        }
      } catch (e) {
        print('removeFromQueue rebuild failed: $e');
      }
    } else {
      // Beyond window — no player change needed, but rebuild to ensure next tracks are correct
      try {
        await _audioService.clearUpcoming();
        _isResolvingNext = false;
        _queueSessionId++;
        _resolveAndAppendNextTrack();
      } catch (e) {
        print('removeFromQueue rebuild failed: $e');
      }
    }
    _scheduleSaveQueue();
  }

  Future<void> saveQueueState() async {
    if (_currentQueue.isEmpty) return;
    final queueRepo = _ref.read(queueRepositoryProvider);
    final items = <QueueItemModel>[];
    for (int i = 0; i < _currentQueue.length; i++) {
      final track = _currentQueue[i];
      final originalIdx =
          _originalQueue.indexWhere((t) => t.sourceId == track.sourceId);
      final item = QueueItemModel()
        ..queueStateId = 1
        ..trackId = track.sourceId
        ..originalIndex = originalIdx != -1 ? originalIdx : i
        ..shuffledIndex = state.isShuffleEnabled ? i : null;
      items.add(item);
    }
    final currentTrackId = state.currentTrack?.sourceId;
    final qState = QueueStateModel()
      ..id = 1
      ..currentTrackId = currentTrackId
      ..currentPositionMs = _audioService.player.position.inMilliseconds
      ..shuffleEnabled = state.isShuffleEnabled
      ..repeatMode = RepeatMode.values.firstWhere(
          (e) => e.name == state.loopMode.name,
          orElse: () => RepeatMode.off)
      ..autoQueueIds =
          _autoQueueSourceIds.isEmpty ? null : _autoQueueSourceIds.join(',')
      ..queueSource =
          _currentQueue.isNotEmpty ? 'queue:${_currentQueue.length}' : null
      ..updatedAt = DateTime.now();
    // Atomic: clear + putAll dalam satu txn via repository (crash-safe)
    await queueRepo.replaceQueue(items: items, state: qState);
  }

  Future<void> restoreQueueState() async {
    final queueRepo = _ref.read(queueRepositoryProvider);
    final qState = await queueRepo.getState();
    if (qState == null) return;

    _queueSessionId++;
    _isResolvingNext = false;
    _isFetchingUpNext = false;

    final items = await queueRepo.getItems();
    if (items.isEmpty) return;

    // Premium single OR query per chunk 80 — tidak N+1
    final trackIds = items.map((i) => i.trackId).toSet().toList();
    final tracks = await _trackRepo.getTracksBySourceIds(trackIds);
    // Restore autoQueueIds for premium repeat logic
    if (qState.autoQueueIds != null && qState.autoQueueIds!.isNotEmpty) {
      _autoQueueSourceIds.clear();
      _autoQueueSourceIds
          .addAll(qState.autoQueueIds!.split(',').where((s) => s.isNotEmpty));
    }
    // Cap queue at 500 (evict oldest auto-queue first)
    if (tracks.length > 500) {
      // Keep user queue first, evict auto-queue overflow
      final userTracks = tracks
          .where((t) => !_autoQueueSourceIds.contains(t.sourceId))
          .toList();
      final autoTracks = tracks
          .where((t) => _autoQueueSourceIds.contains(t.sourceId))
          .toList();
      final keepAuto = (500 - userTracks.length).clamp(0, autoTracks.length);
      tracks.clear();
      tracks.addAll(userTracks);
      tracks.addAll(autoTracks.take(keepAuto));
    }

    if (tracks.isEmpty) return;

    // Reconstruct queues
    _currentQueue.clear();
    _originalQueue.clear();

    // Original queue order
    final sortedItemsByOriginal = List<QueueItemModel>.from(items)
      ..sort((a, b) => a.originalIndex.compareTo(b.originalIndex));
    for (final item in sortedItemsByOriginal) {
      final track = tracks.where((t) => t.sourceId == item.trackId).firstOrNull;
      if (track != null) {
        _originalQueue.add(track);
      }
    }

    if (qState.shuffleEnabled) {
      final sortedItemsByShuffled = List<QueueItemModel>.from(items)
        ..sort((a, b) => (a.shuffledIndex ?? a.originalIndex)
            .compareTo(b.shuffledIndex ?? b.originalIndex));
      for (final item in sortedItemsByShuffled) {
        final track =
            tracks.where((t) => t.sourceId == item.trackId).firstOrNull;
        if (track != null) {
          _currentQueue.add(track);
        }
      }
    } else {
      _currentQueue = List.from(_originalQueue);
    }

    if (_currentQueue.isEmpty) return;

    _currentIndex =
        _currentQueue.indexWhere((t) => t.sourceId == qState.currentTrackId);
    if (_currentIndex == -1) _currentIndex = 0;

    final loopMode = LoopMode.values.firstWhere(
        (e) => e.name == qState.repeatMode.name,
        orElse: () => LoopMode.off);

    state = state.copyWith(
      currentQueue: _currentQueue,
      currentIndex: _currentIndex,
      currentTrack: _currentQueue[_currentIndex],
      isShuffleEnabled: qState.shuffleEnabled,
      loopMode: loopMode,
    );

    // Setup player but DO NOT auto play — premium: load window prev+current+next2 agar hasPrevious/hasNext benar setelah restore
    await _audioService.setRepeatMode(loopMode);

    // Build window: [prev, current, next, next2] — resolve masing-masing
    final windowIndices = <int>[];
    for (final d in [-1, 0, 1, 2]) {
      final idx = _currentIndex + d;
      if (idx >= 0 && idx < _currentQueue.length) windowIndices.add(idx);
    }
    final windowTracks = <Track>[];
    final windowSources = <AudioSource>[];
    int initialIndexInWindow = 0;
    for (final idx in windowIndices) {
      var t = _currentQueue[idx];
      // Resolve hanya jika belum ada streamUrl dan bukan cached
      if (idx == _currentIndex) {
        final resolved = await _resolveTrack(t);
        if (resolved != null) {
          t = resolved;
          _currentQueue[idx] = t;
        }
      } else if (!t.isCached) {
        final resolved = await _resolveTrack(t);
        if (resolved != null) {
          t = resolved;
          _currentQueue[idx] = t;
        }
      }
      final isLocal = t.isCached && t.localAudioPath != null;
      final uri = isLocal ? t.localAudioPath! : (t.streamUrl ?? '');
      if (uri.isEmpty) continue;
      // Skip jika streamUrl belum resolve dan bukan cached (mis offline)
      if (!isLocal && (t.streamUrl == null || t.streamUrl!.isEmpty)) continue;
      final src = _audioService.createAudioSourceFromTrack(uri, t,
          headers: _trackHeaders[t.sourceId], isLocal: isLocal);
      windowSources.add(src);
      windowTracks.add(t);
      if (idx == _currentIndex) initialIndexInWindow = windowSources.length - 1;
    }

    if (windowSources.isNotEmpty) {
      // Update state dengan track yang sudah resolve (untuk notifikasi)
      state = state.copyWith(
          currentTrack: _currentQueue[_currentIndex],
          currentQueue: List.from(_currentQueue));
      await _audioService.startPlaylist(windowSources,
          initialIndex: initialIndexInWindow);

      if (qState.currentPositionMs > 0) {
        await _audioService
            .seek(Duration(milliseconds: qState.currentPositionMs));
      }

      _updateCacheTargets();
      _resolveAndAppendNextTrack();
    } else {
      // Fallback single current jika window kosong
      final currentTrack = _currentQueue[_currentIndex];
      final resolvedTrack = await _resolveTrack(currentTrack);
      if (resolvedTrack != null) {
        _currentQueue[_currentIndex] = resolvedTrack;
        final isLocal =
            resolvedTrack.isCached && resolvedTrack.localAudioPath != null;
        final uri =
            isLocal ? resolvedTrack.localAudioPath! : resolvedTrack.streamUrl!;
        final source = _audioService.createAudioSourceFromTrack(
            uri, resolvedTrack,
            headers: _trackHeaders[resolvedTrack.sourceId], isLocal: isLocal);
        await _audioService.startPlaylist([source]);
        if (qState.currentPositionMs > 0) {
          await _audioService
              .seek(Duration(milliseconds: qState.currentPositionMs));
        }
        _updateCacheTargets();
        _resolveAndAppendNextTrack();
      }
    }
  }
}
