import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Single source of truth untuk cache guard — dipakai hanya di player_controller.
/// cache_download_service TIDAK lagi cek wifiOnly — serahkan ke policy ini.
class CachePolicy {
  bool shouldAllowDownload({
    required bool autoCacheEnabled,
    required bool wifiOnly,
    required ConnectivityResult currentConnectivity,
  }) {
    if (!autoCacheEnabled) return false;
    if (!wifiOnly) return true;
    return currentConnectivity == ConnectivityResult.wifi ||
        currentConnectivity == ConnectivityResult.ethernet;
  }

  bool shouldAllowDownloadFromResults({
    required bool autoCacheEnabled,
    required bool wifiOnly,
    required List<ConnectivityResult> results,
  }) {
    if (!autoCacheEnabled) return false;
    if (!wifiOnly) return true;
    return results.contains(ConnectivityResult.wifi) ||
        results.contains(ConnectivityResult.ethernet);
  }

  /// Premium: jika cachedQuality lebih tinggi dari pref, jangan overwrite — stream low saja
  bool shouldSkipDueToHigherQuality({
    required String? cachedQuality,
    required String prefQuality,
  }) {
    int idx(String? q) {
      if (q == 'high') return 2;
      if (q == 'medium') return 1;
      return 0;
    }
    return cachedQuality != null && idx(cachedQuality) > idx(prefQuality);
  }

  bool shouldUpgradeCache({
    required String? cachedQuality,
    required String prefQuality,
  }) {
    int idx(String? q) {
      if (q == 'high') return 2;
      if (q == 'medium') return 1;
      return 0;
    }
    return cachedQuality != null && idx(prefQuality) > idx(cachedQuality);
  }
}

final cachePolicyProvider = Provider<CachePolicy>((ref) => CachePolicy());
