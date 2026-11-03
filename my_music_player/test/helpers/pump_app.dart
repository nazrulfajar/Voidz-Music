import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:my_music_player/core/theme/app_theme.dart';
import 'package:my_music_player/l10n/app_localizations.dart';

/// Logical phone surface used by UI tests (360 × 640 dp).
const Size kTestSurfaceSize = Size(360, 640);

/// Wraps [child] in a `MaterialApp` that uses the app light/dark themes.
///
/// Use this when a test only needs the widget tree (no pump helper), for
/// example with `testWidgets` + `tester.pumpWidget`.
Widget wrapApp(
  Widget child, {
  ThemeMode themeMode = ThemeMode.dark,
  double textScale = 1.0,
  Locale? locale,
}) {
  return MaterialApp(
    debugShowCheckedModeBanner: false,
    theme: AppTheme.lightTheme,
    darkTheme: AppTheme.darkTheme,
    themeMode: themeMode,
    locale: locale,
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    builder: (context, appChild) {
      final media = MediaQuery.of(context);
      return MediaQuery(
        data: media.copyWith(textScaler: TextScaler.linear(textScale)),
        child: appChild!,
      );
    },
    home: child,
  );
}

/// Pumps [child] at 360 × 640 dp with the app themes.
///
/// [textScale] defaults to 1.0; pass 2.0 for the accessibility size test.
Future<void> pumpApp(
  WidgetTester tester,
  Widget child, {
  ThemeMode themeMode = ThemeMode.dark,
  double textScale = 1.0,
  Size surfaceSize = kTestSurfaceSize,
  Locale? locale,
  List<Override> overrides = const [],
}) async {
  tester.view.devicePixelRatio = 1.0;
  tester.view.physicalSize = surfaceSize;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);

  final app = wrapApp(
    child,
    themeMode: themeMode,
    textScale: textScale,
    locale: locale,
  );
  await tester.pumpWidget(
    overrides.isEmpty ? app : ProviderScope(overrides: overrides, child: app),
  );
  await tester.pump();
}
