import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:mocktail/mocktail.dart';
import 'package:my_music_player/core/network/api_service.dart';
import 'package:my_music_player/core/providers/connectivity_provider.dart';
import 'package:my_music_player/features/cache/data/datasources/cache_download_service.dart';
import 'package:my_music_player/features/player/data/datasources/audio_player_service.dart';
import 'package:my_music_player/features/player/data/repositories/track_repository_impl.dart';
import 'package:my_music_player/features/search/data/models/search_history_model.dart';
import 'package:my_music_player/features/search/presentation/providers/search_provider.dart';
import 'package:my_music_player/features/search/presentation/screens/search_screen.dart';
import 'package:my_music_player/features/settings/data/models/app_settings_model.dart';
import 'package:my_music_player/features/settings/presentation/providers/settings_provider.dart';

import '../../helpers/pump_app.dart';
import '../player/presentation/providers/fakes.dart';

class _MockSearchHistoryController extends Mock
    implements SearchHistoryController {}

class _RouteStub extends StatelessWidget {
  const _RouteStub(this.label);

  final String label;

  @override
  Widget build(BuildContext context) {
    return Scaffold(body: Center(child: Text(label)));
  }
}

void main() {
  testWidgets('search idle exposes a browse card that opens the hub',
      (tester) async {
    final historyController = _MockSearchHistoryController();
    when(() => historyController.deleteHistory(any())).thenAnswer((_) async {});
    when(() => historyController.clearHistory()).thenAnswer((_) async {});

    final router = GoRouter(
      initialLocation: '/search',
      routes: [
        GoRoute(
          path: '/search',
          builder: (context, state) => const SearchScreen(),
          routes: [
            GoRoute(
              path: 'browse',
              builder: (context, state) => const _RouteStub('browse-route'),
            ),
          ],
        ),
      ],
    );
    addTearDown(router.dispose);

    final container = ProviderContainer(
      overrides: [
        connectivityProvider.overrideWith((ref) => Stream.value(true)),
        searchQueryProvider.overrideWith((ref) => ''),
        searchFilterProvider.overrideWith((ref) => 'top'),
        searchResultsProvider.overrideWith((ref) async => const []),
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
        apiServiceProvider.overrideWithValue(FakeApiService()),
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
        child: MaterialApp.router(routerConfig: router),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('What do you want to listen to?'), findsOneWidget);
    expect(find.text('Browse by source'), findsOneWidget);
    expect(find.text('Browse sources'), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('search-browse-entry')));
    await tester.pumpAndSettle();

    expect(find.text('browse-route'), findsOneWidget);
  });
}
