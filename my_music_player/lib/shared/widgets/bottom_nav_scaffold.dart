import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/app_glass.dart';
import '../../features/player/presentation/widgets/mini_player.dart';
import 'app_bottom_nav.dart';
import 'glass_background.dart';

/// Persistent shell for the three main branches.
///
/// Below 600dp the mini-player and custom pill navigation float over the page
/// content. At >= 600dp the pill is replaced by a left rail; the mini-player
/// stays in the bottom slot, inset past the rail so neither overlaps the other
/// or the page content.
class BottomNavScaffold extends ConsumerWidget {
  final StatefulNavigationShell navigationShell;

  const BottomNavScaffold({
    super.key,
    required this.navigationShell,
    this.glassQuality = GlassQuality.blurred,
  });

  /// Shell chrome quality. [GlassQuality.opaque] removes every shell blur.
  final GlassQuality glassQuality;

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
      child: LayoutBuilder(
        builder: (context, constraints) {
          final useRail = constraints.maxWidth >= AppShellLayout.railBreakpoint;

          return Scaffold(
            backgroundColor: Colors.transparent,
            extendBody: true,
            body: GlassBackground(
              child: useRail
                  ? Row(
                      children: [
                        SafeArea(
                          bottom: false,
                          right: false,
                          child: Padding(
                            padding: const EdgeInsets.fromLTRB(
                              AppShellLayout.railSideInset,
                              AppShellLayout.shellGap,
                              0,
                              AppShellLayout.shellGap,
                            ),
                            child: AppNavigationRail(
                              currentIndex: navigationShell.currentIndex,
                              onSelected: _onItemTapped,
                              quality: glassQuality,
                            ),
                          ),
                        ),
                        const SizedBox(width: AppShellLayout.railContentGap),
                        Expanded(child: navigationShell),
                      ],
                    )
                  : navigationShell,
            ),
            bottomNavigationBar: SafeArea(
              top: false,
              minimum: const EdgeInsets.only(
                bottom: AppShellLayout.shellGap,
              ),
              child: Padding(
                padding: EdgeInsets.only(
                  left: useRail ? AppShellLayout.railContentInset : 0,
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    MiniPlayer(quality: glassQuality),
                    if (!useRail)
                      AppBottomNav(
                        currentIndex: navigationShell.currentIndex,
                        onSelected: _onItemTapped,
                        quality: glassQuality,
                      ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
