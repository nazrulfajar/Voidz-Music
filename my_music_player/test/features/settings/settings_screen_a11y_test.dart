import 'dart:async';
import 'dart:ui' show Tristate;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:my_music_player/core/constants/enums.dart';
import 'package:my_music_player/core/theme/app_colors.dart';
import 'package:my_music_player/core/theme/app_glass.dart';
import 'package:my_music_player/features/cache/presentation/providers/cache_stats_provider.dart';
import 'package:my_music_player/features/player/domain/entities/track.dart';
import 'package:my_music_player/features/recap/domain/entities/recap.dart';
import 'package:my_music_player/features/recap/domain/entities/recap_period.dart';
import 'package:my_music_player/features/recap/presentation/providers/recap_provider.dart';
import 'package:my_music_player/features/recap/presentation/screens/recap_screen.dart';
import 'package:my_music_player/features/settings/data/models/app_settings_model.dart';
import 'package:my_music_player/features/settings/presentation/providers/settings_provider.dart';
import 'package:my_music_player/features/settings/presentation/screens/settings_screen.dart';
import 'package:my_music_player/shared/widgets/glass_background.dart';
import 'package:my_music_player/shared/widgets/glass_surface.dart';

import '../../helpers/pump_app.dart';

class _FakeSettingsController extends Fake implements SettingsController {}

class _TogglingSettingsController extends Fake implements SettingsController {
  _TogglingSettingsController(this.model, this.updates);

  final AppSettingsModel model;
  final StreamController<AppSettingsModel> updates;
  bool? resumeOnStartup;

  @override
  Future<void> toggleResumeOnStartup(bool enabled) async {
    resumeOnStartup = enabled;
    model.resumeOnStartup = enabled;
    updates.add(model);
  }
}

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
      locale: const Locale('id'),
    );
    await tester.pumpAndSettle();
  }

  group('SettingsScreen accessibility', () {
    testWidgets('labels every interactive control', (tester) async {
      final handle = tester.ensureSemantics();
      await pumpSettings(tester);

      const topLabels = [
        'Audio quality',
        'Gapless / Crossfade',
        'Resume on startup',
        'Audio focus',
        'YouTube source',
      ];

      for (final label in topLabels) {
        expect(
          find.bySemanticsLabel(RegExp(label)),
          findsWidgets,
          reason: '"$label" must be readable by a screen reader',
        );
      }

      await tester.scrollUntilVisible(
        find.text('Clear cache'),
        200,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.pumpAndSettle();

      const downloadLabels = [
        'Wi-Fi only',
        'Storage limit',
        'Storage used',
        'Auto-cache',
        'Clear cache',
      ];

      for (final label in downloadLabels) {
        expect(
          find.bySemanticsLabel(RegExp(label)),
          findsWidgets,
          reason: '"$label" must be readable by a screen reader',
        );
      }

      await tester.scrollUntilVisible(
        find.text('Licenses'),
        200,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.pumpAndSettle();

      const aboutLabels = ['Version', 'Licenses'];

      for (final label in aboutLabels) {
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

      const labels = [
        'Audio quality',
        'Gapless / Crossfade',
        'Resume on startup',
        'Audio focus',
        'YouTube source',
        'Wi-Fi only',
        'Storage limit',
        'Auto-cache',
        'Clear cache',
        'Theme',
        'Licenses',
      ];

      for (final label in labels) {
        await tester.scrollUntilVisible(
          find.text(label),
          120,
          scrollable: find.byType(Scrollable).first,
        );
        await tester.pumpAndSettle();

        final row = find
            .ancestor(
              of: find.text(label),
              matching: find.byType(InkWell),
            )
            .first;
        final size = tester.getSize(row);
        expect(
          size.height,
          greaterThanOrEqualTo(48),
          reason: '$label row ${size.height}dp is below 48dp',
        );
      }

      final backButton = tester.getSize(find.byType(IconButton).first);
      expect(
        backButton.height,
        greaterThanOrEqualTo(48),
        reason: 'Back button ${backButton.height}dp is below 48dp',
      );
    });

    testWidgets('boolean rows expose visible switches with toggled semantics',
        (tester) async {
      final semantics = tester.ensureSemantics();
      final model = AppSettingsModel();
      final updates = StreamController<AppSettingsModel>.broadcast();
      addTearDown(updates.close);
      final toggling = _TogglingSettingsController(model, updates);

      await pumpApp(
        tester,
        ProviderScope(
          overrides: [
            appSettingsProvider.overrideWith((ref) async* {
              yield model;
              yield* updates.stream;
            }),
            cacheStatsProvider.overrideWith(
              (ref) async => CacheStats(
                totalCachedTracks: 2,
                totalCacheSizeBytes: 100 * 1024 * 1024,
                maxCacheSizeBytes: 1024 * 1024 * 1024,
                usagePercentage: 0.1,
                pinnedTrackIds: const [],
              ),
            ),
            settingsControllerProvider.overrideWithValue(toggling),
          ],
          child: const SettingsScreen(),
        ),
      );
      await tester.pumpAndSettle();

      final label = find.text('Resume on startup');
      expect(label, findsOneWidget);
      final row =
          find.ancestor(of: label, matching: find.byType(InkWell)).first;
      final switchFinder =
          find.descendant(of: row, matching: find.byType(Switch));
      expect(switchFinder, findsOneWidget);
      expect(find.byType(Switch), findsNWidgets(5));
      expect(
        tester.getSize(switchFinder).height,
        greaterThanOrEqualTo(48),
      );
      expect(find.text('On'), findsNothing);
      expect(find.text('Off'), findsNothing);

      var node =
          tester.getSemantics(find.bySemanticsLabel('Resume on startup'));
      expect(node.label, contains('Resume on startup'));
      expect(node.flagsCollection.isToggled, isNot(Tristate.none));
      expect(node.flagsCollection.isToggled, Tristate.isTrue);

      await tester.tap(switchFinder);
      await tester.pumpAndSettle();

      expect(toggling.resumeOnStartup, isFalse);
      node = tester.getSemantics(find.bySemanticsLabel('Resume on startup'));
      expect(node.flagsCollection.isToggled, Tristate.isFalse);
      semantics.dispose();
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

          expect(find.text('PLAYBACK'), findsOneWidget);
          expect(tester.takeException(), isNull);

          await tester.scrollUntilVisible(
            find.text('ABOUT'),
            200,
            scrollable: find.byType(Scrollable).first,
          );
          await tester.pumpAndSettle();

          expect(find.text('ABOUT'), findsOneWidget);
          expect(tester.takeException(), isNull);
        },
      );
    }

    testWidgets('uses light theme tokens for surfaces and text',
        (tester) async {
      await pumpSettings(tester, themeMode: ThemeMode.light);

      final scaffold = tester.widget<Scaffold>(find.byType(Scaffold));
      expect(scaffold.backgroundColor, Colors.transparent);
      expect(find.byType(GlassBackground), findsOneWidget);

      final sectionTitle = tester.widget<Text>(find.text('PLAYBACK'));
      expect(sectionTitle.style?.color, AppColors.light.textSecondary);

      final rowLabel = tester.widget<Text>(find.text('Audio quality'));
      expect(rowLabel.style?.color, AppColors.light.textPrimary);

      final group = find.byKey(const Key('settings-group-playback'));
      expect(
        tester.widget<GlassSurface>(group).quality,
        GlassQuality.frosted,
      );
      final surface = tester.widget<Container>(
        find.descendant(of: group, matching: find.byType(Container)).first,
      );
      final decoration = surface.decoration! as BoxDecoration;
      expect(
        decoration.color,
        AppGlass.light.card.frostedFill(AppColors.light.surface),
      );
      final foreground = surface.foregroundDecoration! as BoxDecoration;
      final border = foreground.border! as Border;
      expect(border.top.color, AppGlass.light.card.border);

      final value = tester.widget<Text>(find.text('Medium'));
      expect(value.style?.color, AppColors.light.textSecondary);
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
