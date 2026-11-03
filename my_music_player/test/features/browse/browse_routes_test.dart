import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:my_music_player/core/router/browse_routes.dart';
import 'package:my_music_player/features/browse/presentation/providers/browse_provider.dart';
import 'package:my_music_player/l10n/app_localizations.dart';

import '../../helpers/pump_app.dart';

class _RouteStub extends StatelessWidget {
  const _RouteStub(this.label);

  final String label;

  @override
  Widget build(BuildContext context) {
    return Scaffold(body: Center(child: Text(label)));
  }
}

void main() {
  Future<GoRouter> pumpBrowseRoute(
    WidgetTester tester, {
    String initialLocation = '/browse',
  }) async {
    final router = GoRouter(
      initialLocation: initialLocation,
      routes: [
        GoRoute(
          path: '/search',
          builder: (context, state) => const _RouteStub('search-route'),
        ),
        GoRoute(
          path: '/device-songs',
          builder: (context, state) => const _RouteStub('device-songs-route'),
        ),
        buildBrowseRoute(),
      ],
    );
    addTearDown(router.dispose);

    await pumpApp(
      tester,
      ProviderScope(
        overrides: [
          browseRecentlyPlayedProvider.overrideWith((ref) async => const []),
        ],
        child: MaterialApp.router(
          routerConfig: router,
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
        ),
      ),
    );
    await tester.pumpAndSettle();
    return router;
  }

  testWidgets('the hub is a root route at /browse', (tester) async {
    final router = await pumpBrowseRoute(tester);

    expect(find.text('Browse'), findsOneWidget);
    expect(
      router.routerDelegate.currentConfiguration.uri.path,
      '/browse',
    );
  });

  testWidgets('YouTube Music card opens Search', (tester) async {
    await pumpBrowseRoute(tester);

    await tester.tap(find.text('YouTube Music'));
    await tester.pumpAndSettle();

    expect(find.text('search-route'), findsOneWidget);
  });

  testWidgets('Device songs card opens the device library route',
      (tester) async {
    await pumpBrowseRoute(tester);

    await tester.tap(find.text('Device songs'));
    await tester.pumpAndSettle();

    expect(find.text('device-songs-route'), findsOneWidget);
  });

  testWidgets('back from the hub opens Search', (tester) async {
    final semantics = tester.ensureSemantics();
    try {
      await pumpBrowseRoute(tester);

      await tester.tap(find.bySemanticsLabel('Back'));
      await tester.pumpAndSettle();

      expect(find.text('search-route'), findsOneWidget);
    } finally {
      semantics.dispose();
    }
  });
}
