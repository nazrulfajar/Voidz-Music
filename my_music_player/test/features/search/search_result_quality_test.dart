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

import '../../helpers/pump_app.dart';
import '../player/presentation/providers/fakes.dart';

class _MockSearchHistoryController extends Mock
    implements SearchHistoryController {}

const _trackWithoutDuration = Track(
  sourceId: 'yt-unknown-duration',
  title: 'Unknown Length',
  artist: 'Some Artist',
  durationMs: 0,
  source: TrackSource.youtube,
);

const _longTrack = Track(
  sourceId: 'yt-long',
  title: 'Long Song',
  artist: 'Long Artist',
  durationMs: 3723000,
  source: TrackSource.youtube,
);

const _songMap = <String, dynamic>{
  'result_type': 'song',
  'source_id': 'yt-one-more-time',
  'title': 'One More Time',
  'artist': 'Daft Punk',
  'duration_ms': 200000,
  'source': 'youtube',
};

const _albumMap = <String, dynamic>{
  'result_type': 'album',
  'browse_id': 'album-discovery',
  'title': 'Discovery',
  'artist': 'Daft Punk',
  'year': '2001',
};

const _artistMap = <String, dynamic>{
  'result_type': 'artist',
  'browse_id': 'artist-daft-punk',
  'name': 'Daft Punk',
  'subscribers': '10M subscribers',
};

Future<ProviderContainer> _pumpSearch(
  WidgetTester tester, {
  required List<dynamic> results,
  String query = 'daft punk',
  String filter = 'top',
  double textScale = 1.0,
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
      child: const SearchScreen(),
    ),
    textScale: textScale,
  );
  await tester.pumpAndSettle();
  return container;
}

void main() {
  testWidgets('unknown duration renders a dash instead of 0:00',
      (tester) async {
    await _pumpSearch(
      tester,
      filter: 'songs',
      results: [_trackWithoutDuration],
    );

    expect(find.text('—'), findsOneWidget);
    expect(find.text('0:00'), findsNothing);
  });

  testWidgets('valid durations render m:ss and h:mm:ss', (tester) async {
    await _pumpSearch(
      tester,
      filter: 'songs',
      results: [_trackWithoutDuration, _longTrack],
    );

    expect(find.text('1:02:03'), findsOneWidget);
    expect(find.text('62:03'), findsNothing);
  });

  testWidgets('top results report result count and readable type labels',
      (tester) async {
    final semantics = tester.ensureSemantics();
    try {
      await _pumpSearch(
        tester,
        results: [_songMap, _albumMap, _artistMap],
      );

      expect(find.text('3 results'), findsOneWidget);
      expect(find.text('3 tracks'), findsNothing);
      expect(find.text('Album • Daft Punk • 2001'), findsOneWidget);
      expect(find.text('Artist • 10M subscribers'), findsOneWidget);

      final album = find.bySemanticsLabel(
        'Album, Discovery, by Daft Punk',
      );
      final artist = find.bySemanticsLabel('Artist, Daft Punk');
      final track = find.bySemanticsLabel(
        'Track, One More Time, by Daft Punk',
      );

      expect(album, findsOneWidget);
      expect(artist, findsOneWidget);
      expect(track, findsOneWidget);

      for (final row in [album, artist, track]) {
        expect(tester.getSize(row).height, greaterThanOrEqualTo(48));
      }
    } finally {
      semantics.dispose();
    }
  });

  testWidgets('songs filter reports song count', (tester) async {
    await _pumpSearch(
      tester,
      filter: 'songs',
      results: [_trackWithoutDuration, _longTrack],
    );

    expect(find.text('2 songs'), findsOneWidget);
    expect(find.text('2 tracks'), findsNothing);
  });

  testWidgets('mixed top results survive text scale 2.0 without overflow',
      (tester) async {
    await _pumpSearch(
      tester,
      results: [_songMap, _albumMap, _artistMap],
      textScale: 2.0,
    );

    expect(find.text('One More Time'), findsOneWidget);
    expect(find.text('Discovery'), findsOneWidget);
    expect(find.text('Daft Punk'), findsNWidgets(2));
    expect(tester.takeException(), isNull);
  });
}
