import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../features/browse/presentation/screens/artist_screen.dart';
import '../../features/browse/presentation/screens/album_screen.dart';
import '../../features/browse/presentation/screens/browse_screen.dart';
import '../../features/browse/presentation/screens/playlist_screen.dart';

/// Single source of truth for browse detail routes.
///
/// They are mounted on the root navigator, so a detail page never renders the
/// tab navigation chrome. Canonical deep links use these same builders.

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
      final slide = Tween<Offset>(
        begin: const Offset(0, 0.04),
        end: Offset.zero,
      ).animate(curved);
      final secondaryFade = Tween<double>(begin: 1.0, end: 0.92).animate(
        CurvedAnimation(parent: secondaryAnimation, curve: Curves.easeInCubic),
      );
      return FadeTransition(
        opacity: curved,
        child: SlideTransition(
          position: slide,
          child: FadeTransition(opacity: secondaryFade, child: child),
        ),
      );
    },
  );
}

GoRoute buildArtistRoute() => GoRoute(
      path: '/artist/:id',
      pageBuilder: (context, state) {
        final id = state.pathParameters['id']!;
        return _smooth(
          context: context,
          state: state,
          child: ArtistScreen(artistId: id),
        );
      },
    );

GoRoute buildAlbumRoute() => GoRoute(
      path: '/album/:id',
      pageBuilder: (context, state) {
        final id = state.pathParameters['id']!;
        return _smooth(
          context: context,
          state: state,
          child: AlbumScreen(albumId: id),
        );
      },
    );

GoRoute buildPlaylistRoute() => GoRoute(
      path: '/playlist/:id',
      pageBuilder: (context, state) {
        final id = state.pathParameters['id']!;
        return _smooth(
          context: context,
          state: state,
          child: PlaylistScreen(playlistId: id),
        );
      },
    );

/// Browse hub, a root detail page so the bottom navigation stays hidden.
GoRoute buildBrowseRoute() => GoRoute(
      path: '/browse',
      pageBuilder: (context, state) => _smooth(
        context: context,
        state: state,
        child: const BrowseScreen(),
      ),
    );

/// Browse hub plus the canonical artist/album/playlist deep links.
List<GoRoute> buildBrowseDetailRoutes() => [
      buildBrowseRoute(),
      buildArtistRoute(),
      buildAlbumRoute(),
      buildPlaylistRoute(),
    ];

/// Keeps pre-TASK-045 links working after details moved to the root navigator.
List<GoRoute> buildLegacyDetailRedirects() => [
      GoRoute(
        path: '/search/browse',
        redirect: (context, state) => '/browse',
      ),
      GoRoute(
        path: '/search/artist/:id',
        redirect: (context, state) => '/artist/${state.pathParameters['id']}',
      ),
      GoRoute(
        path: '/search/album/:id',
        redirect: (context, state) => '/album/${state.pathParameters['id']}',
      ),
      GoRoute(
        path: '/search/playlist/:id',
        redirect: (context, state) => '/playlist/${state.pathParameters['id']}',
      ),
      GoRoute(
        path: '/library/downloaded',
        redirect: (context, state) => '/downloaded',
      ),
      GoRoute(
        path: '/library/device-songs',
        redirect: (context, state) => '/device-songs',
      ),
      GoRoute(
        path: '/library/recap',
        redirect: (context, state) => '/recap',
      ),
      GoRoute(
        path: '/library/recently-played',
        redirect: (context, state) => '/recently-played',
      ),
      GoRoute(
        path: '/library/playlists',
        redirect: (context, state) => '/playlists',
      ),
      GoRoute(
        path: '/library/playlist-detail/:id',
        redirect: (context, state) =>
            '/playlist-detail/${state.pathParameters['id']}',
      ),
    ];
