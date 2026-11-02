import 'dart:convert';
import 'dart:io';

/// Error dari YouTube Music InnerTube.
class YoutubeMusicException implements Exception {
  final String message;

  const YoutubeMusicException(this.message);

  @override
  String toString() => 'YoutubeMusicException: $message';
}

/// Klien YouTube Music InnerTube minimal, tanpa backend dan tanpa API key.
///
/// Semua request memakai client `WEB_REMIX` yang sama seperti web player.
/// Parser dibuat longgar: kalau satu item rusak, item itu dilewati dan
/// hasil lain tetap dipakai.
class YoutubeMusicService {
  YoutubeMusicService({HttpClient? client}) : _client = client ?? HttpClient() {
    _client.connectionTimeout = const Duration(seconds: 15);
    _client.idleTimeout = const Duration(seconds: 30);
    _client.autoUncompress = true;
  }

  final HttpClient _client;
  String? _visitorData;

  static const _baseUrl = 'https://music.youtube.com/youtubei/v1';
  static const _userAgent =
      'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 '
      '(KHTML, like Gecko) Chrome/140.0.0.0 Safari/537.36';

  static const _searchParams = <String, String?>{
    'top': null,
    'songs': 'EgWKAQIIAWoMEA4QChADEAQQCRAF',
    'artists': 'EgWKAQIgAWoMEA4QChADEAQQCRAF',
    'albums': 'EgWKAQIYAWoMEA4QChADEAQQCRAF',
    'playlists': 'Eg-KAQwIABAAGAAgACgBMABqChAEEAMQCRAFEAo%3D',
  };

  /// Cari lagu, artis, album, playlist, atau campuran (top).
  Future<List<Map<String, dynamic>>> search(
    String query, {
    String filter = 'top',
    int limit = 20,
  }) async {
    final body = <String, dynamic>{'query': query};
    final params = _searchParams[filter] ?? _searchParams['top'];
    if (params != null) body['params'] = params;

    var response = await _post('search', body);
    final results = <Map<String, dynamic>>[];
    _appendSearchResults(response, filter, results);

    var pages = 1;
    while (results.length < limit && pages < 6) {
      final token = _findContinuation(response);
      if (token == null) break;
      response = await _post('search', {'continuation': token});
      _appendContinuationResults(response, filter, results);
      pages++;
    }
    return results.take(limit).toList();
  }

  /// Detail artis berdasarkan browseId (`UC...`).
  Future<Map<String, dynamic>> getArtist(String browseId) async {
    final response = await _post('browse', {'browseId': browseId});
    return _parseArtist(response, browseId);
  }

  /// Detail album berdasarkan browseId (`MPRE...`).
  Future<Map<String, dynamic>> getAlbum(String browseId) async {
    final response = await _post('browse', {'browseId': browseId});
    return _parseAlbum(response, browseId);
  }

  /// Detail playlist berdasarkan browseId (`VL...`).
  Future<Map<String, dynamic>> getPlaylist(String browseId) async {
    final response = await _post('browse', {'browseId': browseId});
    return _parsePlaylist(response, browseId);
  }

  /// Rekomendasi lagu berikutnya untuk sebuah video.
  Future<List<Map<String, dynamic>>> getUpNext(String videoId) async {
    final response = await _post('next', {
      'videoId': videoId,
      'playlistId': 'RDAMVM$videoId',
      'enablePersistentPlaylistPanel': true,
      'isAudioOnly': true,
      'tunerSettingValue': 'AUTOMIX_SETTING_NORMAL',
      'watchEndpointMusicSupportedConfigs': {
        'watchEndpointMusicConfig': {
          'hasPersistentPlaylistPanel': true,
          'musicVideoType': 'MUSIC_VIDEO_TYPE_ATV',
        },
      },
    });
    return _parseUpNext(response, videoId);
  }

  void close() => _client.close(force: true);

  // ---------------------------------------------------------------------------
  // Parser entry points (dipakai unit test)
  // ---------------------------------------------------------------------------

  List<Map<String, dynamic>> parseSearchResponse(
    Map<String, dynamic> response,
    String filter,
  ) {
    final results = <Map<String, dynamic>>[];
    _appendSearchResults(response, filter, results);
    return results;
  }

  Map<String, dynamic> parseArtistResponse(
    Map<String, dynamic> response,
    String browseId,
  ) =>
      _parseArtist(response, browseId);

  Map<String, dynamic> parseAlbumResponse(
    Map<String, dynamic> response,
    String browseId,
  ) =>
      _parseAlbum(response, browseId);

  Map<String, dynamic> parsePlaylistResponse(
    Map<String, dynamic> response,
    String browseId,
  ) =>
      _parsePlaylist(response, browseId);

  List<Map<String, dynamic>> parseUpNextResponse(
    Map<String, dynamic> response,
    String seedVideoId,
  ) =>
      _parseUpNext(response, seedVideoId);

  // ---------------------------------------------------------------------------
  // HTTP
  // ---------------------------------------------------------------------------

  Future<Map<String, dynamic>> _post(
    String endpoint,
    Map<String, dynamic> body,
  ) async {
    final clientVersion = _clientVersion();
    final payload = <String, dynamic>{
      'context': {
        'client': {
          'clientName': 'WEB_REMIX',
          'clientVersion': clientVersion,
          'hl': 'en',
          'gl': 'US',
        },
        'user': <String, dynamic>{},
      },
      ...body,
    };

    final request = await _client
        .postUrl(Uri.parse('$_baseUrl/$endpoint?prettyPrint=false&alt=json'));
    request.headers
      ..set(HttpHeaders.contentTypeHeader, 'application/json')
      ..set(HttpHeaders.userAgentHeader, _userAgent)
      ..set(HttpHeaders.acceptHeader, '*/*')
      ..set(HttpHeaders.acceptLanguageHeader, 'en-US,en;q=0.9')
      ..set('origin', 'https://music.youtube.com')
      ..set('referer', 'https://music.youtube.com/')
      ..set('x-youtube-client-name', '67')
      ..set('x-youtube-client-version', clientVersion);
    final visitorData = _visitorData;
    if (visitorData != null && visitorData.isNotEmpty) {
      request.headers.set('x-goog-visitor-id', visitorData);
    }
    request.write(jsonEncode(payload));

    final response = await request.close();
    final text = await response.transform(utf8.decoder).join();
    if (response.statusCode != HttpStatus.ok) {
      throw YoutubeMusicException(
        'HTTP ${response.statusCode} pada $endpoint',
      );
    }

    final decoded = jsonDecode(text);
    if (decoded is! Map<String, dynamic>) {
      throw YoutubeMusicException('Respons $endpoint bukan object JSON');
    }
    final responseVisitor = _asMap(decoded['responseContext'])?['visitorData'];
    if (responseVisitor is String && responseVisitor.isNotEmpty) {
      _visitorData = responseVisitor;
    }
    return decoded;
  }

  static String _clientVersion() {
    final now = DateTime.now().toUtc();
    final month = now.month.toString().padLeft(2, '0');
    final day = now.day.toString().padLeft(2, '0');
    return '1.${now.year}$month$day.01.00';
  }

  // ---------------------------------------------------------------------------
  // Search
  // ---------------------------------------------------------------------------

  void _appendSearchResults(
    Map<String, dynamic> response,
    String filter,
    List<Map<String, dynamic>> out,
  ) {
    final sections = _searchSections(response);
    for (final section in sections) {
      final shelf = _asMap(section['musicShelfRenderer']);
      final itemSection = _asMap(section['itemSectionRenderer']);
      final card = _asMap(section['musicCardShelfRenderer']);
      final items = <Map<String, dynamic>>[
        ..._listOfMaps(shelf?['contents']),
        ..._listOfMaps(itemSection?['contents']),
        ..._listOfMaps(card?['contents']),
      ];
      for (final item in items) {
        final parsed = _parseSearchItem(item, filter);
        if (parsed != null) _addUnique(out, parsed);
      }
    }
  }

  void _appendContinuationResults(
    Map<String, dynamic> response,
    String filter,
    List<Map<String, dynamic>> out,
  ) {
    final contents = _asMap(response['continuationContents']);
    final shelf = _asMap(contents?['musicShelfContinuation']) ??
        _asMap(contents?['musicPlaylistShelfContinuation']);
    for (final item in _listOfMaps(shelf?['contents'])) {
      final parsed = _parseSearchItem(item, filter);
      if (parsed != null) _addUnique(out, parsed);
    }
  }

  List<Map<String, dynamic>> _searchSections(Map<String, dynamic> response) {
    final tabs = _asMap(response['contents'])?['tabbedSearchResultsRenderer'];
    final tabList = _listOfMaps(_asMap(tabs)?['tabs']);
    if (tabList.isEmpty) return const [];
    final content = _asMap(_asMap(tabList.first['tabRenderer'])?['content']);
    return _listOfMaps(_asMap(content?['sectionListRenderer'])?['contents']);
  }

  Map<String, dynamic>? _parseSearchItem(
    Map<String, dynamic> wrapper,
    String filter,
  ) {
    final renderer = _asMap(wrapper['musicResponsiveListItemRenderer']) ??
        _asMap(wrapper['musicTwoRowItemRenderer']) ??
        _asMap(wrapper['musicCardShelfRenderer']);
    if (renderer == null) return null;

    final title = _text(renderer['title']) ?? _firstFlexText(renderer);
    if (title == null || title.isEmpty) return null;

    final pageType = _pageType(renderer);
    final videoId = _videoId(renderer);
    final browseId = _browseId(renderer);
    final thumbnail = _thumbnailUrl(renderer);
    final subtitleRuns = _subtitleRuns(renderer);

    final type = _resolveResultType(
      filter: filter,
      pageType: pageType,
      videoId: videoId,
      browseId: browseId,
      subtitleRuns: subtitleRuns,
    );

    switch (type) {
      case 'song':
        if (videoId == null || videoId.isEmpty) return null;
        final artists = _artistNames(subtitleRuns);
        final album = _albumName(subtitleRuns);
        return {
          'result_type': 'song',
          'source_id': videoId,
          'title': title,
          'artist': artists.isEmpty ? 'Unknown Artist' : artists.join(', '),
          if (album != null) 'album': album,
          'duration_ms': _durationMsFromRuns(subtitleRuns),
          if (thumbnail != null) 'thumbnail_url': thumbnail,
          'source': 'youtube',
        };
      case 'artist':
        if (browseId == null || browseId.isEmpty) return null;
        final subscribers = _lastMeaningfulRun(subtitleRuns);
        return {
          'result_type': 'artist',
          'browse_id': browseId,
          'name': title,
          if (thumbnail != null) 'thumbnail_url': thumbnail,
          if (subscribers != null) 'subscribers': subscribers,
        };
      case 'album':
        if (browseId == null || browseId.isEmpty) return null;
        final artists = _artistNames(subtitleRuns);
        return {
          'result_type': 'album',
          'browse_id': browseId,
          'title': title,
          if (artists.isNotEmpty) 'artist': artists.join(', '),
          if (_yearFromRuns(subtitleRuns) != null)
            'year': _yearFromRuns(subtitleRuns),
          if (thumbnail != null) 'thumbnail_url': thumbnail,
        };
      case 'playlist':
        if (browseId == null || browseId.isEmpty) return null;
        final author = _firstMeaningfulRun(subtitleRuns);
        return {
          'result_type': 'playlist',
          'browse_id': browseId,
          'title': title,
          if (author != null) 'author': author,
          if (thumbnail != null) 'thumbnail_url': thumbnail,
        };
    }
    return null;
  }

  String _resolveResultType({
    required String filter,
    required String? pageType,
    required String? videoId,
    required String? browseId,
    required List<Map<String, dynamic>> subtitleRuns,
  }) {
    if (filter == 'songs') return 'song';
    if (filter == 'artists') return 'artist';
    if (filter == 'albums') return 'album';
    if (filter == 'playlists') return 'playlist';

    // Top: klasifikasikan dari pageType / label subtitle / prefix browseId.
    if (pageType == 'MUSIC_PAGE_TYPE_ARTIST' ||
        pageType == 'MUSIC_PAGE_TYPE_USER_CHANNEL') {
      return 'artist';
    }
    if (pageType == 'MUSIC_PAGE_TYPE_ALBUM') return 'album';
    if (pageType == 'MUSIC_PAGE_TYPE_PLAYLIST') return 'playlist';
    if (pageType == 'MUSIC_PAGE_TYPE_NON_MUSIC_AUDIO_TRACK_PAGE') {
      return 'episode';
    }
    final label = _firstMeaningfulRun(subtitleRuns)?.toLowerCase();
    if (label == 'episode' || label == 'podcast') return 'episode';
    if (videoId != null && videoId.isNotEmpty) return 'song';

    if (label == 'artist' || label == 'profile') return 'artist';
    if (label == 'album' || label == 'single' || label == 'ep') return 'album';
    if (label == 'playlist') return 'playlist';
    if (browseId != null) {
      if (browseId.startsWith('UC')) return 'artist';
      if (browseId.startsWith('MPRE')) return 'album';
      if (browseId.startsWith('VL')) return 'playlist';
    }
    return 'song';
  }

  // ---------------------------------------------------------------------------
  // Artist
  // ---------------------------------------------------------------------------

  Map<String, dynamic> _parseArtist(
    Map<String, dynamic> response,
    String browseId,
  ) {
    final header =
        _asMap(response['header'])?['musicImmersiveHeaderRenderer'] ??
            _asMap(response['header'])?['musicVisualHeaderRenderer'];
    final headerMap = _asMap(header);
    final pageSections = _browseSections(response, singleColumn: true);

    final name = _text(headerMap?['title']) ?? '';
    final description = _artistDescription(headerMap, pageSections);
    final subscribers = _text(headerMap?['monthlyListenerCount']) ??
        _text(_asMap(_asMap(headerMap?['subscriptionButton'])?[
            'subscribeButtonRenderer'])?['subscriberCountText']) ??
        _text(headerMap?['subscriberCountText']);
    final thumbnail = _thumbnailUrl(headerMap) ??
        _thumbnailUrl(
            _asMap(response['microformat'])?['microformatDataRenderer']);

    final topSongs = <Map<String, dynamic>>[];
    final albums = <Map<String, dynamic>>[];
    final singles = <Map<String, dynamic>>[];
    final playlists = <Map<String, dynamic>>[];

    for (final section in pageSections) {
      final shelf = _asMap(section['musicShelfRenderer']);
      if (shelf != null) {
        for (final item in _listOfMaps(shelf['contents'])) {
          final track = _parseTrackItem(item);
          if (track != null) _addUnique(topSongs, track);
        }
        continue;
      }

      final carousel = _asMap(section['musicCarouselShelfRenderer']);
      if (carousel == null) continue;
      final title = (_carouselTitle(carousel) ?? '').toLowerCase();
      final items = _listOfMaps(carousel['contents']);
      for (final item in items) {
        final renderer = _asMap(item['musicTwoRowItemRenderer']);
        if (renderer == null) continue;
        if (title.contains('single') || title.contains('ep')) {
          final album = _parseCarouselAlbum(renderer);
          if (album != null) _addUnique(singles, album);
        } else if (title.contains('playlist')) {
          final playlist = _parseCarouselPlaylist(renderer);
          if (playlist != null) _addUnique(playlists, playlist);
        } else if (title.contains('album') || title.contains('release')) {
          final album = _parseCarouselAlbum(renderer);
          if (album != null) _addUnique(albums, album);
        }
      }
    }

    return {
      'browse_id': browseId,
      'name': name.isEmpty ? 'Unknown Artist' : name,
      if (description != null) 'description': description,
      if (subscribers != null) 'subscribers': subscribers,
      if (thumbnail != null) 'thumbnail_url': thumbnail,
      'top_songs': topSongs,
      'albums': albums,
      'singles': singles,
      'playlists': playlists,
    };
  }

  List<Map<String, dynamic>> _browseSections(
    Map<String, dynamic> response, {
    bool singleColumn = false,
  }) {
    final contents = _asMap(response['contents']);
    final column = singleColumn
        ? _asMap(contents?['singleColumnBrowseResultsRenderer'])
        : _asMap(contents?['twoColumnBrowseResultsRenderer']);
    final tabs = _listOfMaps(column?['tabs']);
    final tabContent =
        _asMap(_asMap(tabs.firstOrNull?['tabRenderer'])?['content']);
    return _listOfMaps(
      _asMap(tabContent?['sectionListRenderer'])?['contents'],
    );
  }

  String? _carouselTitle(Map<String, dynamic> carousel) {
    final header = _asMap(carousel['header']);
    final basic = _asMap(header?['musicCarouselShelfBasicHeaderRenderer']);
    return _text(basic?['title']) ?? _text(header?['title']);
  }

  String? _artistDescription(
    Map<String, dynamic>? header,
    List<Map<String, dynamic>> sections,
  ) {
    final direct = _text(header?['description']);
    if (direct != null && direct.isNotEmpty) return direct;
    for (final section in sections) {
      final description = _asMap(section['musicDescriptionShelfRenderer']);
      final text = _text(description?['description']);
      if (text != null && text.isNotEmpty) return text;
    }
    return null;
  }

  // ---------------------------------------------------------------------------
  // Album
  // ---------------------------------------------------------------------------

  Map<String, dynamic> _parseAlbum(
    Map<String, dynamic> response,
    String browseId,
  ) {
    final twoColumn =
        _asMap(response['contents'])?['twoColumnBrowseResultsRenderer'];
    final tabContent = _asMap(_asMap(_listOfMaps(
      _asMap(twoColumn)?['tabs'],
    ).firstOrNull?['tabRenderer'])?['content']);
    final headerSections = _listOfMaps(
      _asMap(tabContent?['sectionListRenderer'])?['contents'],
    );
    final header =
        _asMap(headerSections.firstOrNull?['musicResponsiveHeaderRenderer']);

    final title = _text(header?['title']) ?? '';
    final artist = _text(header?['straplineTextOne']);
    final subtitleRuns = _runs(header?['subtitle']);
    final secondSubtitleRuns = _runs(header?['secondSubtitle']);
    final year = _yearFromRuns(subtitleRuns);
    final trackCount = _firstIntFromRuns(secondSubtitleRuns);
    final duration = secondSubtitleRuns.isEmpty
        ? null
        : secondSubtitleRuns.last['text']?.toString();
    final thumbnail =
        _thumbnailUrl(header) ?? _thumbnailUrl(_asMap(response['background']));

    final tracks = <Map<String, dynamic>>[];
    final secondary = _asMap(twoColumn)?['secondaryContents'];
    final secondarySections = _listOfMaps(
      _asMap(secondary?['sectionListRenderer'])?['contents'],
    );
    for (final section in secondarySections) {
      final shelf = _asMap(section['musicShelfRenderer']);
      for (final item in _listOfMaps(shelf?['contents'])) {
        final track = _parseTrackItem(
          item,
          fallbackArtist: artist,
          fallbackAlbum: title,
        );
        if (track != null) _addUnique(tracks, track);
      }
    }

    return {
      'browse_id': browseId,
      'title': title.isEmpty ? 'Unknown Album' : title,
      if (artist != null) 'artist': artist,
      if (year != null) 'year': year,
      if (trackCount != null) 'track_count': trackCount,
      if (duration != null) 'duration': duration,
      if (thumbnail != null) 'thumbnail_url': thumbnail,
      'tracks': tracks,
    };
  }

  // ---------------------------------------------------------------------------
  // Playlist
  // ---------------------------------------------------------------------------

  Map<String, dynamic> _parsePlaylist(
    Map<String, dynamic> response,
    String browseId,
  ) {
    final twoColumn =
        _asMap(response['contents'])?['twoColumnBrowseResultsRenderer'];
    final secondary = _asMap(twoColumn)?['secondaryContents'];
    final sections = _listOfMaps(
      _asMap(secondary?['sectionListRenderer'])?['contents'],
    );
    final shelf = _asMap(sections.firstOrNull?['musicPlaylistShelfRenderer']);

    final microformat =
        _asMap(response['microformat'])?['microformatDataRenderer'];
    final microTitle = microformat?['title']?.toString();
    final microDescription = microformat?['description']?.toString() ?? '';
    final author = microDescription.contains('•')
        ? microDescription.split('•').last.trim()
        : null;

    final header = _asMap(shelf?['header']);
    final headerTitle = _text(header?['title']);
    final headerAuthor = _text(header?['straplineTextOne']);

    final tracks = <Map<String, dynamic>>[];
    for (final item in _listOfMaps(shelf?['contents'])) {
      final track = _parseTrackItem(
        item,
        fallbackArtist: headerAuthor ?? author,
      );
      if (track != null) _addUnique(tracks, track);
    }

    final thumbnail = _thumbnailUrl(_asMap(response['background'])) ??
        _thumbnailUrl(microformat);

    return {
      'browse_id': browseId,
      'title': headerTitle ?? microTitle ?? 'Unknown Playlist',
      if (headerAuthor != null || author != null)
        'author': headerAuthor ?? author,
      if (tracks.isNotEmpty) 'track_count': tracks.length,
      if (thumbnail != null) 'thumbnail_url': thumbnail,
      'tracks': tracks,
    };
  }

  // ---------------------------------------------------------------------------
  // Up next
  // ---------------------------------------------------------------------------

  List<Map<String, dynamic>> _parseUpNext(
    Map<String, dynamic> response,
    String seedVideoId,
  ) {
    final contents = _asMap(
        response['contents'])?['singleColumnMusicWatchNextResultsRenderer'];
    final tabs = _listOfMaps(_asMap(
        _asMap(_asMap(contents)?['tabbedRenderer'])?[
            'watchNextTabbedResultsRenderer'])?['tabs']);
    final firstTab = tabs.firstOrNull;
    final queue = _asMap(
        _asMap(firstTab?['tabRenderer'])?['content'])?['musicQueueRenderer'];
    final panel = _asMap(_asMap(queue)?['content'])?['playlistPanelRenderer'];
    final items = _listOfMaps(_asMap(panel)?['contents']);

    final result = <Map<String, dynamic>>[];
    for (final item in items) {
      final renderer = _asMap(item['playlistPanelVideoRenderer']);
      if (renderer == null) continue;
      final videoId = renderer['videoId']?.toString();
      if (videoId == null || videoId.isEmpty || videoId == seedVideoId) {
        continue;
      }
      final title = _text(renderer['title']) ?? '';
      if (title.isEmpty) continue;
      final runs = _runs(renderer['longBylineText']).isNotEmpty
          ? _runs(renderer['longBylineText'])
          : _runs(renderer['shortBylineText']);
      final artists = _artistNames(runs);
      final artist = artists.isEmpty
          ? (_firstMeaningfulRun(runs) ?? 'Unknown Artist')
          : artists.join(', ');
      final thumbnail = _thumbnailUrl(renderer);
      result.add({
        'result_type': 'song',
        'source_id': videoId,
        'title': title,
        'artist': artist,
        'duration_ms': _durationMsFromText(_text(renderer['lengthText'])),
        if (thumbnail != null) 'thumbnail_url': thumbnail,
        'source': 'youtube',
      });
    }
    return result;
  }

  // ---------------------------------------------------------------------------
  // Item parsers
  // ---------------------------------------------------------------------------

  Map<String, dynamic>? _parseTrackItem(
    Map<String, dynamic> wrapper, {
    String? fallbackArtist,
    String? fallbackAlbum,
  }) {
    final renderer = _asMap(wrapper['musicResponsiveListItemRenderer']) ??
        _asMap(wrapper['musicTwoRowItemRenderer']) ??
        _asMap(wrapper['playlistPanelVideoRenderer']);
    if (renderer == null) return null;

    final title = _text(renderer['title']) ?? _firstFlexText(renderer);
    final videoId = _videoId(renderer);
    if (title == null || title.isEmpty || videoId == null) return null;

    final subtitleRuns = _subtitleRuns(renderer);
    final artists = _artistNames(subtitleRuns);
    final album = _albumName(subtitleRuns) ?? fallbackAlbum;
    final fixedDuration = _durationFromFixedColumns(renderer);
    final duration =
        fixedDuration > 0 ? fixedDuration : _durationMsFromRuns(subtitleRuns);

    return {
      'result_type': 'song',
      'source_id': videoId,
      'title': title,
      'artist': artists.isNotEmpty
          ? artists.join(', ')
          : (fallbackArtist ?? 'Unknown Artist'),
      if (album != null) 'album': album,
      'duration_ms': duration,
      if (_thumbnailUrl(renderer) != null)
        'thumbnail_url': _thumbnailUrl(renderer),
      'source': 'youtube',
    };
  }

  Map<String, dynamic>? _parseCarouselAlbum(
    Map<String, dynamic> renderer,
  ) {
    final browseId = _browseId(renderer);
    final title = _text(renderer['title']);
    if (browseId == null || title == null) return null;
    final runs = _runs(renderer['subtitle']);
    final artists = _artistNames(runs);
    return {
      'browse_id': browseId,
      'title': title,
      if (artists.isNotEmpty) 'artist': artists.join(', '),
      if (_yearFromRuns(runs) != null) 'year': _yearFromRuns(runs),
      if (_thumbnailUrl(renderer) != null)
        'thumbnail_url': _thumbnailUrl(renderer),
    };
  }

  Map<String, dynamic>? _parseCarouselPlaylist(
    Map<String, dynamic> renderer,
  ) {
    final browseId = _browseId(renderer);
    final title = _text(renderer['title']);
    if (browseId == null || title == null) return null;
    final runs = _runs(renderer['subtitle']);
    final author = _firstMeaningfulRun(runs);
    return {
      'browse_id': browseId,
      'title': title,
      if (author != null) 'author': author,
      if (_thumbnailUrl(renderer) != null)
        'thumbnail_url': _thumbnailUrl(renderer),
    };
  }

  // ---------------------------------------------------------------------------
  // JSON helpers
  // ---------------------------------------------------------------------------

  static Map<String, dynamic>? _asMap(dynamic value) {
    if (value is Map<String, dynamic>) return value;
    if (value is Map) return Map<String, dynamic>.from(value);
    return null;
  }

  static List<Map<String, dynamic>> _listOfMaps(dynamic value) {
    if (value is! List) return const [];
    return value.map(_asMap).whereType<Map<String, dynamic>>().toList();
  }

  static List<Map<String, dynamic>> _runs(dynamic text) {
    final map = _asMap(text);
    final runs = map?['runs'];
    return _listOfMaps(runs);
  }

  static String? _text(dynamic value) {
    final runs = _runs(value);
    if (runs.isEmpty) {
      if (value is String) return value;
      return null;
    }
    final text = runs
        .map((run) => run['text']?.toString() ?? '')
        .where((part) => part.isNotEmpty)
        .join();
    return text.isEmpty ? null : text;
  }

  static String? _firstFlexText(Map<String, dynamic> renderer) {
    final columns = _listOfMaps(renderer['flexColumns']);
    if (columns.isEmpty) return null;
    final column =
        _asMap(columns.first['musicResponsiveListItemFlexColumnRenderer']);
    return _text(column?['text']);
  }

  static List<Map<String, dynamic>> _subtitleRuns(
    Map<String, dynamic> renderer,
  ) {
    final columns = _listOfMaps(renderer['flexColumns']);
    if (columns.length < 2) {
      return _runs(renderer['subtitle']);
    }
    final runs = <Map<String, dynamic>>[];
    for (final column in columns.skip(1)) {
      final data = _asMap(column['musicResponsiveListItemFlexColumnRenderer']);
      runs.addAll(_runs(data?['text']));
    }
    return runs;
  }

  static String? _pageType(Map<String, dynamic> renderer) {
    final endpoint = _asMap(renderer['navigationEndpoint']) ??
        _endpointFromFirstRun(renderer);
    final browse = _asMap(endpoint?['browseEndpoint']);
    final configs = _asMap(browse?['browseEndpointContextSupportedConfigs']);
    return _asMap(configs?['browseEndpointContextMusicConfig'])?['pageType']
        ?.toString();
  }

  static Map<String, dynamic>? _endpointFromFirstRun(
    Map<String, dynamic> renderer,
  ) {
    final runs = _runs(renderer['title']);
    if (runs.isEmpty) return null;
    return _asMap(runs.first['navigationEndpoint']);
  }

  static String? _videoId(Map<String, dynamic> renderer) {
    final playlistItem = _asMap(renderer['playlistItemData']);
    final direct = playlistItem?['videoId'] ?? renderer['videoId'];
    if (direct is String && direct.isNotEmpty) return direct;

    for (final run in _runs(renderer['title'])) {
      final endpoint = _asMap(run['navigationEndpoint']);
      final videoId = _asMap(endpoint?['watchEndpoint'])?['videoId'];
      if (videoId is String && videoId.isNotEmpty) return videoId;
    }
    for (final column in _listOfMaps(renderer['flexColumns'])) {
      final data = _asMap(column['musicResponsiveListItemFlexColumnRenderer']);
      for (final run in _runs(data?['text'])) {
        final endpoint = _asMap(run['navigationEndpoint']);
        final videoId = _asMap(endpoint?['watchEndpoint'])?['videoId'];
        if (videoId is String && videoId.isNotEmpty) return videoId;
      }
    }
    final overlay = _asMap(renderer['overlay']);
    final overlayContent =
        _asMap(overlay?['musicItemThumbnailOverlayRenderer']);
    final playButton = _asMap(overlayContent?['content']);
    final playNav = _asMap(playButton?['musicPlayButtonRenderer']);
    final videoId =
        _asMap(_asMap(playNav?['playNavigationEndpoint'])?['watchEndpoint'])?[
            'videoId'];
    return videoId is String && videoId.isNotEmpty ? videoId : null;
  }

  static String? _browseId(Map<String, dynamic> renderer) {
    final endpoint = _asMap(renderer['navigationEndpoint']) ??
        _endpointFromFirstRun(renderer);
    final browseId = _asMap(endpoint?['browseEndpoint'])?['browseId'];
    if (browseId is String && browseId.isNotEmpty) return browseId;

    for (final run in _runs(renderer['subtitle'])) {
      final nav = _asMap(run['navigationEndpoint']);
      final id = _asMap(nav?['browseEndpoint'])?['browseId'];
      if (id is String && id.isNotEmpty) return id;
    }
    return null;
  }

  static String? _thumbnailUrl(Map<String, dynamic>? renderer) {
    if (renderer == null) return null;
    final candidates = <dynamic>[
      renderer['thumbnail'],
      _asMap(renderer['thumbnailRenderer'])?['musicThumbnailRenderer'],
      _asMap(renderer['thumbnail'])?['musicThumbnailRenderer'],
      renderer,
    ];
    for (final candidate in candidates) {
      final map = _asMap(candidate);
      final thumbnails = _findThumbnails(map);
      if (thumbnails.isNotEmpty) {
        thumbnails.sort((a, b) {
          final aw = (a['width'] as num?)?.toInt() ?? 0;
          final bw = (b['width'] as num?)?.toInt() ?? 0;
          return bw.compareTo(aw);
        });
        final url = thumbnails.first['url'];
        if (url is String && url.isNotEmpty) return url;
      }
    }
    return null;
  }

  static List<Map<String, dynamic>> _findThumbnails(dynamic value) {
    if (value is Map) {
      final thumbnails = value['thumbnails'];
      if (thumbnails is List) return _listOfMaps(thumbnails);
      for (final child in value.values) {
        final found = _findThumbnails(child);
        if (found.isNotEmpty) return found;
      }
    } else if (value is List) {
      for (final child in value) {
        final found = _findThumbnails(child);
        if (found.isNotEmpty) return found;
      }
    }
    return const [];
  }

  static List<String> _artistNames(List<Map<String, dynamic>> runs) {
    final names = <String>[];
    for (final run in runs) {
      final nav = _asMap(run['navigationEndpoint']);
      final pageType = _pageTypeFromEndpoint(nav);
      final text = run['text']?.toString().trim() ?? '';
      if (text.isEmpty || _isSeparator(text)) continue;
      if (pageType == 'MUSIC_PAGE_TYPE_ARTIST' ||
          pageType == 'MUSIC_PAGE_TYPE_USER_CHANNEL') {
        names.add(text);
      }
    }
    return names;
  }

  static String? _albumName(List<Map<String, dynamic>> runs) {
    for (final run in runs) {
      final nav = _asMap(run['navigationEndpoint']);
      if (_pageTypeFromEndpoint(nav) == 'MUSIC_PAGE_TYPE_ALBUM') {
        final text = run['text']?.toString().trim();
        if (text != null && text.isNotEmpty) return text;
      }
    }
    return null;
  }

  static String? _pageTypeFromEndpoint(Map<String, dynamic>? endpoint) {
    final browse = _asMap(endpoint?['browseEndpoint']);
    final configs = _asMap(browse?['browseEndpointContextSupportedConfigs']);
    return _asMap(configs?['browseEndpointContextMusicConfig'])?['pageType']
        ?.toString();
  }

  static String? _firstMeaningfulRun(List<Map<String, dynamic>> runs) {
    for (final run in runs) {
      final text = run['text']?.toString().trim() ?? '';
      if (text.isNotEmpty && !_isSeparator(text)) return text;
    }
    return null;
  }

  static String? _lastMeaningfulRun(List<Map<String, dynamic>> runs) {
    for (final run in runs.reversed) {
      final text = run['text']?.toString().trim() ?? '';
      if (text.isNotEmpty && !_isSeparator(text)) return text;
    }
    return null;
  }

  static bool _isSeparator(String text) {
    return text == '•' ||
        text == '·' ||
        text == '-' ||
        text == ',' ||
        text.trim().isEmpty;
  }

  static int _durationMsFromRuns(List<Map<String, dynamic>> runs) {
    for (final run in runs.reversed) {
      final ms = _durationMsFromText(run['text']?.toString());
      if (ms > 0) return ms;
    }
    return 0;
  }

  static int _durationMsFromText(String? text) {
    if (text == null) return 0;
    final match = RegExp(r'(\d{1,3}:)?\d{1,3}:\d{2}').firstMatch(text);
    if (match == null) return 0;
    final parts = match.group(0)!.split(':').map(int.tryParse).toList();
    if (parts.any((part) => part == null)) return 0;
    var seconds = 0;
    for (final part in parts.cast<int>()) {
      seconds = seconds * 60 + part;
    }
    return seconds * 1000;
  }

  static int _durationFromFixedColumns(Map<String, dynamic> renderer) {
    for (final item in _listOfMaps(renderer['fixedColumns'])) {
      final column = _asMap(item['musicResponsiveListItemFixedColumnRenderer']);
      final ms = _durationMsFromText(_text(column?['text']));
      if (ms > 0) return ms;
    }
    return 0;
  }

  static String? _yearFromRuns(List<Map<String, dynamic>> runs) {
    for (final run in runs.reversed) {
      final text = run['text']?.toString().trim() ?? '';
      if (RegExp(r'^(19|20)\d{2}$').hasMatch(text)) return text;
    }
    return null;
  }

  static int? _firstIntFromRuns(List<Map<String, dynamic>> runs) {
    for (final run in runs) {
      final match = RegExp(r'\d+').firstMatch(run['text']?.toString() ?? '');
      if (match != null) return int.tryParse(match.group(0)!);
    }
    return null;
  }

  static void _addUnique(
    List<Map<String, dynamic>> list,
    Map<String, dynamic> item,
  ) {
    final id = item['source_id'] ?? item['browse_id'] ?? item['title'];
    if (list.any((existing) =>
        (existing['source_id'] ?? existing['browse_id'] ?? existing['title']) ==
        id)) {
      return;
    }
    list.add(item);
  }

  static String? _findContinuation(dynamic node) {
    if (node is Map) {
      for (final key in const [
        'nextContinuationData',
        'nextRadioContinuationData',
      ]) {
        final data = _asMap(node[key]);
        final token = data?['continuation'];
        if (token is String && token.isNotEmpty) return token;
      }
      for (final value in node.values) {
        final token = _findContinuation(value);
        if (token != null) return token;
      }
    } else if (node is List) {
      for (final value in node) {
        final token = _findContinuation(value);
        if (token != null) return token;
      }
    }
    return null;
  }
}

extension _FirstOrNull<T> on List<T> {
  T? get firstOrNull => isEmpty ? null : first;
}
