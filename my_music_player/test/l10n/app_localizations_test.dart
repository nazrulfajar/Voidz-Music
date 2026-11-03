import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:isar/isar.dart';
import 'package:mocktail/mocktail.dart';
import 'package:my_music_player/core/constants/enums.dart';
import 'package:my_music_player/features/settings/data/models/app_settings_model.dart';
import 'package:my_music_player/features/settings/presentation/providers/settings_provider.dart';
import 'package:my_music_player/l10n/app_localizations.dart';
import 'package:my_music_player/main.dart' as app;

void main() {
  setUpAll(() {
    registerFallbackValue(AppSettingsModel());
  });

  group('AppLanguageMode', () {
    test('keeps Isar ordinals stable with system first', () {
      expect(AppLanguageMode.values, [
        AppLanguageMode.system,
        AppLanguageMode.english,
        AppLanguageMode.indonesian,
      ]);
      expect(AppLanguageMode.system.index, 0);
    });

    test('new settings default to system', () {
      expect(AppSettingsModel().appLanguageMode, AppLanguageMode.system);
    });

    test('generated schema stores the enum ordinal for system first', () {
      final property = AppSettingsModelSchema.properties['appLanguageMode']!;
      expect(property.type, IsarType.byte);
      expect(property.enumMap!['system'], 0);
      expect(property.enumMap!['english'], 1);
      expect(property.enumMap!['indonesian'], 2);
    });
  });

  group('AppSettingsModel persistence', () {
    final offsets = List<int>.generate(
      AppSettingsModelSchema.properties.length,
      (index) => index,
    );

    int languageOffset() =>
        AppSettingsModelSchema.properties['appLanguageMode']!.id;

    Map<int, Object?> serialize(AppSettingsModel settings) {
      final writer = _RecordingWriter();
      // Generated schema APIs are protected, but they are the only way to
      // exercise the persisted binary layout in a unit test.
      // ignore: invalid_use_of_protected_member
      AppSettingsModelSchema.serialize(
        settings,
        writer,
        offsets,
        const {},
      );
      return writer.values;
    }

    AppSettingsModel deserialize(Map<int, Object?> values) {
      // ignore: invalid_use_of_protected_member
      return AppSettingsModelSchema.deserialize(
        1,
        _MapReader(values),
        offsets,
        const {},
      );
    }

    for (final mode in [
      AppLanguageMode.system,
      AppLanguageMode.english,
      AppLanguageMode.indonesian,
    ]) {
      test('persists ${mode.name} across reopen', () {
        final reopened = deserialize(
          serialize(AppSettingsModel()..appLanguageMode = mode),
        );

        expect(reopened.appLanguageMode, mode);
      });
    }

    test('unknown/old ordinal falls back to system', () {
      final values = serialize(
        AppSettingsModel()..appLanguageMode = AppLanguageMode.indonesian,
      );
      values[languageOffset()] = 99;

      final reopened = deserialize(values);

      expect(reopened.appLanguageMode, AppLanguageMode.system);
    });

    test('rows from an old build without the field fall back to system', () {
      final values = serialize(
        AppSettingsModel()..appLanguageMode = AppLanguageMode.english,
      );
      values.remove(languageOffset());

      final reopened = deserialize(values);

      expect(reopened.appLanguageMode, AppLanguageMode.system);
    });
  });

  group('resolveAppLocale', () {
    test('system follows a supported platform locale', () {
      expect(
        app.resolveAppLocale(
          AppLanguageMode.system,
          platformLocales: const [Locale('id')],
        ),
        isNull,
      );
    });

    test('system accepts a supported locale later in the list', () {
      expect(
        app.resolveAppLocale(
          AppLanguageMode.system,
          platformLocales: const [Locale('fr'), Locale('id')],
        ),
        isNull,
      );
    });

    test('system falls back to English for unsupported locales', () {
      expect(
        app.resolveAppLocale(
          AppLanguageMode.system,
          platformLocales: const [Locale('fr')],
        ),
        const Locale('en'),
      );
    });

    test('english forces en on an Indonesian device', () {
      expect(
        app.resolveAppLocale(
          AppLanguageMode.english,
          platformLocales: const [Locale('id')],
        ),
        const Locale('en'),
      );
    });

    test('indonesian forces id on an English device', () {
      expect(
        app.resolveAppLocale(
          AppLanguageMode.indonesian,
          platformLocales: const [Locale('en')],
        ),
        const Locale('id'),
      );
    });
  });

  group('VoidzApp locale', () {
    Future<void> pumpVoidzApp(
      WidgetTester tester, {
      required AppLanguageMode mode,
      Locale platformLocale = const Locale('en'),
    }) async {
      tester.platformDispatcher.localeTestValue = platformLocale;
      tester.platformDispatcher.localesTestValue = [platformLocale];
      addTearDown(tester.platformDispatcher.clearLocaleTestValue);
      addTearDown(tester.platformDispatcher.clearLocalesTestValue);

      final router = GoRouter(
        routes: [
          GoRoute(
            path: '/',
            builder: (context, state) {
              final l10n = AppLocalizations.of(context);
              return Scaffold(
                body: Text(
                  '${l10n.language}|'
                  '${Localizations.localeOf(context).toLanguageTag()}',
                ),
              );
            },
          ),
        ],
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            appSettingsProvider.overrideWith(
              (ref) => Stream.value(
                AppSettingsModel()..appLanguageMode = mode,
              ),
            ),
          ],
          child: app.VoidzApp(routerConfig: router),
        ),
      );
      await tester.pumpAndSettle();
    }

    MaterialApp materialApp(WidgetTester tester) =>
        tester.widget<MaterialApp>(find.byType(MaterialApp));

    testWidgets('system follows an Indonesian device', (tester) async {
      await pumpVoidzApp(
        tester,
        mode: AppLanguageMode.system,
        platformLocale: const Locale('id'),
      );

      expect(materialApp(tester).locale, isNull);
      expect(find.text('Bahasa|id'), findsOneWidget);
      expect(
        materialApp(tester).supportedLocales,
        AppLocalizations.supportedLocales,
      );
      expect(
        materialApp(tester).localizationsDelegates,
        AppLocalizations.localizationsDelegates,
      );
    });

    testWidgets('system falls back to English for unsupported locales', (
      tester,
    ) async {
      await pumpVoidzApp(
        tester,
        mode: AppLanguageMode.system,
        platformLocale: const Locale('fr'),
      );

      expect(materialApp(tester).locale, const Locale('en'));
      expect(find.text('Language|en'), findsOneWidget);
    });

    testWidgets('indonesian forces the Indonesian locale', (tester) async {
      await pumpVoidzApp(
        tester,
        mode: AppLanguageMode.indonesian,
        platformLocale: const Locale('en'),
      );

      expect(materialApp(tester).locale, const Locale('id'));
      expect(find.text('Bahasa|id'), findsOneWidget);
    });

    testWidgets('english forces the English locale', (tester) async {
      await pumpVoidzApp(
        tester,
        mode: AppLanguageMode.english,
        platformLocale: const Locale('id'),
      );

      expect(materialApp(tester).locale, const Locale('en'));
      expect(find.text('Language|en'), findsOneWidget);
    });
  });

  group('ARB files', () {
    Map<String, dynamic> readArb(String fileName) {
      final file = File('lib/l10n/$fileName');
      return jsonDecode(file.readAsStringSync()) as Map<String, dynamic>;
    }

    Set<String> messageKeys(Map<String, dynamic> arb) =>
        arb.keys.where((key) => !key.startsWith('@')).toSet();

    test('en and id expose the same non-empty message keys', () {
      final en = readArb('app_en.arb');
      final id = readArb('app_id.arb');

      expect(messageKeys(id), messageKeys(en));
      for (final key in messageKeys(en)) {
        expect((en[key] as String).trim(), isNotEmpty, reason: 'en.$key');
        expect((id[key] as String).trim(), isNotEmpty, reason: 'id.$key');
      }
    });
  });
}

class _RecordingWriter extends Fake implements IsarWriter {
  final Map<int, Object?> values = {};

  @override
  void writeByte(int offset, int value) => values[offset] = value;

  @override
  void writeBool(int offset, bool? value) => values[offset] = value;

  @override
  void writeLong(int offset, int? value) => values[offset] = value;

  @override
  void writeString(int offset, String? value) => values[offset] = value;
}

class _MapReader extends Fake implements IsarReader {
  _MapReader(this.values);

  final Map<int, Object?> values;

  @override
  bool readBool(int offset) => (values[offset] as bool?) ?? false;

  @override
  int? readByteOrNull(int offset) => values[offset] as int?;

  @override
  int readLong(int offset) => (values[offset] as int?) ?? 0;

  @override
  String readString(int offset) => (values[offset] as String?) ?? '';
}
