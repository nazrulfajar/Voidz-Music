import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:my_music_player/core/constants/app_info.dart';
import 'package:my_music_player/core/constants/enums.dart';
import 'package:my_music_player/core/theme/app_colors.dart';
import 'package:my_music_player/features/cache/presentation/providers/cache_stats_provider.dart';
import 'package:my_music_player/features/settings/data/models/app_settings_model.dart';
import 'package:my_music_player/features/settings/presentation/providers/settings_provider.dart';
import 'package:my_music_player/features/settings/presentation/screens/settings_screen.dart';

import '../../helpers/pump_app.dart';

const _sceneHeight = 1400.0;

const _usageBytes = 1288490189; // 1.2 GiB
const _maxBytes = 2147483648; // 2 GiB

class _RecordingSettingsController extends Fake implements SettingsController {
  AudioQuality? quality;
  int? cacheLimitMb;
  bool? autoCache;
  bool? wifiOnly;
  bool? resumeOnStartup;
  bool? audioFocusPause;
  bool? youtubeSource;
  int? crossfadeSeconds;
  AppThemeMode? themeMode;

  @override
  Future<void> setAudioQuality(AudioQuality quality) async {
    this.quality = quality;
  }

  @override
  Future<void> setCacheLimitMb(int mb) async {
    cacheLimitMb = mb;
  }

  @override
  Future<void> toggleAutoCache(bool enabled) async {
    autoCache = enabled;
  }

  @override
  Future<void> toggleWifiOnly(bool enabled) async {
    wifiOnly = enabled;
  }

  @override
  Future<void> toggleResumeOnStartup(bool enabled) async {
    resumeOnStartup = enabled;
  }

  @override
  Future<void> toggleAudioFocusPause(bool enabled) async {
    audioFocusPause = enabled;
  }

  @override
  Future<void> toggleYoutubeSource(bool enabled) async {
    youtubeSource = enabled;
  }

  @override
  Future<void> setCrossfade(int seconds) async {
    crossfadeSeconds = seconds;
  }

  @override
  Future<void> setThemeMode(AppThemeMode mode) async {
    themeMode = mode;
  }
}

void main() {
  late _RecordingSettingsController controller;

  Future<void> pumpSettings(
    WidgetTester tester, {
    ThemeMode themeMode = ThemeMode.dark,
    double textScale = 1.0,
    Size surfaceSize = const Size(360, _sceneHeight),
    AppSettingsModel? settings,
  }) async {
    controller = _RecordingSettingsController();

    await pumpApp(
      tester,
      ProviderScope(
        overrides: [
          appSettingsProvider.overrideWith(
            (ref) => Stream.value(settings ?? AppSettingsModel()),
          ),
          cacheStatsProvider.overrideWith(
            (ref) async => CacheStats(
              totalCachedTracks: 2,
              totalCacheSizeBytes: _usageBytes,
              maxCacheSizeBytes: _maxBytes,
              usagePercentage: 0.6,
              pinnedTrackIds: const [],
            ),
          ),
          settingsControllerProvider.overrideWithValue(controller),
        ],
        child: const SettingsScreen(),
      ),
      themeMode: themeMode,
      textScale: textScale,
      surfaceSize: surfaceSize,
    );
    await tester.pumpAndSettle();
  }

  double topOf(WidgetTester tester, String text) {
    return tester.getTopLeft(find.text(text)).dy;
  }

  group('Settings parity', () {
    testWidgets('sections run PLAYBACK, DOWNLOADS, APPEARANCE, ABOUT', (
      tester,
    ) async {
      await pumpSettings(tester);

      final playback = topOf(tester, 'PLAYBACK');
      final downloads = topOf(tester, 'DOWNLOADS');
      final appearance = topOf(tester, 'APPEARANCE');
      final about = topOf(tester, 'ABOUT');

      expect(playback, lessThan(downloads));
      expect(downloads, lessThan(appearance));
      expect(appearance, lessThan(about));

      for (final obsolete in ['SOURCES', 'AUDIO', 'CACHE', 'EXTRACTOR']) {
        expect(
          find.text(obsolete),
          findsNothing,
          reason: '$obsolete is not a Settings section anymore',
        );
      }
    });

    testWidgets('playback keeps quality, gapless, resume, focus, source', (
      tester,
    ) async {
      await pumpSettings(tester);

      final playback = topOf(tester, 'PLAYBACK');
      final downloads = topOf(tester, 'DOWNLOADS');

      for (final label in [
        'Audio quality',
        'Gapless / Crossfade',
        'Resume on startup',
        'Audio focus',
        'YouTube source',
      ]) {
        final y = topOf(tester, label);
        expect(y, greaterThan(playback), reason: '$label under Playback');
        expect(y, lessThan(downloads), reason: '$label under Playback');
      }
    });

    testWidgets('downloads group owns wifi, limit, auto-cache and summary', (
      tester,
    ) async {
      await pumpSettings(tester);

      final downloads = topOf(tester, 'DOWNLOADS');
      final appearance = topOf(tester, 'APPEARANCE');

      for (final label in [
        'Wi-Fi only',
        'Storage limit',
        'Storage used',
        'Auto-cache',
        'Clear cache',
      ]) {
        final y = topOf(tester, label);
        expect(y, greaterThan(downloads), reason: '$label under Downloads');
        expect(y, lessThan(appearance), reason: '$label under Downloads');
      }

      expect(find.text('1.2 GB / 2 GB'), findsOneWidget);
      expect(find.byType(Switch), findsNothing);

      await tester.tap(find.text('Storage limit'));
      await tester.pumpAndSettle();

      final slider = tester.widget<Slider>(find.byType(Slider));
      expect(slider.min, 250);
      expect(slider.max, 10000);
      expect(slider.value, 1024);
    });

    testWidgets('wifi only row toggles through the controller', (tester) async {
      await pumpSettings(tester);

      await tester.tap(find.text('Wi-Fi only'));
      await tester.pump();

      expect(controller.wifiOnly, isTrue);
    });

    testWidgets('appearance keeps the TASK-022 theme row', (tester) async {
      await pumpSettings(tester);

      final appearance = topOf(tester, 'APPEARANCE');
      final about = topOf(tester, 'ABOUT');
      final theme = topOf(tester, 'Theme');
      expect(theme, greaterThan(appearance));
      expect(theme, lessThan(about));
      expect(find.text('Dynamic color'), findsNothing);

      await tester.tap(find.text('Theme'));
      await tester.pumpAndSettle();

      expect(find.text('System'), findsWidgets);
      expect(find.text('Light'), findsOneWidget);
      expect(find.text('Dark'), findsOneWidget);

      await tester.tap(find.text('Light'));
      await tester.pumpAndSettle();

      expect(controller.themeMode, AppThemeMode.light);
    });

    testWidgets('about shows version and opens licenses, without reset', (
      tester,
    ) async {
      await pumpSettings(tester);

      expect(appVersion, '0.1.0+1');
      expect(find.text(appVersion), findsOneWidget);
      expect(find.text('Reset app'), findsNothing);

      final pubspec = File('pubspec.yaml').readAsStringSync();
      final version = RegExp(
        r'^version:\s*(\S+)',
        multiLine: true,
      ).firstMatch(pubspec)?.group(1);
      expect(version, appVersion);

      await tester.tap(find.text('Licenses'));
      await tester.pumpAndSettle();

      expect(find.byType(LicensePage), findsOneWidget);
    });

    testWidgets('renders no obsolete extractor vocabulary', (tester) async {
      await pumpSettings(tester);

      expect(
        find.textContaining(
          RegExp('extractor|yt-dlp|python|chaquopy', caseSensitive: false),
        ),
        findsNothing,
      );
    });

    testWidgets('stays overflow-free at 200% text scale', (tester) async {
      await pumpSettings(
        tester,
        textScale: 2.0,
        surfaceSize: const Size(360, 640),
      );

      expect(find.text('PLAYBACK'), findsOneWidget);
      expect(tester.takeException(), isNull, reason: 'initial paint');

      await tester.scrollUntilVisible(
        find.text('ABOUT'),
        60,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.pumpAndSettle();

      expect(find.text('ABOUT'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('rows use surface and border tokens in light theme', (
      tester,
    ) async {
      await pumpSettings(tester, themeMode: ThemeMode.light);

      final group = tester.widget<Material>(
        find
            .ancestor(
              of: find.text('Audio quality'),
              matching: find.byType(Material),
            )
            .first,
      );
      expect(group.color, AppColors.light.surface);
      final shape = group.shape! as RoundedRectangleBorder;
      expect(shape.side.color, AppColors.light.border);

      final label = tester.widget<Text>(find.text('Audio quality'));
      expect(label.style?.color, AppColors.light.textPrimary);
      expect(label.style?.fontSize, 14);

      final value = tester.widget<Text>(find.text('Medium'));
      expect(value.style?.color, AppColors.light.textSecondary);
      expect(value.style?.fontSize, 12);

      expect(tester.takeException(), isNull);
    });
  });
}
