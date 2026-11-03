import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:my_music_player/core/constants/enums.dart';
import 'package:my_music_player/core/theme/app_colors.dart';
import 'package:my_music_player/core/theme/app_glass.dart';
import 'package:my_music_player/features/player/domain/entities/track.dart';
import 'package:my_music_player/features/player/presentation/providers/player_controller.dart';
import 'package:my_music_player/features/recap/domain/entities/recap.dart';
import 'package:my_music_player/features/recap/domain/entities/recap_period.dart';
import 'package:my_music_player/features/recap/presentation/providers/recap_provider.dart';
import 'package:my_music_player/features/recap/presentation/screens/recap_screen.dart';
import 'package:my_music_player/features/settings/data/models/app_settings_model.dart';
import 'package:my_music_player/features/settings/presentation/providers/settings_provider.dart';
import 'package:my_music_player/shared/widgets/glass_surface.dart';

import '../../helpers/pump_app.dart';
import '../player/presentation/providers/fakes.dart';

const _mostPlayed = Track(
  sourceId: 'recap-track-1',
  title: 'Night Drive',
  artist: 'Aurora',
  album: 'Signals',
  durationMs: 215000,
  source: TrackSource.youtube,
);

const _secondTrack = Track(
  sourceId: 'recap-track-2',
  title: 'Cold Light',
  artist: 'Aurora',
  durationMs: 198000,
  source: TrackSource.youtube,
);

Recap _recap() {
  return const Recap(
    year: 2026,
    mostPlayed: _mostPlayed,
    mostPlayedCount: 9,
    topSongs: [_mostPlayed, _secondTrack],
    topSongCounts: [9, 5],
    topArtists: [ArtistCount(name: 'Aurora', count: 14)],
    topAlbums: [
      AlbumCount(album: 'Signals', artist: 'Aurora', count: 11),
    ],
    totalPlays: 45,
    totalTracks: 12,
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
      currentTrack: _mostPlayed,
      currentQueue: const [_mostPlayed],
      currentIndex: 0,
      duration: const Duration(seconds: 215),
    );
  }
}

Future<void> _pumpRecap(
  WidgetTester tester, {
  ThemeMode themeMode = ThemeMode.dark,
  double textScale = 1.0,
  bool disableAnimations = false,
}) async {
  const screen = RecapScreen();
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
    themeMode: themeMode,
    textScale: textScale,
    locale: const Locale('en'),
    overrides: [
      selectedRecapPeriodProvider.overrideWith((ref) => RecapPeriod.year),
      selectedRecapYearProvider.overrideWith((ref) => 2026),
      selectedRecapMonthProvider.overrideWith((ref) => 10),
      recapProvider.overrideWith((ref, query) async => _recap()),
      recapYearsProvider.overrideWith((ref) async => [2026, 2025]),
      appSettingsProvider.overrideWith(
        (ref) => const Stream<AppSettingsModel>.empty(),
      ),
      playerControllerProvider.overrideWith(
        (ref) => _StubPlayerController(ref),
      ),
    ],
  );
  await tester.pumpAndSettle();
}

Future<void> _scrollTo(WidgetTester tester, Finder finder) async {
  await tester.scrollUntilVisible(
    finder,
    200,
    scrollable: find.byType(Scrollable).first,
  );
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('recap summary blurs once and top lists stay frosted',
      (tester) async {
    await _pumpRecap(tester);

    expect(
      tester.widget<Scaffold>(find.byType(Scaffold)).backgroundColor,
      Colors.transparent,
    );

    final summary = find.byKey(const Key('recap-summary-glass'));
    expect(summary, findsOneWidget);
    expect(
      tester.widget<GlassSurface>(summary).quality,
      GlassQuality.blurred,
    );
    expect(
      find.descendant(of: summary, matching: find.byType(BackdropFilter)),
      findsOneWidget,
    );
    // One summary layer; list rows below never add blur.
    expect(find.byType(BackdropFilter), findsOneWidget);

    final song = find.byKey(const Key('recap-song-glass-1'));
    await _scrollTo(tester, song);
    expect(
      tester.widget<GlassSurface>(song).quality,
      GlassQuality.frosted,
    );
    expect(
      find.descendant(of: song, matching: find.byType(BackdropFilter)),
      findsNothing,
    );

    final artist = find.byKey(const Key('recap-artist-glass-1'));
    await _scrollTo(tester, artist);
    expect(
      tester.widget<GlassSurface>(artist).quality,
      GlassQuality.frosted,
    );

    final album = find.byKey(const Key('recap-album-glass-1'));
    await _scrollTo(tester, album);
    expect(
      tester.widget<GlassSurface>(album).quality,
      GlassQuality.frosted,
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('disableAnimations keeps the summary glass without blur',
      (tester) async {
    await _pumpRecap(tester, disableAnimations: true);

    expect(find.byType(BackdropFilter), findsNothing);
    expect(find.byKey(const Key('recap-summary-glass')), findsOneWidget);
    expect(find.text('Total plays'), findsOneWidget);
    expect(find.text('45'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('light theme uses the provisional glass card tokens',
      (tester) async {
    await _pumpRecap(tester, themeMode: ThemeMode.light);

    final summary = find.byKey(const Key('recap-summary-glass'));
    final surface = tester.widget<Container>(
      find.descendant(of: summary, matching: find.byType(Container)).first,
    );
    final decoration = surface.decoration! as BoxDecoration;
    expect(decoration.color, AppGlass.light.card.fill);

    final label = tester.widget<Text>(find.text('Total plays'));
    expect(label.style?.color, AppColors.light.textSecondary);
    final value = tester.widget<Text>(find.text('45'));
    expect(value.style?.color, AppColors.light.accent);
  });

  testWidgets('recap glass survives 200% text scale', (tester) async {
    await _pumpRecap(tester, textScale: 2.0);

    expect(tester.takeException(), isNull);
    expect(find.byKey(const Key('recap-summary-glass')), findsOneWidget);

    await _scrollTo(tester, find.byKey(const Key('recap-album-glass-1')));

    expect(find.byKey(const Key('recap-album-glass-1')), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
