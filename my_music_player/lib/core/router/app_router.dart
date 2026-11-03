import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_colors.dart';
import '../../l10n/app_localizations.dart';
import '../../shared/widgets/app_empty_state.dart';
import '../../shared/widgets/bottom_nav_scaffold.dart';
import '../../features/home/presentation/screens/home_screen.dart';
import '../../features/search/presentation/screens/search_screen.dart';
import '../../features/library/presentation/screens/library_screen.dart';
import '../../features/library/presentation/screens/downloaded_screen.dart';
import '../../features/library/presentation/screens/device_songs_screen.dart';
import '../../features/library/presentation/screens/playlists_screen.dart';
import '../../features/library/presentation/screens/recently_played_screen.dart';
import '../../features/recap/presentation/screens/recap_screen.dart';
import '../../features/library/domain/entities/playlist.dart';
import '../../features/library/presentation/screens/playlist_detail_screen.dart';
import '../../features/player/presentation/screens/player_screen.dart';
import '../../features/settings/presentation/screens/settings_screen.dart';
import '../../features/home/domain/entities/daily_mix.dart';
import '../../features/home/presentation/screens/daily_mix_screen.dart';
import 'browse_routes.dart';

/// Premium router architecture (Spotify / Apple Music / TIDAL):
/// - StatefulShellRoute.indexedStack holds only the three tab roots
///   (Home/Search/Library), preserving each tab's scroll state.
/// - Every detail page is a root route, mapped once in `browse_routes.dart`;
///   canonical /artist/:id etc. use those exact builders.
/// - The app-level `AppChrome` host owns nav/rail/mini-player visibility, so
///   details never inherit navigation chrome and Settings/deep links keep the
///   mini player.
/// - Root overlays: /player (immersive modal) + /settings (mini only).
/// - 260ms drill transition + 420ms player + observers + error handling

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
    // Never crash on unknown route: render the shared tokenized state panel.
    // The raw GoRouter exception and matched location are intentionally not
    // shown to the user (`docs/ERROR_HANDLING.md` §1).
    errorBuilder: (context, state) => const _RouteNotFoundScreen(),
    // Premium: place to add auth/offline guards later
    // refreshListenable: connectivity or auth provider
    // redirect: (ctx, state) => null,
    routes: [
      // Only the three tab roots live inside the stateful shell. Every detail
      // page is a root route, so it can never inherit the navigation chrome
      // and canonical deep links share the exact same builder.
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) {
          return BottomNavScaffold(navigationShell: navigationShell);
        },
        branches: [
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/',
                builder: (context, state) => const HomeScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/search',
                builder: (context, state) => const SearchScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/library',
                builder: (context, state) => const LibraryScreen(),
              ),
            ],
          ),
        ],
      ),

      // Detail routes — root navigator, no navigation chrome.
      ...buildBrowseDetailRoutes(),
      ...buildLegacyDetailRedirects(),
      GoRoute(
        path: '/downloaded',
        pageBuilder: (context, state) => _smoothTransition(
          context: context,
          state: state,
          child: const DownloadedScreen(),
        ),
      ),
      GoRoute(
        path: '/device-songs',
        pageBuilder: (context, state) => _smoothTransition(
          context: context,
          state: state,
          child: const DeviceSongsScreen(),
        ),
      ),
      GoRoute(
        path: '/recap',
        pageBuilder: (context, state) => _smoothTransition(
          context: context,
          state: state,
          child: const RecapScreen(),
        ),
      ),
      GoRoute(
        path: '/recently-played',
        pageBuilder: (context, state) => _smoothTransition(
          context: context,
          state: state,
          child: const RecentlyPlayedScreen(),
        ),
      ),
      GoRoute(
        path: '/playlists',
        pageBuilder: (context, state) => _smoothTransition(
          context: context,
          state: state,
          child: const PlaylistsScreen(),
        ),
      ),
      GoRoute(
        path: '/daily-mix',
        redirect: (context, state) =>
            state.uri.path == '/daily-mix' ? '/daily-mix/energize' : null,
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
      // Fetch by id, extra is an optional hint (deep-link safe).
      GoRoute(
        path: '/playlist-detail/:id',
        pageBuilder: (context, state) {
          final idStr = state.pathParameters['id']!;
          final id = int.tryParse(idStr);
          final hint = state.extra;
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

      // Root overlays — slide over the shell (player modal, settings)
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

/// Fallback for unmatched locations (`GoRouter.errorBuilder`).
///
/// Uses the shared [AppStatePanel] so dark/light tokens, geometry and the CTA
/// stay consistent with every other state surface (§6.7).
class _RouteNotFoundScreen extends StatelessWidget {
  const _RouteNotFoundScreen();

  @override
  Widget build(BuildContext context) {
    final tokens = AppColors.of(context);
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      backgroundColor: tokens.background,
      body: SafeArea(
        child: AppStatePanel(
          variant: AppStateVariant.error,
          icon: Icons.search_off_rounded,
          title: l10n.errorRouteNotFoundTitle,
          message: l10n.errorRouteNotFoundMessage,
          code: 'ERR-404',
          actionLabel: l10n.errorRouteGoHome,
          actionIcon: Icons.home_rounded,
          onAction: () => context.go('/'),
        ),
      ),
    );
  }
}
