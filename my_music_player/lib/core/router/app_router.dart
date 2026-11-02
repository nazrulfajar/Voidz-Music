import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../shared/widgets/bottom_nav_scaffold.dart';
import '../../features/home/presentation/screens/home_screen.dart';
import '../../features/search/presentation/screens/search_screen.dart';
import '../../features/library/presentation/screens/library_screen.dart';
import '../../features/library/presentation/screens/downloaded_screen.dart';
import '../../features/library/presentation/screens/device_songs_screen.dart';
import '../../features/recap/presentation/screens/recap_screen.dart';
import '../../features/library/domain/entities/playlist.dart';
import '../../features/library/presentation/screens/playlist_detail_screen.dart';
import '../../features/player/presentation/screens/player_screen.dart';
import '../../features/settings/presentation/screens/settings_screen.dart';
import '../../features/home/domain/entities/daily_mix.dart';
import '../../features/home/presentation/screens/daily_mix_screen.dart';
import 'browse_routes.dart';

/// Premium router architecture (Spotify / Apple Music / TIDAL):
/// - StatefulShellRoute.indexedStack → 3 independent stacks (Home/Search/Library)
/// - Each branch re-uses canonical browse routes via factory (DRY)
/// - Home also has drill depth (artist/album/playlist)
/// - Canonical top-level /artist/:id etc. for external deep-links
/// - Root navigator overlays: /player (modal slide-up) + /settings
/// - 260ms drill transition (was 320ms) + 420ms player + observers + error handling

final rootNavigatorKey = GlobalKey<NavigatorState>(debugLabel: 'root');

// Shared observer for analytics / logging — attach logger if needed
final routeObserver = NavigatorObserver();

CustomTransitionPage<T> _smoothTransition<T>({
  required BuildContext context,
  required GoRouterState state,
  required Widget child,
}) {
  return CustomTransitionPage<T>(
    key: state.pageKey,
    child: child,
    transitionDuration: const Duration(milliseconds: 260),
    reverseTransitionDuration: const Duration(milliseconds: 220),
    transitionsBuilder: (context, animation, secondaryAnimation, child) {
      final curvedAnimation = CurvedAnimation(
        parent: animation,
        curve: Curves.easeOutCubic,
        reverseCurve: Curves.easeInCubic,
      );
      final slide = Tween<Offset>(
        begin: const Offset(0, 0.04),
        end: Offset.zero,
      ).animate(curvedAnimation);
      final secondaryFade = Tween<double>(begin: 1.0, end: 0.92).animate(
        CurvedAnimation(parent: secondaryAnimation, curve: Curves.easeInCubic),
      );
      return FadeTransition(
        opacity: curvedAnimation,
        child: SlideTransition(
          position: slide,
          child: FadeTransition(
            opacity: secondaryFade,
            child: child,
          ),
        ),
      );
    },
  );
}

final appRouterProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    navigatorKey: rootNavigatorKey,
    initialLocation: '/',
    observers: [routeObserver],
    // Premium: never crash on unknown route — show 404
    errorBuilder: (context, state) => Scaffold(
      backgroundColor: const Color(0xFF0F0F0F),
      appBar: AppBar(backgroundColor: Colors.transparent, title: const Text('Not found')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.search_off, size: 64, color: Colors.white54),
            const SizedBox(height: 16),
            Text('Route not found', style: Theme.of(context).textTheme.titleLarge?.copyWith(color: Colors.white)),
            const SizedBox(height: 8),
            Text(state.error?.toString() ?? state.matchedLocation, style: const TextStyle(color: Colors.white54)),
            const SizedBox(height: 24),
            ElevatedButton(onPressed: () => context.go('/'), child: const Text('Go Home')),
          ],
        ),
      ),
    ),
    // Premium: place to add auth/offline guards later
    // refreshListenable: connectivity or auth provider
    // redirect: (ctx, state) => null,
    routes: [
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) {
          return BottomNavScaffold(navigationShell: navigationShell);
        },
        branches: [
          // Branch 0 — Home (now with drill depth like Search/Library)
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/',
                builder: (context, state) => const HomeScreen(),
                routes: [
                  buildArtistRoute(),
                  buildAlbumRoute(),
                  buildPlaylistRoute(),
                  GoRoute(
                    path: 'daily-mix',
                    redirect: (context, state) => state.uri.path == '/daily-mix'
                        ? '/daily-mix/energize'
                        : null,
                    routes: [
                      GoRoute(
                        path: ':mood',
                        pageBuilder: (context, state) => _smoothTransition(
                          context: context,
                          state: state,
                          child: DailyMixScreen(
                            mood: DailyMixMood.fromSlug(
                              state.pathParameters['mood'] ?? '',
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
          // Branch 1 — Search
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/search',
                builder: (context, state) => const SearchScreen(),
                routes: [
                  buildArtistRoute(),
                  buildAlbumRoute(),
                  buildPlaylistRoute(),
                ],
              ),
            ],
          ),
          // Branch 2 — Library
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/library',
                builder: (context, state) => const LibraryScreen(),
                routes: [
                  GoRoute(
                    path: 'downloaded',
                    pageBuilder: (context, state) => _smoothTransition(
                      context: context,
                      state: state,
                      child: const DownloadedScreen(),
                    ),
                  ),
                  GoRoute(
                    path: 'device-songs',
                    pageBuilder: (context, state) => _smoothTransition(
                      context: context,
                      state: state,
                      child: const DeviceSongsScreen(),
                    ),
                  ),
                  GoRoute(
                    path: 'recap',
                    pageBuilder: (context, state) => _smoothTransition(
                      context: context,
                      state: state,
                      child: const RecapScreen(),
                    ),
                  ),
                  buildArtistRoute(),
                  buildAlbumRoute(),
                  buildPlaylistRoute(),
                  // Premium fix: fetch by id, extra is optional hint (deep-link safe)
                  GoRoute(
                    path: 'playlist-detail/:id',
                    pageBuilder: (context, state) {
                      final idStr = state.pathParameters['id']!;
                      final id = int.tryParse(idStr);
                      final hint = state.extra;
                      // extra may be Playlist or null — pass as hint, screen fetches by id
                      return _smoothTransition(
                        context: context,
                        state: state,
                        child: PlaylistDetailScreen(
                          playlistId: id,
                          playlistIdStr: idStr,
                          initialPlaylist: hint is Playlist ? hint : null,
                        ),
                      );
                    },
                  ),
                ],
              ),
            ],
          ),
        ],
      ),

      // Canonical top-level deep-links — myapp://artist/xyz, /album/xyz, /playlist/xyz
      // Render same screens regardless of current tab (useful for external intents)
      ...buildCanonicalDeepLinkRoutes(),

      // Root overlays — slide over shell (player modal, settings)
      GoRoute(
        parentNavigatorKey: rootNavigatorKey,
        path: '/settings',
        pageBuilder: (context, state) => _smoothTransition(
          context: context,
          state: state,
          child: const SettingsScreen(),
        ),
      ),

      GoRoute(
        parentNavigatorKey: rootNavigatorKey,
        path: '/player',
        pageBuilder: (context, state) => CustomTransitionPage(
          key: state.pageKey,
          child: const PlayerScreen(),
          fullscreenDialog: true,
          transitionDuration: const Duration(milliseconds: 420),
          reverseTransitionDuration: const Duration(milliseconds: 360),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            final curvedAnimation = CurvedAnimation(
              parent: animation,
              curve: Curves.easeOutCubic,
              reverseCurve: Curves.easeInCubic,
            );
            final slide = Tween<Offset>(
              begin: const Offset(0, 1),
              end: Offset.zero,
            ).animate(curvedAnimation);
            final secondaryFade = Tween<double>(begin: 1.0, end: 0.7).animate(
              CurvedAnimation(
                parent: secondaryAnimation,
                curve: Curves.easeInCubic,
              ),
            );
            return SlideTransition(
              position: slide,
              child: FadeTransition(
                opacity: secondaryFade,
                child: child,
              ),
            );
          },
        ),
      ),
    ],
  );
});
