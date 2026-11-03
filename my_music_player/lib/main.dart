import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:just_audio_background/just_audio_background.dart';
import 'package:isar/isar.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';

import 'dart:io';
import 'dart:convert';
import 'core/theme/app_theme.dart';
import 'core/router/app_router.dart';
import 'shared/widgets/app_chrome.dart';
import 'features/player/presentation/widgets/mini_player.dart';
import 'core/constants/enums.dart';
import 'core/utils/cache_dir_helper.dart';
import 'features/player/data/datasources/audio_player_service.dart';
import 'features/player/data/models/track_model.dart';
import 'features/player/data/models/queue_state_model.dart';
import 'features/player/data/models/queue_item_model.dart';
import 'features/settings/data/models/app_settings_model.dart';
import 'features/settings/presentation/providers/settings_provider.dart';
import 'features/player/presentation/providers/player_controller.dart';
import 'features/lyrics/data/models/lyrics_cache_model.dart';
import 'features/library/data/models/playlist_model.dart';
import 'features/library/data/models/playlist_track_model.dart';
import 'features/library/data/models/play_history_model.dart';
import 'features/search/data/models/search_history_model.dart';
import 'features/player/data/repositories/track_repository_impl.dart';
import 'core/providers/isar_provider.dart';
import 'core/network/local_proxy_server.dart';
import 'l10n/app_localizations.dart';

/// Resolves the locale passed to `MaterialApp`.
///
/// [AppLanguageMode.system] follows the platform when at least one platform
/// locale is supported. Unsupported platform locales fall back to English.
/// Explicit choices always return their locale.
Locale? resolveAppLocale(
  AppLanguageMode mode, {
  List<Locale>? platformLocales,
}) {
  switch (mode) {
    case AppLanguageMode.system:
      final locales = platformLocales;
      if (locales == null || locales.isEmpty) {
        return null;
      }
      final hasSupportedLocale = locales.any(
        (platformLocale) => AppLocalizations.supportedLocales.any(
          (supportedLocale) =>
              supportedLocale.languageCode == platformLocale.languageCode,
        ),
      );
      return hasSupportedLocale ? null : const Locale('en');
    case AppLanguageMode.english:
      return const Locale('en');
    case AppLanguageMode.indonesian:
      return const Locale('id');
  }
}

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Start the local proxy server for ExoPlayer — non-blocking with timeout
  try {
    await LocalProxyServer.instance.start().timeout(const Duration(seconds: 5));
  } catch (e) {
    print('LocalProxyServer start failed (non-fatal): $e');
  }

  // Request notification permission for Android 13+ — non-blocking.
  // iOS tidak memakai notifikasi lokal untuk playback; audio background
  // ditangani UIBackgroundModes.
  if (Platform.isAndroid) {
    try {
      await Permission.notification
          .request()
          .timeout(const Duration(seconds: 3));
    } catch (e) {
      print('Permission request timeout/non-fatal: $e');
    }
  }

  // Initialize JustAudioBackground for background playback — premium MediaStyle (artcover + 3 controls)
  try {
    await JustAudioBackground.init(
      androidNotificationChannelId: 'com.mymusic.my_music_player.channel.audio',
      androidNotificationChannelName: 'Audio playback',
      androidNotificationChannelDescription:
          'Playback controls for Voidz Music',
      androidNotificationIcon: 'drawable/ic_stat_music',
      androidNotificationOngoing: false,
      androidShowNotificationBadge: true,
      androidStopForegroundOnPause: true,
      artDownscaleWidth: 300,
      artDownscaleHeight: 300,
      preloadArtwork: true,
      fastForwardInterval: const Duration(seconds: 10),
      rewindInterval: const Duration(seconds: 10),
    ).timeout(const Duration(seconds: 5));
  } catch (e) {
    print('JustAudioBackground init failed (non-fatal): $e');
  }

  // Initialize Isar DB with timeout — critical, but don't hang splash forever
  late Isar isar;
  try {
    final dir = await getApplicationDocumentsDirectory()
        .timeout(const Duration(seconds: 5));
    isar = await Isar.open(
      [
        TrackModelSchema,
        QueueStateModelSchema,
        QueueItemModelSchema,
        AppSettingsModelSchema,
        LyricsCacheModelSchema,
        PlaylistModelSchema,
        PlaylistTrackModelSchema,
        PlayHistoryModelSchema,
        SearchHistoryModelSchema,
      ],
      directory: dir.path,
    ).timeout(const Duration(seconds: 10));
    // Premium: migrate cache dir in background (non-blocking)
    migrateCacheIfNeeded(isar)
        .catchError((e) => print('migrateCache error: $e'));
    // Sanitize crossfadeSeconds sentinel from old DB (Isar returns -9223372036854775808 for uninitialized int)
    try {
      final s = await isar.appSettingsModels.get(1);
      if (s != null && (s.crossfadeSeconds < 0 || s.crossfadeSeconds > 12)) {
        await isar.writeTxn(() async {
          s.crossfadeSeconds = 0;
          await isar.appSettingsModels.put(s);
        });
        print('Sanitized crossfadeSeconds sentinel');
      }
    } catch (e) {
      print('crossfade sanitize failed: $e');
    }

    // Create 1x1 transparent PNG for notification largeIcon placeholder (hide white box)
    try {
      final supDir = await getApplicationSupportDirectory();
      final transparentPath = '${supDir.path}/transparent.png';
      final f = File(transparentPath);
      if (!await f.exists() || await f.length() < 10) {
        const b64 =
            'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAQAAAC1HAwCAAAAC0lEQVR42mP8/x8AAwMCAO+ip1sAAAAASUVORK5CYII=';
        await f.writeAsBytes(base64Decode(b64), flush: true);
      }
      AudioPlayerService.transparentArtPath = transparentPath;
      print('Transparent art ready: $transparentPath');
    } catch (e) {
      print('Transparent art create failed: $e');
    }
  } catch (e) {
    print(
        'Isar open failed/timeout: $e — retrying documents dir without timeout (fix hot restart hilang)');
    // Ponytail: jangan fallback ke temp dir (akan bikin DB kosong & history hilang setelah hot restart).
    // Retry sekali lagi dengan documents dir tanpa timeout, baru fallback error UI.
    try {
      final retryDir = await getApplicationDocumentsDirectory();
      isar = await Isar.open(
        [
          TrackModelSchema,
          QueueStateModelSchema,
          QueueItemModelSchema,
          AppSettingsModelSchema,
          LyricsCacheModelSchema,
          PlaylistModelSchema,
          PlaylistTrackModelSchema,
          PlayHistoryModelSchema,
          SearchHistoryModelSchema,
        ],
        directory: retryDir.path,
      );
      print('Isar retry open succeeded: ${retryDir.path}');
    } catch (e2) {
      print('Retry Isar also failed: $e2');
      runApp(MaterialApp(
          home: Scaffold(
              body: Center(
                  child: Text(
                      'Database init failed. Please reinstall app.\n$e2')))));
      return;
    }
  }

  runApp(
    ProviderScope(
      overrides: [
        // Inject Isar instance into repository provider
        isarProvider.overrideWithValue(isar),
        trackRepositoryProvider.overrideWithValue(TrackRepositoryImpl(isar)),
      ],
      child: const MainApp(),
    ),
  );
}

class MainApp extends ConsumerStatefulWidget {
  const MainApp({super.key});

  @override
  ConsumerState<MainApp> createState() => _MainAppState();
}

class _MainAppState extends ConsumerState<MainApp> with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);

    // Restore queue on startup if enabled — fire & forget, never block UI
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      try {
        final isar = ref.read(isarProvider);
        final settings = await isar.appSettingsModels
            .get(1)
            .timeout(const Duration(seconds: 2));
        if (settings?.resumeOnStartup ?? true) {
          // Don't await — let it run in background, catch errors
          ref
              .read(playerControllerProvider.notifier)
              .restoreQueueState()
              .catchError((e) {
            print('restoreQueueState failed (non-fatal): $e');
          }).timeout(const Duration(seconds: 8), onTimeout: () {
            print('restoreQueueState timeout (non-fatal)');
          });
        }
      } catch (e) {
        print('Settings load failed (non-fatal): $e');
      }
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.inactive ||
        state == AppLifecycleState.detached ||
        state == AppLifecycleState.hidden) {
      ref.read(playerControllerProvider.notifier).saveQueueState();
    }
  }

  @override
  void didChangeLocales(List<Locale>? locales) {
    // Re-resolve the system locale fallback while the app is running.
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final goRouter = ref.watch(appRouterProvider);
    final hasTrack = ref.watch(
      playerControllerProvider.select((state) => state.currentTrack != null),
    );

    return VoidzApp(
      routerConfig: goRouter,
      miniPlayer: hasTrack ? const MiniPlayer() : null,
    );
  }
}

/// Root `MaterialApp` whose theme follows [themeModeProvider] and whose
/// locale follows the persisted [AppLanguageMode].
class VoidzApp extends ConsumerWidget {
  const VoidzApp({
    super.key,
    required this.routerConfig,
    this.miniPlayer,
  });

  final GoRouter routerConfig;

  /// Chrome injection point: the composition root owns the mini-player
  /// instance so `shared/` never imports a feature widget.
  final Widget? miniPlayer;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(appSettingsProvider).valueOrNull;
    final languageMode = settings?.appLanguageMode ?? AppLanguageMode.system;

    return MaterialApp.router(
      onGenerateTitle: (context) => AppLocalizations.of(context).appTitle,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: ref.watch(themeModeProvider),
      locale: resolveAppLocale(
        languageMode,
        platformLocales: WidgetsBinding.instance.platformDispatcher.locales,
      ),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      routerConfig: routerConfig,
      debugShowCheckedModeBanner: false,
      builder: (context, child) {
        return AppChrome(
          router: routerConfig,
          miniPlayer: miniPlayer,
          child: child ?? const SizedBox.shrink(),
        );
      },
    );
  }
}
