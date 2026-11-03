// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'Voidz Music';

  @override
  String get language => 'Language';

  @override
  String get languageSystem => 'System';

  @override
  String get languageEnglish => 'English';

  @override
  String get languageIndonesian => 'Indonesian';

  @override
  String get commonBack => 'Back';

  @override
  String get commonCancel => 'CANCEL';

  @override
  String get commonSave => 'SAVE';

  @override
  String get settingsTitle => 'Settings';

  @override
  String get settingsSectionPlayback => 'Playback';

  @override
  String get settingsAudioQuality => 'Audio quality';

  @override
  String get settingsQualityLow => 'Low';

  @override
  String get settingsQualityMedium => 'Medium';

  @override
  String get settingsQualityHigh => 'High';

  @override
  String get settingsGaplessCrossfade => 'Gapless / Crossfade';

  @override
  String get settingsGapless => 'Gapless';

  @override
  String settingsCrossfadeValue(int seconds) {
    return '${seconds}s';
  }

  @override
  String settingsCrossfadeOption(int seconds) {
    return '${seconds}s crossfade';
  }

  @override
  String get settingsResumeOnStartup => 'Resume on startup';

  @override
  String get settingsAudioFocus => 'Audio focus';

  @override
  String get settingsAudioFocusSubtitle =>
      'Duck 50% for nav, pause for call/headset';

  @override
  String get settingsYoutubeSource => 'YouTube source';

  @override
  String get settingsYoutubeSourceSubtitle =>
      'Search and stream from YouTube Music';

  @override
  String get settingsSectionDownloads => 'Downloads';

  @override
  String get settingsWifiOnly => 'Wi-Fi only';

  @override
  String get settingsStorageLimit => 'Storage limit';

  @override
  String settingsStorageLimitMax(String size) {
    return '$size maximum';
  }

  @override
  String get settingsStorageUsed => 'Storage used';

  @override
  String get settingsUnavailable => 'Unavailable';

  @override
  String settingsTrackCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count tracks',
      one: '1 track',
      zero: 'No tracks',
    );
    return '$_temp0';
  }

  @override
  String settingsPinnedCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count pinned',
      one: '1 pinned',
      zero: '0 pinned',
    );
    return '$_temp0';
  }

  @override
  String get settingsAutoCache => 'Auto-cache';

  @override
  String get settingsAutoCacheSubtitle =>
      'Cache tracks automatically when they play';

  @override
  String get settingsClearCache => 'Clear cache';

  @override
  String get settingsClearCacheSubtitle =>
      'Removes all unpinned downloaded tracks';

  @override
  String get settingsClearCacheTitle => 'Clear cache?';

  @override
  String get settingsClearCacheBody =>
      'This will delete all unpinned downloaded tracks.';

  @override
  String get settingsClearCacheConfirm => 'CLEAR';

  @override
  String get settingsCacheCleared => 'Cache cleared';

  @override
  String get settingsSectionAppearance => 'Appearance';

  @override
  String get settingsTheme => 'Theme';

  @override
  String get settingsThemeSystem => 'System';

  @override
  String get settingsThemeLight => 'Light';

  @override
  String get settingsThemeDark => 'Dark';

  @override
  String get settingsSectionAbout => 'About';

  @override
  String get settingsVersion => 'Version';

  @override
  String get settingsLicenses => 'Licenses';

  @override
  String settingsError(String message) {
    return 'Error: $message';
  }

  @override
  String get commonPlay => 'Play';

  @override
  String get commonPlayAll => 'Play All';

  @override
  String get commonShuffle => 'Shuffle';

  @override
  String get commonTryAgain => 'Try again';

  @override
  String get commonArtist => 'Artist';

  @override
  String get commonAlbum => 'Album';

  @override
  String get commonPlaylist => 'Playlist';

  @override
  String get commonUnknown => 'Unknown';

  @override
  String commonSongCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count songs',
      one: '1 song',
      zero: '0 songs',
    );
    return '$_temp0';
  }

  @override
  String get searchFilterAll => 'All';

  @override
  String get searchFilterSongs => 'Songs';

  @override
  String get searchFilterArtists => 'Artists';

  @override
  String get searchFilterAlbums => 'Albums';

  @override
  String get searchFilterPlaylists => 'Playlists';

  @override
  String searchFilterSemantics(String label) {
    return 'Filter $label';
  }

  @override
  String get searchHeaderTop => 'Top search results';

  @override
  String get searchHeaderResults => 'Results';

  @override
  String searchResultsCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count results',
      one: '1 result',
      zero: '0 results',
    );
    return '$_temp0';
  }

  @override
  String searchArtistsCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count artists',
      one: '1 artist',
      zero: '0 artists',
    );
    return '$_temp0';
  }

  @override
  String searchAlbumsCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count albums',
      one: '1 album',
      zero: '0 albums',
    );
    return '$_temp0';
  }

  @override
  String searchPlaylistsCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count playlists',
      one: '1 playlist',
      zero: '0 playlists',
    );
    return '$_temp0';
  }

  @override
  String get searchOfflineTitle => 'You\'re offline';

  @override
  String get searchOfflineMessage => 'Search is available when connected';

  @override
  String get searchError => 'Check your connection and try again.';

  @override
  String get searchNoResultsTitle => 'No results found';

  @override
  String searchNoResultsMessage(String query) {
    return 'No results for \"$query\"';
  }

  @override
  String get searchClear => 'Clear search';

  @override
  String get searchIdleTitle => 'What do you want to listen to?';

  @override
  String get searchIdleMessage => 'Search for artists, songs, or albums';

  @override
  String get searchRecentTitle => 'Recent searches';

  @override
  String get searchClearHistory => 'Clear';

  @override
  String get searchBrowseBySource => 'Browse by source';

  @override
  String get searchBrowseSources => 'Browse sources';

  @override
  String get searchBrowseSourcesSubtitle => 'YouTube Music and device songs';

  @override
  String get searchHint => 'Search songs, artists...';

  @override
  String get searchHintOffline => 'Search unavailable offline';

  @override
  String searchRecentQuerySemantics(String query) {
    return 'Search $query';
  }

  @override
  String searchRemoveRecentSemantics(String query) {
    return 'Remove $query';
  }

  @override
  String searchSemanticsArtist(String name) {
    return 'Artist, $name';
  }

  @override
  String searchSemanticsAlbum(String title, String artist) {
    return 'Album, $title, by $artist';
  }

  @override
  String searchSemanticsPlaylist(String title, String author) {
    return 'Playlist, $title, by $author';
  }

  @override
  String searchSemanticsTrack(String title, String artist) {
    return 'Track, $title, by $artist';
  }

  @override
  String get browseTitle => 'Browse';

  @override
  String get browseYoutubeSubtitle => 'Search songs, artists, and albums';

  @override
  String get browseYoutubeSemantics => 'Search YouTube Music';

  @override
  String get browseDeviceSongs => 'Device songs';

  @override
  String get browseDeviceSongsSubtitle => 'Play audio stored on this device';

  @override
  String get browseDeviceSongsSemantics => 'Open device songs';

  @override
  String get browseRecentlyPlayed => 'Recently played';

  @override
  String get browseNothingPlayedTitle => 'Nothing played yet';

  @override
  String get browseNothingPlayedSubtitle => 'Tracks you play will appear here';

  @override
  String get browseRecentlyPlayedError => 'Could not load recently played';

  @override
  String get browseRecentlyPlayedErrorSubtitle =>
      'Check your library and try again';

  @override
  String browsePlayTrackSemantics(String title, String artist) {
    return 'Play $title by $artist';
  }

  @override
  String get browseAlbumLoadError => 'Could not load album';

  @override
  String get browseArtistLoadError => 'Could not load artist';

  @override
  String get browsePlaylistLoadError => 'Could not load playlist';

  @override
  String get browseUnknownArtist => 'Unknown Artist';

  @override
  String get browseUnknownAuthor => 'Unknown Author';

  @override
  String get browseAddToPlaylist => 'Add to playlist';

  @override
  String get browseNowPlaying => 'Now playing';

  @override
  String get browseTrackOptions => 'Track options';

  @override
  String get browseTopSongs => 'Top Songs';

  @override
  String get browseAlbums => 'Albums';

  @override
  String get browseSinglesEps => 'Singles & EPs';

  @override
  String get browsePlaylists => 'Playlists';

  @override
  String commonTrackCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count tracks',
      one: '1 track',
      zero: '0 tracks',
    );
    return '$_temp0';
  }

  @override
  String commonPlaylistCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count playlists',
      one: '1 playlist',
      zero: '0 playlists',
    );
    return '$_temp0';
  }

  @override
  String get commonMoreOptions => 'More options';

  @override
  String get libraryTitle => 'Your Library';

  @override
  String get libraryDownloadedCache => 'Downloaded cache';

  @override
  String get libraryCustomPlaylists => 'Custom playlists';

  @override
  String get libraryDeviceSongs => 'Device songs';

  @override
  String get libraryPinnedOfflineTracks => 'Pinned offline tracks';

  @override
  String libraryPinnedMeta(String artist) {
    return '$artist · Pinned offline';
  }

  @override
  String get libraryListeningRecap => 'Listening recap';

  @override
  String get libraryListeningSummary => 'Your listening summary';

  @override
  String get libraryRecentlyPlayed => 'Recently played';

  @override
  String get libraryListeningHistory => 'Your listening history';

  @override
  String get libraryEmptyTitle => 'Your library is empty';

  @override
  String get libraryEmptySubtitle =>
      'Scan the songs already on this device, or search for something new.';

  @override
  String get libraryEmptyScanUnavailable =>
      'Device scan is unavailable. Search music to start your library.';

  @override
  String get librarySearchMusic => 'Search music';

  @override
  String get libraryScanDevice => 'Scan device';

  @override
  String get libraryAutoPlaylistLabel => 'AUTO-PLAYLIST';

  @override
  String get libraryLikedSongs => 'Liked Songs';

  @override
  String libraryLikedMeta(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Auto-playlist · $count tracks',
      one: 'Auto-playlist · 1 track',
      zero: 'Auto-playlist · 0 tracks',
    );
    return '$_temp0';
  }

  @override
  String get libraryLoadError => 'Check your connection and try again.';

  @override
  String get playlistsTitle => 'Your playlists';

  @override
  String get playlistsLoadError => 'Failed to load playlists';

  @override
  String get playlistsNew => 'New playlist';

  @override
  String playlistsDurationMinutes(int minutes) {
    return '$minutes min';
  }

  @override
  String playlistsDurationHoursMinutes(int hours, int minutes) {
    return '$hours hr $minutes min';
  }

  @override
  String get downloadedTitle => 'Downloads';

  @override
  String get downloadedStorageUsed => 'Storage Used';

  @override
  String get downloadedStorageWarning =>
      'Storage is almost full. Old unpinned tracks will be removed automatically.';

  @override
  String get downloadedEmptyTitle => 'No downloaded tracks yet';

  @override
  String get downloadedSemantics => 'Downloaded';

  @override
  String get downloadedRemove => 'Remove download';

  @override
  String get downloadedLoadError => 'Failed to load downloads';

  @override
  String get commonLoading => 'Loading...';

  @override
  String get commonError => 'Error';

  @override
  String commonErrorWithMessage(String message) {
    return 'Error: $message';
  }

  @override
  String get commonDelete => 'Delete';

  @override
  String get commonCancelAction => 'Cancel';

  @override
  String get commonTrackOptions => 'Track options';

  @override
  String get commonUnknownAlbum => 'Unknown Album';

  @override
  String commonAlbumCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count albums',
      one: '1 album',
      zero: '0 albums',
    );
    return '$_temp0';
  }

  @override
  String get commonTryDifferentKeywords => 'Try different keywords';

  @override
  String commonDurationHours(int hours) {
    return '$hours hr';
  }

  @override
  String get timeJustNow => 'just now';

  @override
  String timeMinutesAgo(int count) {
    return '${count}m ago';
  }

  @override
  String timeHoursAgo(int count) {
    return '${count}h ago';
  }

  @override
  String timeDaysAgo(int count) {
    return '${count}d ago';
  }

  @override
  String timeWeeksAgo(int count) {
    return '${count}w ago';
  }

  @override
  String timeMonthsAgo(int count) {
    return '${count}mo ago';
  }

  @override
  String timeYearsAgo(int count) {
    return '${count}y ago';
  }

  @override
  String get deviceSongsRescan => 'Rescan';

  @override
  String get deviceSongsScanFailed => 'Scan failed. Try again.';

  @override
  String get deviceSongsSearchInList => 'Search in this list';

  @override
  String get deviceSongsSearchHint => 'Search songs, artists, albums';

  @override
  String get deviceSongsLoadError => 'Check storage permission and try again.';

  @override
  String get deviceSongsEmptyScannedTitle => 'No songs found on device';

  @override
  String get deviceSongsEmptyScannedSubtitle =>
      'Search music instead, or scan again after adding files.';

  @override
  String get deviceSongsEmptyTitle => 'No songs on this device yet';

  @override
  String get deviceSongsEmptySubtitle =>
      'Put MP3/M4A/FLAC files in the Music or Download folder, then pull to scan';

  @override
  String get deviceSongsScanNow => 'Scan now';

  @override
  String get deviceSongsNoAlbums => 'No albums';

  @override
  String get deviceSongsNoArtists => 'No artists';

  @override
  String get deviceSongsAddToQueue => 'Add to queue';

  @override
  String get deviceSongsAddedToQueue => 'Added to queue';

  @override
  String get deviceSongsPlayNext => 'Play next';

  @override
  String get deviceSongsWillPlayNext => 'Will play next';

  @override
  String get deviceSongsPermissionTitle => 'Allow access to audio';

  @override
  String get deviceSongsPermissionMessage =>
      'Voidz Music needs permission to scan audio files on this device.';

  @override
  String get deviceSongsOpenSettings => 'Open settings';

  @override
  String get deviceSongsAllowAccess => 'Allow access';

  @override
  String get deviceSongsPermissionFootnote =>
      'You can change this in system settings.';

  @override
  String get playlistDetailNotFound => 'Playlist not found';

  @override
  String get playlistDetailTagline => 'Your collection, your soundtrack';

  @override
  String get playlistDetailOptions => 'Playlist options';

  @override
  String get playlistDetailPlayAll => 'Play all';

  @override
  String get playlistDetailRemoveTrack => 'Remove from playlist';

  @override
  String get playlistDetailReadOnly => 'Read-only auto-playlist';

  @override
  String get playlistDetailDelete => 'Delete playlist';

  @override
  String get playlistDetailDeleteTitle => 'Delete Playlist?';

  @override
  String get playlistDetailDeleteBody =>
      'This playlist will be permanently deleted.';

  @override
  String get playlistDetailEmptyTitle => 'Playlist is empty';

  @override
  String get playlistDetailEmptySystemSubtitle =>
      'Tracks will appear here automatically';

  @override
  String get playlistDetailEmptySubtitle => 'Add songs to start listening';

  @override
  String get playlistDetailOverline => 'PLAYLIST';

  @override
  String get playlistDetailTracks => 'TRACKS';

  @override
  String playlistDetailOwner(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count songs',
      one: '1 song',
      zero: '0 songs',
    );
    return 'You · $_temp0';
  }

  @override
  String playlistDetailUpdated(String time) {
    return 'updated $time';
  }

  @override
  String get recentlyPlayedLoadError => 'Failed to load listening history';

  @override
  String get recentlyPlayedClear => 'Clear history';

  @override
  String get recentlyPlayedClearSubtitle => 'Remove all listening history';

  @override
  String get recentlyPlayedClearTitle => 'Clear listening history?';

  @override
  String get recentlyPlayedClearBody =>
      'This permanently removes all play history and recently played tracks. Listening recap totals will change. Your play counts are kept.';

  @override
  String recentlyPlayedSummary(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count unique tracks · last 30 days',
      one: '1 unique track · last 30 days',
      zero: '0 unique tracks · last 30 days',
    );
    return '$_temp0';
  }

  @override
  String get recentlyPlayedTracks => 'Tracks';

  @override
  String get recentlyPlayedOverline => 'LISTENING HISTORY';

  @override
  String recentlyPlayedUniqueCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count unique tracks',
      one: '1 unique track',
      zero: '0 unique tracks',
    );
    return '$_temp0';
  }

  @override
  String get recentlyPlayedWindow => 'Last 30 days';

  @override
  String get recentlyPlayedPlay => 'Play recent';

  @override
  String get recentlyPlayedEmptyTitle => 'No listening history';

  @override
  String get recentlyPlayedEmptySubtitle => 'Tracks you play will appear here.';

  @override
  String get homeGreetingMorning => 'Good Morning';

  @override
  String get homeGreetingAfternoon => 'Good Afternoon';

  @override
  String get homeGreetingEvening => 'Good Evening';

  @override
  String get homeContinueListening => 'Continue Listening';

  @override
  String get homeRecentlyPlayed => 'Recently Played';

  @override
  String get homeNoRecentTitle => 'No recently played tracks';

  @override
  String get homeSearchMusic => 'Search music';

  @override
  String get homeLoadError => 'Unable to load';

  @override
  String get homeQuickDownloaded => 'Downloaded';

  @override
  String get homeOfflineCache => 'Offline cache';

  @override
  String get homeDeviceSongs => 'Device songs';

  @override
  String get homeOnThisDevice => 'On this device';

  @override
  String homePlayTrack(String title) {
    return 'Play $title';
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
      other: '$count tracks · Daily Mix',
      one: '1 track · Daily Mix',
      zero: '0 tracks · Daily Mix',
    );
    return '$_temp0';
  }

  @override
  String get dailyMixPlayAll => 'Play all';

  @override
  String dailyMixEmptyTitle(String mood) {
    return 'No tracks for $mood';
  }

  @override
  String get dailyMixEmptySubtitle =>
      'Search for music or scan your device library.';

  @override
  String get dailyMixSearch => 'Search';

  @override
  String get dailyMixScanDevice => 'Scan device songs';

  @override
  String get dailyMixLoadError =>
      'Couldn\'t load this mix. Check your connection and try again.';

  @override
  String get recapTitle => 'Recap';

  @override
  String recapEmptyTitle(String period) {
    return 'No recap for $period';
  }

  @override
  String get recapEmptySubtitle =>
      'Play some songs first — your recap will appear here.\nHistory keeps up to 10,000 plays.';

  @override
  String get recapLoadError =>
      'Couldn\'t load your recap. Check your connection and try again.';

  @override
  String get recapTopSongsTitle => 'Top 5 Songs';

  @override
  String recapTopSongsSubtitle(String period) {
    return 'Most played $period';
  }

  @override
  String get recapTopArtistsTitle => 'Top 5 Artists';

  @override
  String get recapTopArtistsSubtitle => 'Your top artists';

  @override
  String get recapTopAlbumsTitle => 'Top 5 Albums';

  @override
  String get recapTopAlbumsSubtitle => 'Most played albums';

  @override
  String recapMostPlayedBadge(String period) {
    return '#1 MOST PLAYED $period';
  }

  @override
  String recapTimesPlayed(int count) {
    return '$count× played';
  }

  @override
  String get recapStatTotalPlays => 'Total plays';

  @override
  String get recapStatUniqueSongs => 'Unique songs';

  @override
  String get recapStatYear => 'Year';

  @override
  String get recapPeriodMonth => 'Month';

  @override
  String get recapPeriodYear => 'Year';

  @override
  String recapYearPhrase(int year) {
    return 'in $year';
  }

  @override
  String get recapSelectMonth => 'Select month';

  @override
  String get recapSelectYear => 'Select year';

  @override
  String get lyricsHeader => 'LYRICS';

  @override
  String get lyricsSyncedBadge => 'Synced';

  @override
  String get lyricsNotFoundTitle => 'No lyrics found';

  @override
  String get lyricsNotFoundMessage =>
      'LRCLIB has no lyrics for this track. Instrumental tracks never show lyrics.';

  @override
  String get lyricsRetry => 'Retry';

  @override
  String get lyricsNotFoundFootnote => 'Playback continues without lyrics.';

  @override
  String get lyricsEmpty => 'Lyrics are empty';

  @override
  String get lyricsEmptySyncedMessage =>
      'This LRC file has no lines. Playback continues without lyrics.';

  @override
  String lyricsLineSemantics(String time, String text) {
    return '$time — $text';
  }

  @override
  String get lyricsLoadError => 'Lyrics are unavailable right now.';

  @override
  String get lyricsFooterSynced => 'Synced lyrics · LRCLIB';

  @override
  String get lyricsFooterPlain => 'Lyrics · LRCLIB';

  @override
  String get playlistAddSheetTitle => 'Add to Playlist';

  @override
  String get playlistNoneYet => 'No custom playlists found.';

  @override
  String get playlistCreateNew => 'Create New Playlist';

  @override
  String get playlistNewTitle => 'New Playlist';

  @override
  String get playlistNameHint => 'Playlist name';

  @override
  String get playlistCreate => 'Create';

  @override
  String get playlistCreateAndAdd => 'Create & Add';

  @override
  String playlistAlreadyIn(String name) {
    return 'Already in $name';
  }

  @override
  String playlistAddedTo(String name) {
    return 'Added to $name';
  }

  @override
  String playlistAddedMany(int count, String name) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Added $count tracks to $name',
      one: 'Added 1 track to $name',
    );
    return '$_temp0';
  }

  @override
  String playlistAlreadyExisted(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count already existed',
      one: '1 already existed',
    );
    return '$_temp0';
  }

  @override
  String get playerPlayingFrom => 'PLAYING FROM';

  @override
  String get playerClose => 'Close player';

  @override
  String get playerSleepTimer => 'Sleep Timer';

  @override
  String get playerLike => 'Like';

  @override
  String get playerUnlike => 'Unlike';

  @override
  String get playerPrevious => 'Previous';

  @override
  String get playerNext => 'Next';

  @override
  String get playerPause => 'Pause';

  @override
  String get playerRepeat => 'Repeat';

  @override
  String get playerRepeatOne => 'Repeat one';

  @override
  String playerArtworkSemantics(String title) {
    return 'Artwork for $title';
  }

  @override
  String get playerDockLyrics => 'Lyrics';

  @override
  String playerDockQueue(int count) {
    return 'Queue ($count)';
  }

  @override
  String get playerDockTimer => 'Timer';

  @override
  String get playerPlaybackFailed => 'Playback failed';

  @override
  String get playerStreamUnavailable => 'Couldn\'t resolve the stream.';

  @override
  String get playerRetry => 'Retry';

  @override
  String get playerOfflineArtist => 'Offline mode: Cannot load artist';

  @override
  String get playerArtistNotFound => 'Artist page not found';

  @override
  String get playerArtistLoadError =>
      'Couldn\'t load artist. Check your connection and try again.';

  @override
  String get playerOfflineAlbum => 'Offline mode: Cannot load album';

  @override
  String get playerAlbumNotFound => 'Album page not found';

  @override
  String get playerAlbumLoadError =>
      'Couldn\'t load album. Check your connection and try again.';

  @override
  String get queueTitle => 'Queue';

  @override
  String get queueClear => 'Clear';

  @override
  String get queueEmpty => 'Queue is empty';

  @override
  String queueSummary(int count, String duration) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count songs',
      one: '1 song',
      zero: '0 songs',
    );
    return '$_temp0 · $duration';
  }

  @override
  String get queueNowPlaying => 'NOW PLAYING';

  @override
  String get queueUpNext => 'UP NEXT';

  @override
  String get queueDragHint => 'Drag to reorder · Swipe to remove';

  @override
  String get queueDragToReorder => 'Drag to reorder';

  @override
  String get queueClearTitle => 'Clear queue?';

  @override
  String queueClearBody(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count songs',
      one: '1 song',
    );
    return 'Remove $_temp0 from Up Next? The current track keeps playing.';
  }

  @override
  String queueCleared(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count songs removed',
      one: '1 song removed',
    );
    return '$_temp0';
  }

  @override
  String get queueUndo => 'Undo';

  @override
  String get queueRemoveTrack => 'Remove from queue';

  @override
  String queueRemovedFromPlaylist(String name) {
    return 'Removed from $name';
  }

  @override
  String get sleepTimerTitle => 'Sleep timer';

  @override
  String get sleepTimerSubtitle => 'Playback stops automatically';

  @override
  String sleepTimerMinutes(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count minutes',
      one: '1 minute',
    );
    return '$_temp0';
  }

  @override
  String get sleepTimerEndOfTrack => 'End of track';

  @override
  String get sleepTimerActive => 'Timer Active';

  @override
  String sleepTimerRemaining(String time) {
    return '$time remaining';
  }

  @override
  String get commonSelected => 'Selected';

  @override
  String get commonLoadErrorTitle => 'Couldn\'t load results';

  @override
  String get commonRetryAction => 'Retry';

  @override
  String get commonOfflineTitle => 'You\'re offline';

  @override
  String get commonOfflinePlayingDownloaded => 'Playing downloaded songs';

  @override
  String get commonNowPlaying => 'Now playing';

  @override
  String get commonDownloaded => 'Downloaded';

  @override
  String get shellTabHome => 'Home';

  @override
  String get shellTabSearch => 'Search';

  @override
  String get shellTabLibrary => 'Library';

  @override
  String get miniPlayerOpen => 'Open player';

  @override
  String get miniPlayerProgress => 'Playback position';

  @override
  String get errorRouteNotFoundTitle => 'Page not found';

  @override
  String get errorRouteNotFoundMessage =>
      'We couldn\'t find that page. It may have moved or no longer exists.';

  @override
  String get errorRouteGoHome => 'Go Home';
}
