import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:my_music_player/core/constants/enums.dart';
import 'package:my_music_player/core/network/api_service.dart';
import 'package:my_music_player/core/providers/connectivity_provider.dart';
import 'package:my_music_player/core/theme/app_colors.dart';
import 'package:my_music_player/core/theme/app_glass.dart';
import 'package:my_music_player/features/cache/data/datasources/cache_download_service.dart';
import 'package:my_music_player/features/player/data/datasources/audio_player_service.dart';
import 'package:my_music_player/features/player/data/repositories/track_repository_impl.dart';
import 'package:my_music_player/features/player/domain/entities/track.dart';
import 'package:my_music_player/features/search/data/models/search_history_model.dart';
import 'package:my_music_player/features/search/presentation/providers/search_provider.dart';
import 'package:my_music_player/features/search/presentation/screens/search_screen.dart';
import 'package:my_music_player/features/settings/data/models/app_settings_model.dart';
import 'package:my_music_player/features/settings/presentation/providers/settings_provider.dart';
import 'package:my_music_player/shared/widgets/glass_surface.dart';

import '../../helpers/pump_app.dart';
import '../player/presentation/providers/fakes.dart';

class _MockSearchHistoryController extends Mock
    implements SearchHistoryController {}

const _track = Track(
  sourceId: 'yt-one-more-time',
  title: 'One More Time',
  artist: 'Daft Punk',
  durationMs: 200000,
  source: TrackSource.youtube,
);

SearchHistoryModel _history(int id, String query) {
  return SearchHistoryModel()
    ..id = id
    ..query = query
    ..timestamp = DateTime(2026, 11, 3);
}

Future<void> _pumpSearch(
  WidgetTester tester, {
  List<dynamic> results = const [],
  String query = '',
  String filter = 'top',
  List<SearchHistoryModel> history = const [],
  double textScale = 1.0,
  bool disableAnimations = false,
}) async {
  final historyController = _MockSearchHistoryController();
  when(() => historyController.deleteHistory(any())).thenAnswer((_) async {});
  when(() => historyController.clearHistory()).thenAnswer((_) async {});

  final container = ProviderContainer(
    overrides: [
      connectivityProvider.overrideWith((ref) => Stream.value(true)),
      searchQueryProvider.overrideWith((ref) => query),
      searchFilterProvider.overrideWith((ref) => filter),
      searchResultsProvider.overrideWith((ref) async => results),
      searchHistoryProvider.overrideWith((ref) => Stream.value(history)),
      searchHistoryControllerProvider.overrideWith(
        (ref) => historyController,
      ),
      appSettingsProvider.overrideWith(
        (ref) => Stream.value(AppSettingsModel()),
      ),
      audioPlayerServiceProvider.overrideWithValue(FakeAudioPlayerService()),
      apiServiceProvider.overrideWithValue(FakeApiService()),
      trackRepositoryProvider.overrideWithValue(FakeTrackRepository()),
      cacheDownloadServiceProvider.overrideWithValue(
        FakeCacheDownloadService(),
      ),
    ],
  );
  addTearDown(container.dispose);

  const screen = SearchScreen();
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
    UncontrolledProviderScope(
      container: container,
      child: child,
    ),
    textScale: textScale,
    surfaceSize: const Size(800, 640),
  );
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('search field and browse entry use glass over the aurora',
      (tester) async {
    await _pumpSearch(tester, history: [_history(1, 'daft punk')]);

    expect(
      tester.widget<Scaffold>(find.byType(Scaffold)).backgroundColor,
      Colors.transparent,
    );

    final fieldFinder = find.byKey(const Key('search-field-glass'));
    final field = tester.widget<GlassSurface>(fieldFinder);
    expect(field.quality, GlassQuality.blurred);
    expect(
      find.descendant(
        of: fieldFinder,
        matching: find.byType(BackdropFilter),
      ),
      findsOneWidget,
    );
    expect(tester.getSize(find.byType(TextField)).height, 47);

    final recentFinder = find.byKey(const ValueKey('search-recent-glass-1'));
    expect(
      tester.widget<GlassSurface>(recentFinder).quality,
      GlassQuality.frosted,
    );
    expect(
      find.descendant(
        of: recentFinder,
        matching: find.byType(BackdropFilter),
      ),
      findsNothing,
    );

    final browseFinder = find.byKey(const ValueKey('search-browse-entry'));
    final browseGlass = find.descendant(
      of: browseFinder,
      matching: find.byType(GlassSurface),
    );
    expect(browseGlass, findsOneWidget);
    expect(
      tester.widget<GlassSurface>(browseGlass).quality,
      GlassQuality.frosted,
    );
  });

  testWidgets('filter chips use the glass chip tokens without blur',
      (tester) async {
    await _pumpSearch(tester);

    final selected = tester.widget<Container>(
      find.byKey(const ValueKey('search-filter-chip-top')),
    );
    final selectedDecoration = selected.decoration! as BoxDecoration;
    expect(selectedDecoration.color, AppGlass.dark.chipSelectedFill);
    expect(
      (selectedDecoration.border! as Border).top.color,
      AppGlass.dark.chipSelectedBorder,
    );

    final subtle = tester.widget<Container>(
      find.byKey(const ValueKey('search-filter-chip-songs')),
    );
    final subtleDecoration = subtle.decoration! as BoxDecoration;
    expect(subtleDecoration.color, AppGlass.dark.chipSubtleFill);
    expect(
      (subtleDecoration.border! as Border).top.color,
      AppGlass.dark.chipSubtleBorder,
    );

    expect(
      find.descendant(
        of: find.byKey(const ValueKey('search-filter-chip-top')),
        matching: find.byType(BackdropFilter),
      ),
      findsNothing,
    );
  });

  testWidgets('result rows are frosted glass and keep metadata',
      (tester) async {
    await _pumpSearch(
      tester,
      query: 'daft punk',
      filter: 'songs',
      results: [_track],
    );

    final rowFinder = find.byKey(
      const ValueKey('search-track-glass-yt-one-more-time'),
    );
    expect(rowFinder, findsOneWidget);
    expect(
      tester.widget<GlassSurface>(rowFinder).quality,
      GlassQuality.frosted,
    );
    expect(
      find.descendant(
        of: rowFinder,
        matching: find.byType(BackdropFilter),
      ),
      findsNothing,
    );

    expect(find.text('One More Time'), findsOneWidget);
    expect(find.text('Daft Punk'), findsOneWidget);
    expect(find.text('3:20'), findsOneWidget);
    // Only the fixed search field is allowed to blur.
    expect(find.byType(BackdropFilter), findsOneWidget);
  });

  testWidgets('disableAnimations removes every search backdrop filter',
      (tester) async {
    await _pumpSearch(
      tester,
      history: [_history(1, 'daft punk')],
      disableAnimations: true,
    );

    expect(find.byType(BackdropFilter), findsNothing);

    final fieldFinder = find.byKey(const Key('search-field-glass'));
    final surface = tester.widget<Container>(
      find
          .descendant(
            of: fieldFinder,
            matching: find.byType(Container),
          )
          .first,
    );
    final decoration = surface.decoration! as BoxDecoration;
    expect(
      decoration.color,
      AppGlass.dark.card.frostedFill(AppColors.dark.surface),
    );
    expect(find.text('daft punk'), findsOneWidget);
  });

  testWidgets('search glass survives text scale 2.0', (tester) async {
    await _pumpSearch(
      tester,
      query: 'daft punk',
      filter: 'songs',
      results: [_track],
      textScale: 2.0,
    );

    expect(tester.takeException(), isNull);
    expect(
      find.byKey(const ValueKey('search-track-glass-yt-one-more-time')),
      findsOneWidget,
    );
    expect(find.text('One More Time'), findsOneWidget);
  });
}
