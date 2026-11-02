import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:permission_handler/permission_handler.dart';
import '../../domain/entities/track.dart';
import '../../data/repositories/track_repository_impl.dart';
import '../../data/datasources/local_audio_datasource.dart';

final deviceSongsProvider = FutureProvider<List<Track>>((ref) async {
  final repo = ref.read(trackRepositoryProvider);
  final tracks = await repo.getDeviceTracks();
  // Ponytail: jangan blok UI dengan existsSync per-lagu (puluhan/puluhan ribu stat).
  // Stale entries sudah dibersihkan di scanAndSyncLocalTracks; jika ada yang terhapus di luar scan,
  // akan ter-filter saat play (resolveTrack) dan dibersihkan next scan. Return langsung.
  return tracks;
});

class DeviceScanState {
  final bool isScanning;
  final String? error;
  final bool permissionDenied;
  final bool permanentlyDenied;

  const DeviceScanState({
    this.isScanning = false,
    this.error,
    this.permissionDenied = false,
    this.permanentlyDenied = false,
  });

  DeviceScanState copyWith({
    bool? isScanning,
    String? error,
    bool? permissionDenied,
    bool? permanentlyDenied,
  }) {
    return DeviceScanState(
      isScanning: isScanning ?? this.isScanning,
      error: error,
      permissionDenied: permissionDenied ?? this.permissionDenied,
      permanentlyDenied: permanentlyDenied ?? this.permanentlyDenied,
    );
  }

  DeviceScanState clearError() => DeviceScanState(
        isScanning: isScanning,
        permissionDenied: permissionDenied,
        permanentlyDenied: permanentlyDenied,
      );
}

class DeviceScanController extends StateNotifier<DeviceScanState> {
  final Ref _ref;
  DeviceScanController(this._ref) : super(const DeviceScanState());

  Future<bool> _ensurePermission() async {
    // Use OnAudioQuery internal check first, fallback to permission_handler
    try {
      final ds = _ref.read(localAudioDataSourceProvider);
      final has = await ds.hasPermission();
      if (has) return true;
      final granted = await ds.checkAndRequestPermission(retryRequest: true);
      if (granted) return true;
    } catch (_) {}

    // Fallback via permission_handler for more granular states
    try {
      // Android 13+ READ_MEDIA_AUDIO maps to Permission.audio, <13 to storage
      Permission perm;
      // Try audio first
      var status = await Permission.audio.status;
      if (status.isGranted) return true;
      // If denied, try request
      status = await Permission.audio.request();
      if (status.isGranted) return true;
      if (status.isPermanentlyDenied) {
        state = state.copyWith(permissionDenied: true, permanentlyDenied: true);
        return false;
      }
      // Fallback to storage for older devices
      perm = Permission.storage;
      var s2 = await perm.status;
      if (s2.isGranted) return true;
      s2 = await perm.request();
      if (s2.isGranted) return true;
      if (s2.isPermanentlyDenied) {
        state = state.copyWith(permissionDenied: true, permanentlyDenied: true);
      } else {
        state = state.copyWith(permissionDenied: true, permanentlyDenied: false);
      }
      return false;
    } catch (e) {
      return false;
    }
  }

  Future<void> scan() async {
    if (state.isScanning) return;
    state = const DeviceScanState(isScanning: true);

    final ok = await _ensurePermission();
    if (!ok) {
      state = state.copyWith(isScanning: false, permissionDenied: true);
      return;
    }

    try {
      final repo = _ref.read(trackRepositoryProvider);
      final result = await repo.scanAndSyncLocalTracks();
      result.fold(
        (l) => state = DeviceScanState(error: l.message),
        (_) {
          _ref.invalidate(deviceSongsProvider);
          state = const DeviceScanState();
        },
      );
    } catch (e) {
      state = DeviceScanState(error: e.toString());
    }
  }

  Future<void> checkPermissionStatus() async {
    try {
      final audio = await Permission.audio.status;
      final storage = await Permission.storage.status;
      final denied = !audio.isGranted && !storage.isGranted;
      final permDenied = audio.isPermanentlyDenied || storage.isPermanentlyDenied;
      // Also check via datasource
      final ds = _ref.read(localAudioDataSourceProvider);
      final has = await ds.hasPermission();
      if (!has && denied) {
        state = state.copyWith(permissionDenied: true, permanentlyDenied: permDenied);
      } else if (has) {
        state = state.copyWith(permissionDenied: false, permanentlyDenied: false);
      }
    } catch (_) {}
  }

  void clearPermissionFlag() {
    state = state.copyWith(permissionDenied: false, permanentlyDenied: false);
  }
}

final deviceScanControllerProvider =
    StateNotifierProvider<DeviceScanController, DeviceScanState>((ref) {
  return DeviceScanController(ref);
});
