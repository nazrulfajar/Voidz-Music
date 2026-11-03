import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:my_music_player/core/constants/enums.dart' show TrackSource;
import 'package:my_music_player/features/lyrics/domain/entities/lyrics.dart';
import 'package:my_music_player/features/lyrics/presentation/providers/lyrics_provider.dart';
import 'package:my_music_player/features/lyrics/presentation/widgets/lyrics_view.dart';
import 'package:my_music_player/features/player/domain/entities/track.dart';
import 'package:my_music_player/features/player/presentation/providers/player_controller.dart';
import 'package:my_music_player/features/settings/data/models/app_settings_model.dart';
import 'package:my_music_player/features/settings/presentation/providers/settings_provider.dart';
import 'package:my_music_player/shared/widgets/app_empty_state.dart';

import '../../helpers/pump_app.dart';
import '../player/presentation/providers/fakes.dart';

Track _track() {
  return const Track(
    sourceId: 'lyrics-track',
    title: 'Blinding Lights',
    artist: 'The Weeknd',
    durationMs: 200000,
    source: TrackSource.youtube,
  );
}

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
      currentTrack: _track(),
      currentQueue: [_track()],
      currentIndex: 0,
      position: const Duration(seconds: 6),
      duration: const Duration(seconds: 200),
    );
  }
}

Future<void> _pumpLyrics(
  WidgetTester tester, {
  required Lyrics lyrics,
  double textScale = 1.0,
  Locale locale = const Locale('en'),
}) async {
  await pumpApp(
    tester,
    ProviderScope(
      overrides: [
        appSettingsProvider.overrideWith(
          (ref) => const Stream<AppSettingsModel>.empty(),
        ),
        playerControllerProvider.overrideWith(
          (ref) => _StubPlayerController(ref),
        ),
        currentLyricsProvider.overrideWith((ref) async => lyrics),
      ],
      child: const Scaffold(body: LyricsView()),
    ),
    textScale: textScale,
    locale: locale,
  );
  await tester.pumpAndSettle();
}

final _synced = Lyrics(
  sourceId: 'lyrics-track',
  type: LyricsType.synced,
  syncedLyrics: '[00:00.00]Streetlights blur into the rain\n'
      '[00:05.00]The night keeps calling me home',
);

final _plain = Lyrics(
  sourceId: 'lyrics-track',
  type: LyricsType.plain,
  plainLyrics: 'Streetlights blur into the rain',
);

final _notFound = Lyrics(
  sourceId: 'lyrics-track',
  type: LyricsType.notFound,
);

void main() {
  testWidgets('synced lyrics show header, track, badge and LRCLIB footer',
      (tester) async {
    await _pumpLyrics(tester, lyrics: _synced);

    expect(find.text('LYRICS'), findsOneWidget);
    expect(find.text('Blinding Lights'), findsOneWidget);
    expect(find.text('The Weeknd'), findsOneWidget);
    expect(find.text('Synced'), findsOneWidget);
    expect(find.text('Synced lyrics · LRCLIB'), findsOneWidget);
  });

  testWidgets('plain lyrics hide the synced badge and say Lyrics · LRCLIB',
      (tester) async {
    await _pumpLyrics(tester, lyrics: _plain);

    expect(find.text('LYRICS'), findsOneWidget);
    expect(find.text('Synced'), findsNothing);
    expect(find.text('Synced lyrics · LRCLIB'), findsNothing);
    expect(find.text('Lyrics · LRCLIB'), findsOneWidget);
  });

  testWidgets('missing lyrics use the shared state panel', (tester) async {
    await _pumpLyrics(tester, lyrics: _notFound);

    expect(find.byType(AppStatePanel), findsOneWidget);
    expect(find.text('No lyrics found'), findsOneWidget);
    expect(find.text('Playback continues without lyrics.'), findsOneWidget);
  });

  testWidgets('lyrics handle text scale 2.0 without overflow', (tester) async {
    await _pumpLyrics(tester, lyrics: _synced, textScale: 2.0);

    expect(tester.takeException(), isNull);
    expect(find.text('LYRICS'), findsOneWidget);
  });

  testWidgets('synced lyrics copy follows the Indonesian locale',
      (tester) async {
    await _pumpLyrics(tester, lyrics: _synced, locale: const Locale('id'));

    expect(find.text('LIRIK'), findsOneWidget);
    expect(find.text('Sinkron'), findsOneWidget);
    expect(find.text('Lirik sinkron · LRCLIB'), findsOneWidget);
  });

  testWidgets('missing lyrics copy follows the Indonesian locale',
      (tester) async {
    await _pumpLyrics(tester, lyrics: _notFound, locale: const Locale('id'));

    expect(find.text('Lirik tidak ditemukan'), findsOneWidget);
    expect(find.text('Pemutaran berlanjut tanpa lirik.'), findsOneWidget);
  });
}
