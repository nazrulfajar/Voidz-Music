import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/services.dart';
import 'dio_client.dart';
import 'youtube_resolver_service.dart';
import '../../features/player/domain/entities/track.dart';

final apiServiceProvider = Provider<ApiService>((ref) {
  return ApiService(
      ref.read(dioProvider), ref.read(youtubeResolverServiceProvider));
});

class ApiService {
  final Dio _dio;
  final YoutubeResolverService _youtubeResolver;

  ApiService(this._dio, this._youtubeResolver);

  Future<List<Track>> search(String query,
      {String source = 'youtube', int limit = 20}) async {
    try {
      final response = await _dio.get('/api/search', queryParameters: {
        'query': query,
        'source': source,
        'limit': limit,
        'filter': 'songs',
      });

      if (response.data != null && response.data['results'] != null) {
        final List results = response.data['results'];
        return results.map((json) {
          if (json['thumbnail_url'] != null) {
            String url = json['thumbnail_url'].toString();
            // Upgrade YouTube Music thumbnails (w120-h120 to w800-h800)
            url = url.replaceAll(RegExp(r'=w\d+-h\d+'), '=w800-h800');
            // Do NOT downgrade hq720 to mqdefault anymore
            json['thumbnail_url'] = url;
          }
          return Track.fromJson(json);
        }).toList();
      }
      return [];
    } catch (e) {
      throw Exception('Failed to search: $e');
    }
  }

  Future<List<dynamic>> searchArtistsOrAlbums(String query, String filter,
      {String source = 'youtube', int limit = 20}) async {
    try {
      final response = await _dio.get('/api/search', queryParameters: {
        'query': query,
        'source': source,
        'limit': limit,
        'filter': filter,
      });

      if (response.data != null && response.data['results'] != null) {
        final List results = response.data['results'];
        return results.map((json) {
          if (json['thumbnail_url'] != null) {
            String url = json['thumbnail_url'].toString();
            url = url.replaceAll(RegExp(r'=w\d+-h\d+'), '=w800-h800');
            json['thumbnail_url'] = url;
          }
          return json;
        }).toList();
      }
      return [];
    } catch (e) {
      throw Exception('Failed to search $filter: $e');
    }
  }

  Future<Map<String, dynamic>> getArtistDetails(String artistId) async {
    try {
      final response = await _dio.get('/api/browse/artist/$artistId');
      return response.data;
    } catch (e) {
      throw Exception('Failed to get artist details: $e');
    }
  }

  Future<Map<String, dynamic>> getAlbumDetails(String albumId) async {
    try {
      final response = await _dio.get('/api/browse/album/$albumId');
      return response.data;
    } catch (e) {
      throw Exception('Failed to get album details: $e');
    }
  }

  Future<Map<String, dynamic>> getPlaylistDetails(String playlistId) async {
    try {
      final response = await _dio.get('/api/browse/playlist/$playlistId');
      return response.data;
    } catch (e) {
      throw Exception('Failed to get playlist details: $e');
    }
  }

  static const platform = MethodChannel('com.mymusic.my_music_player/python');

  Future<Map<String, dynamic>> resolve(String sourceId,
      {String source = 'youtube', String quality = 'medium'}) async {
    if (source == 'youtube' || source == 'ytmusic') {
      try {
        // Sanitize sourceId for Python string interpolation
        final safeId = sourceId.replaceAll("'", r"\'");
        final code = '''
import yt_dlp, json, os

# Quality -> format selector (mirror backend/services/yt_service.py:get_ydl)
quality = '$quality'
if quality == 'low':
    format_sel = 'bestaudio[abr<=64]/bestaudio/best'
elif quality == 'high':
    format_sel = 'bestaudio[abr>=256]/bestaudio/best'
else:
    format_sel = 'bestaudio[abr<=128]/bestaudio/best'

# Build ydl opts — FIX reload error: yt-dlp 2024+ butuh extract_flat=False dan hindari tv client yang trigger "page needs to be reloaded"
ydl_opts = {
    'format': format_sel,
    'quiet': True,
    'no_warnings': True,
    'extract_flat': False,
    'extractor_args': {'youtube': {'player_client': ['ios', 'android']}},
    'nocheckcertificate': True,
}

# Cookies: coba pakai jika ada (HP residensial sering tidak butuh, tapi jika ada akan bantu bot check)
# Chaquopy CWD biasanya di files dir — cek beberapa lokasi tanpa crash jika tidak ada
for _p in ['cookies.txt', 'cookies/cookies.txt', '/data/data/com.mymusic.my_music_player/files/cookies.txt']:
    try:
        if os.path.exists(_p):
            ydl_opts['cookiefile'] = _p
            break
    except:
        pass

# Reuse global ydl per quality seperti backend threading.local
if 'ydls' not in globals():
    globals()['ydls'] = {}
if quality not in globals()['ydls']:
    globals()['ydls'][quality] = yt_dlp.YoutubeDL(ydl_opts)
ydl = globals()['ydls'][quality]

# Selalu pakai full watch URL
vid = '$safeId'
url = vid if vid.startswith('http') else f'https://www.youtube.com/watch?v={vid}'
# Retry sekali khusus "The page needs to be reloaded" — bug transient yt-dlp 2024.08+
try:
    info = ydl.extract_info(url, download=False)
except Exception as _e:
    if 'needs to be reloaded' in str(_e).lower() or 'reload' in str(_e).lower():
        import time
        time.sleep(0.6)
        # fallback: buat instance fresh tanpa cache tv
        _opts2 = dict(ydl_opts)
        _opts2['extractor_args'] = {'youtube': {'player_client': ['android']}}
        ydl2 = yt_dlp.YoutubeDL(_opts2)
        info = ydl2.extract_info(url, download=False)
        # simpan untuk next call
        globals()['ydls'][quality] = ydl2
        ydl = ydl2
    else:
        raise

# Format selection identik backend — pilih audio-only terbaik
formats = info.get('formats', []) or []
audio_formats = [f for f in formats if f.get('acodec') != 'none' and f.get('vcodec') == 'none']
stream_url = None
abr = None
ext = None
filesize = None
http_headers = info.get('http_headers', {}) or {}
if not audio_formats:
    stream_url = info.get('url')
    abr = info.get('abr') or info.get('tbr') or 128
    ext = info.get('ext', 'opus')
    filesize = info.get('filesize') or info.get('filesize_approx') or 0
    http_headers = info.get('http_headers', {}) or http_headers
else:
    format_id = info.get('format_id')
    best = None
    for f in audio_formats:
        if f.get('format_id') == format_id:
            best = f
            break
    if best is None:
        best = audio_formats[-1]
    stream_url = best.get('url') or info.get('url')
    abr = best.get('abr') or best.get('tbr') or info.get('abr') or 128
    ext = best.get('ext') or info.get('ext') or 'opus'
    filesize = best.get('filesize') or best.get('filesize_approx') or info.get('filesize') or 0
    # headers bisa di per-format
    if best.get('http_headers'):
        http_headers = best.get('http_headers')

# Normalisasi format label seperti sebelumnya
acodec = (info.get('acodec') or ext or '').lower()
if 'mp4a' in acodec or ext == 'm4a' or ext == 'mp4':
    fmt = 'AAC'
elif 'opus' in acodec or ext == 'webm':
    fmt = 'Opus'
elif 'mp3' in acodec or ext == 'mp3':
    fmt = 'MP3'
else:
    fmt = ext.upper() if ext else 'AUDIO'

output = json.dumps({
    'stream_url': stream_url,
    'format': fmt,
    'bitrate_kbps': int(round(float(abr))) if abr else 128,
    'file_size_bytes': int(filesize) if filesize else 0,
    'headers': http_headers,
})
''';
        // Panggil kode Python via MethodChannel
        final result =
            await platform.invokeMethod('executePython', {'code': code});
        if (result != null) {
          final output = result.toString().trim();
          if (output.startsWith('{')) {
            final data = Map<String, dynamic>.from(json.decode(output));
            // Jika yt-dlp mengembalikan error di JSON (jarang), tangkap
            if (data['stream_url'] == null ||
                (data['stream_url'] as String).isEmpty) {
              throw Exception('Chaquopy returned empty stream_url: $output');
            }
            data['expires_at'] = DateTime.now()
                .add(const Duration(hours: 5, minutes: 30))
                .toIso8601String();

            if (data['bitrate_kbps'] is num) {
              data['bitrate_kbps'] = (data['bitrate_kbps'] as num).toInt();
            }
            if (data['file_size_bytes'] is num) {
              data['file_size_bytes'] =
                  (data['file_size_bytes'] as num).toInt();
            }

            return data;
          } else {
            throw Exception('Chaquopy Error: $output');
          }
        }
        throw Exception(
            'Failed to resolve stream from Chaquopy (Empty result)');
      } catch (e) {
        // Beri pesan yang membedakan bot-check vs error lain
        final msg = e.toString();
        if (msg.contains('Sign in to confirm') || msg.contains('not a bot')) {
          throw Exception(
              'YouTube bot-check: $msg — coba update yt-dlp, ganti quality, atau pakai cookies.txt di files dir');
        }
        throw Exception('Failed to resolve stream from Chaquopy: $e');
      }
    }
    throw UnimplementedError('Resolve not implemented for $source');
  }

  Future<void> warmupPython() async {
    try {
      const code = '''
import yt_dlp
if 'ydls' not in globals():
    globals()['ydls'] = {}
for _q, _fmt in [('low','bestaudio[abr<=64]/bestaudio/best'), ('medium','bestaudio[abr<=128]/bestaudio/best'), ('high','bestaudio[abr>=256]/bestaudio/best')]:
    if _q not in globals()['ydls']:
        opts = {
            'format': _fmt,
            'quiet': True,
            'no_warnings': True,
            'extract_flat': False,
            'extractor_args': {'youtube': {'player_client': ['ios', 'android']}},
            'nocheckcertificate': True,
        }
        try:
            import os
            for _p in ['cookies.txt']:
                if os.path.exists(_p):
                    opts['cookiefile'] = _p
                    break
        except:
            pass
        globals()['ydls'][_q] = yt_dlp.YoutubeDL(opts)
output = "OK"
''';
      await platform.invokeMethod('executePython', {'code': code});
      print("Python engine warmed up successfully (ios,tv,web).");
    } catch (e) {
      print("Failed to warm up Python engine: $e");
    }
  }

  Future<bool> checkHealth() async {
    try {
      final response = await _dio.get('/api/health');
      return response.data['status'] == 'ok';
    } catch (e) {
      return false;
    }
  }

  Future<List<dynamic>> getUpNext(String videoId) async {
    try {
      final response = await _dio
          .get('/api/player/up-next', queryParameters: {'video_id': videoId});
      final List<dynamic> data = response.data;
      return data.map((json) {
        if (json['thumbnail_url'] != null) {
          String url = json['thumbnail_url'].toString();
          url = url.replaceAll(RegExp(r'=w\d+-h\d+'), '=w800-h800');
          json['thumbnail_url'] = url;
        }
        return json;
      }).toList();
    } catch (e) {
      throw Exception('Failed to get up next tracks: $e');
    }
  }
}
