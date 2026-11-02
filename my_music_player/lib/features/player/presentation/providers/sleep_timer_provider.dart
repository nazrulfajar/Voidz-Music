import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/datasources/audio_player_service.dart';

final sleepTimerProvider = StateNotifierProvider<SleepTimerNotifier, SleepTimerState>((ref) {
  return SleepTimerNotifier(ref);
});

class SleepTimerState {
  final bool isActive;
  final Duration remainingTime;

  SleepTimerState({
    this.isActive = false,
    this.remainingTime = Duration.zero,
  });

  SleepTimerState copyWith({
    bool? isActive,
    Duration? remainingTime,
  }) {
    return SleepTimerState(
      isActive: isActive ?? this.isActive,
      remainingTime: remainingTime ?? this.remainingTime,
    );
  }
}

class SleepTimerNotifier extends StateNotifier<SleepTimerState> {
  final Ref _ref;
  Timer? _timer;
  DateTime? _endTime;

  SleepTimerNotifier(this._ref) : super(SleepTimerState());

  void startTimer(Duration duration) {
    _timer?.cancel();
    _endTime = DateTime.now().add(duration);
    state = state.copyWith(isActive: true, remainingTime: duration);

    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      final remaining = _endTime!.difference(DateTime.now());
      if (remaining.isNegative || remaining.inSeconds <= 0) {
        _timer?.cancel();
        _endTime = null;
        state = state.copyWith(isActive: false, remainingTime: Duration.zero);
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

  void stopTimer() {
    _timer?.cancel();
    _endTime = null;
    state = state.copyWith(isActive: false, remainingTime: Duration.zero);
  }

  /// Dipanggil saat mini-player dismiss — premium: timer ikut cancel
  void cancelIfActive() {
    if (state.isActive) stopTimer();
  }
  
  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }
}
