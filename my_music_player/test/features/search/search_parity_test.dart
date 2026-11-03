import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:my_music_player/core/constants/enums.dart';
import 'package:my_music_player/core/network/api_service.dart';
import 'package:my_music_player/core/providers/connectivity_provider.dart';
import 'package:my_music_player/core/theme/app_colors.dart';
import 'package:my_music_player/features/cache/data/datasources/cache_download_service.dart';
import 'package:my_music_player/features/player/data/datasources/audio_player_service.dart';
import 'package:my_music_player/features/player/data/repositories/track_repository_impl.dart';
import 'package:my_music_player/features/player/domain/entities/track.dart';
import 'package:my_music_player/features/search/data/models/search_history_model.dart';
import 'package:my_music_player/features/search/presentation/providers/search_provider.dart';
import 'package:my_music_player/features/search/presentation/screens/search_screen.dart';
import 'package:my_music_player/features/settings/data/models/app_settings_model.dart';
import 'package:my_music_player/features/settings/presentation/providers/settings_provider.dart';

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
    ..timestamp = DateTime(2026, 11, 2);
}

late ProviderContainer _container;
late _MockSearchHistoryController _historyController;

Future<void> _pumpSearch(
  WidgetTester tester, {
  List<dynamic> results = const [],
  String query = '',
  String filter = 'top',
  List<SearchHistoryModel> history = const [],
  ThemeMode themeMode = ThemeMode.dark,
  double textScale = 1.0,
  Size surfaceSize = kTestSurfaceSize,
}) async {
  _historyController = _MockSearchHistoryController();
  when(() => _historyController.deleteHistory(any())).thenAnswer((_) async {});
  when(() => _historyController.clearHistory()).thenAnswer((_) async {});

  _container = ProviderContainer(
    overrides: [
      connectivityProvider.overrideWith((ref) => Stream.value(true)),
      searchQueryProvider.overrideWith((ref) => query),
      searchFilterProvider.overrideWith((ref) => filter),
      searchResultsProvider.overrideWith((ref) async => results),
      searchHistoryProvider.overrideWith((ref) => Stream.value(history)),
      searchHistoryControllerProvider.overrideWith(
        (ref) => _historyController,
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
  addTearDown(_container.dispose);

  await pumpApp(
    tester,
    UncontrolledProviderScope(
      container: _container,
      child: const SearchScreen(),
    ),
    themeMode: themeMode,
    textScale: textScale,
    surfaceSize: surfaceSize,
  );
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('track count and duration use the secondary text token',
      (tester) async {
    await _pumpSearch(
      tester,
      query: 'daft punk',
      filter: 'songs',
      results: [_track],
    );

    final count = tester.widget<Text>(find.text('1 song'));
    expect(count.style?.color, AppColors.dark.textSecondary);
    expect(count.style?.color, isNot(AppColors.dark.textMuted));

    final duration = tester.widget<Text>(find.text('3:20'));
    expect(duration.style?.color, AppColors.dark.textSecondary);
    expect(duration.style?.color, isNot(AppColors.dark.textMuted));
  });

  testWidgets('light theme also uses secondary for count and duration',
      (tester) async {
    await _pumpSearch(
      tester,
      query: 'daft punk',
      filter: 'songs',
      results: [_track],
      themeMode: ThemeMode.light,
    );

    expect(
      tester.widget<Text>(find.text('1 song')).style?.color,
      AppColors.light.textSecondary,
    );
    expect(
      tester.widget<Text>(find.text('3:20')).style?.color,
      AppColors.light.textSecondary,
    );
  });

  testWidgets('filter chips expose a label and a 48dp tap target',
      (tester) async {
    final semantics = tester.ensureSemantics();
    try {
      await _pumpSearch(tester, surfaceSize: const Size(800, 640));

      const filters = <String, String>{
        'All': 'top',
        'Songs': 'songs',
        'Artists': 'artists',
        'Albums': 'albums',
        'Playlists': 'playlists',
      };

      for (final entry in filters.entries) {
        final chip = find.bySemanticsLabel('Filter ${entry.key}');
        await tester.scrollUntilVisible(
          chip,
          80,
          scrollable: find.byType(Scrollable).first,
        );
        await tester.pumpAndSettle();
        expect(chip, findsOneWidget, reason: '${entry.key} semantics');

        final node = tester.getSemantics(chip);
        expect(
          node.getSemanticsData().flagsCollection.isButton,
          isTrue,
          reason: '${entry.key} is a button',
        );

        final target = tester.getSize(chip);
        expect(
          target.height,
          greaterThanOrEqualTo(48),
          reason: '${entry.key} height',
        );
        expect(
          target.width,
          greaterThanOrEqualTo(48),
          reason: '${entry.key} width',
        );

        final visual = tester.getSize(
          find.byKey(ValueKey('search-filter-chip-${entry.value}')),
        );
        expect(visual.height, 29, reason: '${entry.key} visual height');
      }

      await tester.tap(find.bySemanticsLabel('Filter Playlists'));
      await tester.pump();
      expect(_container.read(searchFilterProvider), 'playlists');
    } finally {
      semantics.dispose();
    }
  });

  testWidgets('tapping a recent search fills the query field', (tester) async {
    final semantics = tester.ensureSemantics();
    try {
      await _pumpSearch(
        tester,
        history: [_history(1, 'daft punk')],
      );

      expect(find.text('RECENT SEARCHES'), findsOneWidget);

      final remove = find.bySemanticsLabel('Remove daft punk');
      expect(remove, findsOneWidget);
      final removeSize = tester.getSize(remove);
      expect(removeSize.width, greaterThanOrEqualTo(48));
      expect(removeSize.height, greaterThanOrEqualTo(48));

      await tester.tap(remove);
      await tester.pump();
      verify(() => _historyController.deleteHistory(1)).called(1);

      await tester.tap(find.text('daft punk'));
      await tester.pumpAndSettle();

      expect(_container.read(searchQueryProvider), 'daft punk');
      final field = tester.widget<TextField>(find.byType(TextField));
      expect(field.controller?.text, 'daft punk');
    } finally {
      semantics.dispose();
    }
  });

  testWidgets('the recent searches header can clear history', (tester) async {
    await _pumpSearch(
      tester,
      history: [_history(1, 'daft punk'), _history(2, 'justice')],
    );

    await tester.tap(find.text('Clear'));
    await tester.pump();

    verify(() => _historyController.clearHistory()).called(1);
  });

  testWidgets('search field is 47dp with a labeled 48dp clear action',
      (tester) async {
    final semantics = tester.ensureSemantics();
    try {
      await _pumpSearch(tester);

      expect(tester.getSize(find.byType(TextField)).height, 47);

      final searchIcon = tester.widget<Icon>(
        find.byIcon(Icons.search_rounded).first,
      );
      expect(searchIcon.size, 18);

      await tester.enterText(find.byType(TextField), 'daft punk');
      await tester.pump();

      final clear = find.bySemanticsLabel('Clear search');
      expect(clear, findsOneWidget);
      final clearSize = tester.getSize(clear);
      expect(clearSize.width, greaterThanOrEqualTo(48));
      expect(clearSize.height, greaterThanOrEqualTo(48));

      await tester.tap(clear);
      await tester.pumpAndSettle();

      expect(_container.read(searchQueryProvider), '');
      expect(
        tester.widget<TextField>(find.byType(TextField)).controller?.text,
        '',
      );
    } finally {
      semantics.dispose();
    }
  });

  testWidgets('result rows show title, artist, duration and no legacy sources',
      (tester) async {
    await _pumpSearch(
      tester,
      query: 'daft punk',
      filter: 'songs',
      results: [_track],
    );

    expect(find.text('SONGS'), findsOneWidget);
    expect(find.text('One More Time'), findsOneWidget);
    expect(find.text('Daft Punk'), findsOneWidget);
    expect(find.text('3:20'), findsOneWidget);
    expect(find.textContaining('SoundCloud'), findsNothing);
    expect(find.textContaining('Jamendo'), findsNothing);
  });

  testWidgets('results survive text scale 2.0 without overflow',
      (tester) async {
    await _pumpSearch(
      tester,
      query: 'daft punk',
      filter: 'songs',
      results: [_track],
      textScale: 2.0,
    );

    expect(find.text('One More Time'), findsOneWidget);
    expect(find.text('3:20'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('recent searches survive text scale 2.0 without overflow',
      (tester) async {
    await _pumpSearch(
      tester,
      history: [
        _history(1, 'the weeknd blinding lights'),
        _history(2, 'daft punk'),
      ],
      textScale: 2.0,
    );

    expect(find.text('RECENT SEARCHES'), findsOneWidget);
    expect(find.text('the weeknd blinding lights'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
