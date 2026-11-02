import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:just_audio/just_audio.dart';
import 'package:my_music_player/features/player/data/datasources/audio_player_service.dart';
import 'package:my_music_player/features/player/presentation/providers/sleep_timer_provider.dart';
import 'package:my_music_player/features/player/presentation/widgets/sleep_timer_sheet.dart';

import '../../helpers/pump_app.dart';
import 'presentation/providers/fakes.dart';

class _SeededSleepTimerNotifier extends SleepTimerNotifier {
  // ignore: use_super_parameters - the super parameter is private.
  _SeededSleepTimerNotifier(Ref ref, SleepTimerState seed) : super(ref) {
    state = seed;
  }
}

Future<void> _pumpSheet(
  WidgetTester tester, {
  SleepTimerState? seed,
  double textScale = 1.0,
}) async {
  final audio = FakeAudioPlayerService();
  addTearDown(audio.disposeFake);

  await pumpApp(
    tester,
    ProviderScope(
      overrides: [
        audioPlayerServiceProvider.overrideWithValue(audio),
        if (seed != null)
          sleepTimerProvider.overrideWith(
            (ref) => _SeededSleepTimerNotifier(ref, seed),
          ),
      ],
      child: const Scaffold(body: SleepTimerSheet()),
    ),
    textScale: textScale,
  );
}

void main() {
  testWidgets('sleep timer uses the new copy and duration options',
      (tester) async {
    await _pumpSheet(tester);

    expect(find.text('Sleep timer'), findsOneWidget);
    expect(find.text('Playback stops automatically'), findsOneWidget);
    for (final label in const [
      '5 minutes',
      '10 minutes',
      '15 minutes',
      '30 minutes',
      '60 minutes',
      'End of track',
    ]) {
      expect(find.text(label), findsOneWidget, reason: label);
    }
    expect(find.text('45 minutes'), findsNothing);
  });

  testWidgets('active duration is visible through a checked icon',
      (tester) async {
    await _pumpSheet(
      tester,
      seed: SleepTimerState(
        isActive: true,
        mode: SleepTimerMode.duration,
        selectedDuration: const Duration(minutes: 15),
        remainingTime: const Duration(minutes: 10),
      ),
    );

    expect(find.byIcon(Icons.radio_button_checked), findsOneWidget);
    expect(find.byIcon(Icons.radio_button_unchecked), findsNWidgets(5));
    expect(find.text('15 minutes'), findsOneWidget);
  });

  testWidgets('active end of track state shows label and Cancel',
      (tester) async {
    await _pumpSheet(
      tester,
      seed: SleepTimerState(
        isActive: true,
        mode: SleepTimerMode.endOfTrack,
      ),
    );

    expect(find.text('End of track'), findsNWidgets(2));
    expect(find.text('Cancel'), findsOneWidget);
  });

  testWidgets('sleep timer handles text scale 2.0 without overflow',
      (tester) async {
    await _pumpSheet(tester, textScale: 2.0);

    expect(tester.takeException(), isNull);
    expect(find.text('Sleep timer'), findsOneWidget);
  });

  testWidgets('end of track option arms the timer from the sheet',
      (tester) async {
    final audio = FakeAudioPlayerService();
    addTearDown(audio.disposeFake);

    await pumpApp(
      tester,
      Scaffold(
        body: Builder(
          builder: (context) => TextButton(
            onPressed: () => showSleepTimerSheet(context),
            child: const Text('open'),
          ),
        ),
      ),
      overrides: [
        audioPlayerServiceProvider.overrideWithValue(audio),
      ],
    );

    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('End of track'));
    await tester.pumpAndSettle();

    final container = ProviderScope.containerOf(
      tester.element(find.byType(Scaffold)),
    );
    final state = container.read(sleepTimerProvider);
    expect(state.isActive, isTrue);
    expect(state.mode, SleepTimerMode.endOfTrack);
  });

  test('end of track pauses once when playback completes', () async {
    final audio = FakeAudioPlayerService();
    addTearDown(audio.disposeFake);
    final container = ProviderContainer(
      overrides: [
        audioPlayerServiceProvider.overrideWithValue(audio),
      ],
    );
    addTearDown(container.dispose);

    final notifier = container.read(sleepTimerProvider.notifier);
    notifier.startEndOfTrack();
    expect(container.read(sleepTimerProvider).mode, SleepTimerMode.endOfTrack);

    audio.player.setProcessingState(ProcessingState.completed);
    await pumpEventQueue();

    expect(audio.player.pauseCalls, 1);
    expect(audio.pauseCalls, 0);
    expect(audio.stopCalls, 0);
    final state = container.read(sleepTimerProvider);
    expect(state.isActive, isFalse);
    expect(state.mode, SleepTimerMode.off);
  });

  test('cancelling end of track unsubscribes the completion listener',
      () async {
    final audio = FakeAudioPlayerService();
    addTearDown(audio.disposeFake);
    final container = ProviderContainer(
      overrides: [
        audioPlayerServiceProvider.overrideWithValue(audio),
      ],
    );
    addTearDown(container.dispose);

    final notifier = container.read(sleepTimerProvider.notifier);
    notifier.startEndOfTrack();
    notifier.stopTimer();

    audio.player.setProcessingState(ProcessingState.completed);
    await pumpEventQueue();

    expect(audio.player.pauseCalls, 0);
  });
}
