import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:my_music_player/core/constants/enums.dart';
import 'package:my_music_player/features/browse/presentation/providers/browse_provider.dart';
import 'package:my_music_player/features/browse/presentation/screens/browse_screen.dart';
import 'package:my_music_player/features/player/domain/entities/track.dart';
import 'package:my_music_player/features/player/presentation/providers/player_controller.dart';

import '../../helpers/pump_app.dart';

class _MockPlayerController extends Mock implements PlayerController {}

const _oneMoreTime = Track(
  sourceId: 'yt-one-more-time',
  title: 'One More Time',
  artist: 'Daft Punk',
  durationMs: 200000,
  source: TrackSource.youtube,
);

const _getLucky = Track(
  sourceId: 'yt-get-lucky',
  title: 'Get Lucky',
  artist: 'Daft Punk',
  durationMs: 369000,
  source: TrackSource.youtube,
);

void main() {
  late _MockPlayerController player;

  setUpAll(() {
    registerFallbackValue(_oneMoreTime);
  });

  setUp(() {
    player = _MockPlayerController();
    when(() => player.state).thenReturn(PlayerState());
    when(() => player.playTrack(any(), queue: any(named: 'queue')))
        .thenAnswer((_) async {});
  });

  Future<void> pumpBrowse(
    WidgetTester tester, {
    List<Track> tracks = const <Track>[],
    ThemeMode themeMode = ThemeMode.dark,
    double textScale = 1.0,
  }) async {
    await pumpApp(
      tester,
      ProviderScope(
        overrides: [
          browseRecentlyPlayedProvider.overrideWith((ref) async => tracks),
          playerControllerProvider.overrideWith((ref) => player),
        ],
        child: const BrowseScreen(),
      ),
      themeMode: themeMode,
      textScale: textScale,
    );
    await tester.pumpAndSettle();
  }

  testWidgets('hub shows source cards and real recently played tracks',
      (tester) async {
    await pumpBrowse(tester, tracks: const [_oneMoreTime, _getLucky]);

    expect(find.text('Browse'), findsOneWidget);
    expect(find.text('YouTube Music'), findsOneWidget);
    expect(find.text('Device songs'), findsOneWidget);
    expect(find.text('Recently played'), findsOneWidget);
    expect(find.text('One More Time'), findsOneWidget);
    expect(find.text('Get Lucky'), findsOneWidget);
    expect(find.textContaining('collections'), findsNothing);
    expect(find.textContaining('SoundCloud'), findsNothing);
    expect(find.textContaining('yt-dlp'), findsNothing);
  });

  testWidgets('hub uses the empty state when nothing has been played',
      (tester) async {
    await pumpBrowse(tester);

    expect(find.text('Nothing played yet'), findsOneWidget);
    expect(find.text('Tracks you play will appear here'), findsOneWidget);
  });

  testWidgets('source cards expose labeled 48dp tap targets', (tester) async {
    final semantics = tester.ensureSemantics();
    try {
      await pumpBrowse(tester, tracks: const [_oneMoreTime]);

      final youtube = find.bySemanticsLabel('Search YouTube Music');
      final device = find.bySemanticsLabel('Open device songs');
      expect(youtube, findsOneWidget);
      expect(device, findsOneWidget);

      for (final target in [youtube, device]) {
        final size = tester.getSize(target);
        expect(size.width, greaterThanOrEqualTo(48));
        expect(size.height, greaterThanOrEqualTo(48));
      }
    } finally {
      semantics.dispose();
    }
  });

  testWidgets('tapping a track plays it with the list as the queue',
      (tester) async {
    final semantics = tester.ensureSemantics();
    try {
      await pumpBrowse(
        tester,
        tracks: const [_oneMoreTime, _getLucky],
      );

      await tester
          .tap(find.bySemanticsLabel('Play One More Time by Daft Punk'));
      await tester.pump();

      verify(
        () => player.playTrack(
          _oneMoreTime,
          queue: const [_oneMoreTime, _getLucky],
        ),
      ).called(1);
    } finally {
      semantics.dispose();
    }
  });

  testWidgets('hub is readable at text scale 2.0 without overflow',
      (tester) async {
    await pumpBrowse(
      tester,
      tracks: const [_oneMoreTime, _getLucky],
      textScale: 2.0,
    );

    expect(find.text('Browse'), findsOneWidget);
    expect(find.text('Recently played'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('hub uses the light theme tokens', (tester) async {
    await pumpBrowse(
      tester,
      tracks: const [_oneMoreTime],
      themeMode: ThemeMode.light,
    );

    expect(find.text('Browse'), findsOneWidget);
    expect(find.text('One More Time'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
