import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:isar/isar.dart';
import 'package:my_music_player/core/constants/enums.dart';
import 'package:my_music_player/core/theme/app_colors.dart';
import 'package:my_music_player/core/theme/app_theme.dart';
import 'package:my_music_player/features/cache/presentation/providers/cache_stats_provider.dart';
import 'package:my_music_player/features/settings/data/models/app_settings_model.dart';
import 'package:my_music_player/features/settings/presentation/providers/settings_provider.dart';
import 'package:my_music_player/features/settings/presentation/screens/settings_screen.dart';
import 'package:my_music_player/main.dart' as app;
import 'package:mocktail/mocktail.dart';

import '../../helpers/pump_app.dart';

void main() {
  setUpAll(() {
    registerFallbackValue(AppSettingsModel());
  });

  group('AppThemeMode', () {
    test('keeps Isar ordinals stable with system first', () {
      expect(AppThemeMode.values, [
        AppThemeMode.system,
        AppThemeMode.light,
        AppThemeMode.dark,
      ]);
      expect(AppThemeMode.system.index, 0);
    });

    test('new settings default to system', () {
      expect(AppSettingsModel().appThemeMode, AppThemeMode.system);
    });

    test('maps every value to the matching ThemeMode', () {
      expect(AppThemeMode.system.themeMode, ThemeMode.system);
      expect(AppThemeMode.light.themeMode, ThemeMode.light);
      expect(AppThemeMode.dark.themeMode, ThemeMode.dark);
    });

    test('generated schema stores the enum ordinal for system first', () {
      final property = AppSettingsModelSchema.properties['appThemeMode']!;
      expect(property.type, IsarType.byte);
      expect(property.enumMap!['system'], 0);
      expect(property.enumMap!['light'], 1);
      expect(property.enumMap!['dark'], 2);
    });
  });

  group('themeModeProvider', () {
    test('follows the persisted theme preference', () async {
      final container = ProviderContainer(
        overrides: [
          appSettingsProvider.overrideWith(
            (ref) => Stream.value(
              AppSettingsModel()..appThemeMode = AppThemeMode.light,
            ),
          ),
        ],
      );
      addTearDown(container.dispose);

      await container.read(appSettingsProvider.future);

      expect(container.read(themeModeProvider), ThemeMode.light);
    });

    test('falls back to system when settings are not available', () {
      final container = ProviderContainer(
        overrides: [
          appSettingsProvider.overrideWith((ref) => const Stream.empty()),
        ],
      );
      addTearDown(container.dispose);

      expect(container.read(themeModeProvider), ThemeMode.system);
    });
  });

  group('VoidzApp theme rendering', () {
    Future<void> pumpVoidzApp(
      WidgetTester tester,
      AppThemeMode mode,
    ) async {
      tester.view.devicePixelRatio = 1.0;
      tester.view.physicalSize = const Size(360, 640);
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final router = GoRouter(
        routes: [
          GoRoute(
            path: '/',
            builder: (context, state) =>
                const Scaffold(body: Text('theme probe')),
          ),
        ],
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            appSettingsProvider.overrideWith(
              (ref) => Stream.value(
                AppSettingsModel()..appThemeMode = mode,
              ),
            ),
          ],
          child: app.VoidzApp(routerConfig: router),
        ),
      );
      await tester.pumpAndSettle();
    }

    testWidgets('light setting renders the light theme', (tester) async {
      await pumpVoidzApp(tester, AppThemeMode.light);

      final materialApp = tester.widget<MaterialApp>(find.byType(MaterialApp));
      expect(materialApp.themeMode, ThemeMode.light);
      expect(materialApp.theme?.brightness, Brightness.light);
      expect(
        Theme.of(tester.element(find.text('theme probe'))).brightness,
        Brightness.light,
      );
    });

    testWidgets('dark setting renders the dark theme', (tester) async {
      await pumpVoidzApp(tester, AppThemeMode.dark);

      final materialApp = tester.widget<MaterialApp>(find.byType(MaterialApp));
      expect(materialApp.themeMode, ThemeMode.dark);
      expect(materialApp.darkTheme?.brightness, Brightness.dark);
      expect(
        Theme.of(tester.element(find.text('theme probe'))).brightness,
        Brightness.dark,
      );
    });

    for (final brightness in [Brightness.light, Brightness.dark]) {
      testWidgets(
        'system setting follows the OS (${brightness.name})',
        (tester) async {
          tester.platformDispatcher.platformBrightnessTestValue = brightness;
          addTearDown(
            tester.platformDispatcher.clearPlatformBrightnessTestValue,
          );

          await pumpVoidzApp(tester, AppThemeMode.system);

          expect(
            tester.widget<MaterialApp>(find.byType(MaterialApp)).themeMode,
            ThemeMode.system,
          );
          expect(
            Theme.of(tester.element(find.text('theme probe'))).brightness,
            brightness,
          );
        },
      );
    }
  });

  group('Settings appearance section', () {
    late _RecordingSettingsController controller;

    Future<void> pumpSettings(
      WidgetTester tester, {
      AppThemeMode mode = AppThemeMode.system,
      ThemeMode themeMode = ThemeMode.dark,
    }) async {
      controller = _RecordingSettingsController();

      await pumpApp(
        tester,
        ProviderScope(
          overrides: [
            appSettingsProvider.overrideWith(
              (ref) => Stream.value(
                AppSettingsModel()..appThemeMode = mode,
              ),
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
            settingsControllerProvider.overrideWithValue(controller),
          ],
          child: const SettingsScreen(),
        ),
        themeMode: themeMode,
      );
      await tester.pumpAndSettle();
    }

    testWidgets('shows the Appearance section with the current value', (
      tester,
    ) async {
      await pumpSettings(tester, mode: AppThemeMode.dark);

      await tester.scrollUntilVisible(
        find.text('APPEARANCE'),
        200,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.pumpAndSettle();

      expect(find.text('APPEARANCE'), findsOneWidget);
      expect(find.text('Theme'), findsOneWidget);
      expect(find.text('Dark'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('picker lists System, Light and Dark and saves the choice', (
      tester,
    ) async {
      await pumpSettings(tester);

      await tester.scrollUntilVisible(
        find.text('Theme'),
        200,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('Theme'));
      await tester.pumpAndSettle();

      expect(find.text('System'), findsWidgets);
      expect(find.text('Light'), findsOneWidget);
      expect(find.text('Dark'), findsOneWidget);

      await tester.tap(find.text('Light'));
      await tester.pumpAndSettle();

      expect(controller.selected, AppThemeMode.light);
    });

    testWidgets('appearance row uses theme tokens in light mode', (
      tester,
    ) async {
      await pumpSettings(tester, themeMode: ThemeMode.light);
      await tester.scrollUntilVisible(
        find.text('Theme'),
        200,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.pumpAndSettle();

      final value = tester.widget<Text>(find.text('System'));
      expect(value.style?.color, AppColors.light.textSecondary);
    });
  });

  group('SettingsController.setThemeMode', () {
    late _MockSettingsCollection collection;
    late SettingsController controller;
    late _FakeIsar isar;
    AppSettingsModel? saved;

    setUp(() {
      collection = _MockSettingsCollection();
      saved = null;

      when(() => collection.get(1)).thenAnswer((_) async => AppSettingsModel());
      when(() => collection.put(any())).thenAnswer((invocation) async {
        saved = invocation.positionalArguments.first as AppSettingsModel;
        return 1;
      });

      isar = _FakeIsar(collection);
      controller = SettingsController(_MockRef(), isar);
    });

    test('persists light and dark selections', () async {
      await controller.setThemeMode(AppThemeMode.light);
      expect(saved?.appThemeMode, AppThemeMode.light);

      await controller.setThemeMode(AppThemeMode.dark);
      expect(saved?.appThemeMode, AppThemeMode.dark);
    });
  });
}

class _FakeIsar extends Fake implements Isar {
  _FakeIsar(this.settingsCollection);

  final IsarCollection<AppSettingsModel> settingsCollection;

  @override
  IsarCollection<T> collection<T>() => settingsCollection as IsarCollection<T>;

  @override
  Future<T> writeTxn<T>(
    Future<T> Function() callback, {
    bool silent = false,
  }) =>
      callback();
}

class _RecordingSettingsController extends Fake implements SettingsController {
  AppThemeMode? selected;

  @override
  Future<void> setThemeMode(AppThemeMode mode) async {
    selected = mode;
  }
}

class _MockSettingsCollection extends Mock
    implements IsarCollection<AppSettingsModel> {}

class _MockRef extends Mock implements Ref {}
