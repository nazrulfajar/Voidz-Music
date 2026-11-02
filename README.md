# Voidz Music

Voidz Music is a personal, premium-feeling music player application built with Flutter. The YouTube resolver runs entirely on-device (serverless), so the app works on Android and iOS without a FastAPI/yt-dlp backend. The app provides full control over offline playback, lyrics, and library management without ads.

## 🚀 Features

- **On-device YouTube Search & Playback**: Streams audio directly using InnerTube metadata and a Dart resolver.
- **Premium UI/UX**: Dynamic blurred backgrounds, fluid mini-player, and smooth page transitions.
- **Background Playback**: Full support for background audio and lockscreen media controls.
- **Smart Offline Caching**: 
  - Automatically caches songs during playback (up to 4 upcoming tracks).
  - Validates cache integrity and skips corrupt files.
  - "Wi-Fi Only" download controls.
- **Synchronized Lyrics**: Real-time synced lyrics with click-to-seek functionality, fetched directly from LRCLIB.
- **Custom Library & Playlists**:
  - User-created playlists with drag-and-drop reordering.
  - System playlists (`Liked Songs`, `Recently Played`, `Downloaded`).
  - Immersive mosaic cover arts for playlists.
- **Robust Queue Management**: Autoplay suggestions, robust looping, and shuffling modes.

## 🛠️ Technology Stack

- **Client**: Flutter, Riverpod (State Management), Isar (Local Database), just_audio, go_router.
- **YouTube resolver**: `youtube_explode_dart` + YouTube Music InnerTube, running in-app.
- **Backend**: None. All requests go directly to public services (YouTube/LRCLIB).

## 📦 Setup & Installation

### 1. Flutter Client
```bash
cd my_music_player
flutter pub get
flutter run
```

### 2. Platform requirements

- **Android**: Android 8.0+ (API 26+).
- **iOS**: iOS 15+, built on macOS with Xcode and CocoaPods:
  ```bash
  cd my_music_player
  flutter pub get
  cd ios && pod install && cd ..
  flutter run -d ios
  ```

No backend URL configuration is needed. The resolver runs on the device.

## 📝 License
Created for personal use.
