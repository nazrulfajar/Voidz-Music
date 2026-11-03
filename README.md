# Voidz Music

Voidz Music is a personal, premium-feeling music player built with Flutter. The
YouTube resolver runs entirely on-device (serverless), so the app works without
a FastAPI/yt-dlp backend. It provides background playback, offline caching,
synchronized lyrics, and library management without ads.

## 📥 Download

The Android APK is distributed through [GitHub Releases](https://github.com/nazrulfajar/Voidz-Music/releases/latest).
There is no Play Store version.

- **Requirements:** Android 8.0 (API 26) or newer.
- **Recommended asset:** `VoidzMusic-<version>-arm64-v8a.apk` for phones and
  tablets. Use `VoidzMusic-<version>-armeabi-v7a.apk` only for older 32-bit
  devices, and `VoidzMusic-<version>-x86_64.apk` only for x86_64 emulators.
- **Install:** open the downloaded APK and allow "Install unknown apps" for
  your browser or file manager when prompted. Play Protect may warn because
  the app is not distributed through the Play Store; that is expected.
- **Data:** the app stores its library locally. Uninstalling the app removes
  that data. App-data backup is disabled, so data is not migrated automatically
  to a new device.

## ✨ Features

- **On-device YouTube search & playback:** streams audio using InnerTube
  metadata and an in-app Dart resolver.
- **Premium UI/UX:** dynamic blurred backgrounds, fluid mini-player, and smooth
  page transitions.
- **Background playback:** background audio and lockscreen media controls.
- **Smart offline caching:**
  - Automatically caches songs during playback (up to 4 upcoming tracks).
  - Validates cache integrity and skips corrupt files.
  - "Wi-Fi only" download controls.
- **Synchronized lyrics:** real-time synced lyrics with click-to-seek,
  fetched directly from LRCLIB.
- **Custom library & playlists:**
  - User-created playlists with drag-and-drop reordering.
  - System playlists (`Liked Songs`, `Recently Played`, `Downloaded`).
  - Immersive mosaic cover art for playlists.
- **Robust queue management:** autoplay suggestions, looping, and shuffling.

## 🔐 Privacy

- No account, no login, and no analytics/ads/crash SDK.
- Library, playlists, playback history, and cache stay on the device.
- Network requests go directly to public YouTube/LRCLIB endpoints. No developer
  backend receives your data.
- Android app-data backup is disabled in the manifest, so the local database and
  audio cache are not uploaded to Google Drive.
- The app is single-user. There are no separate profiles or PIN protection; any
  person who can unlock the device can open the library.

## ⚠️ Disclaimer

Voidz Music is an unofficial client and is not affiliated with, endorsed by, or
sponsored by YouTube or Google. It accesses public endpoints and does not host
or distribute copyrighted content. Availability can break at any time when
those services change. Users are responsible for complying with applicable
terms of service and local law. The software is provided "as is", without
warranty.

## 🛠️ Technology Stack

- **Client:** Flutter, Riverpod (state management), Isar (local database),
  just_audio, go_router.
- **YouTube resolver:** `youtube_explode_dart` + YouTube Music InnerTube,
  running in-app.
- **Backend:** none. Requests go directly to public services.

## 🧑‍💻 Build from Source

### Flutter client

```bash
cd my_music_player
flutter pub get
flutter run
```

### Platform requirements

- **Android:** Android 8.0+ (API 26+).
- **iOS:** iOS 15+, built on macOS with Xcode and CocoaPods:

```bash
cd my_music_player
flutter pub get
cd ios && pod install && cd ..
flutter run -d ios
```

No backend URL configuration is needed. The resolver runs on the device.

### Release APK

Release builds use a local keystore and a `key.properties` file. Both are
ignored by git and must never be committed. The keystore can live outside the
repo; point Gradle at its properties file in one of these ways:

1. Add this to your user-level `~/.gradle/gradle.properties`:
   ```properties
   voidz.keystore.properties=D:/secure/Voidz-Music/key.properties
   ```
2. Set the `VOIDZ_KEYSTORE_PROPERTIES` environment variable to the same path.
3. Place `key.properties` at `my_music_player/android/key.properties`.

Inside `key.properties`, `storeFile` may be absolute or relative to the
properties file:

```properties
keyAlias=upload
storeFile=upload-keystore.jks
storePassword=...
keyPassword=...
```

The release task fails if no valid keystore is configured, so an accidental
debug-signed release cannot be published.

```bash
cd my_music_player
flutter clean
flutter pub get
flutter build apk --release --split-per-abi
```

Verify the signer before publishing:

```bash
apksigner verify --print-certs build/app/outputs/flutter-apk/app-arm64-v8a-release.apk
```

Do not distribute an APK signed with the Android debug key.

## 📝 License

Source code is licensed under the [MIT License](LICENSE). Third-party
dependencies keep their own licenses; their notices are available in
**Settings → About → Licenses** inside the app.
