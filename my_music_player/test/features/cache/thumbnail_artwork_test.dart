import 'dart:io';

import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:my_music_player/core/constants/enums.dart';
import 'package:my_music_player/core/errors/failures.dart';
import 'package:my_music_player/core/utils/artwork_url.dart';
import 'package:my_music_player/features/cache/data/datasources/thumbnail_artwork_store.dart';
import 'package:my_music_player/features/cache/data/datasources/thumbnail_upgrade_service.dart';
import 'package:my_music_player/features/player/domain/entities/track.dart';
import 'package:my_music_player/features/player/domain/repositories/track_repository.dart';

class _MockTrackRepository extends Mock implements TrackRepository {}

const _youtubeSquare =
    'https://yt3.googleusercontent.com/cover=w120-h120-l90-rj';
const _youtubeLarge =
    'https://yt3.googleusercontent.com/cover=w2048-h2048-l90-rj';

Track _cachedTrack({
  String sourceId = 'track-1',
  String? thumbnailUrl = _youtubeSquare,
  String? localThumbnailPath,
  String? localAudioPath,
  bool isCached = true,
  TrackSource source = TrackSource.youtube,
  int? fileSizeBytes,
}) {
  return Track(
    sourceId: sourceId,
    title: sourceId,
    artist: 'Artist',
    durationMs: 180000,
    thumbnailUrl: thumbnailUrl,
    localThumbnailPath: localThumbnailPath,
    localAudioPath: localAudioPath,
    isCached: isCached,
    fileSizeBytes: fileSizeBytes,
    source: source,
  );
}

String _path(Directory directory, String name) =>
    '${directory.path}${Platform.pathSeparator}$name';

Future<Directory> _tempDir() async {
  final directory =
      await Directory.systemTemp.createTemp('voidz-thumbnail-test-');
  addTearDown(() async {
    if (await directory.exists()) {
      await directory.delete(recursive: true);
    }
  });
  return directory;
}

ThumbnailDownloader _writingDownloader(
  List<String> requestedUrls, {
  int bytes = 2048,
}) {
  return (url, path) async {
    requestedUrls.add(url);
    await File(path).writeAsBytes(List<int>.filled(bytes, 7), flush: true);
  };
}

Iterable<String> _partialFiles(Directory directory) =>
    directory.listSync().map((entry) => entry.path).where(
          (path) => path.endsWith('.part'),
        );

void main() {
  group('youtubeArtworkUrl', () {
    test('requests the capped cache width for a small YouTube thumbnail', () {
      expect(maxCachedArtworkWidth, 1024);
      expect(
        youtubeArtworkUrl(_youtubeSquare, maxCachedArtworkWidth),
        'https://yt3.googleusercontent.com/cover=w1024-h1024-l90-rj',
      );
    });

    test('never upscales a source that is already larger than the request', () {
      expect(youtubeArtworkUrl(_youtubeLarge, maxCachedArtworkWidth),
          _youtubeLarge);
    });

    test('leaves non-YouTube, insecure and non-square URLs unchanged', () {
      const urls = [
        'https://example.com/cover=w120-h120-l90-rj',
        'https://yt3.googleusercontent.com.evil.example/cover=w120-h120-l90-rj',
        'http://yt3.googleusercontent.com/cover=w120-h120-l90-rj',
        'https://yt3.googleusercontent.com/cover=w120-h90-l90-rj',
        'https://user@yt3.googleusercontent.com/cover=w120-h120-l90-rj',
        'https://yt3.googleusercontent.com:8443/cover=w120-h120-l90-rj',
        'https://yt3.googleusercontent.com/cover?size=w120-h120-l90-rj',
      ];
      for (final url in urls) {
        expect(youtubeArtworkUrl(url, maxCachedArtworkWidth), url);
      }
    });

    test('leaves a URL with conflicting size options unchanged', () {
      const url = 'https://yt3.googleusercontent.com/'
          'cover=w120-h120-w2048-h2048-l90-rj';
      expect(youtubeArtworkUrl(url, maxCachedArtworkWidth), url);
    });
  });

  group('ThumbnailArtworkStore', () {
    test('writes a width-tagged file atomically and requests the large URL',
        () async {
      final directory = await _tempDir();
      final requestedUrls = <String>[];
      final store = ThumbnailArtworkStore(
        cacheDirectory: () async => directory,
        downloader: _writingDownloader(requestedUrls),
      );

      final path = await store.storeThumbnail(
        sourceId: 'abc',
        thumbnailUrl: _youtubeSquare,
        width: maxCachedArtworkWidth,
      );

      expect(path, isNotNull);
      expect(path, endsWith('abc_thumb_w1024.jpg'));
      expect(
        requestedUrls.single,
        'https://yt3.googleusercontent.com/cover=w1024-h1024-l90-rj',
      );
      expect(await File(path!).length(), 2048);
      expect(_partialFiles(directory), isEmpty);
    });

    test('reuses a valid width-tagged file without downloading again',
        () async {
      final directory = await _tempDir();
      final existing = File(
        '${directory.path}${Platform.pathSeparator}abc_thumb_w1024.jpg',
      );
      await existing.writeAsBytes(List<int>.filled(2048, 1), flush: true);
      var downloads = 0;
      final store = ThumbnailArtworkStore(
        cacheDirectory: () async => directory,
        downloader: (url, path) async => downloads++,
      );

      final path = await store.storeThumbnail(
        sourceId: 'abc',
        thumbnailUrl: _youtubeSquare,
        width: maxCachedArtworkWidth,
      );

      expect(path, existing.path);
      expect(downloads, 0);
    });

    test('keeps the old thumbnail and cleans up when the download fails',
        () async {
      final directory = await _tempDir();
      final oldThumbnail = File('${directory.path}/abc_thumb.jpg');
      await oldThumbnail.writeAsBytes(List<int>.filled(2048, 1), flush: true);
      final store = ThumbnailArtworkStore(
        cacheDirectory: () async => directory,
        downloader: (url, path) async => throw Exception('offline'),
      );

      final path = await store.storeThumbnail(
        sourceId: 'abc',
        thumbnailUrl: _youtubeSquare,
        width: maxCachedArtworkWidth,
      );

      expect(path, isNull);
      expect(await oldThumbnail.exists(), isTrue);
      expect(await oldThumbnail.length(), 2048);
      expect(_partialFiles(directory), isEmpty);
    });

    test('rejects a truncated download without publishing it', () async {
      final directory = await _tempDir();
      final store = ThumbnailArtworkStore(
        cacheDirectory: () async => directory,
        downloader: _writingDownloader([], bytes: 12),
      );

      final path = await store.storeThumbnail(
        sourceId: 'abc',
        thumbnailUrl: _youtubeSquare,
        width: maxCachedArtworkWidth,
      );

      expect(path, isNull);
      expect(
        File(
          '${directory.path}${Platform.pathSeparator}abc_thumb_w1024.jpg',
        ).existsSync(),
        isFalse,
      );
      expect(_partialFiles(directory), isEmpty);
    });
  });

  group('ThumbnailUpgradeService', () {
    late _MockTrackRepository repository;
    late Directory cacheDir;

    setUpAll(() {
      registerFallbackValue(_cachedTrack());
    });

    setUp(() async {
      repository = _MockTrackRepository();
      cacheDir = await _tempDir();
    });

    ThumbnailUpgradeService buildService({
      required List<Track> cachedTracks,
      bool online = true,
      int maxPerSession = 3,
      ThumbnailDownloader? downloader,
    }) {
      when(() => repository.getAllCachedTracks())
          .thenAnswer((_) async => Right(cachedTracks));
      when(() => repository.updateTrack(any()))
          .thenAnswer((_) async => const Right<Failure, void>(null));
      return ThumbnailUpgradeService(
        trackRepository: repository,
        store: ThumbnailArtworkStore(
          cacheDirectory: () async => cacheDir,
          downloader: downloader ??
              (url, path) async {
                await File(path).writeAsBytes(
                  List<int>.filled(2048, 7),
                  flush: true,
                );
              },
        ),
        isOnline: () async => online,
        maxPerSession: maxPerSession,
      );
    }

    test('does nothing while offline', () async {
      final service =
          buildService(cachedTracks: [_cachedTrack()], online: false);

      expect(await service.upgradeLegacyThumbnails(), 0);
      verifyNever(() => repository.getAllCachedTracks());
      verifyNever(() => repository.updateTrack(any()));
    });

    test('refreshes at most maxPerSession entries once per session', () async {
      var downloads = 0;
      final tracks = [
        for (var index = 0; index < 5; index++)
          _cachedTrack(
            sourceId: 'track-$index',
            localThumbnailPath: _path(cacheDir, 'track-${index}_thumb.jpg'),
          ),
      ];
      final service = buildService(
        cachedTracks: tracks,
        downloader: (url, path) async {
          downloads++;
          await File(path).writeAsBytes(List<int>.filled(2048, 7));
        },
      );

      expect(await service.upgradeLegacyThumbnails(), 3);
      expect(downloads, 3);
      verify(() => repository.updateTrack(any())).called(3);

      clearInteractions(repository);
      expect(await service.upgradeLegacyThumbnails(), 0);
      expect(downloads, 3);
      verifyNever(() => repository.getAllCachedTracks());
    });

    test('keeps the old path when the refresh fails', () async {
      final oldThumbnail = File(_path(cacheDir, 'track-1_thumb.jpg'));
      await oldThumbnail.writeAsBytes(List<int>.filled(2048, 1));
      final service = buildService(
        cachedTracks: [_cachedTrack(localThumbnailPath: oldThumbnail.path)],
        downloader: (url, path) async => throw Exception('offline'),
      );

      expect(await service.upgradeLegacyThumbnails(), 0);
      verifyNever(() => repository.updateTrack(any()));
      expect(await oldThumbnail.exists(), isTrue);
    });

    test('keeps the old path when the database update fails', () async {
      final oldThumbnail = File(_path(cacheDir, 'track-1_thumb.jpg'));
      await oldThumbnail.writeAsBytes(List<int>.filled(2048, 1));
      final service = buildService(
        cachedTracks: [_cachedTrack(localThumbnailPath: oldThumbnail.path)],
      );
      when(() => repository.updateTrack(any())).thenAnswer(
        (_) async => const Left<Failure, void>(CacheFailure('write failed')),
      );

      expect(await service.upgradeLegacyThumbnails(), 0);
      expect(await oldThumbnail.exists(), isTrue);
    });

    test('updates only the thumbnail path after a successful refresh',
        () async {
      final audio = File(_path(cacheDir, 'track-1_opus.webm'));
      await audio.writeAsBytes(List<int>.filled(4096, 4));
      final oldThumbnail = File(_path(cacheDir, 'track-1_thumb.jpg'));
      await oldThumbnail.writeAsBytes(List<int>.filled(2048, 1));
      Track? persisted;
      final service = buildService(
        cachedTracks: [
          _cachedTrack(
            localThumbnailPath: oldThumbnail.path,
            localAudioPath: audio.path,
            fileSizeBytes: 4096,
          ),
        ],
      );
      when(() => repository.updateTrack(any())).thenAnswer((invocation) async {
        persisted = invocation.positionalArguments.first as Track;
        return const Right<Failure, void>(null);
      });

      expect(await service.upgradeLegacyThumbnails(), 1);

      expect(persisted, isNotNull);
      expect(
        persisted!.localThumbnailPath,
        endsWith('track-1_thumb_w1024.jpg'),
      );
      expect(persisted!.localAudioPath, audio.path);
      expect(persisted!.isCached, isTrue);
      expect(persisted!.fileSizeBytes, 4096);
      expect(await audio.exists(), isTrue);
      expect(await oldThumbnail.exists(), isFalse);
    });

    test('refreshes legacy or broken files and keeps current ones', () async {
      final current = File(_path(cacheDir, 'current_thumb_w1024.jpg'));
      await current.writeAsBytes(List<int>.filled(2048, 5));
      final legacy = File(_path(cacheDir, 'legacy_thumb.jpg'));
      await legacy.writeAsBytes(List<int>.filled(2048, 5));
      final broken = File(_path(cacheDir, 'broken_thumb_w1024.jpg'));
      await broken.writeAsBytes(List<int>.filled(100, 5));
      final downloadedPaths = <String>[];
      final service = buildService(
        cachedTracks: [
          _cachedTrack(sourceId: 'current', localThumbnailPath: current.path),
          _cachedTrack(sourceId: 'legacy', localThumbnailPath: legacy.path),
          _cachedTrack(sourceId: 'broken', localThumbnailPath: broken.path),
          _cachedTrack(
            sourceId: 'missing',
            localThumbnailPath: _path(cacheDir, 'missing_thumb_w1024.jpg'),
          ),
          _cachedTrack(sourceId: 'not-cached', isCached: false),
          _cachedTrack(
            sourceId: 'local',
            source: TrackSource.local,
            localThumbnailPath: _path(cacheDir, 'local_thumb.jpg'),
          ),
          _cachedTrack(sourceId: 'no-url', thumbnailUrl: null),
        ],
        maxPerSession: 4,
        downloader: (url, path) async {
          downloadedPaths.add(path);
          await File(path).writeAsBytes(List<int>.filled(2048, 7));
        },
      );

      expect(await service.upgradeLegacyThumbnails(), 3);
      expect(downloadedPaths, hasLength(3));
      expect(
        downloadedPaths.any((path) => path.contains('current_thumb')),
        isFalse,
      );
      verify(() => repository.updateTrack(any())).called(3);
      expect(await current.exists(), isTrue);
    });
  });
}
