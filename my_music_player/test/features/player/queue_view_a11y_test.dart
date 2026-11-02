import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:my_music_player/core/constants/enums.dart';
import 'package:my_music_player/core/network/api_service.dart';
import 'package:my_music_player/core/theme/app_colors.dart';
import 'package:my_music_player/features/cache/data/datasources/cache_download_service.dart';
import 'package:my_music_player/features/library/data/repositories/playlist_repository_impl.dart';
import 'package:my_music_player/features/player/data/datasources/audio_player_service.dart';
import 'package:my_music_player/features/player/data/repositories/queue_repository.dart';
import 'package:my_music_player/features/player/data/repositories/track_repository_impl.dart';
import 'package:my_music_player/features/player/domain/entities/track.dart';
import 'package:my_music_player/features/player/presentation/providers/player_controller.dart';
import 'package:my_music_player/features/player/presentation/widgets/queue_view.dart';
import 'package:my_music_player/features/settings/presentation/providers/settings_provider.dart';

import '../../helpers/pump_app.dart';
import 'presentation/providers/fakes.dart';

Track _track(String id) {
  return Track(
    sourceId: id,
    title: 'Track $id',
    artist: 'Artist $id',
    durationMs: 180000,
    source: TrackSource.local,
    localAudioPath: 'C:/music/$id.mp3',
  );
}

/// Real controller with fakes, seeded directly so the widget test does not
/// need the network or a platform audio player.
class _TestPlayerController extends PlayerController {
  _TestPlayerController(
    super.audioService,
    super.apiService,
    super.trackRepo,
    super.cacheDownloadService,
    super.ref,
    PlayerState seed,
  ) {
    state = seed;
  }

  int removeCalls = 0;
  int? lastRemovedIndex;

  @override
  Future<void> removeFromQueue(int index) async {
    removeCalls++;
    lastRemovedIndex = index;
    await super.removeFromQueue(index);
  }
}

Future<_TestPlayerController> _pumpQueue(
  WidgetTester tester, {
  List<Track>? tracks,
  ThemeMode themeMode = ThemeMode.dark,
  double textScale = 1.0,
}) async {
  final audio = FakeAudioPlayerService();
  final trackRepo = FakeTrackRepository();
  final queueRepo = FakeQueueRepository();
  final api = FakeApiService();
  final playlistRepo = FakePlaylistRepository();
  final cacheService = FakeCacheDownloadService();
  addTearDown(audio.disposeFake);

  final queue = tracks ?? [_track('1'), _track('2')];
  late _TestPlayerController controller;

  await pumpApp(
    tester,
    ProviderScope(
      overrides: [
        audioPlayerServiceProvider.overrideWithValue(audio),
        apiServiceProvider.overrideWithValue(api),
        trackRepositoryProvider.overrideWithValue(trackRepo),
        cacheDownloadServiceProvider.overrideWithValue(cacheService),
        queueRepositoryProvider.overrideWithValue(queueRepo),
        playlistRepositoryProvider.overrideWithValue(playlistRepo),
        appSettingsProvider.overrideWith(
          (ref) => const Stream.empty(),
        ),
        playerControllerProvider.overrideWith((ref) {
          controller = _TestPlayerController(
            audio,
            api,
            trackRepo,
            cacheService,
            ref,
            PlayerState(
              currentTrack: queue.isEmpty ? null : queue.first,
              currentQueue: queue,
              currentIndex: queue.isEmpty ? -1 : 0,
            ),
          );
          return controller;
        }),
      ],
      child: const Scaffold(body: QueueView()),
    ),
    themeMode: themeMode,
    textScale: textScale,
  );

  return controller;
}

void main() {
  testWidgets('queue actions expose labels and >= 48dp targets',
      (tester) async {
    final semantics = tester.ensureSemantics();
    try {
      final controller = await _pumpQueue(tester);

      expect(find.bySemanticsLabel('Track options'), findsNWidgets(2));
      expect(find.bySemanticsLabel('Drag to reorder'), findsNWidgets(2));

      final optionsSize = tester.getSize(
        find.bySemanticsLabel('Track options').first,
      );
      expect(optionsSize.width, greaterThanOrEqualTo(48));
      expect(optionsSize.height, greaterThanOrEqualTo(48));

      final dragSize = tester.getSize(
        find.bySemanticsLabel('Drag to reorder').first,
      );
      expect(dragSize.width, greaterThanOrEqualTo(48));
      expect(dragSize.height, greaterThanOrEqualTo(48));

      // Swipe-to-remove has a labelled menu alternative (a11y §10).
      await tester.tap(find.bySemanticsLabel('Track options').first);
      await tester.pumpAndSettle();

      expect(find.text('Remove from queue'), findsOneWidget);
      final removeItem = find.ancestor(
        of: find.text('Remove from queue'),
        matching: find.byType(PopupMenuItem<String>),
      );
      final removeSize = tester.getSize(removeItem);
      expect(removeSize.height, greaterThanOrEqualTo(48));

      await tester.tap(removeItem);
      await tester.pumpAndSettle();

      expect(controller.removeCalls, 1);
      expect(controller.lastRemovedIndex, 0);
    } finally {
      semantics.dispose();
    }
  });

  testWidgets('queue row does not overflow at text scale 2.0', (tester) async {
    await _pumpQueue(tester, textScale: 2.0);

    expect(tester.takeException(), isNull);
    expect(find.text('Track 1'), findsOneWidget);
    expect(find.text('Artist 2'), findsOneWidget);
  });

  testWidgets('queue row colours resolve from the light token set',
      (tester) async {
    await _pumpQueue(tester, themeMode: ThemeMode.light);

    final popup = tester.widget<PopupMenuButton<String>>(
      find.byType(PopupMenuButton<String>).first,
    );
    expect(popup.color, AppColors.light.raised);

    final title = tester.widget<Text>(find.text('Track 1'));
    expect(title.style?.color, AppColors.light.accent);
  });
}
