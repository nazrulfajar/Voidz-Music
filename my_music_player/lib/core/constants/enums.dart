enum TrackSource {
  youtube,

  /// Slot index 1 dipertahankan agar index `local` tetap 2 dan data Isar
  /// lama tidak bergeser. Tidak ada fitur yang memakai nilai ini.
  reserved,

  local
}

enum RepeatMode { off, all, one }

enum AudioQuality { low, medium, high }

/// Persisted as an Isar ordinal; do not reorder after release.
///
/// Isar's generated enum map falls back to the first declared value for
/// unknown ordinals, so [system] must stay at index 0.
enum AppThemeMode { system, light, dark }

/// Persisted as an Isar ordinal; do not reorder after release.
///
/// Isar's generated enum map falls back to the first declared value for
/// unknown ordinals, so [system] must stay at index 0.
enum AppLanguageMode { system, english, indonesian }

enum LyricsType { synced, plain, notFound }
