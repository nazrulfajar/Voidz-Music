import 'package:dartz/dartz.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:my_music_player/core/constants/enums.dart';
import 'package:my_music_player/core/errors/failures.dart';
import 'package:my_music_player/core/network/api_service.dart';
import 'package:my_music_player/features/home/domain/entities/daily_mix.dart';
import 'package:my_music_player/features/home/presentation/providers/mood_mix_provider.dart';
import 'package:my_music_player/features/player/data/repositories/track_repository_impl.dart';
import 'package:my_music_player/features/player/domain/entities/track.dart';
import 'package:my_music_player/features/player/domain/repositories/track_repository.dart';

class _MockApiService extends Mock implements ApiService {}

class _MockTrackRepository extends Mock implements TrackRepository {}

Track _track({
  String sourceId = 't1',
  String title = 'Alpha',
  String? thumbnailUrl,
}) {
  return Track(
    sourceId: sourceId,
    title: title,
    artist: 'Artist',
    durationMs: 200000,
    thumbnailUrl: thumbnailUrl,
    source: TrackSource.youtube,
  );
}

void main() {
  late _MockApiService api;
  late _MockTrackRepository repository;
  late ProviderContainer container;

  setUp(() {
    api = _MockApiService();
    repository = _MockTrackRepository();
    container = ProviderContainer(
      overrides: [
        apiServiceProvider.overrideWithValue(api),
        trackRepositoryProvider.overrideWithValue(repository),
      ],
    );
    addTearDown(container.dispose);
  });

  group('DailyMixMood', () {
    test('has exactly the five product moods with labels', () {
      expect(
        DailyMixMood.values.map((mood) => mood.name).toList(),
        ['energize', 'workout', 'relax', 'commute', 'focus'],
      );
      expect(
        DailyMixMood.values.map((mood) => mood.label).toList(),
        ['Energize', 'Workout', 'Relax', 'Commute', 'Focus'],
      );
    });
  });

  group('moodMixProvider', () {
    test('searches the mood label and keeps at most four artworks', () async {
      final tracks = [
        _track(sourceId: 't1', thumbnailUrl: 'https://img/1'),
        _track(sourceId: 't2', thumbnailUrl: 'https://img/2'),
        _track(sourceId: 't3', thumbnailUrl: 'https://img/3'),
        _track(sourceId: 't4', thumbnailUrl: 'https://img/4'),
        _track(sourceId: 't5', thumbnailUrl: 'https://img/5'),
        _track(sourceId: 't6'),
      ];
      when(() => api.search(any(), limit: any(named: 'limit')))
          .thenAnswer((_) async => tracks);

      final mix = await container.read(
        moodMixProvider(DailyMixMood.energize).future,
      );

      expect(mix.mood, DailyMixMood.energize);
      expect(mix.tracks, hasLength(6));
      expect(
        mix.artworkUrls,
        ['https://img/1', 'https://img/2', 'https://img/3', 'https://img/4'],
      );
      verify(() => api.search('Energize', limit: 8)).called(1);
      verifyNever(
          () => repository.getQuickPicksTracks(limit: any(named: 'limit')));
    });

    test('falls back to local quick picks when search throws', () async {
      final fallback = [_track(sourceId: 'local', thumbnailUrl: 'local-art')];
      when(() => api.search(any(), limit: any(named: 'limit')))
          .thenThrow(Exception('offline'));
      when(() => repository.getQuickPicksTracks(limit: any(named: 'limit')))
          .thenAnswer((_) async => Right(fallback));

      final mix = await container.read(
        moodMixProvider(DailyMixMood.relax).future,
      );

      expect(mix.tracks, fallback);
      expect(mix.artworkUrls, ['local-art']);
      verify(() => repository.getQuickPicksTracks(limit: 8)).called(1);
    });

    test('falls back when search returns no tracks', () async {
      final fallback = [_track(sourceId: 'local')];
      when(() => api.search(any(), limit: any(named: 'limit')))
          .thenAnswer((_) async => const []);
      when(() => repository.getQuickPicksTracks(limit: any(named: 'limit')))
          .thenAnswer((_) async => Right(fallback));

      final mix = await container.read(
        moodMixProvider(DailyMixMood.commute).future,
      );

      expect(mix.tracks, fallback);
      verify(() => repository.getQuickPicksTracks(limit: 8)).called(1);
    });

    test('returns an empty mix when search and fallback are empty', () async {
      when(() => api.search(any(), limit: any(named: 'limit')))
          .thenAnswer((_) async => const []);
      when(() => repository.getQuickPicksTracks(limit: any(named: 'limit')))
          .thenAnswer((_) async => const Right([]));

      final mix = await container.read(
        moodMixProvider(DailyMixMood.focus).future,
      );

      expect(mix.isEmpty, isTrue);
      expect(mix.tracks, isEmpty);
      expect(mix.artworkUrls, isEmpty);
    });

    test('returns an empty mix when the local fallback fails', () async {
      when(() => api.search(any(), limit: any(named: 'limit')))
          .thenThrow(Exception('offline'));
      when(() => repository.getQuickPicksTracks(limit: any(named: 'limit')))
          .thenAnswer((_) async => const Left(CacheFailure('no cache')));

      final mix = await container.read(
        moodMixProvider(DailyMixMood.workout).future,
      );

      expect(mix.isEmpty, isTrue);
    });
  });
}
