// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Indonesian (`id`).
class AppLocalizationsId extends AppLocalizations {
  AppLocalizationsId([String locale = 'id']) : super(locale);

  @override
  String get appTitle => 'Voidz Music';

  @override
  String get language => 'Bahasa';

  @override
  String get languageSystem => 'Sistem';

  @override
  String get languageEnglish => 'English';

  @override
  String get languageIndonesian => 'Indonesia';

  @override
  String get commonBack => 'Kembali';

  @override
  String get commonCancel => 'BATAL';

  @override
  String get commonSave => 'SIMPAN';

  @override
  String get settingsTitle => 'Pengaturan';

  @override
  String get settingsSectionPlayback => 'Pemutaran';

  @override
  String get settingsAudioQuality => 'Kualitas audio';

  @override
  String get settingsQualityLow => 'Rendah';

  @override
  String get settingsQualityMedium => 'Sedang';

  @override
  String get settingsQualityHigh => 'Tinggi';

  @override
  String get settingsGaplessCrossfade => 'Gapless / Crossfade';

  @override
  String get settingsGapless => 'Gapless';

  @override
  String settingsCrossfadeValue(int seconds) {
    return '$seconds dtk';
  }

  @override
  String settingsCrossfadeOption(int seconds) {
    return '$seconds dtk crossfade';
  }

  @override
  String get settingsResumeOnStartup => 'Lanjutkan saat dibuka';

  @override
  String get settingsAudioFocus => 'Fokus audio';

  @override
  String get settingsAudioFocusSubtitle =>
      'Kecilkan 50% untuk navigasi, jeda saat telepon/headset';

  @override
  String get settingsYoutubeSource => 'Sumber YouTube';

  @override
  String get settingsYoutubeSourceSubtitle =>
      'Cari dan streaming dari YouTube Music';

  @override
  String get settingsSectionDownloads => 'Unduhan';

  @override
  String get settingsWifiOnly => 'Hanya Wi-Fi';

  @override
  String get settingsStorageLimit => 'Batas penyimpanan';

  @override
  String settingsStorageLimitMax(String size) {
    return 'Maksimum $size';
  }

  @override
  String get settingsStorageUsed => 'Penyimpanan terpakai';

  @override
  String get settingsUnavailable => 'Tidak tersedia';

  @override
  String settingsTrackCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count track',
      one: '1 track',
      zero: 'Tidak ada track',
    );
    return '$_temp0';
  }

  @override
  String settingsPinnedCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count disematkan',
      one: '1 disematkan',
      zero: '0 disematkan',
    );
    return '$_temp0';
  }

  @override
  String get settingsAutoCache => 'Cache otomatis';

  @override
  String get settingsAutoCacheSubtitle => 'Cache track otomatis saat diputar';

  @override
  String get settingsClearCache => 'Hapus cache';

  @override
  String get settingsClearCacheSubtitle =>
      'Menghapus semua track unduhan yang tidak disematkan';

  @override
  String get settingsClearCacheTitle => 'Hapus cache?';

  @override
  String get settingsClearCacheBody =>
      'Semua track unduhan yang tidak disematkan akan dihapus.';

  @override
  String get settingsClearCacheConfirm => 'HAPUS';

  @override
  String get settingsCacheCleared => 'Cache dihapus';

  @override
  String get settingsSectionAppearance => 'Tampilan';

  @override
  String get settingsTheme => 'Tema';

  @override
  String get settingsThemeSystem => 'Sistem';

  @override
  String get settingsThemeLight => 'Terang';

  @override
  String get settingsThemeDark => 'Gelap';

  @override
  String get settingsSectionAbout => 'Tentang';

  @override
  String get settingsVersion => 'Versi';

  @override
  String get settingsLicenses => 'Lisensi';

  @override
  String settingsError(String message) {
    return 'Galat: $message';
  }

  @override
  String get commonPlay => 'Putar';

  @override
  String get commonPlayAll => 'Putar Semua';

  @override
  String get commonShuffle => 'Acak';

  @override
  String get commonTryAgain => 'Coba lagi';

  @override
  String get commonArtist => 'Artis';

  @override
  String get commonAlbum => 'Album';

  @override
  String get commonPlaylist => 'Playlist';

  @override
  String get commonUnknown => 'Tidak dikenal';

  @override
  String commonSongCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count lagu',
      one: '1 lagu',
      zero: '0 lagu',
    );
    return '$_temp0';
  }

  @override
  String get searchFilterAll => 'Semua';

  @override
  String get searchFilterSongs => 'Lagu';

  @override
  String get searchFilterArtists => 'Artis';

  @override
  String get searchFilterAlbums => 'Album';

  @override
  String get searchFilterPlaylists => 'Playlist';

  @override
  String searchFilterSemantics(String label) {
    return 'Filter $label';
  }

  @override
  String get searchHeaderTop => 'Hasil pencarian teratas';

  @override
  String get searchHeaderResults => 'Hasil';

  @override
  String searchResultsCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count hasil',
      one: '1 hasil',
      zero: '0 hasil',
    );
    return '$_temp0';
  }

  @override
  String searchArtistsCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count artis',
      zero: '0 artis',
    );
    return '$_temp0';
  }

  @override
  String searchAlbumsCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count album',
      zero: '0 album',
    );
    return '$_temp0';
  }

  @override
  String searchPlaylistsCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count playlist',
      zero: '0 playlist',
    );
    return '$_temp0';
  }

  @override
  String get searchOfflineTitle => 'Kamu sedang offline';

  @override
  String get searchOfflineMessage => 'Pencarian tersedia saat terhubung';

  @override
  String get searchError => 'Periksa koneksi lalu coba lagi.';

  @override
  String get searchNoResultsTitle => 'Tidak ada hasil';

  @override
  String searchNoResultsMessage(String query) {
    return 'Tidak ada hasil untuk \"$query\"';
  }

  @override
  String get searchClear => 'Hapus pencarian';

  @override
  String get searchIdleTitle => 'Apa yang ingin kamu dengarkan?';

  @override
  String get searchIdleMessage => 'Cari artis, lagu, atau album';

  @override
  String get searchRecentTitle => 'Pencarian terbaru';

  @override
  String get searchClearHistory => 'Hapus';

  @override
  String get searchBrowseBySource => 'Jelajahi berdasarkan sumber';

  @override
  String get searchBrowseSources => 'Jelajahi sumber';

  @override
  String get searchBrowseSourcesSubtitle => 'YouTube Music dan lagu perangkat';

  @override
  String get searchHint => 'Cari lagu, artis...';

  @override
  String get searchHintOffline => 'Pencarian tidak tersedia saat offline';

  @override
  String searchRecentQuerySemantics(String query) {
    return 'Cari $query';
  }

  @override
  String searchRemoveRecentSemantics(String query) {
    return 'Hapus $query';
  }

  @override
  String searchSemanticsArtist(String name) {
    return 'Artis, $name';
  }

  @override
  String searchSemanticsAlbum(String title, String artist) {
    return 'Album, $title, oleh $artist';
  }

  @override
  String searchSemanticsPlaylist(String title, String author) {
    return 'Playlist, $title, oleh $author';
  }

  @override
  String searchSemanticsTrack(String title, String artist) {
    return 'Lagu, $title, oleh $artist';
  }

  @override
  String get browseTitle => 'Jelajahi';

  @override
  String get browseYoutubeSubtitle => 'Cari lagu, artis, dan album';

  @override
  String get browseYoutubeSemantics => 'Cari di YouTube Music';

  @override
  String get browseDeviceSongs => 'Lagu perangkat';

  @override
  String get browseDeviceSongsSubtitle =>
      'Putar audio yang tersimpan di perangkat ini';

  @override
  String get browseDeviceSongsSemantics => 'Buka lagu perangkat';

  @override
  String get browseRecentlyPlayed => 'Terakhir diputar';

  @override
  String get browseNothingPlayedTitle => 'Belum ada yang diputar';

  @override
  String get browseNothingPlayedSubtitle =>
      'Track yang kamu putar akan muncul di sini';

  @override
  String get browseRecentlyPlayedError => 'Gagal memuat yang terakhir diputar';

  @override
  String get browseRecentlyPlayedErrorSubtitle =>
      'Periksa library lalu coba lagi';

  @override
  String browsePlayTrackSemantics(String title, String artist) {
    return 'Putar $title oleh $artist';
  }

  @override
  String get browseAlbumLoadError => 'Gagal memuat album';

  @override
  String get browseArtistLoadError => 'Gagal memuat artis';

  @override
  String get browsePlaylistLoadError => 'Gagal memuat playlist';

  @override
  String get browseUnknownArtist => 'Artis tidak dikenal';

  @override
  String get browseUnknownAuthor => 'Pembuat tidak dikenal';

  @override
  String get browseAddToPlaylist => 'Tambah ke playlist';

  @override
  String get browseNowPlaying => 'Sedang diputar';

  @override
  String get browseTrackOptions => 'Opsi lagu';

  @override
  String get browseTopSongs => 'Lagu Teratas';

  @override
  String get browseAlbums => 'Album';

  @override
  String get browseSinglesEps => 'Single & EP';

  @override
  String get browsePlaylists => 'Playlist';

  @override
  String commonTrackCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count track',
      one: '1 track',
      zero: '0 track',
    );
    return '$_temp0';
  }

  @override
  String commonPlaylistCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count playlist',
      one: '1 playlist',
      zero: '0 playlist',
    );
    return '$_temp0';
  }

  @override
  String get commonMoreOptions => 'Opsi lainnya';

  @override
  String get libraryTitle => 'Library Kamu';

  @override
  String get libraryDownloadedCache => 'Cache unduhan';

  @override
  String get libraryCustomPlaylists => 'Playlist kustom';

  @override
  String get libraryDeviceSongs => 'Lagu perangkat';

  @override
  String get libraryPinnedOfflineTracks => 'Track offline disematkan';

  @override
  String libraryPinnedMeta(String artist) {
    return '$artist · Disematkan offline';
  }

  @override
  String get libraryListeningRecap => 'Rekap mendengarkan';

  @override
  String get libraryListeningSummary => 'Ringkasan mendengarkanmu';

  @override
  String get libraryRecentlyPlayed => 'Terakhir diputar';

  @override
  String get libraryListeningHistory => 'Riwayat mendengarkanmu';

  @override
  String get libraryEmptyTitle => 'Library kamu kosong';

  @override
  String get libraryEmptySubtitle =>
      'Pindai lagu yang sudah ada di perangkat ini, atau cari sesuatu yang baru.';

  @override
  String get libraryEmptyScanUnavailable =>
      'Pemindaian perangkat tidak tersedia. Cari musik untuk mulai mengisi library kamu.';

  @override
  String get librarySearchMusic => 'Cari musik';

  @override
  String get libraryScanDevice => 'Pindai perangkat';

  @override
  String get libraryAutoPlaylistLabel => 'PLAYLIST OTOMATIS';

  @override
  String get libraryLikedSongs => 'Lagu Disukai';

  @override
  String libraryLikedMeta(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Playlist otomatis · $count lagu',
      one: 'Playlist otomatis · 1 lagu',
      zero: 'Playlist otomatis · 0 lagu',
    );
    return '$_temp0';
  }

  @override
  String get libraryLoadError => 'Periksa koneksi lalu coba lagi.';

  @override
  String get playlistsTitle => 'Playlist Kamu';

  @override
  String get playlistsLoadError => 'Gagal memuat playlist';

  @override
  String get playlistsNew => 'Playlist baru';

  @override
  String playlistsDurationMinutes(int minutes) {
    return '$minutes mnt';
  }

  @override
  String playlistsDurationHoursMinutes(int hours, int minutes) {
    return '$hours jam $minutes mnt';
  }

  @override
  String get downloadedTitle => 'Unduhan';

  @override
  String get downloadedStorageUsed => 'Penyimpanan terpakai';

  @override
  String get downloadedStorageWarning =>
      'Penyimpanan hampir penuh. Track lama yang tidak disematkan akan dihapus otomatis.';

  @override
  String get downloadedEmptyTitle => 'Belum ada track unduhan';

  @override
  String get downloadedSemantics => 'Terunduh';

  @override
  String get downloadedRemove => 'Hapus unduhan';

  @override
  String get downloadedLoadError => 'Gagal memuat unduhan';

  @override
  String get commonLoading => 'Memuat...';

  @override
  String get commonError => 'Galat';

  @override
  String commonErrorWithMessage(String message) {
    return 'Galat: $message';
  }

  @override
  String get commonDelete => 'Hapus';

  @override
  String get commonCancelAction => 'Batal';

  @override
  String get commonTrackOptions => 'Opsi lagu';

  @override
  String get commonUnknownAlbum => 'Album tidak dikenal';

  @override
  String commonAlbumCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count album',
      one: '1 album',
      zero: '0 album',
    );
    return '$_temp0';
  }

  @override
  String get commonTryDifferentKeywords => 'Coba kata kunci lain';

  @override
  String commonDurationHours(int hours) {
    return '$hours jam';
  }

  @override
  String get timeJustNow => 'baru saja';

  @override
  String timeMinutesAgo(int count) {
    return '${count}m lalu';
  }

  @override
  String timeHoursAgo(int count) {
    return '${count}j lalu';
  }

  @override
  String timeDaysAgo(int count) {
    return '${count}h lalu';
  }

  @override
  String timeWeeksAgo(int count) {
    return '${count}mgg lalu';
  }

  @override
  String timeMonthsAgo(int count) {
    return '${count}bln lalu';
  }

  @override
  String timeYearsAgo(int count) {
    return '${count}thn lalu';
  }

  @override
  String get deviceSongsRescan => 'Pindai ulang';

  @override
  String get deviceSongsScanFailed => 'Pemindaian gagal. Coba lagi.';

  @override
  String get deviceSongsSearchInList => 'Cari di daftar ini';

  @override
  String get deviceSongsSearchHint => 'Cari lagu, artis, album';

  @override
  String get deviceSongsLoadError => 'Periksa izin penyimpanan lalu coba lagi.';

  @override
  String get deviceSongsEmptyScannedTitle => 'Tidak ada lagu di perangkat';

  @override
  String get deviceSongsEmptyScannedSubtitle =>
      'Cari musik, atau pindai lagi setelah menambah file.';

  @override
  String get deviceSongsEmptyTitle => 'Belum ada lagu di perangkat';

  @override
  String get deviceSongsEmptySubtitle =>
      'Letakkan file MP3/M4A/FLAC di folder Music atau Download, lalu tarik untuk pindai';

  @override
  String get deviceSongsScanNow => 'Pindai Sekarang';

  @override
  String get deviceSongsNoAlbums => 'Tidak ada album';

  @override
  String get deviceSongsNoArtists => 'Tidak ada artis';

  @override
  String get deviceSongsAddToQueue => 'Tambah ke antrean';

  @override
  String get deviceSongsAddedToQueue => 'Ditambahkan ke antrean';

  @override
  String get deviceSongsPlayNext => 'Putar berikutnya';

  @override
  String get deviceSongsWillPlayNext => 'Akan diputar berikutnya';

  @override
  String get deviceSongsPermissionTitle => 'Izinkan akses ke audio';

  @override
  String get deviceSongsPermissionMessage =>
      'Voidz Music membutuhkan izin untuk memindai file audio di perangkat ini.';

  @override
  String get deviceSongsOpenSettings => 'Buka pengaturan';

  @override
  String get deviceSongsAllowAccess => 'Izinkan akses';

  @override
  String get deviceSongsPermissionFootnote =>
      'Kamu dapat mengubahnya di pengaturan sistem.';

  @override
  String get playlistDetailNotFound => 'Playlist tidak ditemukan';

  @override
  String get playlistDetailTagline => 'Koleksimu, soundtrack-mu';

  @override
  String get playlistDetailOptions => 'Opsi playlist';

  @override
  String get playlistDetailPlayAll => 'Putar semua';

  @override
  String get playlistDetailRemoveTrack => 'Hapus dari playlist';

  @override
  String get playlistDetailReadOnly => 'Playlist otomatis hanya-baca';

  @override
  String get playlistDetailDelete => 'Hapus playlist';

  @override
  String get playlistDetailDeleteTitle => 'Hapus playlist?';

  @override
  String get playlistDetailDeleteBody => 'Playlist ini akan dihapus permanen.';

  @override
  String get playlistDetailEmptyTitle => 'Playlist kosong';

  @override
  String get playlistDetailEmptySystemSubtitle =>
      'Track akan muncul di sini otomatis';

  @override
  String get playlistDetailEmptySubtitle =>
      'Tambahkan lagu untuk mulai mendengarkan';

  @override
  String get playlistDetailOverline => 'PLAYLIST';

  @override
  String get playlistDetailTracks => 'TRACK';

  @override
  String playlistDetailOwner(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count lagu',
      one: '1 lagu',
      zero: '0 lagu',
    );
    return 'Kamu · $_temp0';
  }

  @override
  String playlistDetailUpdated(String time) {
    return 'diperbarui $time';
  }

  @override
  String get recentlyPlayedLoadError => 'Gagal memuat riwayat mendengarkan';

  @override
  String get recentlyPlayedClear => 'Hapus riwayat';

  @override
  String get recentlyPlayedClearSubtitle => 'Hapus semua riwayat mendengarkan';

  @override
  String get recentlyPlayedClearTitle => 'Hapus riwayat mendengarkan?';

  @override
  String get recentlyPlayedClearBody =>
      'Ini menghapus permanen semua riwayat pemutaran dan track yang terakhir diputar. Total rekap mendengarkan akan berubah. Jumlah pemutaranmu tetap disimpan.';

  @override
  String recentlyPlayedSummary(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count track unik · 30 hari terakhir',
      one: '1 track unik · 30 hari terakhir',
      zero: '0 track unik · 30 hari terakhir',
    );
    return '$_temp0';
  }

  @override
  String get recentlyPlayedTracks => 'Track';

  @override
  String get recentlyPlayedOverline => 'RIWAYAT MENDENGARKAN';

  @override
  String recentlyPlayedUniqueCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count track unik',
      one: '1 track unik',
      zero: '0 track unik',
    );
    return '$_temp0';
  }

  @override
  String get recentlyPlayedWindow => '30 hari terakhir';

  @override
  String get recentlyPlayedPlay => 'Putar terbaru';

  @override
  String get recentlyPlayedEmptyTitle => 'Belum ada riwayat mendengarkan';

  @override
  String get recentlyPlayedEmptySubtitle =>
      'Track yang kamu putar akan muncul di sini.';

  @override
  String get homeGreetingMorning => 'Selamat Pagi';

  @override
  String get homeGreetingAfternoon => 'Selamat Siang';

  @override
  String get homeGreetingEvening => 'Selamat Malam';

  @override
  String get homeContinueListening => 'Lanjutkan Mendengarkan';

  @override
  String get homeNowListening => 'Sedang Mendengarkan';

  @override
  String homePauseTrack(String title) {
    return 'Jeda $title';
  }

  @override
  String get homeRecentlyPlayed => 'Terakhir diputar';

  @override
  String get homeNoRecentTitle => 'Belum ada yang terakhir diputar';

  @override
  String get homeSearchMusic => 'Cari musik';

  @override
  String get homeLoadError => 'Gagal memuat';

  @override
  String get homeQuickDownloaded => 'Terunduh';

  @override
  String get homeOfflineCache => 'Cache offline';

  @override
  String get homeDeviceSongs => 'Lagu lokal';

  @override
  String get homeOnThisDevice => 'Di perangkat ini';

  @override
  String homePlayTrack(String title) {
    return 'Putar $title';
  }

  @override
  String get dailyMixLabel => 'Daily Mix';

  @override
  String dailyMixBadge(String number) {
    return 'MIX $number';
  }

  @override
  String dailyMixSemantics(String mood) {
    return 'Daily Mix $mood';
  }

  @override
  String dailyMixTrackCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count lagu · Daily Mix',
      one: '1 lagu · Daily Mix',
      zero: '0 lagu · Daily Mix',
    );
    return '$_temp0';
  }

  @override
  String get dailyMixPlayAll => 'Putar semua';

  @override
  String dailyMixEmptyTitle(String mood) {
    return 'Tidak ada track untuk $mood';
  }

  @override
  String get dailyMixEmptySubtitle =>
      'Cari musik atau pindai library perangkatmu.';

  @override
  String get dailyMixSearch => 'Cari';

  @override
  String get dailyMixScanDevice => 'Pindai lagu perangkat';

  @override
  String get dailyMixLoadError =>
      'Gagal memuat mix ini. Periksa koneksi lalu coba lagi.';

  @override
  String get recapTitle => 'Rekap';

  @override
  String recapEmptyTitle(String period) {
    return 'Belum ada rekap $period';
  }

  @override
  String get recapEmptySubtitle =>
      'Putar lagu dulu, rekap akan muncul di sini.\nRiwayat maksimal 10.000 pemutaran.';

  @override
  String get recapLoadError =>
      'Gagal memuat rekap. Periksa koneksi lalu coba lagi.';

  @override
  String get recapTopSongsTitle => 'Top 5 Lagu';

  @override
  String recapTopSongsSubtitle(String period) {
    return 'Paling sering diputar $period';
  }

  @override
  String get recapTopArtistsTitle => 'Top 5 Artis';

  @override
  String get recapTopArtistsSubtitle => 'Artis teratasmu';

  @override
  String get recapTopAlbumsTitle => 'Top 5 Album';

  @override
  String get recapTopAlbumsSubtitle => 'Album paling diputar';

  @override
  String recapMostPlayedBadge(String period) {
    return '#1 PALING SERING $period';
  }

  @override
  String recapTimesPlayed(int count) {
    return '$count× diputar';
  }

  @override
  String get recapStatTotalPlays => 'Total Putar';

  @override
  String get recapStatUniqueSongs => 'Lagu Unik';

  @override
  String get recapStatYear => 'Tahun';

  @override
  String get recapPeriodMonth => 'Bulan';

  @override
  String get recapPeriodYear => 'Tahun';

  @override
  String recapYearPhrase(int year) {
    return 'tahun $year';
  }

  @override
  String get recapSelectMonth => 'Pilih bulan';

  @override
  String get recapSelectYear => 'Pilih tahun';

  @override
  String get lyricsHeader => 'LIRIK';

  @override
  String get lyricsSyncedBadge => 'Sinkron';

  @override
  String get lyricsNotFoundTitle => 'Lirik tidak ditemukan';

  @override
  String get lyricsNotFoundMessage =>
      'LRCLIB tidak punya lirik untuk track ini. Track instrumental tidak pernah menampilkan lirik.';

  @override
  String get lyricsRetry => 'Coba lagi';

  @override
  String get lyricsNotFoundFootnote => 'Pemutaran berlanjut tanpa lirik.';

  @override
  String get lyricsEmpty => 'Lirik kosong';

  @override
  String get lyricsEmptySyncedMessage =>
      'File LRC ini tidak punya baris. Pemutaran berlanjut tanpa lirik.';

  @override
  String lyricsLineSemantics(String time, String text) {
    return '$time — $text';
  }

  @override
  String get lyricsLoadError => 'Lirik tidak tersedia saat ini.';

  @override
  String get lyricsFooterSynced => 'Lirik sinkron · LRCLIB';

  @override
  String get lyricsFooterPlain => 'Lirik · LRCLIB';

  @override
  String get playlistAddSheetTitle => 'Tambah ke Playlist';

  @override
  String get playlistNoneYet => 'Belum ada playlist kustom.';

  @override
  String get playlistCreateNew => 'Buat Playlist Baru';

  @override
  String get playlistNewTitle => 'Playlist Baru';

  @override
  String get playlistNameHint => 'Nama playlist';

  @override
  String get playlistCreate => 'Buat';

  @override
  String get playlistCreateAndAdd => 'Buat & Tambah';

  @override
  String playlistAlreadyIn(String name) {
    return 'Sudah ada di $name';
  }

  @override
  String playlistAddedTo(String name) {
    return 'Ditambahkan ke $name';
  }

  @override
  String playlistAddedMany(int count, String name) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count lagu ditambahkan ke $name',
      one: '1 lagu ditambahkan ke $name',
    );
    return '$_temp0';
  }

  @override
  String playlistAlreadyExisted(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count sudah ada',
      one: '1 sudah ada',
    );
    return '$_temp0';
  }

  @override
  String get playerPlayingFrom => 'DIPUTAR DARI';

  @override
  String get playerClose => 'Tutup pemutar';

  @override
  String get playerSleepTimer => 'Timer Tidur';

  @override
  String get playerLike => 'Suka';

  @override
  String get playerUnlike => 'Batal suka';

  @override
  String get playerPrevious => 'Sebelumnya';

  @override
  String get playerNext => 'Berikutnya';

  @override
  String get playerPause => 'Jeda';

  @override
  String get playerRepeat => 'Ulangi';

  @override
  String get playerRepeatOne => 'Ulangi satu';

  @override
  String playerArtworkSemantics(String title) {
    return 'Sampul $title';
  }

  @override
  String get playerDockLyrics => 'Lirik';

  @override
  String playerDockQueue(int count) {
    return 'Antrean ($count)';
  }

  @override
  String get playerDockTimer => 'Timer';

  @override
  String get playerPlaybackFailed => 'Pemutaran gagal';

  @override
  String get playerStreamUnavailable => 'Tidak bisa memuat stream.';

  @override
  String get playerRetry => 'Coba lagi';

  @override
  String get playerOfflineArtist => 'Mode offline: Tidak bisa memuat artis';

  @override
  String get playerArtistNotFound => 'Halaman artis tidak ditemukan';

  @override
  String get playerArtistLoadError =>
      'Gagal memuat artis. Periksa koneksi lalu coba lagi.';

  @override
  String get playerOfflineAlbum => 'Mode offline: Tidak bisa memuat album';

  @override
  String get playerAlbumNotFound => 'Halaman album tidak ditemukan';

  @override
  String get playerAlbumLoadError =>
      'Gagal memuat album. Periksa koneksi lalu coba lagi.';

  @override
  String get queueTitle => 'Antrean';

  @override
  String get queueClear => 'Hapus';

  @override
  String get queueEmpty => 'Antrean kosong';

  @override
  String queueSummary(int count, String duration) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count lagu',
      one: '1 lagu',
      zero: '0 lagu',
    );
    return '$_temp0 · $duration';
  }

  @override
  String get queueNowPlaying => 'SEDANG DIPUTAR';

  @override
  String get queueUpNext => 'BERIKUTNYA';

  @override
  String get queueDragHint =>
      'Tarik untuk mengubah urutan · Geser untuk menghapus';

  @override
  String get queueDragToReorder => 'Tarik untuk mengubah urutan';

  @override
  String get queueClearTitle => 'Hapus antrean?';

  @override
  String queueClearBody(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count lagu',
      one: '1 lagu',
    );
    return 'Hapus $_temp0 dari Berikutnya? Track saat ini tetap diputar.';
  }

  @override
  String queueCleared(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count lagu dihapus',
      one: '1 lagu dihapus',
    );
    return '$_temp0';
  }

  @override
  String get queueUndo => 'Urungkan';

  @override
  String get queueRemoveTrack => 'Hapus dari antrean';

  @override
  String queueRemovedFromPlaylist(String name) {
    return 'Dihapus dari $name';
  }

  @override
  String get sleepTimerTitle => 'Timer tidur';

  @override
  String get sleepTimerSubtitle => 'Pemutaran berhenti otomatis';

  @override
  String sleepTimerMinutes(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count menit',
    );
    return '$_temp0';
  }

  @override
  String get sleepTimerEndOfTrack => 'Akhir lagu';

  @override
  String get sleepTimerActive => 'Timer aktif';

  @override
  String sleepTimerRemaining(String time) {
    return 'Sisa $time';
  }

  @override
  String get commonSelected => 'Dipilih';

  @override
  String get commonLoadErrorTitle => 'Tidak dapat memuat hasil';

  @override
  String get commonRetryAction => 'Coba lagi';

  @override
  String get commonOfflineTitle => 'Kamu sedang offline';

  @override
  String get commonOfflinePlayingDownloaded => 'Memutar lagu terunduh';

  @override
  String get commonNowPlaying => 'Sedang diputar';

  @override
  String get commonDownloaded => 'Terunduh';

  @override
  String get shellTabHome => 'Beranda';

  @override
  String get shellTabSearch => 'Cari';

  @override
  String get shellTabLibrary => 'Library';

  @override
  String get miniPlayerOpen => 'Buka pemutar';

  @override
  String get miniPlayerProgress => 'Posisi pemutaran';

  @override
  String get miniPlayerDismissHint => 'Geser kiri atau kanan untuk menutup';

  @override
  String get miniPlayerDismiss => 'Tutup pemutar';

  @override
  String get errorRouteNotFoundTitle => 'Halaman tidak ditemukan';

  @override
  String get errorRouteNotFoundMessage =>
      'Kami tidak dapat menemukan halaman itu. Mungkin sudah dipindahkan atau tidak ada lagi.';

  @override
  String get errorRouteGoHome => 'Ke Beranda';
}
