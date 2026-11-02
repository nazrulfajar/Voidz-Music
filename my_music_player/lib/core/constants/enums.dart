enum TrackSource {
  youtube,

  /// Slot index 1 dipertahankan agar index `local` tetap 2 dan data Isar
  /// lama tidak bergeser. Tidak ada fitur yang memakai nilai ini.
  reserved,

  local
}

enum RepeatMode { off, all, one }

enum AudioQuality { low, medium, high }

enum LyricsType { synced, plain, notFound }
