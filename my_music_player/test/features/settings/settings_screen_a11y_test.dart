import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:my_music_player/core/constants/enums.dart';
import 'package:my_music_player/core/theme/app_colors.dart';
import 'package:my_music_player/features/cache/presentation/providers/cache_stats_provider.dart';
import 'package:my_music_player/features/player/domain/entities/track.dart';
import 'package:my_music_player/features/recap/domain/entities/recap.dart';
import 'package:my_music_player/features/recap/domain/entities/recap_period.dart';
import 'package:my_music_player/features/recap/presentation/providers/recap_provider.dart';
import 'package:my_music_player/features/recap/presentation/screens/recap_screen.dart';
import 'package:my_music_player/features/settings/data/models/app_settings_model.dart';
import 'package:my_music_player/features/settings/presentation/providers/settings_provider.dart';
import 'package:my_music_player/features/settings/presentation/screens/settings_screen.dart';

import '../../helpers/pump_app.dart';

class _FakeSettingsController extends Fake implements SettingsController {}

void main() {
  Future<void> pumpSettings(
    WidgetTester tester, {
    ThemeMode themeMode = ThemeMode.dark,
    double textScale = 1.0,
  }) async {
    await pumpApp(
      tester,
      ProviderScope(
        overrides: [
          appSettingsProvider.overrideWith(
            (ref) => Stream.value(AppSettingsModel()),
          ),
          cacheStatsProvider.overrideWith(
            (ref) async => CacheStats(
              totalCachedTracks: 2,
              totalCacheSizeBytes: 100 * 1024 * 1024,
              maxCacheSizeBytes: 1024 * 1024 * 1024,
              usagePercentage: 0.1,
              pinnedTrackIds: const [],
            ),
          ),
          settingsControllerProvider.overrideWithValue(
            _FakeSettingsController(),
          ),
        ],
        child: const SettingsScreen(),
      ),
      themeMode: themeMode,
      textScale: textScale,
    );
    await tester.pumpAndSettle();
  }

  Future<void> pumpRecap(
    WidgetTester tester, {
    ThemeMode themeMode = ThemeMode.dark,
    double textScale = 1.0,
  }) async {
    const track = Track(
      sourceId: 'track-1',
      title: 'Night Drive',
      artist: 'Aurora',
      album: 'Signals',
      durationMs: 215000,
      source: TrackSource.youtube,
    );
    const recap = Recap(
      year: 2024,
      mostPlayed: track,
      mostPlayedCount: 9,
      topSongs: [],
      topSongCounts: [],
      topArtists: [],
      topAlbums: [],
      totalPlays: 45,
      totalTracks: 12,
    );

    await pumpApp(
      tester,
      ProviderScope(
        overrides: [
          selectedRecapPeriodProvider.overrideWith(
            (ref) => RecapPeriod.year,
          ),
          selectedRecapYearProvider.overrideWith((ref) => 2024),
          selectedRecapMonthProvider.overrideWith((ref) => 10),
          recapProvider.overrideWith((ref, query) async => recap),
          recapYearsProvider.overrideWith((ref) async => [2024, 2023]),
        ],
        child: const RecapScreen(),
      ),
      themeMode: themeMode,
      textScale: textScale,
    );
    await tester.pumpAndSettle();
  }

  group('SettingsScreen accessibility', () {
    testWidgets('labels every interactive control', (tester) async {
      final handle = tester.ensureSemantics();
      await pumpSettings(tester);

      const topLabels = [
        'Enable YouTube Source',
        'Preferred Audio Quality',
        'Storage Used',
        'Max Cache Size',
        'Auto-Cache on Play',
        'Download on Wi-Fi Only',
        'Clear Cache',
      ];

      for (final label in topLabels) {
        expect(
          find.bySemanticsLabel(RegExp(label)),
          findsWidgets,
          reason: '"$label" must be readable by a screen reader',
        );
      }

      await tester.scrollUntilVisible(
        find.text('Resume on Startup'),
        200,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.pumpAndSettle();

      const bottomLabels = [
        'Resume on Startup',
        'Pause on Audio Focus Loss',
        'Crossfade',
      ];

      for (final label in bottomLabels) {
        expect(
          find.bySemanticsLabel(RegExp(label)),
          findsWidgets,
          reason: '"$label" must be readable by a screen reader',
        );
      }
      expect(find.byTooltip('Back'), findsOneWidget);
      handle.dispose();
    });

    testWidgets('every control meets the 48dp touch target', (tester) async {
      await pumpSettings(tester);

      void expectMinHeight(Finder finder, String label) {
        final widgets = finder.evaluate().length;
        expect(widgets, greaterThan(0), reason: '$label should exist');
        for (var i = 0; i < widgets; i++) {
          final size = tester.getSize(finder.at(i));
          expect(
            size.height,
            greaterThanOrEqualTo(48),
            reason: '$label target ${size.height}dp is below 48dp',
          );
        }
      }

      expectMinHeight(find.byType(SwitchListTile), 'SwitchListTile');
      expectMinHeight(find.byType(ListTile), 'ListTile');
      expectMinHeight(
        find.byType(DropdownButton<AudioQuality>),
        'DropdownButton',
      );
      expectMinHeight(find.byType(Slider), 'Slider');
      expectMinHeight(find.byType(IconButton), 'IconButton');
    });

    for (final themeMode in [ThemeMode.dark, ThemeMode.light]) {
      testWidgets(
        'stays overflow-free at 200% text scale (${themeMode.name})',
        (tester) async {
          await pumpSettings(
            tester,
            themeMode: themeMode,
            textScale: 2.0,
          );

          expect(find.text('SOURCES'), findsOneWidget);
          expect(tester.takeException(), isNull);

          await tester.scrollUntilVisible(
            find.text('Gapless'),
            200,
            scrollable: find.byType(Scrollable).first,
          );
          await tester.pumpAndSettle();

          expect(find.text('Gapless'), findsOneWidget);
          expect(tester.takeException(), isNull);
        },
      );
    }

    testWidgets('uses light theme tokens for surfaces and text',
        (tester) async {
      await pumpSettings(tester, themeMode: ThemeMode.light);

      final scaffold = tester.widget<Scaffold>(find.byType(Scaffold));
      expect(scaffold.backgroundColor, AppColors.light.background);

      final sectionTitle = tester.widget<Text>(find.text('SOURCES'));
      expect(sectionTitle.style?.color, AppColors.light.textSecondary);

      final switchTitle =
          tester.widget<Text>(find.text('Enable YouTube Source'));
      expect(switchTitle.style?.color, AppColors.light.textPrimary);

      final card = tester.widget<Material>(
        find
            .ancestor(
              of: find.text('Enable YouTube Source'),
              matching: find.byType(Material),
            )
            .first,
      );
      expect(card.color, AppColors.light.surface);
      final shape = card.shape! as RoundedRectangleBorder;
      expect(shape.side.color, AppColors.light.border);

      final cacheMeta = tester.widget<Text>(
        find.textContaining('MB /').first,
      );
      expect(cacheMeta.style?.color, AppColors.light.textSecondary);
    });
  });

  group('RecapScreen header accessibility', () {
    testWidgets('keeps stats readable at 200% text scale in light theme',
        (tester) async {
      await pumpRecap(
        tester,
        themeMode: ThemeMode.light,
        textScale: 2.0,
      );

      expect(find.text('Total Putar'), findsOneWidget);
      expect(find.text('45'), findsOneWidget);
      expect(find.text('Lagu Unik'), findsOneWidget);
      expect(find.text('12'), findsOneWidget);
      expect(tester.takeException(), isNull);

      final label = tester.widget<Text>(find.text('Total Putar'));
      expect(label.style?.color, AppColors.light.textSecondary);
      final value = tester.widget<Text>(find.text('45'));
      expect(value.style?.color, AppColors.light.accent);
    });
  });
}
