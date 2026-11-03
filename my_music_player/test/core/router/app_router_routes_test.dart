import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:my_music_player/core/router/app_router.dart';

void main() {
  late ProviderContainer container;
  late GoRouter router;

  setUp(() {
    container = ProviderContainer();
    router = container.read(appRouterProvider);
  });

  tearDown(() {
    router.dispose();
    container.dispose();
  });

  test('the stateful shell contains only the three tab roots', () {
    final shell =
        router.configuration.routes.whereType<StatefulShellRoute>().single;

    expect(shell.branches, hasLength(3));
    expect(
      shell.branches.map((branch) => branch.routes.single).map(
            (route) => (route as GoRoute).path,
          ),
      ['/', '/search', '/library'],
    );
    for (final branch in shell.branches) {
      expect(
        (branch.routes.single as GoRoute).routes,
        isEmpty,
        reason: 'details must not be nested inside a tab branch',
      );
    }
  });

  test('detail and canonical deep links are root routes', () {
    final paths = router.configuration.routes
        .whereType<GoRoute>()
        .map((route) => route.path)
        .toSet();

    expect(
      paths,
      containsAll([
        '/browse',
        '/artist/:id',
        '/album/:id',
        '/playlist/:id',
        '/downloaded',
        '/device-songs',
        '/recap',
        '/recently-played',
        '/playlists',
        '/playlist-detail/:id',
        '/daily-mix',
        '/settings',
        '/player',
        '/lyrics',
      ]),
    );
  });
}
