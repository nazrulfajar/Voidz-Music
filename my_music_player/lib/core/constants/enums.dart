enum TrackSource {
  youtube,

  /// Legacy: sumber Jamendo sudah dihapus. Nilai ini dipertahankan hanya
  /// agar index enum di Isar tidak bergeser dan data lama tetap terbaca.
  jamendo,

  local
}

enum RepeatMode { off, all, one }

enum AudioQuality { low, medium, high }

enum LyricsType { synced, plain, notFound }
