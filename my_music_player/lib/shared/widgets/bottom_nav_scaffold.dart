import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../features/player/presentation/widgets/mini_player.dart';
import '../../core/theme/app_colors.dart';

/// Premium scaffold — persists MiniPlayer + BottomNav for all shell routes.
/// - Preserves tab stacks via StatefulNavigationShell (IndexedStack)
/// - Tap active tab = pop to root (Spotify behavior)
/// - Android back: pop inner stack first, else go Home, else exit
/// - Does NOT clear searchQuery on tab switch (preserves history)
class BottomNavScaffold extends ConsumerWidget {
  final StatefulNavigationShell navigationShell;

  const BottomNavScaffold({
    super.key,
    required this.navigationShell,
  });

  void _onItemTapped(int index) {
    // Premium: tap active tab → pop to root of that branch
    navigationShell.goBranch(
      index,
      initialLocation: index == navigationShell.currentIndex,
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return PopScope(
      // If inner shell can pop, let it; otherwise handle tab switch / exit
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        final shell = navigationShell;
        // If current branch has nested route, pop it
        // go_router's StatefulNavigationShell doesn't expose canPop directly
        // so we try to pop via context and intercept fallback
        final canPopInner = GoRouter.of(context).canPop();
        if (canPopInner) {
          GoRouter.of(context).pop();
          return;
        }
        // At root of a non-Home tab → switch to Home
        if (shell.currentIndex != 0) {
          shell.goBranch(0);
          return;
        }
        // At Home root → allow system pop (exit app) via Navigator
        // PopScope with canPop:false would block exit, so we forward to root navigator
        Navigator.of(context, rootNavigator: true).maybePop();
      },
      child: Scaffold(
        extendBody: true,
        body: navigationShell,
        bottomNavigationBar: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const MiniPlayer(),
            ClipRRect(
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
                child: Container(
                  decoration: const BoxDecoration(
                    color: AppColors.blurBackground,
                    border: Border(
                      top: BorderSide(
                        color: AppColors.glassBorder,
                        width: 0.5,
                      ),
                    ),
                  ),
                  child: NavigationBar(
                    backgroundColor: Colors.transparent,
                    indicatorColor:
                        AppColors.accentPrimary.withValues(alpha: 0.2),
                    selectedIndex: navigationShell.currentIndex,
                    onDestinationSelected: _onItemTapped,
                    destinations: const [
                      NavigationDestination(
                        icon: Icon(Icons.home_outlined),
                        selectedIcon:
                            Icon(Icons.home, color: AppColors.accentPrimary),
                        label: 'Home',
                      ),
                      NavigationDestination(
                        icon: Icon(Icons.search_outlined),
                        selectedIcon:
                            Icon(Icons.search, color: AppColors.accentPrimary),
                        label: 'Search',
                      ),
                      NavigationDestination(
                        icon: Icon(Icons.library_music_outlined),
                        selectedIcon: Icon(Icons.library_music,
                            color: AppColors.accentPrimary),
                        label: 'Library',
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
