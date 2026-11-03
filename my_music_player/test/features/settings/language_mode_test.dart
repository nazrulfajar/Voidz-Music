import 'dart:async';
import 'dart:ui' show Tristate;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:isar/isar.dart';
import 'package:mocktail/mocktail.dart';
import 'package:my_music_player/core/constants/enums.dart';
import 'package:my_music_player/features/cache/presentation/providers/cache_stats_provider.dart';
import 'package:my_music_player/features/settings/data/models/app_settings_model.dart';
import 'package:my_music_player/features/settings/presentation/providers/settings_provider.dart';
import 'package:my_music_player/features/settings/presentation/screens/settings_screen.dart';
import 'package:my_music_player/main.dart' as app;

import '../../helpers/pump_app.dart';

class _RecordingSettingsController extends Fake implements SettingsController {
  AppLanguageMode? languageMode;

  @override
  Future<void> setAppLanguageMode(AppLanguageMode mode) async {
    languageMode = mode;
  }
}

/// Mirrors the real provider: the controller writes the model and the
/// settings stream emits it, so `VoidzApp` can rebuild with the new locale.
class _LiveSettingsController extends _RecordingSettingsController {
  _LiveSettingsController(this.model, this.updates);

  final AppSettingsModel model;
  final StreamController<AppSettingsModel> updates;

  @override
  Future<void> setAppLanguageMode(AppLanguageMode mode) async {
    await super.setAppLanguageMode(mode);
    model.appLanguageMode = mode;
    updates.add(model);
  }
}

void main() {
  setUpAll(() {
    registerFallbackValue(AppSettingsModel());
  });

  Future<_RecordingSettingsController> pumpSettings(
    WidgetTester tester, {
    AppLanguageMode mode = AppLanguageMode.system,
    ThemeMode themeMode = ThemeMode.dark,
    double textScale = 1.0,
    Size surfaceSize = kTestSurfaceSize,
  }) async {
    final controller = _RecordingSettingsController();

    await pumpApp(
      tester,
      ProviderScope(
        overrides: [
          appSettingsProvider.overrideWith(
            (ref) => Stream.value(
              AppSettingsModel()..appLanguageMode = mode,
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
      textScale: textScale,
      surfaceSize: surfaceSize,
    );
    await tester.pumpAndSettle();
    return controller;
  }

  Future<void> scrollToLanguage(WidgetTester tester) async {
    await tester.scrollUntilVisible(
      find.text('Language'),
      120,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();
  }

  group('Settings Language row', () {
    testWidgets('sits in Appearance and shows the active value', (
      tester,
    ) async {
      await pumpSettings(
        tester,
        mode: AppLanguageMode.indonesian,
        surfaceSize: const Size(360, 1400),
      );

      expect(find.text('Language'), findsOneWidget);
      expect(find.text('Indonesian'), findsOneWidget);

      final appearance = tester.getTopLeft(find.text('APPEARANCE')).dy;
      final language = tester.getTopLeft(find.text('Language')).dy;
      final about = tester.getTopLeft(find.text('ABOUT')).dy;
      expect(language, greaterThan(appearance));
      expect(language, lessThan(about));

      final row = find
          .ancestor(of: find.text('Language'), matching: find.byType(InkWell))
          .first;
      expect(tester.getSize(row).height, greaterThanOrEqualTo(48));
    });

    testWidgets('offers System, English and Indonesian, then saves', (
      tester,
    ) async {
      final controller = await pumpSettings(tester);
      await scrollToLanguage(tester);

      await tester.tap(find.text('Language'));
      await tester.pumpAndSettle();

      final dialog = find.byType(SimpleDialog);
      expect(dialog, findsOneWidget);
      for (final option in ['System', 'English', 'Indonesian']) {
        expect(
          find.descendant(of: dialog, matching: find.text(option)),
          findsOneWidget,
          reason: '$option must be listed',
        );
      }

      await tester.tap(
        find.descendant(of: dialog, matching: find.text('Indonesian')),
      );
      await tester.pumpAndSettle();

      expect(controller.languageMode, AppLanguageMode.indonesian);
      expect(find.byType(SimpleDialog), findsNothing);
    });

    testWidgets('marks the active option as selected for TalkBack', (
      tester,
    ) async {
      final semantics = tester.ensureSemantics();
      await pumpSettings(tester, mode: AppLanguageMode.english);
      await scrollToLanguage(tester);

      await tester.tap(find.text('Language'));
      await tester.pumpAndSettle();

      final active = tester.getSemantics(
        find.widgetWithText(SimpleDialogOption, 'English'),
      );
      expect(active.label, contains('English'));
      expect(active.flagsCollection.isSelected, Tristate.isTrue);

      final inactive = tester.getSemantics(
        find.widgetWithText(SimpleDialogOption, 'Indonesian'),
      );
      expect(inactive.flagsCollection.isSelected, isNot(Tristate.isTrue));
      semantics.dispose();
    });

    testWidgets('keeps the row and dialog overflow-free at 200% text scale', (
      tester,
    ) async {
      await pumpSettings(tester, textScale: 2.0);
      await scrollToLanguage(tester);

      expect(find.text('Language'), findsOneWidget);
      expect(tester.takeException(), isNull);

      await tester.tap(find.text('Language'));
      await tester.pumpAndSettle();

      expect(find.byType(SimpleDialog), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  });

  testWidgets('applies a new language immediately without a restart', (
    tester,
  ) async {
    tester.view.devicePixelRatio = 1.0;
    tester.view.physicalSize = kTestSurfaceSize;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final model = AppSettingsModel();
    final updates = StreamController<AppSettingsModel>.broadcast();
    addTearDown(updates.close);
    final controller = _LiveSettingsController(model, updates);

    final router = GoRouter(
      routes: [
        GoRoute(
          path: '/',
          builder: (context, state) => const SettingsScreen(),
        ),
      ],
    );

    await tester.pumpWidget(
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
          settingsControllerProvider.overrideWithValue(controller),
        ],
        child: app.VoidzApp(routerConfig: router),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Settings'), findsOneWidget);
    await scrollToLanguage(tester);
    expect(find.text('Language'), findsOneWidget);

    await tester.tap(find.text('Language'));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(SimpleDialogOption, 'Indonesian'));
    await tester.pumpAndSettle();

    expect(controller.languageMode, AppLanguageMode.indonesian);
    final materialApp = tester.widget<MaterialApp>(find.byType(MaterialApp));
    expect(materialApp.locale, const Locale('id'));
    expect(find.text('Pengaturan'), findsOneWidget);
    expect(find.text('Bahasa'), findsOneWidget);
  });

  group('SettingsController.setAppLanguageMode', () {
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

    test('persists the selected language', () async {
      await controller.setAppLanguageMode(AppLanguageMode.indonesian);
      expect(saved?.appLanguageMode, AppLanguageMode.indonesian);

      await controller.setAppLanguageMode(AppLanguageMode.english);
      expect(saved?.appLanguageMode, AppLanguageMode.english);
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

class _MockSettingsCollection extends Mock
    implements IsarCollection<AppSettingsModel> {}

class _MockRef extends Mock implements Ref {}
