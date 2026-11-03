import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:my_music_player/core/theme/app_colors.dart';
import 'package:my_music_player/core/theme/app_glass.dart';
import 'package:my_music_player/features/cache/presentation/providers/cache_stats_provider.dart';
import 'package:my_music_player/features/settings/data/models/app_settings_model.dart';
import 'package:my_music_player/features/settings/presentation/providers/settings_provider.dart';
import 'package:my_music_player/features/settings/presentation/screens/settings_screen.dart';
import 'package:my_music_player/shared/widgets/glass_background.dart';
import 'package:my_music_player/shared/widgets/glass_surface.dart';

import '../../helpers/pump_app.dart';

class _FakeSettingsController extends Fake implements SettingsController {}

Future<void> _pumpSettings(
  WidgetTester tester, {
  ThemeMode themeMode = ThemeMode.dark,
  double textScale = 1.0,
  bool disableAnimations = false,
}) async {
  const screen = SettingsScreen();
  Widget child = screen;
  if (disableAnimations) {
    child = Builder(
      builder: (context) => MediaQuery(
        data: MediaQuery.of(context).copyWith(disableAnimations: true),
        child: screen,
      ),
    );
  }

  await pumpApp(
    tester,
    child,
    themeMode: themeMode,
    textScale: textScale,
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
  );
  await tester.pumpAndSettle();
}

Container _surfaceContainer(WidgetTester tester, Finder group) {
  return tester.widget<Container>(
    find.descendant(of: group, matching: find.byType(Container)).first,
  );
}

void _expectFrostedGroup(WidgetTester tester, String key) {
  final group = find.byKey(Key(key));
  expect(group, findsOneWidget, reason: key);
  expect(
    tester.widget<GlassSurface>(group).quality,
    GlassQuality.frosted,
    reason: key,
  );
  expect(
    find.descendant(of: group, matching: find.byType(BackdropFilter)),
    findsNothing,
    reason: key,
  );
}

void main() {
  testWidgets('settings groups are frosted glass over the aurora',
      (tester) async {
    await _pumpSettings(tester);

    expect(
      tester.widget<Scaffold>(find.byType(Scaffold)).backgroundColor,
      Colors.transparent,
    );
    expect(find.byType(GlassBackground), findsOneWidget);

    _expectFrostedGroup(tester, 'settings-group-playback');
    _expectFrostedGroup(tester, 'settings-group-downloads');

    await tester.scrollUntilVisible(
      find.byKey(const Key('settings-group-appearance')),
      200,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();
    _expectFrostedGroup(tester, 'settings-group-appearance');

    await tester.scrollUntilVisible(
      find.byKey(const Key('settings-group-about')),
      200,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();
    _expectFrostedGroup(tester, 'settings-group-about');

    // Four groups cannot each blur without breaking the 2-3 layer cap.
    expect(find.byType(BackdropFilter), findsNothing);
    expect(find.byType(Switch), findsWidgets);
    expect(tester.takeException(), isNull);
  });

  testWidgets('light theme uses the provisional glass card fill and border',
      (tester) async {
    await _pumpSettings(tester, themeMode: ThemeMode.light);

    final group = find.byKey(const Key('settings-group-playback'));
    final surface = _surfaceContainer(tester, group);
    final decoration = surface.decoration! as BoxDecoration;
    expect(
      decoration.color,
      AppGlass.light.card.frostedFill(AppColors.light.surface),
    );

    final foreground = surface.foregroundDecoration! as BoxDecoration;
    final border = foreground.border! as Border;
    expect(border.top.color, AppGlass.light.card.border);

    expect(
      tester.widget<Text>(find.text('PLAYBACK')).style?.color,
      AppColors.light.textSecondary,
    );
    expect(
      tester.widget<Text>(find.text('Audio quality')).style?.color,
      AppColors.light.textPrimary,
    );
  });

  testWidgets('disableAnimations keeps the frosted groups readable',
      (tester) async {
    await _pumpSettings(tester, disableAnimations: true);

    expect(find.byType(BackdropFilter), findsNothing);
    _expectFrostedGroup(tester, 'settings-group-playback');
    expect(find.text('Audio quality'), findsOneWidget);
    expect(find.byType(Switch), findsWidgets);

    await tester.scrollUntilVisible(
      find.byKey(const Key('settings-group-about')),
      200,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();
    _expectFrostedGroup(tester, 'settings-group-about');
    expect(tester.takeException(), isNull);
  });

  for (final themeMode in [ThemeMode.dark, ThemeMode.light]) {
    testWidgets(
      'settings glass survives 200% text scale (${themeMode.name})',
      (tester) async {
        await _pumpSettings(
          tester,
          themeMode: themeMode,
          textScale: 2.0,
        );

        expect(tester.takeException(), isNull);
        expect(
            find.byKey(const Key('settings-group-playback')), findsOneWidget);

        await tester.scrollUntilVisible(
          find.text('ABOUT'),
          200,
          scrollable: find.byType(Scrollable).first,
        );
        await tester.pumpAndSettle();

        expect(find.byKey(const Key('settings-group-about')), findsOneWidget);
        expect(tester.takeException(), isNull);
      },
    );
  }
}
