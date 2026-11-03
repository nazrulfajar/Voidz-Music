import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:my_music_player/core/constants/enums.dart';
import 'package:my_music_player/features/player/data/datasources/audio_player_service.dart';
import 'package:my_music_player/features/player/domain/entities/track.dart';
import 'package:my_music_player/features/player/presentation/providers/player_controller.dart';
import 'package:my_music_player/features/player/presentation/screens/player_screen.dart';
import 'package:my_music_player/features/player/presentation/widgets/queue_view.dart';
import 'package:my_music_player/features/player/presentation/widgets/sleep_timer_sheet.dart';
import 'package:my_music_player/features/settings/data/models/app_settings_model.dart';
import 'package:my_music_player/features/settings/presentation/providers/settings_provider.dart';

import '../../helpers/pump_app.dart';
import 'presentation/providers/fakes.dart';

Track _track(String id) {
  return Track(
    sourceId: id,
    title: 'Track $id',
    artist: 'Artist $id',
    album: 'Album',
    durationMs: 180000,
    source: TrackSource.youtube,
  );
}

PlayerState _playerState({int queueLength = 2, int currentIndex = 0}) {
  final queue = List<Track>.generate(queueLength, (index) => _track('v$index'));
  return PlayerState(
    currentTrack: queue[currentIndex],
    currentQueue: queue,
    currentIndex: currentIndex,
    isPlaying: false,
    position: const Duration(seconds: 30),
    duration: const Duration(minutes: 3),
  );
}

class _StubPlayerController extends PlayerController {
  _StubPlayerController(Ref ref, PlayerState initial)
      : super(
          FakeAudioPlayerService(),
          FakeApiService(),
          FakeTrackRepository(),
          FakeCacheDownloadService(),
          ref,
        ) {
    state = initial;
  }
}

Future<void> _pumpPlayer(
  WidgetTester tester, {
  required Locale locale,
}) async {
  await pumpApp(
    tester,
    ProviderScope(
      overrides: [
        appSettingsProvider.overrideWith(
          (ref) => const Stream<AppSettingsModel>.empty(),
        ),
        playerControllerProvider.overrideWith(
          (ref) => _StubPlayerController(ref, _playerState()),
        ),
      ],
      child: const PlayerScreen(),
    ),
    locale: locale,
  );
  await tester.pumpAndSettle();
}

Future<void> _pumpQueue(
  WidgetTester tester, {
  required Locale locale,
}) async {
  await pumpApp(
    tester,
    ProviderScope(
      overrides: [
        appSettingsProvider.overrideWith(
          (ref) => const Stream<AppSettingsModel>.empty(),
        ),
        playerControllerProvider.overrideWith(
          (ref) => _StubPlayerController(ref, _playerState()),
        ),
      ],
      child: const Scaffold(body: QueueView()),
    ),
    locale: locale,
  );
  await tester.pumpAndSettle();
}

Future<void> _pumpSleepTimer(
  WidgetTester tester, {
  required Locale locale,
}) async {
  final audio = FakeAudioPlayerService();
  addTearDown(audio.disposeFake);

  await pumpApp(
    tester,
    ProviderScope(
      overrides: [
        audioPlayerServiceProvider.overrideWithValue(audio),
      ],
      child: const Scaffold(body: SleepTimerSheet()),
    ),
    locale: locale,
  );
  await tester.pumpAndSettle();
}

void main() {
  const en = Locale('en');
  const id = Locale('id');

  testWidgets('player copy follows the app locale', (tester) async {
    final semantics = tester.ensureSemantics();
    try {
      await _pumpPlayer(tester, locale: en);
      expect(find.text('PLAYING FROM'), findsOneWidget);
      expect(find.bySemanticsLabel('Close player'), findsOneWidget);
      expect(find.text('Lyrics'), findsOneWidget);
      expect(find.text('Queue (2)'), findsOneWidget);
      expect(find.text('Timer'), findsOneWidget);
      expect(find.bySemanticsLabel('Play'), findsOneWidget);

      await _pumpPlayer(tester, locale: id);
      expect(find.text('DIPUTAR DARI'), findsOneWidget);
      expect(find.bySemanticsLabel('Tutup pemutar'), findsOneWidget);
      expect(find.text('Lirik'), findsOneWidget);
      expect(find.text('Antrean (2)'), findsOneWidget);
      expect(find.text('Timer'), findsOneWidget);
      expect(find.bySemanticsLabel('Putar'), findsOneWidget);
    } finally {
      semantics.dispose();
    }
  });

  testWidgets('queue copy follows the app locale', (tester) async {
    await _pumpQueue(tester, locale: en);
    expect(find.text('Queue'), findsOneWidget);
    expect(find.text('2 songs · 6 min'), findsOneWidget);
    expect(find.text('NOW PLAYING'), findsOneWidget);
    expect(find.text('UP NEXT'), findsOneWidget);
    expect(find.text('1 song'), findsOneWidget);
    expect(
      find.text('Drag to reorder · Swipe to remove'),
      findsOneWidget,
    );

    await _pumpQueue(tester, locale: id);
    expect(find.text('Antrean'), findsOneWidget);
    expect(find.text('2 lagu · 6 mnt'), findsOneWidget);
    expect(find.text('SEDANG DIPUTAR'), findsOneWidget);
    expect(find.text('BERIKUTNYA'), findsOneWidget);
    expect(find.text('1 lagu'), findsOneWidget);
    expect(
      find.text('Tarik untuk mengubah urutan · Geser untuk menghapus'),
      findsOneWidget,
    );

    await tester.tap(find.text('Hapus'));
    await tester.pumpAndSettle();
    expect(find.text('Hapus antrean?'), findsOneWidget);
    expect(
      find.textContaining('1 lagu'),
      findsWidgets,
    );
    expect(find.text('Batal'), findsOneWidget);
  });

  testWidgets('sleep timer copy follows the app locale', (tester) async {
    await _pumpSleepTimer(tester, locale: en);
    expect(find.text('Sleep timer'), findsOneWidget);
    expect(find.text('Playback stops automatically'), findsOneWidget);
    expect(find.text('5 minutes'), findsOneWidget);
    expect(find.text('End of track'), findsOneWidget);

    await _pumpSleepTimer(tester, locale: id);
    expect(find.text('Timer tidur'), findsOneWidget);
    expect(find.text('Pemutaran berhenti otomatis'), findsOneWidget);
    expect(find.text('5 menit'), findsOneWidget);
    expect(find.text('Akhir lagu'), findsOneWidget);
  });
}
