import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
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

Future<void> _pumpSearch(WidgetTester tester, Locale locale) async {
  final historyController = _MockSearchHistoryController();
  when(() => historyController.deleteHistory(any())).thenAnswer((_) async {});
  when(() => historyController.clearHistory()).thenAnswer((_) async {});

  await pumpApp(
    tester,
    ProviderScope(
      overrides: [
        connectivityProvider.overrideWith((ref) => Stream.value(true)),
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
      child: const SearchScreen(),
    ),
    locale: locale,
  );
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('search idle and filters follow the English locale',
      (tester) async {
    final semantics = tester.ensureSemantics();
    try {
      await _pumpSearch(tester, const Locale('en'));

      expect(find.text('What do you want to listen to?'), findsOneWidget);
      expect(find.text('Browse by source'), findsOneWidget);
      expect(find.bySemanticsLabel('Filter All'), findsOneWidget);
    } finally {
      semantics.dispose();
    }
  });

  testWidgets('search idle and filters follow the Indonesian locale',
      (tester) async {
    final semantics = tester.ensureSemantics();
    try {
      await _pumpSearch(tester, const Locale('id'));

      expect(find.text('Apa yang ingin kamu dengarkan?'), findsOneWidget);
      expect(find.text('Jelajahi berdasarkan sumber'), findsOneWidget);
      expect(find.bySemanticsLabel('Filter Semua'), findsOneWidget);
      expect(find.text('What do you want to listen to?'), findsNothing);
    } finally {
      semantics.dispose();
    }
  });
}
