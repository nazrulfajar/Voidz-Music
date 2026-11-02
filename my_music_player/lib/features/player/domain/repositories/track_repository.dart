import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../entities/track.dart';

abstract class TrackRepository {
  Future<Either<Failure, void>> saveTrack(Track track);
  Future<Either<Failure, void>> updateTrack(Track track);
  Future<Either<Failure, Track?>> getTrack(String sourceId, String source);
  Future<Either<Failure, Track?>> getTrackBySourceId(String sourceId);
  Future<Either<Failure, List<Track>>> getAllCachedTracks();
  Future<Either<Failure, void>> updateTrackPlayCount(String sourceId, String source);
  Future<Either<Failure, List<Track>>> getRecentlyPlayedTracks({int limit = 10});
  Future<Either<Failure, List<Track>>> getQuickPicksTracks({int limit = 10});
  Future<List<Track>> getTracksBySourceIds(List<String> sourceIds);
  Future<List<Track>> getDeviceTracks();
  Future<Either<Failure, List<Track>>> scanAndSyncLocalTracks();
}
