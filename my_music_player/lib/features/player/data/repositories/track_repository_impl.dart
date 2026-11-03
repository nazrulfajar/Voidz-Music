import 'package:dartz/dartz.dart';
import 'package:isar/isar.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/errors/failures.dart';
import '../../../../core/constants/enums.dart';
import '../../domain/entities/track.dart';
import '../../domain/repositories/track_repository.dart';
import '../models/track_model.dart';
import '../datasources/local_audio_datasource.dart';

// Provider placeholder, requires Isar instance
final trackRepositoryProvider = Provider<TrackRepository>((ref) {
  throw UnimplementedError(
      'trackRepositoryProvider must be overridden with Isar instance');
});

class TrackRepositoryImpl implements TrackRepository {
  final Isar _isar;

  TrackRepositoryImpl(this._isar);

  @override
  Future<Either<Failure, void>> saveTrack(Track track) async {
    try {
      final trackModel = track.toModel();

      await _isar.writeTxn(() async {
        // Find existing to preserve ID if replacing
        final existing = await _isar.trackModels
            .where()
            .sourceIdSourceEqualTo(track.sourceId, track.source)
            .findFirst();

        if (existing != null) {
          trackModel.id = existing.id;
          trackModel.createdAt = existing.createdAt;
          trackModel.playCount = existing.playCount;
          trackModel.lastPlayedAt = existing.lastPlayedAt;
          trackModel.isLiked = existing.isLiked;
          // Do NOT preserve isCached — caller may explicitly clear it when file is missing or quality changed
        }

        await _isar.trackModels.put(trackModel);
      });
      return const Right(null);
    } catch (e) {
      return const Left(CacheFailure('Failed to save track: \$e'));
    }
  }

  @override
  Future<Either<Failure, void>> updateTrack(Track track) async {
    try {
      final trackModel = track.toModel();

      await _isar.writeTxn(() async {
        final existing = await _isar.trackModels
            .where()
            .sourceIdSourceEqualTo(track.sourceId, track.source)
            .findFirst();

        if (existing != null) {
          trackModel.id = existing.id;
          trackModel.createdAt = existing.createdAt;
          // We intentionally do NOT overwrite isLiked, isCached, playCount etc.
          // Because updateTrack is used when the caller wants to explicitly update these fields.
        }

        await _isar.trackModels.put(trackModel);
      });
      return const Right(null);
    } catch (e) {
      return Left(CacheFailure('Failed to update track: $e'));
    }
  }

  @override
  Future<Either<Failure, Track?>> getTrack(
      String sourceId, String source) async {
    try {
      final trackSource =
          TrackSource.values.firstWhere((e) => e.name == source);
      final model = await _isar.trackModels
          .where()
          .sourceIdSourceEqualTo(sourceId, trackSource)
          .findFirst();

      if (model != null) {
        return Right(Track.fromModel(model));
      }
      return const Right(null);
    } catch (e) {
      return const Left(CacheFailure('Failed to get track: \$e'));
    }
  }

  @override
  Future<Either<Failure, Track?>> getTrackBySourceId(String sourceId) async {
    try {
      final model = await _isar.trackModels
          .filter()
          .sourceIdEqualTo(sourceId)
          .findFirst();

      if (model != null) {
        return Right(Track.fromModel(model));
      }
      return const Right(null);
    } catch (e) {
      return const Left(CacheFailure('Failed to get track by source id: \$e'));
    }
  }

  @override
  Future<Either<Failure, List<Track>>> getAllCachedTracks() async {
    try {
      final models =
          await _isar.trackModels.where().isCachedEqualTo(true).findAll();
      // Exclude local device songs — they use same isCached flag but stored externally
      final filtered = models.where((m) => m.source != TrackSource.local).toList();
      return Right(filtered.map((m) => Track.fromModel(m)).toList());
    } catch (e) {
      return const Left(CacheFailure('Failed to get cached tracks: \$e'));
    }
  }

  /// Explicit downloaded-only (same as getAllCachedTracks but name makes intent clear)
  Future<Either<Failure, List<Track>>> getDownloadedTracks() => getAllCachedTracks();

  @override
  Future<Either<Failure, void>> updateTrackPlayCount(
      String sourceId, String source) async {
    try {
      final trackSource =
          TrackSource.values.firstWhere((e) => e.name == source);
      await _isar.writeTxn(() async {
        final model = await _isar.trackModels
            .where()
            .sourceIdSourceEqualTo(sourceId, trackSource)
            .findFirst();

        if (model != null) {
          model.playCount += 1;
          model.lastPlayedAt = DateTime.now();
          model.updatedAt = DateTime.now();
          await _isar.trackModels.put(model);
        }
      });
      return const Right(null);
    } catch (e) {
      return const Left(CacheFailure('Failed to update play count: \$e'));
    }
  }

  @override
  Future<Either<Failure, List<Track>>> getRecentlyPlayedTracks(
      {int limit = 10}) async {
    try {
      final models = await _isar.trackModels
          .where()
          .lastPlayedAtIsNotNull()
          .sortByLastPlayedAtDesc()
          .limit(limit)
          .findAll();

      return Right(models.map((m) => Track.fromModel(m)).toList());
    } catch (e) {
      return const Left(
          CacheFailure('Failed to get recently played tracks: \$e'));
    }
  }

  @override
  Future<Either<Failure, List<Track>>> getQuickPicksTracks(
      {int limit = 10}) async {
    try {
      // For quick picks, we show the most frequently played tracks
      final models = await _isar.trackModels
          .where()
          .anyId()
          .sortByPlayCountDesc()
          .limit(limit)
          .findAll();

      return Right(models.map((m) => Track.fromModel(m)).toList());
    } catch (e) {
      return const Left(CacheFailure('Failed to get quick picks tracks: \$e'));
    }
  }

  /// Premium: single OR query per chunk (50 ids) — jauh lebih cepat dari N sequential getTrackBySourceId
  @override
  Future<List<Track>> getTracksBySourceIds(List<String> sourceIds) async {
    if (sourceIds.isEmpty) return [];
    final result = <Track>[];
    // Chunk 80 ids per OR query to keep query size reasonable
    for (int i = 0; i < sourceIds.length; i += 80) {
      final chunk = sourceIds.sublist(i, (i + 80).clamp(0, sourceIds.length));
      if (chunk.isEmpty) continue;
      var q = _isar.trackModels.filter().sourceIdEqualTo(chunk[0]);
      for (int j = 1; j < chunk.length; j++) {
        q = q.or().sourceIdEqualTo(chunk[j]);
      }
      final models = await q.findAll();
      result.addAll(models.map((m) => Track.fromModel(m)));
    }
    return result;
  }

  @override
  Future<List<Track>> getDeviceTracks() async {
    final models = await _isar.trackModels
        .filter()
        .sourceEqualTo(TrackSource.local)
        .findAll();
    // Sort by title ASC for stable UI
    models.sort((a, b) => a.title.toLowerCase().compareTo(b.title.toLowerCase()));
    return models.map((m) => Track.fromModel(m)).toList();
  }

  @override
  Future<Either<Failure, List<Track>>> scanAndSyncLocalTracks() async {
    try {
      final ds = LocalAudioDataSource();
      final scanned = await ds.scanDeviceSongs();
      // Build map for quick lookup
      final scannedIds = scanned.map((t) => t.sourceId).toSet();

      await _isar.writeTxn(() async {
        // Upsert scanned tracks — jangan blok txn dengan File.existsSync
        for (final t in scanned) {
          final existing = await _isar.trackModels
              .where()
              .sourceIdSourceEqualTo(t.sourceId, TrackSource.local)
              .findFirst();
          final model = t.toModel();
          if (existing != null) {
            model.id = existing.id;
            model.createdAt = existing.createdAt;
            model.playCount = existing.playCount;
            model.lastPlayedAt = existing.lastPlayedAt;
            model.isLiked = existing.isLiked;
            // Preserve existing thumb jika scan belum punya (asumsikan cache masih valid, tidak perlu stat)
            if (model.localThumbnailPath == null && existing.localThumbnailPath != null) {
              model.localThumbnailPath = existing.localThumbnailPath;
            }
            model.updatedAt = DateTime.now();
          }
          await _isar.trackModels.put(model);
        }
        // Delete stale: hanya yang tidak ada di MediaStore hasil scan
        final existingLocal = await _isar.trackModels
            .filter()
            .sourceEqualTo(TrackSource.local)
            .findAll();
        for (final e in existingLocal) {
          if (!scannedIds.contains(e.sourceId)) {
            await _isar.trackModels.delete(e.id);
          }
        }
      });
      return Right(scanned);
    } catch (e) {
      return Left(CacheFailure('scan failed: $e'));
    }
  }
}
