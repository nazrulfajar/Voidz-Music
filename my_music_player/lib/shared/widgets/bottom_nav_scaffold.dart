import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

/// Shell for the three root tab branches.
///
/// Chrome (mini player, pill navigation, rail) is owned by the app-level
/// `AppChrome` host above the router. This widget only preserves branch state
/// and handles the Android back button while a tab root is showing.
class BottomNavScaffold extends StatelessWidget {
  final StatefulNavigationShell navigationShell;

  const BottomNavScaffold({
    super.key,
    required this.navigationShell,
  });

  @override
  Widget build(BuildContext context) {
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
      child: navigationShell,
    );
  }
}
