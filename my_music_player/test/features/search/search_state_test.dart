import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:my_music_player/core/constants/enums.dart';
import 'package:my_music_player/core/network/api_service.dart';
import 'package:my_music_player/core/providers/connectivity_provider.dart';
import 'package:my_music_player/features/cache/data/datasources/cache_download_service.dart';
import 'package:my_music_player/features/player/data/datasources/audio_player_service.dart';
import 'package:my_music_player/features/player/data/repositories/track_repository_impl.dart';
import 'package:my_music_player/features/player/domain/entities/track.dart';
import 'package:my_music_player/features/search/data/models/search_history_model.dart';
import 'package:my_music_player/features/search/presentation/providers/search_provider.dart';
import 'package:my_music_player/features/search/presentation/screens/search_screen.dart';
import 'package:my_music_player/features/settings/data/models/app_settings_model.dart';
import 'package:my_music_player/features/settings/presentation/providers/settings_provider.dart';
import 'package:my_music_player/shared/widgets/shimmer_loading.dart';

import '../../helpers/pump_app.dart';
import '../player/presentation/providers/fakes.dart';

class _MockSearchHistoryController extends Mock
    implements SearchHistoryController {}

class _ControlledSearchApi extends Fake implements ApiService {
  final List<String> queries = [];
  final List<Completer<List<dynamic>>> pending = [];

  Future<List<dynamic>> _hold(String query) {
    queries.add(query);
    final completer = Completer<List<dynamic>>();
    pending.add(completer);
    return completer.future;
  }

  @override
  Future<List<Track>> search(
    String query, {
    String source = 'youtube',
    int limit = 20,
  }) async {
    final results = await _hold(query);
    return results.cast<Track>();
  }

  @override
  Future<List<dynamic>> searchArtistsOrAlbums(
    String query,
    String filter, {
    String source = 'youtube',
    int limit = 20,
  }) {
    return _hold(query);
  }

  void completeLast(List<dynamic> results) {
    pending.last.complete(results);
  }

  void failLast(Object error) {
    pending.last.completeError(error);
  }
}

const _firstTrack = Track(
  sourceId: 'yt-first',
  title: 'First Song',
  artist: 'First Artist',
  durationMs: 200000,
  source: TrackSource.youtube,
);

const _secondTrack = Track(
  sourceId: 'yt-second',
  title: 'Second Song',
  artist: 'Second Artist',
  durationMs: 180000,
  source: TrackSource.youtube,
);

Future<ProviderContainer> _pumpSearchScreen(
  WidgetTester tester,
  _ControlledSearchApi api,
) async {
  final historyController = _MockSearchHistoryController();
  when(() => historyController.addHistory(any())).thenAnswer((_) async {});
  when(() => historyController.deleteHistory(any())).thenAnswer((_) async {});
  when(() => historyController.clearHistory()).thenAnswer((_) async {});

  final container = ProviderContainer(
    overrides: [
      connectivityProvider.overrideWith((ref) => Stream.value(true)),
      apiServiceProvider.overrideWithValue(api),
      searchHistoryProvider.overrideWith(
        (ref) => Stream.value(const <SearchHistoryModel>[]),
      ),
      searchHistoryControllerProvider.overrideWith(
        (ref) => historyController,
      ),
      appSettingsProvider.overrideWith(
        (ref) => Stream.value(AppSettingsModel()),
      ),
      audioPlayerServiceProvider.overrideWithValue(FakeAudioPlayerService()),
      trackRepositoryProvider.overrideWithValue(FakeTrackRepository()),
      cacheDownloadServiceProvider.overrideWithValue(
        FakeCacheDownloadService(),
      ),
    ],
  );
  addTearDown(container.dispose);

  await pumpApp(
    tester,
    UncontrolledProviderScope(
      container: container,
      child: const SearchScreen(),
    ),
  );
  return container;
}

ProviderContainer _createContainer(_ControlledSearchApi api) {
  final historyController = _MockSearchHistoryController();
  when(() => historyController.addHistory(any())).thenAnswer((_) async {});

  final container = ProviderContainer(
    overrides: [
      apiServiceProvider.overrideWithValue(api),
      searchHistoryControllerProvider.overrideWith(
        (ref) => historyController,
      ),
    ],
  );
  addTearDown(container.dispose);

  final subscription = container.listen(searchStateProvider, (_, __) {});
  addTearDown(subscription.close);
  return container;
}

void main() {
  group('searchStateProvider', () {
    test('an empty query is idle and never calls the API', () {
      final api = _ControlledSearchApi();
      final container = _createContainer(api);

      expect(container.read(searchStateProvider), isA<SearchIdle>());
      expect(api.queries, isEmpty);
    });

    test('an in-flight request is loading, then empty only after success',
        () async {
      final api = _ControlledSearchApi();
      final container = _createContainer(api);

      container.read(searchQueryProvider.notifier).state = 'nothing';
      expect(container.read(searchStateProvider), isA<SearchLoading>());
      expect(api.pending, hasLength(1));

      api.completeLast(const []);
      await container.read(searchResultsProvider.future);

      final state = container.read(searchStateProvider);
      expect(state, isA<SearchEmpty>());
      expect((state as SearchEmpty).query, 'nothing');
    });

    test('a stale response is ignored after the query changes', () async {
      final api = _ControlledSearchApi();
      final container = _createContainer(api);
      container.read(searchFilterProvider.notifier).state = 'songs';

      container.read(searchQueryProvider.notifier).state = 'first';
      final firstFuture = container.read(searchResultsProvider.future);
      container.read(searchQueryProvider.notifier).state = 'second';
      final secondFuture = container.read(searchResultsProvider.future);
      expect(api.pending, hasLength(2));

      api.pending[1].complete(const [_secondTrack]);
      await secondFuture;
      final second = container.read(searchStateProvider);
      expect(second, isA<SearchData>());
      expect(
        (second as SearchData).items.cast<Track>().single.title,
        'Second Song',
      );

      api.pending[0].complete(const [_firstTrack]);
      await firstFuture;

      final state = container.read(searchStateProvider);
      expect(state, isA<SearchData>());
      expect(
        (state as SearchData).items.cast<Track>().single.title,
        'Second Song',
      );
    });

    test('a failed request becomes an error carrying the query', () async {
      final api = _ControlledSearchApi();
      final container = _createContainer(api);

      container.read(searchQueryProvider.notifier).state = 'daft punk';
      expect(container.read(searchStateProvider), isA<SearchLoading>());
      api.failLast(StateError('boom'));
      await expectLater(
        container.read(searchResultsProvider.future),
        throwsA(isA<StateError>()),
      );

      final state = container.read(searchStateProvider);
      expect(state, isA<SearchError>());
      expect((state as SearchError).query, 'daft punk');
      expect(state.error, isA<StateError>());
    });
  });

  testWidgets('an empty query shows idle content, never the empty panel',
      (tester) async {
    final api = _ControlledSearchApi();
    await _pumpSearchScreen(tester, api);
    await tester.pumpAndSettle();

    expect(find.text('What do you want to listen to?'), findsOneWidget);
    expect(find.text('No results found'), findsNothing);
    expect(api.queries, isEmpty);
  });

  testWidgets('a new query shows loading instead of the previous empty state',
      (tester) async {
    final api = _ControlledSearchApi();
    final container = await _pumpSearchScreen(tester, api);

    container.read(searchQueryProvider.notifier).state = 'first';
    await tester.pump();
    api.completeLast(const []);
    await tester.pumpAndSettle();
    expect(find.text('No results found'), findsOneWidget);

    container.read(searchQueryProvider.notifier).state = 'second';
    await tester.pump();

    expect(find.text('No results found'), findsNothing);
    expect(find.byType(ShimmerSection), findsOneWidget);
  });

  testWidgets('previous results disappear while a new query is loading',
      (tester) async {
    final api = _ControlledSearchApi();
    final container = await _pumpSearchScreen(tester, api);
    container.read(searchFilterProvider.notifier).state = 'songs';

    container.read(searchQueryProvider.notifier).state = 'first';
    await tester.pump();
    api.completeLast(const [_firstTrack]);
    await tester.pumpAndSettle();
    expect(find.text('First Song'), findsOneWidget);

    container.read(searchQueryProvider.notifier).state = 'second';
    await tester.pump();

    expect(find.text('First Song'), findsNothing);
    expect(find.byType(ShimmerSection), findsOneWidget);

    api.completeLast(const [_secondTrack]);
    await tester.pumpAndSettle();
    expect(find.text('Second Song'), findsOneWidget);
    expect(find.text('First Song'), findsNothing);
  });

  testWidgets('changing filter hides results from the previous filter',
      (tester) async {
    final api = _ControlledSearchApi();
    final container = await _pumpSearchScreen(tester, api);
    container.read(searchFilterProvider.notifier).state = 'songs';

    container.read(searchQueryProvider.notifier).state = 'daft punk';
    await tester.pump();
    api.completeLast(const [_firstTrack]);
    await tester.pumpAndSettle();
    expect(find.text('First Song'), findsOneWidget);

    container.read(searchFilterProvider.notifier).state = 'artists';
    await tester.pump();

    expect(find.text('First Song'), findsNothing);
    expect(find.byType(ShimmerSection), findsOneWidget);
  });

  testWidgets('a successful empty response is the only empty state',
      (tester) async {
    final api = _ControlledSearchApi();
    final container = await _pumpSearchScreen(tester, api);

    container.read(searchQueryProvider.notifier).state = 'nothing';
    await tester.pump();
    expect(find.text('No results found'), findsNothing);

    api.completeLast(const []);
    await tester.pumpAndSettle();

    expect(find.text('No results found'), findsOneWidget);
    expect(find.textContaining('"nothing"'), findsOneWidget);
  });

  testWidgets('error shows human copy, a safe code, and retry keeps the query',
      (tester) async {
    final api = _ControlledSearchApi();
    final container = await _pumpSearchScreen(tester, api);

    container.read(searchQueryProvider.notifier).state = 'daft punk';
    await tester.pump();
    api.failLast(StateError('boom-raw-secret'));
    await tester.pumpAndSettle();

    expect(find.text('No results found'), findsNothing);
    expect(
      find.text('Check your connection and try again.'),
      findsOneWidget,
    );
    expect(find.text('ERR-APP-01'), findsOneWidget);
    expect(find.textContaining('boom-raw-secret'), findsNothing);

    await tester.tap(find.widgetWithText(FilledButton, 'Retry'));
    await tester.pump();

    expect(container.read(searchQueryProvider), 'daft punk');
    expect(api.queries, ['daft punk', 'daft punk']);
    expect(find.byType(ShimmerSection), findsOneWidget);

    api.completeLast(const []);
    await tester.pumpAndSettle();
    expect(find.text('No results found'), findsOneWidget);
  });
}
