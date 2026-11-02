import 'dart:convert';
import 'dart:ffi';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:isar/isar.dart';
import 'package:my_music_player/core/constants/enums.dart';
import 'package:my_music_player/features/library/data/models/play_history_model.dart';
import 'package:my_music_player/features/library/data/repositories/playlist_repository_impl.dart';
import 'package:my_music_player/features/player/data/models/track_model.dart';

Directory _packageRoot(String name) {
  final config = File('.dart_tool/package_config.json');
  final json = jsonDecode(config.readAsStringSync()) as Map<String, dynamic>;
  final packages =
      (json['packages'] as List<dynamic>).cast<Map<String, dynamic>>();
  for (final entry in packages) {
    if (entry['name'] != name) continue;
    final uri = entry['rootUri'] as String;
    if (uri.startsWith('file://')) return Directory.fromUri(Uri.parse(uri));
    return Directory(
      '${config.parent.parent.path}${Platform.pathSeparator}$uri',
    );
  }
  throw StateError('package $name not found');
}

String _isarLibraryPath() {
  final root = _packageRoot('isar_flutter_libs');
  final relative = switch (Platform.operatingSystem) {
    'windows' => ['windows', 'isar.dll'],
    'linux' => ['linux', 'libisar.so'],
    'macos' => ['macos', 'libisar.dylib'],
    _ => throw UnsupportedError(
        'Isar test library missing for ${Platform.operatingSystem}',
      ),
  };
  return [root.path, ...relative].join(Platform.pathSeparator);
}

void main() {
  final now = DateTime(2026, 11, 2, 12);
  var instance = 0;
  late Directory directory;
  late Isar isar;
  late PlaylistRepositoryImpl repository;

  setUpAll(() async {
    await Isar.initializeIsarCore(
      libraries: {Abi.current(): _isarLibraryPath()},
    );
  });

  setUp(() async {
    directory = await Directory.systemTemp.createTemp('recently_played_');
    isar = await Isar.open(
      [PlayHistoryModelSchema, TrackModelSchema],
      directory: directory.path,
      name: 'recent_${instance++}',
      maxSizeMiB: 64,
    );
    repository = PlaylistRepositoryImpl(isar);
  });

  tearDown(() async {
    await isar.close(deleteFromDisk: true);
    await directory.delete(recursive: true);
  });

  TrackModel track(
    String id, {
    int playCount = 0,
    DateTime? lastPlayedAt,
  }) {
    return TrackModel()
      ..sourceId = id
      ..title = 'Track $id'
      ..artist = 'Artist $id'
      ..durationMs = 200000
      ..source = TrackSource.youtube
      ..playCount = playCount
      ..lastPlayedAt = lastPlayedAt
      ..createdAt = now
      ..updatedAt = now;
  }

  Future<void> seedHistory(String id, DateTime playedAt) async {
    await isar.writeTxn(() async {
      await isar.playHistoryModels.put(
        PlayHistoryModel()
          ..trackSourceId = id
          ..playedAt = playedAt,
      );
    });
  }

  Future<List<String>> recentIds({
    int days = 30,
    int limit = 100,
  }) async {
    final tracks = await repository.getRecentlyPlayedTracks(
      days: days,
      limit: limit,
      now: now,
    );
    return tracks.map((track) => track.sourceId).toList();
  }

  test('returns distinct tracks inside the 30-day window, newest first',
      () async {
    await isar.writeTxn(() async {
      await isar.trackModels.putAll([
        track('a'),
        track('b'),
        track('c'),
      ]);
    });
    await seedHistory('a', now.subtract(const Duration(days: 2)));
    await seedHistory('a', now.subtract(const Duration(days: 1)));
    await seedHistory('b', now.subtract(const Duration(days: 31)));
    await seedHistory('c', now.subtract(const Duration(days: 5)));

    expect(await recentIds(), ['a', 'c']);
  });

  test('includes a play at exactly 30 days and excludes older plays', () async {
    await isar.writeTxn(() async {
      await isar.trackModels.putAll([
        track('boundary'),
        track('older'),
        track('recent'),
      ]);
    });
    await seedHistory('boundary', now.subtract(const Duration(days: 30)));
    await seedHistory(
      'older',
      now.subtract(const Duration(days: 30, microseconds: 1)),
    );
    await seedHistory('recent', now.subtract(const Duration(days: 29)));

    expect(await recentIds(), ['recent', 'boundary']);
  });

  test('honours the limit and the injected day window', () async {
    await isar.writeTxn(() async {
      await isar.trackModels.putAll([
        track('a'),
        track('b'),
        track('c'),
      ]);
    });
    await seedHistory('a', now.subtract(const Duration(days: 1)));
    await seedHistory('b', now.subtract(const Duration(days: 2)));
    await seedHistory('c', now.subtract(const Duration(days: 3)));

    expect(await recentIds(limit: 2), ['a', 'b']);
    expect(await recentIds(days: 1), ['a']);
  });

  test('counts distinct track ids inside the window', () async {
    await isar.writeTxn(() async {
      await isar.trackModels.putAll([
        track('a'),
        track('b'),
        track('c'),
      ]);
    });
    await seedHistory('a', now.subtract(const Duration(days: 1)));
    await seedHistory('a', now.subtract(const Duration(days: 2)));
    await seedHistory('b', now.subtract(const Duration(days: 20)));
    await seedHistory('c', now.subtract(const Duration(days: 40)));

    expect(await repository.getRecentlyPlayedCount(now: now), 2);
    expect(await repository.getRecentlyPlayedCount(days: 7, now: now), 1);
  });

  test('caps the list at 100 rows by default', () async {
    await isar.writeTxn(() async {
      await isar.trackModels.putAll([
        for (var i = 0; i < 101; i++) track('t$i'),
      ]);
      for (var i = 0; i < 101; i++) {
        await isar.playHistoryModels.put(
          PlayHistoryModel()
            ..trackSourceId = 't$i'
            ..playedAt = now.subtract(Duration(minutes: i + 1)),
        );
      }
    });

    final capped = await repository.getRecentlyPlayedTracks(now: now);

    expect(capped.length, 100);
    expect(capped.first.sourceId, 't0');
    expect(capped.last.sourceId, 't99');
  });

  test('clearPlayHistory deletes history and keeps playCount', () async {
    await isar.writeTxn(() async {
      await isar.trackModels.putAll([
        track(
          'a',
          playCount: 12,
          lastPlayedAt: now.subtract(const Duration(days: 1)),
        ),
        track('b', playCount: 3),
      ]);
    });
    await seedHistory('a', now.subtract(const Duration(days: 1)));
    await seedHistory('a', now.subtract(const Duration(days: 2)));
    await seedHistory('b', now.subtract(const Duration(days: 3)));

    await repository.clearPlayHistory();

    expect(await isar.playHistoryModels.count(), 0);
    final a = await isar.trackModels.filter().sourceIdEqualTo('a').findFirst();
    final b = await isar.trackModels.filter().sourceIdEqualTo('b').findFirst();
    expect(a!.lastPlayedAt, isNull);
    expect(a.playCount, 12);
    expect(b!.lastPlayedAt, isNull);
    expect(b.playCount, 3);
  });
}
