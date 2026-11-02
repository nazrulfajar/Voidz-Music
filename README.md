# Voidz Music

Voidz Music is a personal, premium-feeling music player application built with Flutter. The YouTube resolver lives in a separate FastAPI service; this repository contains the Flutter client only. The app provides full control over offline playback, lyrics, and library management without ads.

## 🚀 Features

- **Multi-Source Search & Playback**: Streams audio seamlessly from YouTube and Jamendo.
- **Premium UI/UX**: Dynamic blurred backgrounds, fluid mini-player, and smooth page transitions.
- **Background Playback**: Full support for background audio and lockscreen media controls.
- **Smart Offline Caching**: 
  - Automatically caches songs during playback (up to 4 upcoming tracks).
  - Validates cache integrity and skips corrupt files.
  - "Wi-Fi Only" download controls.
- **Synchronized Lyrics**: Real-time synced lyrics with click-to-seek functionality, fetched via LRCLIB.
- **Custom Library & Playlists**:
  - User-created playlists with drag-and-drop reordering.
  - System playlists (`Liked Songs`, `Recently Played`, `Downloaded`).
  - Immersive mosaic cover arts for playlists.
- **Robust Queue Management**: Autoplay suggestions, robust looping, and shuffling modes.

## 🛠️ Technology Stack

- **Client**: Flutter, Riverpod (State Management), Isar (Local Database), just_audio, go_router.
- **Backend**: FastAPI + yt-dlp/ytmusicapi, deployed separately (not in this repository).

## 📦 Setup & Installation

### 1. Backend Resolver (external)

The FastAPI resolver is maintained and deployed separately from this repository.
Start it wherever it is hosted, then set its base URL in the app's Settings
screen. The app never runs Python or yt-dlp locally.

### 2. Flutter Client
```bash
cd my_music_player
flutter pub get
flutter run
```

## 📝 License
Created for personal use.
