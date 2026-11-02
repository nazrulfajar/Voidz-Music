import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:just_audio/just_audio.dart';
import '../../data/datasources/audio_player_service.dart';

final sleepTimerProvider =
    StateNotifierProvider<SleepTimerNotifier, SleepTimerState>((ref) {
  return SleepTimerNotifier(ref);
});

enum SleepTimerMode { off, duration, endOfTrack }

class SleepTimerState {
  final bool isActive;
  final SleepTimerMode mode;
  final Duration? selectedDuration;
  final Duration remainingTime;

  SleepTimerState({
    this.isActive = false,
    this.mode = SleepTimerMode.off,
    this.selectedDuration,
    this.remainingTime = Duration.zero,
  });

  bool get isEndOfTrack => mode == SleepTimerMode.endOfTrack;

  SleepTimerState copyWith({
    bool? isActive,
    SleepTimerMode? mode,
    Duration? selectedDuration,
    Duration? remainingTime,
  }) {
    return SleepTimerState(
      isActive: isActive ?? this.isActive,
      mode: mode ?? this.mode,
      selectedDuration: selectedDuration ?? this.selectedDuration,
      remainingTime: remainingTime ?? this.remainingTime,
    );
  }
}

class SleepTimerNotifier extends StateNotifier<SleepTimerState> {
  final Ref _ref;
  Timer? _timer;
  DateTime? _endTime;
  StreamSubscription<PlayerState>? _completionSub;

  SleepTimerNotifier(this._ref) : super(SleepTimerState());

  void startTimer(Duration duration) {
    _cancelPending();
    _endTime = DateTime.now().add(duration);
    state = SleepTimerState(
      isActive: true,
      mode: SleepTimerMode.duration,
      selectedDuration: duration,
      remainingTime: duration,
    );

    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      final remaining = _endTime!.difference(DateTime.now());
      if (remaining.isNegative || remaining.inSeconds <= 0) {
        _timer?.cancel();
        _endTime = null;
        state = SleepTimerState();
        // Premium: pause via controller ( konsisten, saveQueue )
        try {
          final audioService = _ref.read(audioPlayerServiceProvider);
          audioService.player.pause();
        } catch (_) {}
      } else {
        state = state.copyWith(remainingTime: remaining);
      }
    });
  }

  /// Pauses once the current track reaches `ProcessingState.completed`.
  /// The queue is left intact so playback can resume with Play.
  void startEndOfTrack() {
    _cancelPending();
    state = SleepTimerState(
      isActive: true,
      mode: SleepTimerMode.endOfTrack,
    );

    try {
      final audioService = _ref.read(audioPlayerServiceProvider);
      _completionSub =
          audioService.player.playerStateStream.listen((playerState) {
        if (playerState.processingState != ProcessingState.completed) return;
        _handleEndOfTrack(audioService);
      });
    } catch (_) {}
  }

  Future<void> _handleEndOfTrack(AudioPlayerService audioService) async {
    // Cancel first so a repeated completed event cannot pause twice.
    await _completionSub?.cancel();
    _completionSub = null;
    if (!mounted) return;
    state = SleepTimerState();
    try {
      await audioService.player.pause();
    } catch (_) {}
  }

  void stopTimer() {
    _cancelPending();
    state = SleepTimerState();
  }

  void _cancelPending() {
    _timer?.cancel();
    _timer = null;
    _endTime = null;
    _completionSub?.cancel();
    _completionSub = null;
  }

  /// Dipanggil saat mini-player dismiss — premium: timer ikut cancel
  void cancelIfActive() {
    if (state.isActive) stopTimer();
  }

  @override
  void dispose() {
    _cancelPending();
    super.dispose();
  }
}
