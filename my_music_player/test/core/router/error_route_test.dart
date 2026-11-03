import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:my_music_player/core/router/app_router.dart';
import 'package:my_music_player/core/theme/app_colors.dart';
import 'package:my_music_player/core/theme/app_theme.dart';
import 'package:my_music_player/l10n/app_localizations.dart';
import 'package:my_music_player/shared/widgets/app_empty_state.dart';

Future<void> _pumpUnknownRoute(
  WidgetTester tester, {
  ThemeMode themeMode = ThemeMode.dark,
  double textScale = 1.0,
  Locale? locale,
}) async {
  tester.view.devicePixelRatio = 1.0;
  tester.view.physicalSize = const Size(360, 640);
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);

  final container = ProviderContainer();
  addTearDown(container.dispose);
  final router = container.read(appRouterProvider);
  router.go('/this-route-does-not-exist');

  await tester.pumpWidget(
    UncontrolledProviderScope(
      container: container,
      child: MaterialApp.router(
        debugShowCheckedModeBanner: false,
        theme: AppTheme.lightTheme,
        darkTheme: AppTheme.darkTheme,
        themeMode: themeMode,
        locale: locale,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        routerConfig: router,
        builder: (context, child) {
          final media = MediaQuery.of(context);
          return MediaQuery(
            data: media.copyWith(textScaler: TextScaler.linear(textScale)),
            child: child!,
          );
        },
      ),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('404 uses the tokenized state panel with human copy',
      (tester) async {
    await _pumpUnknownRoute(tester);

    expect(find.byType(AppStatePanel), findsOneWidget);
    expect(find.text('Page not found'), findsOneWidget);
    expect(find.text('Go Home'), findsOneWidget);
    expect(find.textContaining('GoException'), findsNothing);
    expect(find.textContaining('this-route-does-not-exist'), findsNothing);
    expect(find.textContaining('Exception'), findsNothing);

    final scaffold = tester.widget<Scaffold>(find.byType(Scaffold));
    expect(scaffold.backgroundColor, AppColors.dark.background);
    final panel = tester.widget<Container>(
      find.byKey(const Key('app-state-panel')),
    );
    final decoration = panel.decoration! as BoxDecoration;
    expect(decoration.color, AppColors.dark.surface);
  });

  testWidgets('404 follows the app locale', (tester) async {
    await _pumpUnknownRoute(tester, locale: const Locale('id'));

    expect(find.text('Halaman tidak ditemukan'), findsOneWidget);
    expect(find.text('Ke Beranda'), findsOneWidget);
    expect(find.text('Page not found'), findsNothing);
    expect(find.textContaining('GoException'), findsNothing);
    expect(find.textContaining('this-route-does-not-exist'), findsNothing);
    expect(find.textContaining('Exception'), findsNothing);
  });

  testWidgets('404 follows the light theme tokens', (tester) async {
    await _pumpUnknownRoute(tester, themeMode: ThemeMode.light);

    final scaffold = tester.widget<Scaffold>(find.byType(Scaffold));
    expect(scaffold.backgroundColor, AppColors.light.background);
    final panel = tester.widget<Container>(
      find.byKey(const Key('app-state-panel')),
    );
    final decoration = panel.decoration! as BoxDecoration;
    expect(decoration.color, AppColors.light.surface);
  });

  testWidgets('404 stays overflow-free at 200% text scale', (tester) async {
    await _pumpUnknownRoute(tester, textScale: 2.0);

    expect(find.text('Page not found'), findsOneWidget);
    expect(find.text('Go Home'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
