import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/player/presentation/widgets/mini_player.dart';
import 'app_bottom_nav.dart';

/// Persistent shell for the three main branches.
///
/// The mini-player and custom pill navigation float over the page content;
/// the page keeps its own scroll view and bottom padding.
class BottomNavScaffold extends ConsumerWidget {
  final StatefulNavigationShell navigationShell;

  const BottomNavScaffold({
    super.key,
    required this.navigationShell,
  });

  void _onItemTapped(int index) {
    navigationShell.goBranch(
      index,
      initialLocation: index == navigationShell.currentIndex,
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        final shell = navigationShell;
        final canPopInner = GoRouter.of(context).canPop();
        if (canPopInner) {
          GoRouter.of(context).pop();
          return;
        }
        if (shell.currentIndex != 0) {
          shell.goBranch(0);
          return;
        }
        Navigator.of(context, rootNavigator: true).maybePop();
      },
      child: Scaffold(
        extendBody: true,
        body: navigationShell,
        bottomNavigationBar: SafeArea(
          top: false,
          minimum: const EdgeInsets.only(bottom: 8),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const MiniPlayer(),
              AppBottomNav(
                currentIndex: navigationShell.currentIndex,
                onSelected: _onItemTapped,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
