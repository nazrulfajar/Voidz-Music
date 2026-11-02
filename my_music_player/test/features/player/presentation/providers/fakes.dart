import 'dart:async';

import 'package:dartz/dartz.dart';
import 'package:just_audio/just_audio.dart';
import 'package:mocktail/mocktail.dart';
import 'package:my_music_player/core/errors/failures.dart';
import 'package:my_music_player/core/network/api_service.dart';
import 'package:my_music_player/features/cache/data/datasources/cache_download_service.dart';
import 'package:my_music_player/features/library/domain/entities/playlist.dart';
import 'package:my_music_player/features/library/domain/repositories/playlist_repository.dart';
import 'package:my_music_player/features/player/data/datasources/audio_player_service.dart';
import 'package:my_music_player/features/player/data/models/queue_item_model.dart';
import 'package:my_music_player/features/player/data/models/queue_state_model.dart';
import 'package:my_music_player/features/player/data/repositories/queue_repository.dart';
import 'package:my_music_player/features/player/domain/entities/track.dart';
import 'package:my_music_player/features/player/domain/repositories/track_repository.dart';

class FakeIndexedAudioSource extends Mock implements IndexedAudioSource {}

/// In-memory `AudioPlayer` for controller tests. It mirrors only the window
/// state that `PlayerController` reads: sequence length/index and streams.
class FakeAudioPlayer extends Mock implements AudioPlayer {
  final _playing = StreamController<bool>.broadcast();
  final _playerState = StreamController<PlayerState>.broadcast();
  final _playbackEvent = StreamController<PlaybackEvent>.broadcast();
  final _position = StreamController<Duration>.broadcast();
  final _duration = StreamController<Duration?>.broadcast();
  final _loopMode = StreamController<LoopMode>.broadcast();
  final _sequenceState = StreamController<SequenceState?>.broadcast();
  final _currentIndex = StreamController<int?>.broadcast();

  List<IndexedAudioSource>? _sequence;
  int? _currentIndexValue;
  bool _playingValue = false;
  Duration _positionValue = Duration.zero;
  Duration? _durationValue;
  LoopMode _loopModeValue = LoopMode.off;
  double _volumeValue = 1.0;
  int seekToNextCalls = 0;
  int seekToPreviousCalls = 0;
  int seekCalls = 0;

  @override
  Stream<bool> get playingStream => _playing.stream;

  @override
  Stream<PlayerState> get playerStateStream => _playerState.stream;

  @override
  Stream<PlaybackEvent> get playbackEventStream => _playbackEvent.stream;

  @override
  Stream<Duration> get positionStream => _position.stream;

  @override
  Stream<Duration?> get durationStream => _duration.stream;

  @override
  Stream<LoopMode> get loopModeStream => _loopMode.stream;

  @override
  LoopMode get loopMode => _loopModeValue;

  @override
  Stream<SequenceState?> get sequenceStateStream => _sequenceState.stream;

  @override
  Stream<int?> get currentIndexStream => _currentIndex.stream;

  @override
  List<IndexedAudioSource>? get sequence => _sequence;

  @override
  int? get currentIndex => _currentIndexValue;

  @override
  bool get playing => _playingValue;

  @override
  PlayerState get playerState =>
      PlayerState(_playingValue, ProcessingState.idle);

  @override
  Duration get position => _positionValue;

  @override
  Duration? get duration => _durationValue;

  @override
  bool get hasNext =>
      _currentIndexValue != null &&
      _sequence != null &&
      _currentIndexValue! + 1 < _sequence!.length;

  @override
  bool get hasPrevious => (_currentIndexValue ?? 0) > 0;

  @override
  double get volume => _volumeValue;

  int get sequenceLength => _sequence?.length ?? 0;

  void setSequenceLength(int length, {int initialIndex = 0}) {
    _sequence = List<IndexedAudioSource>.generate(
      length,
      (_) => FakeIndexedAudioSource(),
      growable: true,
    );
    _currentIndexValue = length == 0 ? null : initialIndex.clamp(0, length - 1);
    _currentIndex.add(_currentIndexValue);
  }

  void appendSource() {
    _sequence ??= [];
    _sequence!.add(FakeIndexedAudioSource());
  }

  void clearUpcoming() {
    final index = _currentIndexValue;
    if (index == null || _sequence == null) return;
    if (index + 1 < _sequence!.length) {
      _sequence!.removeRange(index + 1, _sequence!.length);
    }
  }

  void moveSource(int oldIndex, int newIndex) {
    final sequence = _sequence;
    if (sequence == null) return;
    final item = sequence.removeAt(oldIndex);
    sequence.insert(newIndex, item);
    final current = _currentIndexValue;
    if (current == null) return;
    if (oldIndex == current) {
      _currentIndexValue = newIndex;
    } else if (oldIndex < current && newIndex >= current) {
      _currentIndexValue = current - 1;
    } else if (oldIndex > current && newIndex <= current) {
      _currentIndexValue = current + 1;
    }
  }

  void removeSourceAt(int index) {
    final sequence = _sequence;
    if (sequence == null || index < 0 || index >= sequence.length) return;
    sequence.removeAt(index);
    final current = _currentIndexValue;
    if (current != null) {
      if (index < current) {
        _currentIndexValue = current - 1;
      } else if (index == current) {
        _currentIndexValue =
            sequence.isEmpty ? null : index.clamp(0, sequence.length - 1);
      }
    }
  }

  void setPlaying(bool playing) {
    _playingValue = playing;
    _playing.add(playing);
  }

  void setLoopModeValue(LoopMode mode) {
    _loopModeValue = mode;
    _loopMode.add(mode);
  }

  @override
  Future<void> seekToNext() async {
    seekToNextCalls++;
    final index = _currentIndexValue;
    if (index != null && hasNext) {
      _currentIndexValue = index + 1;
      _currentIndex.add(_currentIndexValue);
    }
  }

  @override
  Future<void> seekToPrevious() async {
    seekToPreviousCalls++;
    final index = _currentIndexValue;
    if (index != null && hasPrevious) {
      _currentIndexValue = index - 1;
      _currentIndex.add(_currentIndexValue);
    }
  }

  @override
  Future<void> seek(Duration? position, {int? index}) async {
    seekCalls++;
    _positionValue = position ?? Duration.zero;
    _position.add(_positionValue);
  }

  @override
  Future<void> setLoopMode(LoopMode mode) async => setLoopModeValue(mode);

  @override
  Future<void> setShuffleModeEnabled(bool enabled) async {}

  @override
  Future<void> setVolume(double volume) async => _volumeValue = volume;

  Future<void> disposeFake() async {
    await _playing.close();
    await _playerState.close();
    await _playbackEvent.close();
    await _position.close();
    await _duration.close();
    await _loopMode.close();
    await _sequenceState.close();
    await _currentIndex.close();
  }
}

/// Fake service that keeps the just_audio window in memory. No platform
/// channels, files, or network are touched.
class FakeAudioPlayerService implements AudioPlayerService {
  @override
  final FakeAudioPlayer player = FakeAudioPlayer();

  int initCalls = 0;
  int startPlaylistCalls = 0;
  int appendToPlaylistCalls = 0;
  int playCalls = 0;
  int pauseCalls = 0;
  int stopCalls = 0;
  int clearUpcomingCalls = 0;
  int moveInPlaylistCalls = 0;
  int removeFromPlaylistCalls = 0;
  int crossfadeToNextCalls = 0;
  int crossfadeToPreviousCalls = 0;
  LoopMode lastRepeatMode = LoopMode.off;
  bool? lastShuffleMode;
  bool? lastIsLocal;

  bool Function()? audioFocusCheck;
  int Function()? crossfadeSecondsProvider;

  @override
  Stream<int?> get currentIndexStream => player.currentIndexStream;

  @override
  void setAudioFocusCheck(bool Function() check) {
    audioFocusCheck = check;
  }

  @override
  Future<void> init() async {
    initCalls++;
  }

  @override
  void enableAutoCrossfade(int Function() crossfadeSecondsProvider) {
    this.crossfadeSecondsProvider = crossfadeSecondsProvider;
  }

  @override
  AudioSource createAudioSourceFromTrack(
    String url,
    dynamic track, {
    Map<String, String>? headers,
    bool isLocal = false,
  }) {
    lastIsLocal = isLocal;
    return AudioSource.uri(Uri.parse(url));
  }

  @override
  AudioSource createAudioSource(
    String url, {
    required String id,
    required String title,
    String? artist,
    String? album,
    String? artUri,
    Duration? duration,
    Map<String, String>? headers,
    bool isLocal = false,
  }) {
    lastIsLocal = isLocal;
    return AudioSource.uri(Uri.parse(url));
  }

  @override
  Future<void> startPlaylist(
    List<AudioSource> sources, {
    int initialIndex = 0,
  }) async {
    startPlaylistCalls++;
    player.setSequenceLength(sources.length, initialIndex: initialIndex);
  }

  @override
  Future<void> appendToPlaylist(AudioSource source) async {
    appendToPlaylistCalls++;
    player.appendSource();
  }

  @override
  Future<void> clearUpcoming() async {
    clearUpcomingCalls++;
    player.clearUpcoming();
  }

  @override
  Future<void> moveInPlaylist(int oldIndex, int newIndex) async {
    moveInPlaylistCalls++;
    player.moveSource(oldIndex, newIndex);
  }

  @override
  Future<void> removeFromPlaylist(int index) async {
    removeFromPlaylistCalls++;
    player.removeSourceAt(index);
  }

  @override
  Future<void> play() async {
    playCalls++;
    player.setPlaying(true);
  }

  @override
  Future<void> pause() async {
    pauseCalls++;
    player.setPlaying(false);
  }

  @override
  Future<void> stop() async {
    stopCalls++;
    player.setPlaying(false);
  }

  @override
  Future<void> seek(Duration position) async => player.seek(position);

  @override
  Future<void> setRepeatMode(LoopMode mode) async {
    lastRepeatMode = mode;
    await player.setLoopMode(mode);
  }

  @override
  Future<void> setShuffleModeEnabled(bool enabled) async {
    lastShuffleMode = enabled;
  }

  @override
  Future<void> setVolume(double volume) async => player.setVolume(volume);

  @override
  Future<void> crossfadeToNext(int seconds) async {
    crossfadeToNextCalls++;
    if (player.hasNext) {
      await player.seekToNext();
    } else {
      await player.seek(Duration.zero);
    }
  }

  @override
  Future<void> crossfadeToPrevious(int seconds) async {
    crossfadeToPreviousCalls++;
    if (player.hasPrevious) {
      await player.seekToPrevious();
    } else {
      await player.seek(Duration.zero);
    }
  }

  @override
  void dispose() {
    player.disposeFake();
  }

  Future<void> disposeFake() => player.disposeFake();
}

class FakeCacheDownloadService extends Mock implements CacheDownloadService {
  List<Track>? lastTargets;

  @override
  bool isDownloading(String trackId) => false;

  @override
  void setTargetTracks(List<Track> targets) {
    lastTargets = List<Track>.of(targets);
  }
}

class FakeApiService extends Mock implements ApiService {
  @override
  Future<List<dynamic>> getUpNext(String videoId) async => const [];
}

class FakeTrackRepository implements TrackRepository {
  final Map<String, Track> tracks = {};
  int saveTrackCalls = 0;
  int updateTrackCalls = 0;

  @override
  Future<Either<Failure, void>> saveTrack(Track track) async {
    saveTrackCalls++;
    tracks[track.sourceId] = track;
    return const Right(null);
  }

  @override
  Future<Either<Failure, void>> updateTrack(Track track) async {
    updateTrackCalls++;
    tracks[track.sourceId] = track;
    return const Right(null);
  }

  @override
  Future<Either<Failure, Track?>> getTrack(
    String sourceId,
    String source,
  ) async {
    return Right(tracks[sourceId]);
  }

  @override
  Future<Either<Failure, Track?>> getTrackBySourceId(String sourceId) async {
    return Right(tracks[sourceId]);
  }

  @override
  Future<Either<Failure, List<Track>>> getAllCachedTracks() async {
    return Right(
      tracks.values.where((track) => track.isCached).toList(),
    );
  }

  @override
  Future<Either<Failure, void>> updateTrackPlayCount(
    String sourceId,
    String source,
  ) async {
    final track = tracks[sourceId];
    if (track != null) {
      tracks[sourceId] = track.copyWith(playCount: track.playCount + 1);
    }
    return const Right(null);
  }

  @override
  Future<Either<Failure, List<Track>>> getRecentlyPlayedTracks({
    int limit = 10,
  }) async {
    return const Right([]);
  }

  @override
  Future<Either<Failure, List<Track>>> getQuickPicksTracks({
    int limit = 10,
  }) async {
    return const Right([]);
  }

  @override
  Future<List<Track>> getTracksBySourceIds(List<String> sourceIds) async {
    return [
      for (final id in sourceIds)
        if (tracks[id] != null) tracks[id]!,
    ];
  }

  @override
  Future<List<Track>> getDeviceTracks() async =>
      tracks.values.where((track) => track.source.name == 'local').toList();

  @override
  Future<Either<Failure, List<Track>>> scanAndSyncLocalTracks() async {
    return Right(
      tracks.values.where((track) => track.source.name == 'local').toList(),
    );
  }
}

class FakeQueueRepository extends QueueRepository {
  FakeQueueRepository() : super(null);

  QueueStateModel? state;
  List<QueueItemModel> items = [];
  int clearCalls = 0;
  List<QueueItemModel>? lastItems;
  QueueStateModel? lastState;

  @override
  Future<void> replaceQueue({
    required List<QueueItemModel> items,
    required QueueStateModel state,
  }) async {
    lastItems = items;
    lastState = state;
    this.items = items;
    this.state = state;
  }

  @override
  Future<QueueStateModel?> getState() async => state;

  @override
  Future<List<QueueItemModel>> getItems() async => List.of(items);

  @override
  Future<void> clear() async {
    clearCalls++;
    items = [];
    state = null;
  }
}

class FakePlaylistRepository implements PlaylistRepository {
  int addToPlayHistoryCalls = 0;

  @override
  Future<void> addToPlayHistory(String trackSourceId) async {
    addToPlayHistoryCalls++;
  }

  @override
  Future<Playlist> createPlaylist(String name, {String? description}) =>
      throw UnimplementedError();

  @override
  Future<void> updatePlaylist(Playlist playlist) => throw UnimplementedError();

  @override
  Future<void> deletePlaylist(int id) => throw UnimplementedError();

  @override
  Future<List<Playlist>> getAllPlaylists() async => const [];

  @override
  Future<Playlist?> getPlaylistById(int id) async => null;

  @override
  Future<List<Track>> getPlaylistTracks(int playlistId) async => const [];

  @override
  Future<void> addTrackToPlaylist(int playlistId, Track track) async {}

  @override
  Future<({int added, int existed})> addTracksToPlaylist(
    int playlistId,
    List<Track> tracks,
  ) async {
    return (added: 0, existed: 0);
  }

  @override
  Future<void> removeTrackFromPlaylist(
    int playlistId,
    String trackSourceId,
  ) async {}

  @override
  Future<void> reorderTracks(
    int playlistId,
    int oldIndex,
    int newIndex,
  ) async {}

  @override
  Future<Playlist> getVirtualPlaylist(String virtualId) =>
      throw UnimplementedError();

  @override
  Future<List<Track>> getPlayHistory({int limit = 20}) async => const [];
}
