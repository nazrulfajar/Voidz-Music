import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_id.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
      : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
    delegate,
    GlobalMaterialLocalizations.delegate,
    GlobalCupertinoLocalizations.delegate,
    GlobalWidgetsLocalizations.delegate,
  ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('id')
  ];

  /// No description provided for @appTitle.
  ///
  /// In en, this message translates to:
  /// **'Voidz Music'**
  String get appTitle;

  /// No description provided for @language.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get language;

  /// No description provided for @languageSystem.
  ///
  /// In en, this message translates to:
  /// **'System'**
  String get languageSystem;

  /// No description provided for @languageEnglish.
  ///
  /// In en, this message translates to:
  /// **'English'**
  String get languageEnglish;

  /// No description provided for @languageIndonesian.
  ///
  /// In en, this message translates to:
  /// **'Indonesian'**
  String get languageIndonesian;

  /// No description provided for @commonBack.
  ///
  /// In en, this message translates to:
  /// **'Back'**
  String get commonBack;

  /// No description provided for @commonCancel.
  ///
  /// In en, this message translates to:
  /// **'CANCEL'**
  String get commonCancel;

  /// No description provided for @commonSave.
  ///
  /// In en, this message translates to:
  /// **'SAVE'**
  String get commonSave;

  /// No description provided for @settingsTitle.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settingsTitle;

  /// No description provided for @settingsSectionPlayback.
  ///
  /// In en, this message translates to:
  /// **'Playback'**
  String get settingsSectionPlayback;

  /// No description provided for @settingsAudioQuality.
  ///
  /// In en, this message translates to:
  /// **'Audio quality'**
  String get settingsAudioQuality;

  /// No description provided for @settingsQualityLow.
  ///
  /// In en, this message translates to:
  /// **'Low'**
  String get settingsQualityLow;

  /// No description provided for @settingsQualityMedium.
  ///
  /// In en, this message translates to:
  /// **'Medium'**
  String get settingsQualityMedium;

  /// No description provided for @settingsQualityHigh.
  ///
  /// In en, this message translates to:
  /// **'High'**
  String get settingsQualityHigh;

  /// No description provided for @settingsGaplessCrossfade.
  ///
  /// In en, this message translates to:
  /// **'Gapless / Crossfade'**
  String get settingsGaplessCrossfade;

  /// No description provided for @settingsGapless.
  ///
  /// In en, this message translates to:
  /// **'Gapless'**
  String get settingsGapless;

  /// No description provided for @settingsCrossfadeValue.
  ///
  /// In en, this message translates to:
  /// **'{seconds}s'**
  String settingsCrossfadeValue(int seconds);

  /// No description provided for @settingsCrossfadeOption.
  ///
  /// In en, this message translates to:
  /// **'{seconds}s crossfade'**
  String settingsCrossfadeOption(int seconds);

  /// No description provided for @settingsResumeOnStartup.
  ///
  /// In en, this message translates to:
  /// **'Resume on startup'**
  String get settingsResumeOnStartup;

  /// No description provided for @settingsAudioFocus.
  ///
  /// In en, this message translates to:
  /// **'Audio focus'**
  String get settingsAudioFocus;

  /// No description provided for @settingsAudioFocusSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Duck 50% for nav, pause for call/headset'**
  String get settingsAudioFocusSubtitle;

  /// No description provided for @settingsYoutubeSource.
  ///
  /// In en, this message translates to:
  /// **'YouTube source'**
  String get settingsYoutubeSource;

  /// No description provided for @settingsYoutubeSourceSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Search and stream from YouTube Music'**
  String get settingsYoutubeSourceSubtitle;

  /// No description provided for @settingsSectionDownloads.
  ///
  /// In en, this message translates to:
  /// **'Downloads'**
  String get settingsSectionDownloads;

  /// No description provided for @settingsWifiOnly.
  ///
  /// In en, this message translates to:
  /// **'Wi-Fi only'**
  String get settingsWifiOnly;

  /// No description provided for @settingsStorageLimit.
  ///
  /// In en, this message translates to:
  /// **'Storage limit'**
  String get settingsStorageLimit;

  /// No description provided for @settingsStorageLimitMax.
  ///
  /// In en, this message translates to:
  /// **'{size} maximum'**
  String settingsStorageLimitMax(String size);

  /// No description provided for @settingsStorageUsed.
  ///
  /// In en, this message translates to:
  /// **'Storage used'**
  String get settingsStorageUsed;

  /// No description provided for @settingsUnavailable.
  ///
  /// In en, this message translates to:
  /// **'Unavailable'**
  String get settingsUnavailable;

  /// No description provided for @settingsTrackCount.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =0{No tracks} =1{1 track} other{{count} tracks}}'**
  String settingsTrackCount(int count);

  /// No description provided for @settingsPinnedCount.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =0{0 pinned} =1{1 pinned} other{{count} pinned}}'**
  String settingsPinnedCount(int count);

  /// No description provided for @settingsAutoCache.
  ///
  /// In en, this message translates to:
  /// **'Auto-cache'**
  String get settingsAutoCache;

  /// No description provided for @settingsAutoCacheSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Cache tracks automatically when they play'**
  String get settingsAutoCacheSubtitle;

  /// No description provided for @settingsClearCache.
  ///
  /// In en, this message translates to:
  /// **'Clear cache'**
  String get settingsClearCache;

  /// No description provided for @settingsClearCacheSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Removes all unpinned downloaded tracks'**
  String get settingsClearCacheSubtitle;

  /// No description provided for @settingsClearCacheTitle.
  ///
  /// In en, this message translates to:
  /// **'Clear cache?'**
  String get settingsClearCacheTitle;

  /// No description provided for @settingsClearCacheBody.
  ///
  /// In en, this message translates to:
  /// **'This will delete all unpinned downloaded tracks.'**
  String get settingsClearCacheBody;

  /// No description provided for @settingsClearCacheConfirm.
  ///
  /// In en, this message translates to:
  /// **'CLEAR'**
  String get settingsClearCacheConfirm;

  /// No description provided for @settingsCacheCleared.
  ///
  /// In en, this message translates to:
  /// **'Cache cleared'**
  String get settingsCacheCleared;

  /// No description provided for @settingsSectionAppearance.
  ///
  /// In en, this message translates to:
  /// **'Appearance'**
  String get settingsSectionAppearance;

  /// No description provided for @settingsTheme.
  ///
  /// In en, this message translates to:
  /// **'Theme'**
  String get settingsTheme;

  /// No description provided for @settingsThemeSystem.
  ///
  /// In en, this message translates to:
  /// **'System'**
  String get settingsThemeSystem;

  /// No description provided for @settingsThemeLight.
  ///
  /// In en, this message translates to:
  /// **'Light'**
  String get settingsThemeLight;

  /// No description provided for @settingsThemeDark.
  ///
  /// In en, this message translates to:
  /// **'Dark'**
  String get settingsThemeDark;

  /// No description provided for @settingsSectionAbout.
  ///
  /// In en, this message translates to:
  /// **'About'**
  String get settingsSectionAbout;

  /// No description provided for @settingsVersion.
  ///
  /// In en, this message translates to:
  /// **'Version'**
  String get settingsVersion;

  /// No description provided for @settingsLicenses.
  ///
  /// In en, this message translates to:
  /// **'Licenses'**
  String get settingsLicenses;

  /// No description provided for @settingsError.
  ///
  /// In en, this message translates to:
  /// **'Error: {message}'**
  String settingsError(String message);

  /// No description provided for @commonPlay.
  ///
  /// In en, this message translates to:
  /// **'Play'**
  String get commonPlay;

  /// No description provided for @commonPlayAll.
  ///
  /// In en, this message translates to:
  /// **'Play All'**
  String get commonPlayAll;

  /// No description provided for @commonShuffle.
  ///
  /// In en, this message translates to:
  /// **'Shuffle'**
  String get commonShuffle;

  /// No description provided for @commonTryAgain.
  ///
  /// In en, this message translates to:
  /// **'Try again'**
  String get commonTryAgain;

  /// No description provided for @commonArtist.
  ///
  /// In en, this message translates to:
  /// **'Artist'**
  String get commonArtist;

  /// No description provided for @commonAlbum.
  ///
  /// In en, this message translates to:
  /// **'Album'**
  String get commonAlbum;

  /// No description provided for @commonPlaylist.
  ///
  /// In en, this message translates to:
  /// **'Playlist'**
  String get commonPlaylist;

  /// No description provided for @commonUnknown.
  ///
  /// In en, this message translates to:
  /// **'Unknown'**
  String get commonUnknown;

  /// No description provided for @commonSongCount.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =0{0 songs} =1{1 song} other{{count} songs}}'**
  String commonSongCount(int count);

  /// No description provided for @searchFilterAll.
  ///
  /// In en, this message translates to:
  /// **'All'**
  String get searchFilterAll;

  /// No description provided for @searchFilterSongs.
  ///
  /// In en, this message translates to:
  /// **'Songs'**
  String get searchFilterSongs;

  /// No description provided for @searchFilterArtists.
  ///
  /// In en, this message translates to:
  /// **'Artists'**
  String get searchFilterArtists;

  /// No description provided for @searchFilterAlbums.
  ///
  /// In en, this message translates to:
  /// **'Albums'**
  String get searchFilterAlbums;

  /// No description provided for @searchFilterPlaylists.
  ///
  /// In en, this message translates to:
  /// **'Playlists'**
  String get searchFilterPlaylists;

  /// No description provided for @searchFilterSemantics.
  ///
  /// In en, this message translates to:
  /// **'Filter {label}'**
  String searchFilterSemantics(String label);

  /// No description provided for @searchHeaderTop.
  ///
  /// In en, this message translates to:
  /// **'Top search results'**
  String get searchHeaderTop;

  /// No description provided for @searchHeaderResults.
  ///
  /// In en, this message translates to:
  /// **'Results'**
  String get searchHeaderResults;

  /// No description provided for @searchResultsCount.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =0{0 results} =1{1 result} other{{count} results}}'**
  String searchResultsCount(int count);

  /// No description provided for @searchArtistsCount.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =0{0 artists} =1{1 artist} other{{count} artists}}'**
  String searchArtistsCount(int count);

  /// No description provided for @searchAlbumsCount.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =0{0 albums} =1{1 album} other{{count} albums}}'**
  String searchAlbumsCount(int count);

  /// No description provided for @searchPlaylistsCount.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =0{0 playlists} =1{1 playlist} other{{count} playlists}}'**
  String searchPlaylistsCount(int count);

  /// No description provided for @searchOfflineTitle.
  ///
  /// In en, this message translates to:
  /// **'You\'re offline'**
  String get searchOfflineTitle;

  /// No description provided for @searchOfflineMessage.
  ///
  /// In en, this message translates to:
  /// **'Search is available when connected'**
  String get searchOfflineMessage;

  /// No description provided for @searchError.
  ///
  /// In en, this message translates to:
  /// **'Check your connection and try again.'**
  String get searchError;

  /// No description provided for @searchNoResultsTitle.
  ///
  /// In en, this message translates to:
  /// **'No results found'**
  String get searchNoResultsTitle;

  /// No description provided for @searchNoResultsMessage.
  ///
  /// In en, this message translates to:
  /// **'No results for \"{query}\"'**
  String searchNoResultsMessage(String query);

  /// No description provided for @searchClear.
  ///
  /// In en, this message translates to:
  /// **'Clear search'**
  String get searchClear;

  /// No description provided for @searchIdleTitle.
  ///
  /// In en, this message translates to:
  /// **'What do you want to listen to?'**
  String get searchIdleTitle;

  /// No description provided for @searchIdleMessage.
  ///
  /// In en, this message translates to:
  /// **'Search for artists, songs, or albums'**
  String get searchIdleMessage;

  /// No description provided for @searchRecentTitle.
  ///
  /// In en, this message translates to:
  /// **'Recent searches'**
  String get searchRecentTitle;

  /// No description provided for @searchClearHistory.
  ///
  /// In en, this message translates to:
  /// **'Clear'**
  String get searchClearHistory;

  /// No description provided for @searchBrowseBySource.
  ///
  /// In en, this message translates to:
  /// **'Browse by source'**
  String get searchBrowseBySource;

  /// No description provided for @searchBrowseSources.
  ///
  /// In en, this message translates to:
  /// **'Browse sources'**
  String get searchBrowseSources;

  /// No description provided for @searchBrowseSourcesSubtitle.
  ///
  /// In en, this message translates to:
  /// **'YouTube Music and device songs'**
  String get searchBrowseSourcesSubtitle;

  /// No description provided for @searchHint.
  ///
  /// In en, this message translates to:
  /// **'Search songs, artists...'**
  String get searchHint;

  /// No description provided for @searchHintOffline.
  ///
  /// In en, this message translates to:
  /// **'Search unavailable offline'**
  String get searchHintOffline;

  /// No description provided for @searchRecentQuerySemantics.
  ///
  /// In en, this message translates to:
  /// **'Search {query}'**
  String searchRecentQuerySemantics(String query);

  /// No description provided for @searchRemoveRecentSemantics.
  ///
  /// In en, this message translates to:
  /// **'Remove {query}'**
  String searchRemoveRecentSemantics(String query);

  /// No description provided for @searchSemanticsArtist.
  ///
  /// In en, this message translates to:
  /// **'Artist, {name}'**
  String searchSemanticsArtist(String name);

  /// No description provided for @searchSemanticsAlbum.
  ///
  /// In en, this message translates to:
  /// **'Album, {title}, by {artist}'**
  String searchSemanticsAlbum(String title, String artist);

  /// No description provided for @searchSemanticsPlaylist.
  ///
  /// In en, this message translates to:
  /// **'Playlist, {title}, by {author}'**
  String searchSemanticsPlaylist(String title, String author);

  /// No description provided for @searchSemanticsTrack.
  ///
  /// In en, this message translates to:
  /// **'Track, {title}, by {artist}'**
  String searchSemanticsTrack(String title, String artist);

  /// No description provided for @browseTitle.
  ///
  /// In en, this message translates to:
  /// **'Browse'**
  String get browseTitle;

  /// No description provided for @browseYoutubeSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Search songs, artists, and albums'**
  String get browseYoutubeSubtitle;

  /// No description provided for @browseYoutubeSemantics.
  ///
  /// In en, this message translates to:
  /// **'Search YouTube Music'**
  String get browseYoutubeSemantics;

  /// No description provided for @browseDeviceSongs.
  ///
  /// In en, this message translates to:
  /// **'Device songs'**
  String get browseDeviceSongs;

  /// No description provided for @browseDeviceSongsSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Play audio stored on this device'**
  String get browseDeviceSongsSubtitle;

  /// No description provided for @browseDeviceSongsSemantics.
  ///
  /// In en, this message translates to:
  /// **'Open device songs'**
  String get browseDeviceSongsSemantics;

  /// No description provided for @browseRecentlyPlayed.
  ///
  /// In en, this message translates to:
  /// **'Recently played'**
  String get browseRecentlyPlayed;

  /// No description provided for @browseNothingPlayedTitle.
  ///
  /// In en, this message translates to:
  /// **'Nothing played yet'**
  String get browseNothingPlayedTitle;

  /// No description provided for @browseNothingPlayedSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Tracks you play will appear here'**
  String get browseNothingPlayedSubtitle;

  /// No description provided for @browseRecentlyPlayedError.
  ///
  /// In en, this message translates to:
  /// **'Could not load recently played'**
  String get browseRecentlyPlayedError;

  /// No description provided for @browseRecentlyPlayedErrorSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Check your library and try again'**
  String get browseRecentlyPlayedErrorSubtitle;

  /// No description provided for @browsePlayTrackSemantics.
  ///
  /// In en, this message translates to:
  /// **'Play {title} by {artist}'**
  String browsePlayTrackSemantics(String title, String artist);

  /// No description provided for @browseAlbumLoadError.
  ///
  /// In en, this message translates to:
  /// **'Could not load album'**
  String get browseAlbumLoadError;

  /// No description provided for @browseArtistLoadError.
  ///
  /// In en, this message translates to:
  /// **'Could not load artist'**
  String get browseArtistLoadError;

  /// No description provided for @browsePlaylistLoadError.
  ///
  /// In en, this message translates to:
  /// **'Could not load playlist'**
  String get browsePlaylistLoadError;

  /// No description provided for @browseUnknownArtist.
  ///
  /// In en, this message translates to:
  /// **'Unknown Artist'**
  String get browseUnknownArtist;

  /// No description provided for @browseUnknownAuthor.
  ///
  /// In en, this message translates to:
  /// **'Unknown Author'**
  String get browseUnknownAuthor;

  /// No description provided for @browseAddToPlaylist.
  ///
  /// In en, this message translates to:
  /// **'Add to playlist'**
  String get browseAddToPlaylist;

  /// No description provided for @browseNowPlaying.
  ///
  /// In en, this message translates to:
  /// **'Now playing'**
  String get browseNowPlaying;

  /// No description provided for @browseTrackOptions.
  ///
  /// In en, this message translates to:
  /// **'Track options'**
  String get browseTrackOptions;

  /// No description provided for @browseTopSongs.
  ///
  /// In en, this message translates to:
  /// **'Top Songs'**
  String get browseTopSongs;

  /// No description provided for @browseAlbums.
  ///
  /// In en, this message translates to:
  /// **'Albums'**
  String get browseAlbums;

  /// No description provided for @browseSinglesEps.
  ///
  /// In en, this message translates to:
  /// **'Singles & EPs'**
  String get browseSinglesEps;

  /// No description provided for @browsePlaylists.
  ///
  /// In en, this message translates to:
  /// **'Playlists'**
  String get browsePlaylists;

  /// No description provided for @commonTrackCount.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =0{0 tracks} =1{1 track} other{{count} tracks}}'**
  String commonTrackCount(int count);

  /// No description provided for @commonPlaylistCount.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =0{0 playlists} =1{1 playlist} other{{count} playlists}}'**
  String commonPlaylistCount(int count);

  /// No description provided for @commonMoreOptions.
  ///
  /// In en, this message translates to:
  /// **'More options'**
  String get commonMoreOptions;

  /// No description provided for @libraryTitle.
  ///
  /// In en, this message translates to:
  /// **'Your Library'**
  String get libraryTitle;

  /// No description provided for @libraryDownloadedCache.
  ///
  /// In en, this message translates to:
  /// **'Downloaded cache'**
  String get libraryDownloadedCache;

  /// No description provided for @libraryCustomPlaylists.
  ///
  /// In en, this message translates to:
  /// **'Custom playlists'**
  String get libraryCustomPlaylists;

  /// No description provided for @libraryDeviceSongs.
  ///
  /// In en, this message translates to:
  /// **'Device songs'**
  String get libraryDeviceSongs;

  /// No description provided for @libraryPinnedOfflineTracks.
  ///
  /// In en, this message translates to:
  /// **'Pinned offline tracks'**
  String get libraryPinnedOfflineTracks;

  /// No description provided for @libraryPinnedMeta.
  ///
  /// In en, this message translates to:
  /// **'{artist} · Pinned offline'**
  String libraryPinnedMeta(String artist);

  /// No description provided for @libraryListeningRecap.
  ///
  /// In en, this message translates to:
  /// **'Listening recap'**
  String get libraryListeningRecap;

  /// No description provided for @libraryListeningSummary.
  ///
  /// In en, this message translates to:
  /// **'Your listening summary'**
  String get libraryListeningSummary;

  /// No description provided for @libraryRecentlyPlayed.
  ///
  /// In en, this message translates to:
  /// **'Recently played'**
  String get libraryRecentlyPlayed;

  /// No description provided for @libraryListeningHistory.
  ///
  /// In en, this message translates to:
  /// **'Your listening history'**
  String get libraryListeningHistory;

  /// No description provided for @libraryEmptyTitle.
  ///
  /// In en, this message translates to:
  /// **'Your library is empty'**
  String get libraryEmptyTitle;

  /// No description provided for @libraryEmptySubtitle.
  ///
  /// In en, this message translates to:
  /// **'Scan the songs already on this device, or search for something new.'**
  String get libraryEmptySubtitle;

  /// No description provided for @libraryEmptyScanUnavailable.
  ///
  /// In en, this message translates to:
  /// **'Device scan is unavailable. Search music to start your library.'**
  String get libraryEmptyScanUnavailable;

  /// No description provided for @librarySearchMusic.
  ///
  /// In en, this message translates to:
  /// **'Search music'**
  String get librarySearchMusic;

  /// No description provided for @libraryScanDevice.
  ///
  /// In en, this message translates to:
  /// **'Scan device'**
  String get libraryScanDevice;

  /// No description provided for @libraryAutoPlaylistLabel.
  ///
  /// In en, this message translates to:
  /// **'AUTO-PLAYLIST'**
  String get libraryAutoPlaylistLabel;

  /// No description provided for @libraryLikedSongs.
  ///
  /// In en, this message translates to:
  /// **'Liked Songs'**
  String get libraryLikedSongs;

  /// No description provided for @libraryLikedMeta.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =0{Auto-playlist · 0 tracks} =1{Auto-playlist · 1 track} other{Auto-playlist · {count} tracks}}'**
  String libraryLikedMeta(int count);

  /// No description provided for @libraryLoadError.
  ///
  /// In en, this message translates to:
  /// **'Check your connection and try again.'**
  String get libraryLoadError;

  /// No description provided for @playlistsTitle.
  ///
  /// In en, this message translates to:
  /// **'Your playlists'**
  String get playlistsTitle;

  /// No description provided for @playlistsLoadError.
  ///
  /// In en, this message translates to:
  /// **'Failed to load playlists'**
  String get playlistsLoadError;

  /// No description provided for @playlistsNew.
  ///
  /// In en, this message translates to:
  /// **'New playlist'**
  String get playlistsNew;

  /// No description provided for @playlistsDurationMinutes.
  ///
  /// In en, this message translates to:
  /// **'{minutes} min'**
  String playlistsDurationMinutes(int minutes);

  /// No description provided for @playlistsDurationHoursMinutes.
  ///
  /// In en, this message translates to:
  /// **'{hours} hr {minutes} min'**
  String playlistsDurationHoursMinutes(int hours, int minutes);

  /// No description provided for @downloadedTitle.
  ///
  /// In en, this message translates to:
  /// **'Downloads'**
  String get downloadedTitle;

  /// No description provided for @downloadedStorageUsed.
  ///
  /// In en, this message translates to:
  /// **'Storage Used'**
  String get downloadedStorageUsed;

  /// No description provided for @downloadedStorageWarning.
  ///
  /// In en, this message translates to:
  /// **'Storage is almost full. Old unpinned tracks will be removed automatically.'**
  String get downloadedStorageWarning;

  /// No description provided for @downloadedEmptyTitle.
  ///
  /// In en, this message translates to:
  /// **'No downloaded tracks yet'**
  String get downloadedEmptyTitle;

  /// No description provided for @downloadedSemantics.
  ///
  /// In en, this message translates to:
  /// **'Downloaded'**
  String get downloadedSemantics;

  /// No description provided for @downloadedRemove.
  ///
  /// In en, this message translates to:
  /// **'Remove download'**
  String get downloadedRemove;

  /// No description provided for @downloadedLoadError.
  ///
  /// In en, this message translates to:
  /// **'Failed to load downloads'**
  String get downloadedLoadError;

  /// No description provided for @commonLoading.
  ///
  /// In en, this message translates to:
  /// **'Loading...'**
  String get commonLoading;

  /// No description provided for @commonError.
  ///
  /// In en, this message translates to:
  /// **'Error'**
  String get commonError;

  /// No description provided for @commonErrorWithMessage.
  ///
  /// In en, this message translates to:
  /// **'Error: {message}'**
  String commonErrorWithMessage(String message);

  /// No description provided for @commonDelete.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get commonDelete;

  /// No description provided for @commonCancelAction.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get commonCancelAction;

  /// No description provided for @commonTrackOptions.
  ///
  /// In en, this message translates to:
  /// **'Track options'**
  String get commonTrackOptions;

  /// No description provided for @commonUnknownAlbum.
  ///
  /// In en, this message translates to:
  /// **'Unknown Album'**
  String get commonUnknownAlbum;

  /// No description provided for @commonAlbumCount.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =0{0 albums} =1{1 album} other{{count} albums}}'**
  String commonAlbumCount(int count);

  /// No description provided for @commonTryDifferentKeywords.
  ///
  /// In en, this message translates to:
  /// **'Try different keywords'**
  String get commonTryDifferentKeywords;

  /// No description provided for @commonDurationHours.
  ///
  /// In en, this message translates to:
  /// **'{hours} hr'**
  String commonDurationHours(int hours);

  /// No description provided for @timeJustNow.
  ///
  /// In en, this message translates to:
  /// **'just now'**
  String get timeJustNow;

  /// No description provided for @timeMinutesAgo.
  ///
  /// In en, this message translates to:
  /// **'{count}m ago'**
  String timeMinutesAgo(int count);

  /// No description provided for @timeHoursAgo.
  ///
  /// In en, this message translates to:
  /// **'{count}h ago'**
  String timeHoursAgo(int count);

  /// No description provided for @timeDaysAgo.
  ///
  /// In en, this message translates to:
  /// **'{count}d ago'**
  String timeDaysAgo(int count);

  /// No description provided for @timeWeeksAgo.
  ///
  /// In en, this message translates to:
  /// **'{count}w ago'**
  String timeWeeksAgo(int count);

  /// No description provided for @timeMonthsAgo.
  ///
  /// In en, this message translates to:
  /// **'{count}mo ago'**
  String timeMonthsAgo(int count);

  /// No description provided for @timeYearsAgo.
  ///
  /// In en, this message translates to:
  /// **'{count}y ago'**
  String timeYearsAgo(int count);

  /// No description provided for @deviceSongsRescan.
  ///
  /// In en, this message translates to:
  /// **'Rescan'**
  String get deviceSongsRescan;

  /// No description provided for @deviceSongsScanFailed.
  ///
  /// In en, this message translates to:
  /// **'Scan failed. Try again.'**
  String get deviceSongsScanFailed;

  /// No description provided for @deviceSongsSearchInList.
  ///
  /// In en, this message translates to:
  /// **'Search in this list'**
  String get deviceSongsSearchInList;

  /// No description provided for @deviceSongsSearchHint.
  ///
  /// In en, this message translates to:
  /// **'Search songs, artists, albums'**
  String get deviceSongsSearchHint;

  /// No description provided for @deviceSongsLoadError.
  ///
  /// In en, this message translates to:
  /// **'Check storage permission and try again.'**
  String get deviceSongsLoadError;

  /// No description provided for @deviceSongsEmptyScannedTitle.
  ///
  /// In en, this message translates to:
  /// **'No songs found on device'**
  String get deviceSongsEmptyScannedTitle;

  /// No description provided for @deviceSongsEmptyScannedSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Search music instead, or scan again after adding files.'**
  String get deviceSongsEmptyScannedSubtitle;

  /// No description provided for @deviceSongsEmptyTitle.
  ///
  /// In en, this message translates to:
  /// **'No songs on this device yet'**
  String get deviceSongsEmptyTitle;

  /// No description provided for @deviceSongsEmptySubtitle.
  ///
  /// In en, this message translates to:
  /// **'Put MP3/M4A/FLAC files in the Music or Download folder, then pull to scan'**
  String get deviceSongsEmptySubtitle;

  /// No description provided for @deviceSongsScanNow.
  ///
  /// In en, this message translates to:
  /// **'Scan now'**
  String get deviceSongsScanNow;

  /// No description provided for @deviceSongsNoAlbums.
  ///
  /// In en, this message translates to:
  /// **'No albums'**
  String get deviceSongsNoAlbums;

  /// No description provided for @deviceSongsNoArtists.
  ///
  /// In en, this message translates to:
  /// **'No artists'**
  String get deviceSongsNoArtists;

  /// No description provided for @deviceSongsAddToQueue.
  ///
  /// In en, this message translates to:
  /// **'Add to queue'**
  String get deviceSongsAddToQueue;

  /// No description provided for @deviceSongsAddedToQueue.
  ///
  /// In en, this message translates to:
  /// **'Added to queue'**
  String get deviceSongsAddedToQueue;

  /// No description provided for @deviceSongsPlayNext.
  ///
  /// In en, this message translates to:
  /// **'Play next'**
  String get deviceSongsPlayNext;

  /// No description provided for @deviceSongsWillPlayNext.
  ///
  /// In en, this message translates to:
  /// **'Will play next'**
  String get deviceSongsWillPlayNext;

  /// No description provided for @deviceSongsPermissionTitle.
  ///
  /// In en, this message translates to:
  /// **'Allow access to audio'**
  String get deviceSongsPermissionTitle;

  /// No description provided for @deviceSongsPermissionMessage.
  ///
  /// In en, this message translates to:
  /// **'Voidz Music needs permission to scan audio files on this device.'**
  String get deviceSongsPermissionMessage;

  /// No description provided for @deviceSongsOpenSettings.
  ///
  /// In en, this message translates to:
  /// **'Open settings'**
  String get deviceSongsOpenSettings;

  /// No description provided for @deviceSongsAllowAccess.
  ///
  /// In en, this message translates to:
  /// **'Allow access'**
  String get deviceSongsAllowAccess;

  /// No description provided for @deviceSongsPermissionFootnote.
  ///
  /// In en, this message translates to:
  /// **'You can change this in system settings.'**
  String get deviceSongsPermissionFootnote;

  /// No description provided for @playlistDetailNotFound.
  ///
  /// In en, this message translates to:
  /// **'Playlist not found'**
  String get playlistDetailNotFound;

  /// No description provided for @playlistDetailTagline.
  ///
  /// In en, this message translates to:
  /// **'Your collection, your soundtrack'**
  String get playlistDetailTagline;

  /// No description provided for @playlistDetailOptions.
  ///
  /// In en, this message translates to:
  /// **'Playlist options'**
  String get playlistDetailOptions;

  /// No description provided for @playlistDetailPlayAll.
  ///
  /// In en, this message translates to:
  /// **'Play all'**
  String get playlistDetailPlayAll;

  /// No description provided for @playlistDetailRemoveTrack.
  ///
  /// In en, this message translates to:
  /// **'Remove from playlist'**
  String get playlistDetailRemoveTrack;

  /// No description provided for @playlistDetailReadOnly.
  ///
  /// In en, this message translates to:
  /// **'Read-only auto-playlist'**
  String get playlistDetailReadOnly;

  /// No description provided for @playlistDetailDelete.
  ///
  /// In en, this message translates to:
  /// **'Delete playlist'**
  String get playlistDetailDelete;

  /// No description provided for @playlistDetailDeleteTitle.
  ///
  /// In en, this message translates to:
  /// **'Delete Playlist?'**
  String get playlistDetailDeleteTitle;

  /// No description provided for @playlistDetailDeleteBody.
  ///
  /// In en, this message translates to:
  /// **'This playlist will be permanently deleted.'**
  String get playlistDetailDeleteBody;

  /// No description provided for @playlistDetailEmptyTitle.
  ///
  /// In en, this message translates to:
  /// **'Playlist is empty'**
  String get playlistDetailEmptyTitle;

  /// No description provided for @playlistDetailEmptySystemSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Tracks will appear here automatically'**
  String get playlistDetailEmptySystemSubtitle;

  /// No description provided for @playlistDetailEmptySubtitle.
  ///
  /// In en, this message translates to:
  /// **'Add songs to start listening'**
  String get playlistDetailEmptySubtitle;

  /// No description provided for @playlistDetailOverline.
  ///
  /// In en, this message translates to:
  /// **'PLAYLIST'**
  String get playlistDetailOverline;

  /// No description provided for @playlistDetailTracks.
  ///
  /// In en, this message translates to:
  /// **'TRACKS'**
  String get playlistDetailTracks;

  /// No description provided for @playlistDetailOwner.
  ///
  /// In en, this message translates to:
  /// **'You · {count, plural, =0{0 songs} =1{1 song} other{{count} songs}}'**
  String playlistDetailOwner(int count);

  /// No description provided for @playlistDetailUpdated.
  ///
  /// In en, this message translates to:
  /// **'updated {time}'**
  String playlistDetailUpdated(String time);

  /// No description provided for @recentlyPlayedLoadError.
  ///
  /// In en, this message translates to:
  /// **'Failed to load listening history'**
  String get recentlyPlayedLoadError;

  /// No description provided for @recentlyPlayedClear.
  ///
  /// In en, this message translates to:
  /// **'Clear history'**
  String get recentlyPlayedClear;

  /// No description provided for @recentlyPlayedClearSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Remove all listening history'**
  String get recentlyPlayedClearSubtitle;

  /// No description provided for @recentlyPlayedClearTitle.
  ///
  /// In en, this message translates to:
  /// **'Clear listening history?'**
  String get recentlyPlayedClearTitle;

  /// No description provided for @recentlyPlayedClearBody.
  ///
  /// In en, this message translates to:
  /// **'This permanently removes all play history and recently played tracks. Listening recap totals will change. Your play counts are kept.'**
  String get recentlyPlayedClearBody;

  /// No description provided for @recentlyPlayedSummary.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =0{0 unique tracks · last 30 days} =1{1 unique track · last 30 days} other{{count} unique tracks · last 30 days}}'**
  String recentlyPlayedSummary(int count);

  /// No description provided for @recentlyPlayedTracks.
  ///
  /// In en, this message translates to:
  /// **'Tracks'**
  String get recentlyPlayedTracks;

  /// No description provided for @recentlyPlayedOverline.
  ///
  /// In en, this message translates to:
  /// **'LISTENING HISTORY'**
  String get recentlyPlayedOverline;

  /// No description provided for @recentlyPlayedUniqueCount.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =0{0 unique tracks} =1{1 unique track} other{{count} unique tracks}}'**
  String recentlyPlayedUniqueCount(int count);

  /// No description provided for @recentlyPlayedWindow.
  ///
  /// In en, this message translates to:
  /// **'Last 30 days'**
  String get recentlyPlayedWindow;

  /// No description provided for @recentlyPlayedPlay.
  ///
  /// In en, this message translates to:
  /// **'Play recent'**
  String get recentlyPlayedPlay;

  /// No description provided for @recentlyPlayedEmptyTitle.
  ///
  /// In en, this message translates to:
  /// **'No listening history'**
  String get recentlyPlayedEmptyTitle;

  /// No description provided for @recentlyPlayedEmptySubtitle.
  ///
  /// In en, this message translates to:
  /// **'Tracks you play will appear here.'**
  String get recentlyPlayedEmptySubtitle;

  /// No description provided for @homeGreetingMorning.
  ///
  /// In en, this message translates to:
  /// **'Good Morning'**
  String get homeGreetingMorning;

  /// No description provided for @homeGreetingAfternoon.
  ///
  /// In en, this message translates to:
  /// **'Good Afternoon'**
  String get homeGreetingAfternoon;

  /// No description provided for @homeGreetingEvening.
  ///
  /// In en, this message translates to:
  /// **'Good Evening'**
  String get homeGreetingEvening;

  /// No description provided for @homeContinueListening.
  ///
  /// In en, this message translates to:
  /// **'Continue Listening'**
  String get homeContinueListening;

  /// No description provided for @homeNowListening.
  ///
  /// In en, this message translates to:
  /// **'Now Listening'**
  String get homeNowListening;

  /// No description provided for @homePauseTrack.
  ///
  /// In en, this message translates to:
  /// **'Pause {title}'**
  String homePauseTrack(String title);

  /// No description provided for @homeRecentlyPlayed.
  ///
  /// In en, this message translates to:
  /// **'Recently Played'**
  String get homeRecentlyPlayed;

  /// No description provided for @homeNoRecentTitle.
  ///
  /// In en, this message translates to:
  /// **'No recently played tracks'**
  String get homeNoRecentTitle;

  /// No description provided for @homeSearchMusic.
  ///
  /// In en, this message translates to:
  /// **'Search music'**
  String get homeSearchMusic;

  /// No description provided for @homeLoadError.
  ///
  /// In en, this message translates to:
  /// **'Unable to load'**
  String get homeLoadError;

  /// No description provided for @homeQuickDownloaded.
  ///
  /// In en, this message translates to:
  /// **'Downloaded'**
  String get homeQuickDownloaded;

  /// No description provided for @homeOfflineCache.
  ///
  /// In en, this message translates to:
  /// **'Offline cache'**
  String get homeOfflineCache;

  /// No description provided for @homeDeviceSongs.
  ///
  /// In en, this message translates to:
  /// **'Device songs'**
  String get homeDeviceSongs;

  /// No description provided for @homeOnThisDevice.
  ///
  /// In en, this message translates to:
  /// **'On this device'**
  String get homeOnThisDevice;

  /// No description provided for @homePlayTrack.
  ///
  /// In en, this message translates to:
  /// **'Play {title}'**
  String homePlayTrack(String title);

  /// No description provided for @dailyMixLabel.
  ///
  /// In en, this message translates to:
  /// **'Daily Mix'**
  String get dailyMixLabel;

  /// No description provided for @dailyMixBadge.
  ///
  /// In en, this message translates to:
  /// **'MIX {number}'**
  String dailyMixBadge(String number);

  /// No description provided for @dailyMixSemantics.
  ///
  /// In en, this message translates to:
  /// **'Daily Mix {mood}'**
  String dailyMixSemantics(String mood);

  /// No description provided for @dailyMixTrackCount.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =0{0 tracks · Daily Mix} =1{1 track · Daily Mix} other{{count} tracks · Daily Mix}}'**
  String dailyMixTrackCount(int count);

  /// No description provided for @dailyMixPlayAll.
  ///
  /// In en, this message translates to:
  /// **'Play all'**
  String get dailyMixPlayAll;

  /// No description provided for @dailyMixEmptyTitle.
  ///
  /// In en, this message translates to:
  /// **'No tracks for {mood}'**
  String dailyMixEmptyTitle(String mood);

  /// No description provided for @dailyMixEmptySubtitle.
  ///
  /// In en, this message translates to:
  /// **'Search for music or scan your device library.'**
  String get dailyMixEmptySubtitle;

  /// No description provided for @dailyMixSearch.
  ///
  /// In en, this message translates to:
  /// **'Search'**
  String get dailyMixSearch;

  /// No description provided for @dailyMixScanDevice.
  ///
  /// In en, this message translates to:
  /// **'Scan device songs'**
  String get dailyMixScanDevice;

  /// No description provided for @dailyMixLoadError.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t load this mix. Check your connection and try again.'**
  String get dailyMixLoadError;

  /// No description provided for @recapTitle.
  ///
  /// In en, this message translates to:
  /// **'Recap'**
  String get recapTitle;

  /// No description provided for @recapEmptyTitle.
  ///
  /// In en, this message translates to:
  /// **'No recap for {period}'**
  String recapEmptyTitle(String period);

  /// No description provided for @recapEmptySubtitle.
  ///
  /// In en, this message translates to:
  /// **'Play some songs first — your recap will appear here.\nHistory keeps up to 10,000 plays.'**
  String get recapEmptySubtitle;

  /// No description provided for @recapLoadError.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t load your recap. Check your connection and try again.'**
  String get recapLoadError;

  /// No description provided for @recapTopSongsTitle.
  ///
  /// In en, this message translates to:
  /// **'Top 5 Songs'**
  String get recapTopSongsTitle;

  /// No description provided for @recapTopSongsSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Most played {period}'**
  String recapTopSongsSubtitle(String period);

  /// No description provided for @recapTopArtistsTitle.
  ///
  /// In en, this message translates to:
  /// **'Top 5 Artists'**
  String get recapTopArtistsTitle;

  /// No description provided for @recapTopArtistsSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Your top artists'**
  String get recapTopArtistsSubtitle;

  /// No description provided for @recapTopAlbumsTitle.
  ///
  /// In en, this message translates to:
  /// **'Top 5 Albums'**
  String get recapTopAlbumsTitle;

  /// No description provided for @recapTopAlbumsSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Most played albums'**
  String get recapTopAlbumsSubtitle;

  /// No description provided for @recapMostPlayedBadge.
  ///
  /// In en, this message translates to:
  /// **'#1 MOST PLAYED {period}'**
  String recapMostPlayedBadge(String period);

  /// No description provided for @recapTimesPlayed.
  ///
  /// In en, this message translates to:
  /// **'{count}× played'**
  String recapTimesPlayed(int count);

  /// No description provided for @recapStatTotalPlays.
  ///
  /// In en, this message translates to:
  /// **'Total plays'**
  String get recapStatTotalPlays;

  /// No description provided for @recapStatUniqueSongs.
  ///
  /// In en, this message translates to:
  /// **'Unique songs'**
  String get recapStatUniqueSongs;

  /// No description provided for @recapStatYear.
  ///
  /// In en, this message translates to:
  /// **'Year'**
  String get recapStatYear;

  /// No description provided for @recapPeriodMonth.
  ///
  /// In en, this message translates to:
  /// **'Month'**
  String get recapPeriodMonth;

  /// No description provided for @recapPeriodYear.
  ///
  /// In en, this message translates to:
  /// **'Year'**
  String get recapPeriodYear;

  /// No description provided for @recapYearPhrase.
  ///
  /// In en, this message translates to:
  /// **'in {year}'**
  String recapYearPhrase(int year);

  /// No description provided for @recapSelectMonth.
  ///
  /// In en, this message translates to:
  /// **'Select month'**
  String get recapSelectMonth;

  /// No description provided for @recapSelectYear.
  ///
  /// In en, this message translates to:
  /// **'Select year'**
  String get recapSelectYear;

  /// No description provided for @lyricsHeader.
  ///
  /// In en, this message translates to:
  /// **'LYRICS'**
  String get lyricsHeader;

  /// No description provided for @lyricsSyncedBadge.
  ///
  /// In en, this message translates to:
  /// **'Synced'**
  String get lyricsSyncedBadge;

  /// No description provided for @lyricsNotFoundTitle.
  ///
  /// In en, this message translates to:
  /// **'No lyrics found'**
  String get lyricsNotFoundTitle;

  /// No description provided for @lyricsNotFoundMessage.
  ///
  /// In en, this message translates to:
  /// **'LRCLIB has no lyrics for this track. Instrumental tracks never show lyrics.'**
  String get lyricsNotFoundMessage;

  /// No description provided for @lyricsRetry.
  ///
  /// In en, this message translates to:
  /// **'Retry'**
  String get lyricsRetry;

  /// No description provided for @lyricsNotFoundFootnote.
  ///
  /// In en, this message translates to:
  /// **'Playback continues without lyrics.'**
  String get lyricsNotFoundFootnote;

  /// No description provided for @lyricsEmpty.
  ///
  /// In en, this message translates to:
  /// **'Lyrics are empty'**
  String get lyricsEmpty;

  /// No description provided for @lyricsEmptySyncedMessage.
  ///
  /// In en, this message translates to:
  /// **'This LRC file has no lines. Playback continues without lyrics.'**
  String get lyricsEmptySyncedMessage;

  /// No description provided for @lyricsLineSemantics.
  ///
  /// In en, this message translates to:
  /// **'{time} — {text}'**
  String lyricsLineSemantics(String time, String text);

  /// No description provided for @lyricsLoadError.
  ///
  /// In en, this message translates to:
  /// **'Lyrics are unavailable right now.'**
  String get lyricsLoadError;

  /// No description provided for @lyricsFooterSynced.
  ///
  /// In en, this message translates to:
  /// **'Synced lyrics · LRCLIB'**
  String get lyricsFooterSynced;

  /// No description provided for @lyricsFooterPlain.
  ///
  /// In en, this message translates to:
  /// **'Lyrics · LRCLIB'**
  String get lyricsFooterPlain;

  /// No description provided for @playlistAddSheetTitle.
  ///
  /// In en, this message translates to:
  /// **'Add to Playlist'**
  String get playlistAddSheetTitle;

  /// No description provided for @playlistNoneYet.
  ///
  /// In en, this message translates to:
  /// **'No custom playlists found.'**
  String get playlistNoneYet;

  /// No description provided for @playlistCreateNew.
  ///
  /// In en, this message translates to:
  /// **'Create New Playlist'**
  String get playlistCreateNew;

  /// No description provided for @playlistNewTitle.
  ///
  /// In en, this message translates to:
  /// **'New Playlist'**
  String get playlistNewTitle;

  /// No description provided for @playlistNameHint.
  ///
  /// In en, this message translates to:
  /// **'Playlist name'**
  String get playlistNameHint;

  /// No description provided for @playlistCreate.
  ///
  /// In en, this message translates to:
  /// **'Create'**
  String get playlistCreate;

  /// No description provided for @playlistCreateAndAdd.
  ///
  /// In en, this message translates to:
  /// **'Create & Add'**
  String get playlistCreateAndAdd;

  /// No description provided for @playlistAlreadyIn.
  ///
  /// In en, this message translates to:
  /// **'Already in {name}'**
  String playlistAlreadyIn(String name);

  /// No description provided for @playlistAddedTo.
  ///
  /// In en, this message translates to:
  /// **'Added to {name}'**
  String playlistAddedTo(String name);

  /// No description provided for @playlistAddedMany.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{Added 1 track to {name}} other{Added {count} tracks to {name}}}'**
  String playlistAddedMany(int count, String name);

  /// No description provided for @playlistAlreadyExisted.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 already existed} other{{count} already existed}}'**
  String playlistAlreadyExisted(int count);

  /// No description provided for @playerPlayingFrom.
  ///
  /// In en, this message translates to:
  /// **'PLAYING FROM'**
  String get playerPlayingFrom;

  /// No description provided for @playerClose.
  ///
  /// In en, this message translates to:
  /// **'Close player'**
  String get playerClose;

  /// No description provided for @playerSleepTimer.
  ///
  /// In en, this message translates to:
  /// **'Sleep Timer'**
  String get playerSleepTimer;

  /// No description provided for @playerLike.
  ///
  /// In en, this message translates to:
  /// **'Like'**
  String get playerLike;

  /// No description provided for @playerUnlike.
  ///
  /// In en, this message translates to:
  /// **'Unlike'**
  String get playerUnlike;

  /// No description provided for @playerPrevious.
  ///
  /// In en, this message translates to:
  /// **'Previous'**
  String get playerPrevious;

  /// No description provided for @playerNext.
  ///
  /// In en, this message translates to:
  /// **'Next'**
  String get playerNext;

  /// No description provided for @playerPause.
  ///
  /// In en, this message translates to:
  /// **'Pause'**
  String get playerPause;

  /// No description provided for @playerRepeat.
  ///
  /// In en, this message translates to:
  /// **'Repeat'**
  String get playerRepeat;

  /// No description provided for @playerRepeatOne.
  ///
  /// In en, this message translates to:
  /// **'Repeat one'**
  String get playerRepeatOne;

  /// No description provided for @playerArtworkSemantics.
  ///
  /// In en, this message translates to:
  /// **'Artwork for {title}'**
  String playerArtworkSemantics(String title);

  /// No description provided for @playerDockLyrics.
  ///
  /// In en, this message translates to:
  /// **'Lyrics'**
  String get playerDockLyrics;

  /// No description provided for @playerDockQueue.
  ///
  /// In en, this message translates to:
  /// **'Queue ({count})'**
  String playerDockQueue(int count);

  /// No description provided for @playerDockTimer.
  ///
  /// In en, this message translates to:
  /// **'Timer'**
  String get playerDockTimer;

  /// No description provided for @playerPlaybackFailed.
  ///
  /// In en, this message translates to:
  /// **'Playback failed'**
  String get playerPlaybackFailed;

  /// No description provided for @playerStreamUnavailable.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t resolve the stream.'**
  String get playerStreamUnavailable;

  /// No description provided for @playerRetry.
  ///
  /// In en, this message translates to:
  /// **'Retry'**
  String get playerRetry;

  /// No description provided for @playerOfflineArtist.
  ///
  /// In en, this message translates to:
  /// **'Offline mode: Cannot load artist'**
  String get playerOfflineArtist;

  /// No description provided for @playerArtistNotFound.
  ///
  /// In en, this message translates to:
  /// **'Artist page not found'**
  String get playerArtistNotFound;

  /// No description provided for @playerArtistLoadError.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t load artist. Check your connection and try again.'**
  String get playerArtistLoadError;

  /// No description provided for @playerOfflineAlbum.
  ///
  /// In en, this message translates to:
  /// **'Offline mode: Cannot load album'**
  String get playerOfflineAlbum;

  /// No description provided for @playerAlbumNotFound.
  ///
  /// In en, this message translates to:
  /// **'Album page not found'**
  String get playerAlbumNotFound;

  /// No description provided for @playerAlbumLoadError.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t load album. Check your connection and try again.'**
  String get playerAlbumLoadError;

  /// No description provided for @queueTitle.
  ///
  /// In en, this message translates to:
  /// **'Queue'**
  String get queueTitle;

  /// No description provided for @queueClear.
  ///
  /// In en, this message translates to:
  /// **'Clear'**
  String get queueClear;

  /// No description provided for @queueEmpty.
  ///
  /// In en, this message translates to:
  /// **'Queue is empty'**
  String get queueEmpty;

  /// No description provided for @queueSummary.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =0{0 songs} =1{1 song} other{{count} songs}} · {duration}'**
  String queueSummary(int count, String duration);

  /// No description provided for @queueNowPlaying.
  ///
  /// In en, this message translates to:
  /// **'NOW PLAYING'**
  String get queueNowPlaying;

  /// No description provided for @queueUpNext.
  ///
  /// In en, this message translates to:
  /// **'UP NEXT'**
  String get queueUpNext;

  /// No description provided for @queueDragHint.
  ///
  /// In en, this message translates to:
  /// **'Drag to reorder · Swipe to remove'**
  String get queueDragHint;

  /// No description provided for @queueDragToReorder.
  ///
  /// In en, this message translates to:
  /// **'Drag to reorder'**
  String get queueDragToReorder;

  /// No description provided for @queueClearTitle.
  ///
  /// In en, this message translates to:
  /// **'Clear queue?'**
  String get queueClearTitle;

  /// No description provided for @queueClearBody.
  ///
  /// In en, this message translates to:
  /// **'Remove {count, plural, =1{1 song} other{{count} songs}} from Up Next? The current track keeps playing.'**
  String queueClearBody(int count);

  /// No description provided for @queueCleared.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 song removed} other{{count} songs removed}}'**
  String queueCleared(int count);

  /// No description provided for @queueUndo.
  ///
  /// In en, this message translates to:
  /// **'Undo'**
  String get queueUndo;

  /// No description provided for @queueRemoveTrack.
  ///
  /// In en, this message translates to:
  /// **'Remove from queue'**
  String get queueRemoveTrack;

  /// No description provided for @queueRemovedFromPlaylist.
  ///
  /// In en, this message translates to:
  /// **'Removed from {name}'**
  String queueRemovedFromPlaylist(String name);

  /// No description provided for @sleepTimerTitle.
  ///
  /// In en, this message translates to:
  /// **'Sleep timer'**
  String get sleepTimerTitle;

  /// No description provided for @sleepTimerSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Playback stops automatically'**
  String get sleepTimerSubtitle;

  /// No description provided for @sleepTimerMinutes.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 minute} other{{count} minutes}}'**
  String sleepTimerMinutes(int count);

  /// No description provided for @sleepTimerEndOfTrack.
  ///
  /// In en, this message translates to:
  /// **'End of track'**
  String get sleepTimerEndOfTrack;

  /// No description provided for @sleepTimerActive.
  ///
  /// In en, this message translates to:
  /// **'Timer Active'**
  String get sleepTimerActive;

  /// No description provided for @sleepTimerRemaining.
  ///
  /// In en, this message translates to:
  /// **'{time} remaining'**
  String sleepTimerRemaining(String time);

  /// No description provided for @commonSelected.
  ///
  /// In en, this message translates to:
  /// **'Selected'**
  String get commonSelected;

  /// No description provided for @commonLoadErrorTitle.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t load results'**
  String get commonLoadErrorTitle;

  /// No description provided for @commonRetryAction.
  ///
  /// In en, this message translates to:
  /// **'Retry'**
  String get commonRetryAction;

  /// No description provided for @commonOfflineTitle.
  ///
  /// In en, this message translates to:
  /// **'You\'re offline'**
  String get commonOfflineTitle;

  /// No description provided for @commonOfflinePlayingDownloaded.
  ///
  /// In en, this message translates to:
  /// **'Playing downloaded songs'**
  String get commonOfflinePlayingDownloaded;

  /// No description provided for @commonNowPlaying.
  ///
  /// In en, this message translates to:
  /// **'Now playing'**
  String get commonNowPlaying;

  /// No description provided for @commonDownloaded.
  ///
  /// In en, this message translates to:
  /// **'Downloaded'**
  String get commonDownloaded;

  /// No description provided for @shellTabHome.
  ///
  /// In en, this message translates to:
  /// **'Home'**
  String get shellTabHome;

  /// No description provided for @shellTabSearch.
  ///
  /// In en, this message translates to:
  /// **'Search'**
  String get shellTabSearch;

  /// No description provided for @shellTabLibrary.
  ///
  /// In en, this message translates to:
  /// **'Library'**
  String get shellTabLibrary;

  /// No description provided for @miniPlayerOpen.
  ///
  /// In en, this message translates to:
  /// **'Open player'**
  String get miniPlayerOpen;

  /// No description provided for @miniPlayerProgress.
  ///
  /// In en, this message translates to:
  /// **'Playback position'**
  String get miniPlayerProgress;

  /// No description provided for @miniPlayerDismissHint.
  ///
  /// In en, this message translates to:
  /// **'Swipe left or right to dismiss'**
  String get miniPlayerDismissHint;

  /// No description provided for @miniPlayerDismiss.
  ///
  /// In en, this message translates to:
  /// **'Dismiss player'**
  String get miniPlayerDismiss;

  /// No description provided for @errorRouteNotFoundTitle.
  ///
  /// In en, this message translates to:
  /// **'Page not found'**
  String get errorRouteNotFoundTitle;

  /// No description provided for @errorRouteNotFoundMessage.
  ///
  /// In en, this message translates to:
  /// **'We couldn\'t find that page. It may have moved or no longer exists.'**
  String get errorRouteNotFoundMessage;

  /// No description provided for @errorRouteGoHome.
  ///
  /// In en, this message translates to:
  /// **'Go Home'**
  String get errorRouteGoHome;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'id'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'id':
      return AppLocalizationsId();
  }

  throw FlutterError(
      'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
      'an issue with the localizations generation tool. Please file an issue '
      'on GitHub with a reproducible sample app and the gen-l10n configuration '
      'that was used.');
}
