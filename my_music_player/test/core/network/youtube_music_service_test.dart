import 'package:flutter_test/flutter_test.dart';
import 'package:my_music_player/core/network/youtube_music_service.dart';
import 'package:my_music_player/features/player/domain/entities/track.dart';

Map<String, dynamic> flexColumn(List<Map<String, dynamic>> runs) => {
      'musicResponsiveListItemFlexColumnRenderer': {
        'text': {'runs': runs},
      },
    };

Map<String, dynamic> browseRun(
  String text,
  String browseId,
  String pageType,
) =>
    {
      'text': text,
      'navigationEndpoint': {
        'browseEndpoint': {
          'browseId': browseId,
          'browseEndpointContextSupportedConfigs': {
            'browseEndpointContextMusicConfig': {'pageType': pageType},
          },
        },
      },
    };

Map<String, dynamic> thumbnail(List<String> urls) => {
      'musicThumbnailRenderer': {
        'thumbnail': {
          'thumbnails': urls
              .asMap()
              .entries
              .map((entry) => {
                    'url': entry.value,
                    'width': (entry.key + 1) * 100,
                    'height': (entry.key + 1) * 100,
                  })
              .toList(),
        },
      },
    };

void main() {
  late YoutubeMusicService service;

  setUp(() {
    service = YoutubeMusicService();
  });

  tearDown(() {
    service.close();
  });

  test('parse search songs menjadi Track-compatible map', () {
    final response = {
      'contents': {
        'tabbedSearchResultsRenderer': {
          'tabs': [
            {
              'tabRenderer': {
                'content': {
                  'sectionListRenderer': {
                    'contents': [
                      {
                        'musicShelfRenderer': {
                          'contents': [
                            {
                              'musicResponsiveListItemRenderer': {
                                'thumbnail': thumbnail(
                                  ['https://x/60.jpg', 'https://x/800.jpg'],
                                ),
                                'flexColumns': [
                                  flexColumn([
                                    {
                                      'text': 'Song A',
                                      'navigationEndpoint': {
                                        'watchEndpoint': {'videoId': 'vid1'},
                                      },
                                    },
                                  ]),
                                  flexColumn([
                                    browseRun(
                                      'Artist A',
                                      'UC1',
                                      'MUSIC_PAGE_TYPE_ARTIST',
                                    ),
                                    {'text': ' • '},
                                    browseRun(
                                      'Album A',
                                      'MPRE1',
                                      'MUSIC_PAGE_TYPE_ALBUM',
                                    ),
                                    {'text': ' • '},
                                    {'text': '3:24'},
                                  ]),
                                ],
                              },
                            },
                          ],
                        },
                      },
                    ],
                  },
                },
              },
            },
          ],
        },
      },
    };

    final results = service.parseSearchResponse(response, 'songs');

    expect(results, hasLength(1));
    expect(results.first['result_type'], 'song');
    expect(results.first['source_id'], 'vid1');
    expect(results.first['title'], 'Song A');
    expect(results.first['artist'], 'Artist A');
    expect(results.first['album'], 'Album A');
    expect(results.first['duration_ms'], 204000);
    expect(results.first['thumbnail_url'], 'https://x/800.jpg');
    expect(results.first['source'], 'youtube');

    final track = Track.fromJson(results.first);
    expect(track.sourceId, 'vid1');
    expect(track.title, 'Song A');
    expect(track.source.name, 'youtube');
    expect(track.durationMs, 204000);
  });

  test('parse search artists/albums/playlists', () {
    final artistResponse = {
      'contents': {
        'tabbedSearchResultsRenderer': {
          'tabs': [
            {
              'tabRenderer': {
                'content': {
                  'sectionListRenderer': {
                    'contents': [
                      {
                        'musicShelfRenderer': {
                          'contents': [
                            {
                              'musicResponsiveListItemRenderer': {
                                'thumbnail':
                                    thumbnail(['https://x/artist.jpg']),
                                'navigationEndpoint': {
                                  'browseEndpoint': {'browseId': 'UC2'},
                                },
                                'flexColumns': [
                                  flexColumn([
                                    {'text': 'Artist B'}
                                  ]),
                                  flexColumn([
                                    {'text': 'Artist'},
                                    {'text': ' • '},
                                    {'text': '6.2M monthly audience'},
                                  ]),
                                ],
                              },
                            },
                          ],
                        },
                      },
                    ],
                  },
                },
              },
            },
          ],
        },
      },
    };
    final artists = service.parseSearchResponse(artistResponse, 'artists');
    expect(artists.first['result_type'], 'artist');
    expect(artists.first['browse_id'], 'UC2');
    expect(artists.first['name'], 'Artist B');
    expect(artists.first['subscribers'], '6.2M monthly audience');

    final albumResponse = {
      'contents': {
        'tabbedSearchResultsRenderer': {
          'tabs': [
            {
              'tabRenderer': {
                'content': {
                  'sectionListRenderer': {
                    'contents': [
                      {
                        'musicShelfRenderer': {
                          'contents': [
                            {
                              'musicResponsiveListItemRenderer': {
                                'navigationEndpoint': {
                                  'browseEndpoint': {'browseId': 'MPRE2'},
                                },
                                'flexColumns': [
                                  flexColumn([
                                    {'text': 'Album B'}
                                  ]),
                                  flexColumn([
                                    {'text': 'Album'},
                                    {'text': ' • '},
                                    browseRun(
                                      'Artist B',
                                      'UC2',
                                      'MUSIC_PAGE_TYPE_ARTIST',
                                    ),
                                    {'text': ' • '},
                                    {'text': '2024'},
                                  ]),
                                ],
                              },
                            },
                          ],
                        },
                      },
                    ],
                  },
                },
              },
            },
          ],
        },
      },
    };
    final albums = service.parseSearchResponse(albumResponse, 'albums');
    expect(albums.first['result_type'], 'album');
    expect(albums.first['browse_id'], 'MPRE2');
    expect(albums.first['artist'], 'Artist B');
    expect(albums.first['year'], '2024');

    final playlistResponse = {
      'contents': {
        'tabbedSearchResultsRenderer': {
          'tabs': [
            {
              'tabRenderer': {
                'content': {
                  'sectionListRenderer': {
                    'contents': [
                      {
                        'musicShelfRenderer': {
                          'contents': [
                            {
                              'musicResponsiveListItemRenderer': {
                                'navigationEndpoint': {
                                  'browseEndpoint': {'browseId': 'VLPL1'},
                                },
                                'flexColumns': [
                                  flexColumn([
                                    {'text': 'Playlist B'}
                                  ]),
                                  flexColumn([
                                    {'text': 'Author B'},
                                    {'text': ' • '},
                                    {'text': '30K views'},
                                  ]),
                                ],
                              },
                            },
                          ],
                        },
                      },
                    ],
                  },
                },
              },
            },
          ],
        },
      },
    };
    final playlists =
        service.parseSearchResponse(playlistResponse, 'playlists');
    expect(playlists.first['result_type'], 'playlist');
    expect(playlists.first['browse_id'], 'VLPL1');
    expect(playlists.first['author'], 'Author B');
  });

  test('parse album memakai fallback artist dari header', () {
    final response = {
      'contents': {
        'twoColumnBrowseResultsRenderer': {
          'tabs': [
            {
              'tabRenderer': {
                'content': {
                  'sectionListRenderer': {
                    'contents': [
                      {
                        'musicResponsiveHeaderRenderer': {
                          'title': {
                            'runs': [
                              {'text': 'Album C'},
                            ],
                          },
                          'straplineTextOne': {
                            'runs': [
                              {'text': 'Artist C'},
                            ],
                          },
                          'subtitle': {
                            'runs': [
                              {'text': 'Album'},
                              {'text': ' • '},
                              {'text': '2022'},
                            ],
                          },
                          'secondSubtitle': {
                            'runs': [
                              {'text': '10 songs'},
                              {'text': ' • '},
                              {'text': '40 minutes'},
                            ],
                          },
                          'thumbnail': thumbnail(['https://x/album.jpg']),
                        },
                      },
                    ],
                  },
                },
              },
            },
          ],
          'secondaryContents': {
            'sectionListRenderer': {
              'contents': [
                {
                  'musicShelfRenderer': {
                    'contents': [
                      {
                        'musicResponsiveListItemRenderer': {
                          'playlistItemData': {'videoId': 'vid2'},
                          'flexColumns': [
                            flexColumn([
                              {'text': 'Track C'}
                            ]),
                            flexColumn([]),
                          ],
                          'fixedColumns': [
                            {
                              'musicResponsiveListItemFixedColumnRenderer': {
                                'text': {
                                  'runs': [
                                    {'text': '4:05'},
                                  ],
                                },
                              },
                            },
                          ],
                        },
                      },
                    ],
                  },
                },
              ],
            },
          },
        },
      },
    };

    final album = service.parseAlbumResponse(response, 'MPRE3');

    expect(album['browse_id'], 'MPRE3');
    expect(album['title'], 'Album C');
    expect(album['artist'], 'Artist C');
    expect(album['year'], '2022');
    expect(album['track_count'], 10);
    expect(album['tracks'], hasLength(1));
    expect(album['tracks'][0]['artist'], 'Artist C');
    expect(album['tracks'][0]['album'], 'Album C');
    expect(album['tracks'][0]['duration_ms'], 245000);
  });

  test('parse up next melewati video seed', () {
    final response = {
      'contents': {
        'singleColumnMusicWatchNextResultsRenderer': {
          'tabbedRenderer': {
            'watchNextTabbedResultsRenderer': {
              'tabs': [
                {
                  'tabRenderer': {
                    'content': {
                      'musicQueueRenderer': {
                        'content': {
                          'playlistPanelRenderer': {
                            'contents': [
                              {
                                'playlistPanelVideoRenderer': {
                                  'videoId': 'seed',
                                  'title': {
                                    'runs': [
                                      {'text': 'Seed Song'},
                                    ],
                                  },
                                  'lengthText': {
                                    'runs': [
                                      {'text': '3:00'},
                                    ],
                                  },
                                },
                              },
                              {
                                'playlistPanelVideoRenderer': {
                                  'videoId': 'next1',
                                  'title': {
                                    'runs': [
                                      {'text': 'Next Song'},
                                    ],
                                  },
                                  'longBylineText': {
                                    'runs': [
                                      {'text': 'Next Artist'},
                                    ],
                                  },
                                  'lengthText': {
                                    'runs': [
                                      {'text': '2:30'},
                                    ],
                                  },
                                },
                              },
                            ],
                          },
                        },
                      },
                    },
                  },
                },
              ],
            },
          },
        },
      },
    };

    final next = service.parseUpNextResponse(response, 'seed');

    expect(next, hasLength(1));
    expect(next.first['source_id'], 'next1');
    expect(next.first['title'], 'Next Song');
    expect(next.first['artist'], 'Next Artist');
    expect(next.first['duration_ms'], 150000);
  });
}
