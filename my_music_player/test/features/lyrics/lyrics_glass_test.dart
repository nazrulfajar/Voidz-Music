import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:my_music_player/core/constants/enums.dart' show TrackSource;
import 'package:my_music_player/core/theme/app_glass.dart';
import 'package:my_music_player/features/lyrics/domain/entities/lyrics.dart';
import 'package:my_music_player/features/lyrics/presentation/providers/lyrics_provider.dart';
import 'package:my_music_player/features/lyrics/presentation/widgets/lyrics_view.dart';
import 'package:my_music_player/features/player/domain/entities/track.dart';
import 'package:my_music_player/features/player/presentation/providers/player_controller.dart';
import 'package:my_music_player/features/player/presentation/screens/player_screen.dart';
import 'package:my_music_player/features/settings/data/models/app_settings_model.dart';
import 'package:my_music_player/features/settings/presentation/providers/settings_provider.dart';
import 'package:my_music_player/shared/widgets/glass_surface.dart';

import '../../helpers/pump_app.dart';
import '../player/presentation/providers/fakes.dart';

const _track = Track(
  sourceId: 'lyrics-track',
  title: 'Blinding Lights',
  artist: 'The Weeknd',
  durationMs: 200000,
  source: TrackSource.youtube,
);

final _synced = Lyrics(
  sourceId: 'lyrics-track',
  type: LyricsType.synced,
  syncedLyrics: '[00:00.00]Streetlights blur into the rain\n'
      '[00:05.00]The night keeps calling me home',
);

class _StubPlayerController extends PlayerController {
  _StubPlayerController(Ref ref)
      : super(
          FakeAudioPlayerService(),
          FakeApiService(),
          FakeTrackRepository(),
          FakeCacheDownloadService(),
          ref,
        ) {
    state = PlayerState(
      currentTrack: _track,
      currentQueue: const [_track],
      currentIndex: 0,
      position: const Duration(seconds: 6),
      duration: const Duration(seconds: 200),
    );
  }
}

Future<void> _pumpPlayer(
  WidgetTester tester, {
  double textScale = 1.0,
  bool disableAnimations = false,
}) async {
  const screen = PlayerScreen();
  Widget child = screen;
  if (disableAnimations) {
    child = Builder(
      builder: (context) => MediaQuery(
        data: MediaQuery.of(context).copyWith(disableAnimations: true),
        child: screen,
      ),
    );
  }

  await pumpApp(
    tester,
    child,
    textScale: textScale,
    locale: const Locale('en'),
    overrides: [
      appSettingsProvider.overrideWith(
        (ref) => const Stream<AppSettingsModel>.empty(),
      ),
      playerControllerProvider.overrideWith(
        (ref) => _StubPlayerController(ref),
      ),
      currentLyricsProvider.overrideWith((ref) async => _synced),
    ],
  );
  await tester.pumpAndSettle();
}

Future<void> _openLyrics(WidgetTester tester) async {
  final semantics = tester.ensureSemantics();
  try {
    await tester.tap(find.bySemanticsLabel('Lyrics'));
    await tester.pumpAndSettle();
  } finally {
    semantics.dispose();
  }
}

void main() {
  testWidgets('lyrics sheet is one frosted chrome panel without row blur',
      (tester) async {
    await _pumpPlayer(tester);
    await _openLyrics(tester);

    final sheet = find.byKey(const Key('lyrics-sheet-glass'));
    expect(sheet, findsOneWidget);
    expect(
      tester.widget<GlassSurface>(sheet).quality,
      GlassQuality.frosted,
    );
    expect(
      find.descendant(of: sheet, matching: find.byType(BackdropFilter)),
      findsNothing,
    );

    expect(find.byType(LyricsView), findsOneWidget);
    expect(find.text('LYRICS'), findsOneWidget);
    expect(
      find.descendant(of: sheet, matching: find.text('Blinding Lights')),
      findsOneWidget,
    );
    expect(
      find.descendant(of: sheet, matching: find.text('The Weeknd')),
      findsOneWidget,
    );
    expect(find.text('Synced lyrics · LRCLIB'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('disableAnimations keeps the lyrics sheet readable',
      (tester) async {
    await _pumpPlayer(tester, disableAnimations: true);
    await _openLyrics(tester);

    expect(find.byType(BackdropFilter), findsNothing);
    expect(find.byKey(const Key('lyrics-sheet-glass')), findsOneWidget);
    expect(find.text('LYRICS'), findsOneWidget);
    expect(find.text('Synced lyrics · LRCLIB'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('lyrics sheet survives 200% text scale', (tester) async {
    await _pumpPlayer(tester, textScale: 2.0);
    await _openLyrics(tester);

    expect(tester.takeException(), isNull);
    expect(find.byKey(const Key('lyrics-sheet-glass')), findsOneWidget);
    expect(find.byType(LyricsView), findsOneWidget);
    expect(find.text('LYRICS'), findsOneWidget);
  });
}
