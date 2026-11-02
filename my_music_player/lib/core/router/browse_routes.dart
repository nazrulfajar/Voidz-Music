import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../features/browse/presentation/screens/artist_screen.dart';
import '../../features/browse/presentation/screens/album_screen.dart';
import '../../features/browse/presentation/screens/playlist_screen.dart';

/// Single source of truth for browse detail routes.
/// DRY: defined once, re-used in every StatefulShellBranch (Home/Search/Library).
/// Premium apps (Spotify/Apple) have canonical `/artist/:id` etc. — we mount
/// the same widget under each branch so `push` never forces tab switch,
/// plus we also expose canonical top-level routes for external deep-links.

CustomTransitionPage<T> _smooth<T>({
  required BuildContext context,
  required GoRouterState state,
  required Widget child,
  Duration duration = const Duration(milliseconds: 260),
}) {
  return CustomTransitionPage<T>(
    key: state.pageKey,
    child: child,
    transitionDuration: duration,
    reverseTransitionDuration: const Duration(milliseconds: 220),
    transitionsBuilder: (context, animation, secondaryAnimation, child) {
      final curved = CurvedAnimation(
        parent: animation,
        curve: Curves.easeOutCubic,
        reverseCurve: Curves.easeInCubic,
      );
      final slide = Tween<Offset>(begin: const Offset(0, 0.04), end: Offset.zero).animate(curved);
      final secondaryFade = Tween<double>(begin: 1.0, end: 0.92).animate(
        CurvedAnimation(parent: secondaryAnimation, curve: Curves.easeInCubic),
      );
      return FadeTransition(
        opacity: curved,
        child: SlideTransition(position: slide, child: FadeTransition(opacity: secondaryFade, child: child)),
      );
    },
  );
}

GoRoute buildArtistRoute() => GoRoute(
      path: 'artist/:id',
      pageBuilder: (context, state) {
        final id = state.pathParameters['id']!;
        return _smooth(context: context, state: state, child: ArtistScreen(artistId: id));
      },
    );

GoRoute buildAlbumRoute() => GoRoute(
      path: 'album/:id',
      pageBuilder: (context, state) {
        final id = state.pathParameters['id']!;
        return _smooth(context: context, state: state, child: AlbumScreen(albumId: id));
      },
    );

GoRoute buildPlaylistRoute() => GoRoute(
      path: 'playlist/:id',
      pageBuilder: (context, state) {
        final id = state.pathParameters['id']!;
        return _smooth(context: context, state: state, child: PlaylistScreen(playlistId: id));
      },
    );

/// Canonical top-level routes for external deep-links `myapp://artist/xyz`.
/// They redirect to the current branch's artist route so tab state is preserved
/// but deep-link still works. Alternatively they directly render the screen.
List<GoRoute> buildCanonicalDeepLinkRoutes() => [
      GoRoute(
        path: '/artist/:id',
        pageBuilder: (context, state) {
          final id = state.pathParameters['id']!;
          return _smooth(context: context, state: state, child: ArtistScreen(artistId: id));
        },
      ),
      GoRoute(
        path: '/album/:id',
        pageBuilder: (context, state) {
          final id = state.pathParameters['id']!;
          return _smooth(context: context, state: state, child: AlbumScreen(albumId: id));
        },
      ),
      GoRoute(
        path: '/playlist/:id',
        pageBuilder: (context, state) {
          final id = state.pathParameters['id']!;
          return _smooth(context: context, state: state, child: PlaylistScreen(playlistId: id));
        },
      ),
    ];
