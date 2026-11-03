package io.github.nazrulfajar.voidzmusic

import android.os.Bundle
import android.provider.MediaStore
import android.database.Cursor
import android.net.Uri
import android.content.ContentUris
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import com.ryanheise.audioservice.AudioServiceActivity

class MainActivity : AudioServiceActivity() {
    private val MEDIA_CHANNEL = "io.github.nazrulfajar.voidzmusic/media"

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        // MediaStore scan - ponytail: native platform before dependency
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, MEDIA_CHANNEL).setMethodCallHandler { call, result ->
            when (call.method) {
                "querySongs" -> {
                    Thread {
                        try {
                            val songs = queryDeviceSongs()
                            android.os.Handler(android.os.Looper.getMainLooper()).post {
                                result.success(songs)
                            }
                        } catch (e: Exception) {
                            android.os.Handler(android.os.Looper.getMainLooper()).post {
                                result.error("QUERY_ERROR", e.message, null)
                            }
                        }
                    }.start()
                }
                "queryArtwork" -> {
                    val albumId = (call.argument<Number>("albumId")?.toLong()) ?: (call.argument<Long>("albumId"))
                    if (albumId == null) {
                        result.error("INVALID_ARG", "albumId required", null)
                    } else {
                        Thread {
                            try {
                                val bytes = queryArtwork(albumId)
                                android.os.Handler(android.os.Looper.getMainLooper()).post {
                                    result.success(bytes)
                                }
                            } catch (e: Exception) {
                                android.os.Handler(android.os.Looper.getMainLooper()).post {
                                    result.error("ART_ERROR", e.message, null)
                                }
                            }
                        }.start()
                    }
                }
                else -> result.notImplemented()
            }
        }
    }

    private fun queryDeviceSongs(): List<Map<String, Any?>> {
        val list = mutableListOf<Map<String, Any?>>()
        val uri = MediaStore.Audio.Media.EXTERNAL_CONTENT_URI
        val projection = arrayOf(
            MediaStore.Audio.Media._ID,
            MediaStore.Audio.Media.DATA,
            MediaStore.Audio.Media.TITLE,
            MediaStore.Audio.Media.ARTIST,
            MediaStore.Audio.Media.ALBUM,
            MediaStore.Audio.Media.ALBUM_ID,
            MediaStore.Audio.Media.DURATION,
            MediaStore.Audio.Media.SIZE,
            MediaStore.Audio.Media.DISPLAY_NAME,
            MediaStore.Audio.Media.IS_MUSIC,
            MediaStore.Audio.Media.TRACK,
            MediaStore.Audio.Media.YEAR,
            MediaStore.Audio.Media.DATE_ADDED
        )
        // Only music, duration > 30s to skip ringtones
        val selection = "${MediaStore.Audio.Media.IS_MUSIC} != 0 AND ${MediaStore.Audio.Media.DURATION} > 30000"
        val sortOrder = "${MediaStore.Audio.Media.TITLE} COLLATE NOCASE ASC"
        var cursor: Cursor? = null
        try {
            cursor = contentResolver.query(uri, projection, selection, null, sortOrder)
            cursor?.let {
                val idCol = it.getColumnIndexOrThrow(MediaStore.Audio.Media._ID)
                val dataCol = it.getColumnIndexOrThrow(MediaStore.Audio.Media.DATA)
                val titleCol = it.getColumnIndexOrThrow(MediaStore.Audio.Media.TITLE)
                val artistCol = it.getColumnIndexOrThrow(MediaStore.Audio.Media.ARTIST)
                val albumCol = it.getColumnIndexOrThrow(MediaStore.Audio.Media.ALBUM)
                val albumIdCol = it.getColumnIndexOrThrow(MediaStore.Audio.Media.ALBUM_ID)
                val durCol = it.getColumnIndexOrThrow(MediaStore.Audio.Media.DURATION)
                val sizeCol = it.getColumnIndexOrThrow(MediaStore.Audio.Media.SIZE)
                val displayCol = it.getColumnIndexOrThrow(MediaStore.Audio.Media.DISPLAY_NAME)
                val trackCol = it.getColumnIndex(MediaStore.Audio.Media.TRACK)
                val yearCol = it.getColumnIndex(MediaStore.Audio.Media.YEAR)
                while (it.moveToNext()) {
                    val data = it.getString(dataCol) ?: continue
                    if (data.isEmpty()) continue
                    // Skip our own cache dir to avoid duplicate
                    if (data.contains("/audio/") && data.contains("my_music_player")) continue
                    val map = mutableMapOf<String, Any?>()
                    map["_id"] = it.getLong(idCol)
                    map["_data"] = data
                    map["title"] = it.getString(titleCol) ?: ""
                    map["artist"] = it.getString(artistCol) ?: ""
                    map["album"] = it.getString(albumCol) ?: ""
                    map["album_id"] = it.getLong(albumIdCol)
                    map["duration"] = it.getLong(durCol)
                    map["size"] = it.getLong(sizeCol)
                    map["display_name"] = it.getString(displayCol) ?: ""
                    // track & year (may be missing on some devices → default 0)
                    val rawTrack = if (trackCol >= 0) try { it.getInt(trackCol) } catch (_: Exception) { 0 } else 0
                    val rawYear = if (yearCol >= 0) try { it.getInt(yearCol) } catch (_: Exception) { 0 } else 0
                    map["track"] = rawTrack
                    map["year"] = rawYear
                    // file extension
                    val ext = data.substringAfterLast('.', "").lowercase()
                    map["file_extension"] = ext
                    list.add(map)
                }
            }
        } finally {
            cursor?.close()
        }
        return list
    }

    private fun queryArtwork(albumId: Long): ByteArray? {
        // Try albumart URI first (pre-Q)
        try {
            val uri = ContentUris.withAppendedId(Uri.parse("content://media/external/audio/albumart"), albumId)
            contentResolver.openInputStream(uri)?.use { input ->
                val bytes = input.readBytes()
                if (bytes.isNotEmpty()) return bytes
            }
        } catch (_: Exception) {}
        // Fallback: query ALBUM_ART path (works on many devices)
        try {
            val proj = arrayOf(MediaStore.Audio.Albums.ALBUM_ART)
            val sel = "${MediaStore.Audio.Albums._ID}=?"
            contentResolver.query(
                MediaStore.Audio.Albums.EXTERNAL_CONTENT_URI,
                proj, sel, arrayOf(albumId.toString()), null
            )?.use { c ->
                if (c.moveToFirst()) {
                    val idx = c.getColumnIndex(MediaStore.Audio.Albums.ALBUM_ART)
                    if (idx >= 0) {
                        val path = c.getString(idx)
                        if (!path.isNullOrEmpty()) {
                            val f = java.io.File(path)
                            if (f.exists() && f.length() > 0 && f.length() < 10 * 1024 * 1024) {
                                return f.readBytes()
                            }
                        }
                    }
                }
            }
        } catch (_: Exception) {}
        // Q+ loadThumbnail fallback for album uri
        try {
            if (android.os.Build.VERSION.SDK_INT >= android.os.Build.VERSION_CODES.Q) {
                val albumUri = ContentUris.withAppendedId(MediaStore.Audio.Albums.EXTERNAL_CONTENT_URI, albumId)
                val thumb = contentResolver.loadThumbnail(albumUri, android.util.Size(300, 300), null)
                val out = java.io.ByteArrayOutputStream()
                thumb.compress(android.graphics.Bitmap.CompressFormat.JPEG, 85, out)
                val bytes = out.toByteArray()
                if (bytes.isNotEmpty()) return bytes
            }
        } catch (_: Exception) {}
        return null
    }
}
