import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_glass.dart';
import '../../core/theme/app_radius.dart';
import '../../l10n/app_localizations.dart';
import 'glass_surface.dart';

/// Shared geometry for the persistent app shell.
///
/// See `docs/DESIGN_SYSTEM.md` §4.4 and §6.1. Screens must not hardcode
/// their own shell breakpoints or chrome sizes.
class AppShellLayout {
  const AppShellLayout._();

  /// Width at or above which the shell uses a navigation rail.
  static const double railBreakpoint = 600.0;

  static const double railWidth = 64.0;
  static const double railMaxHeight = 388.0;
  static const double railSideInset = 8.0;
  static const double railContentInset = 96.0;

  /// Gap between the rail and the page content: 96 - 8 - 64.
  static const double railContentGap = 24.0;

  static const double bottomNavHeight = 72.0;
  static const double miniPlayerHeight = 66.0;
  static const double shellGap = 8.0;

  /// Approximate occupied height of the portrait bottom chrome.
  static const double bottomChromeHeight =
      miniPlayerHeight + bottomNavHeight + shellGap * 2;

  /// Approximate occupied height of the rail shell bottom chrome.
  static const double railBottomChromeHeight = miniPlayerHeight + shellGap * 2;
}

/// Floating pill navigation from `docs/DESIGN_SYSTEM.md` §6.1.
///
/// 380 × 72, r36, navigation surface, 1px border, three equal items.
class AppBottomNav extends StatelessWidget {
  const AppBottomNav({
    super.key,
    required this.currentIndex,
    required this.onSelected,
    this.quality = GlassQuality.blurred,
  });

  final int currentIndex;
  final ValueChanged<int> onSelected;

  /// Glass quality. Pass [GlassQuality.opaque] for the lowest-cost fallback.
  final GlassQuality quality;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Align(
      alignment: Alignment.bottomCenter,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 420),
          child: SizedBox(
            height: 72,
            child: GlassSurface.chrome(
              quality: quality,
              borderRadius: BorderRadius.circular(AppRadius.x5xl),
              child: Row(
                children: [
                  _NavItem(
                    label: l10n.shellTabHome,
                    icon: Icons.home_outlined,
                    activeIcon: Icons.home_rounded,
                    selected: currentIndex == 0,
                    onTap: () => onSelected(0),
                  ),
                  _NavItem(
                    label: l10n.shellTabSearch,
                    icon: Icons.search_rounded,
                    activeIcon: Icons.search_rounded,
                    selected: currentIndex == 1,
                    onTap: () => onSelected(1),
                  ),
                  _NavItem(
                    label: l10n.shellTabLibrary,
                    icon: Icons.library_music_outlined,
                    activeIcon: Icons.library_music_rounded,
                    selected: currentIndex == 2,
                    onTap: () => onSelected(2),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Floating navigation rail used by the shell at >= 600dp.
///
/// 64dp wide, r30, `miniPlayer` surface and 1px border from
/// `docs/DESIGN_SYSTEM.md` §6.1. Wraps [NavigationRail] so semantics and
/// 48dp targets stay platform-standard.
class AppNavigationRail extends StatelessWidget {
  const AppNavigationRail({
    super.key,
    required this.currentIndex,
    required this.onSelected,
    this.quality = GlassQuality.blurred,
  });

  final int currentIndex;
  final ValueChanged<int> onSelected;

  /// Glass quality. Pass [GlassQuality.opaque] for the lowest-cost fallback.
  final GlassQuality quality;

  @override
  Widget build(BuildContext context) {
    final tokens = AppColors.of(context);
    final textTheme = Theme.of(context).textTheme;
    final l10n = AppLocalizations.of(context);
    final labelStyle = textTheme.labelSmall?.copyWith(fontSize: 11);

    return ConstrainedBox(
      constraints: const BoxConstraints(
        maxHeight: AppShellLayout.railMaxHeight,
      ),
      child: SizedBox(
        key: const Key('app-navigation-rail'),
        width: AppShellLayout.railWidth,
        height: double.infinity,
        child: GlassSurface.chrome(
          quality: quality,
          borderRadius: BorderRadius.circular(AppRadius.rail),
          child: NavigationRail(
            backgroundColor: Colors.transparent,
            minWidth: AppShellLayout.railWidth,
            selectedIndex: currentIndex,
            onDestinationSelected: onSelected,
            labelType: NavigationRailLabelType.all,
            groupAlignment: 0,
            useIndicator: false,
            selectedIconTheme: IconThemeData(
              size: 21,
              color: tokens.textPrimary,
            ),
            unselectedIconTheme: IconThemeData(
              size: 21,
              color: tokens.textInactive,
            ),
            selectedLabelTextStyle: labelStyle?.copyWith(
              color: tokens.textPrimary,
              fontWeight: FontWeight.w700,
            ),
            unselectedLabelTextStyle: labelStyle?.copyWith(
              color: tokens.textSecondary,
            ),
            destinations: [
              NavigationRailDestination(
                icon: const Icon(Icons.home_outlined),
                selectedIcon: const Icon(Icons.home_rounded),
                label: _RailLabel(l10n.shellTabHome),
              ),
              NavigationRailDestination(
                icon: const Icon(Icons.search_rounded),
                selectedIcon: const Icon(Icons.search_rounded),
                label: _RailLabel(l10n.shellTabSearch),
              ),
              NavigationRailDestination(
                icon: const Icon(Icons.library_music_outlined),
                selectedIcon: const Icon(Icons.library_music_rounded),
                label: _RailLabel(l10n.shellTabLibrary),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Single-line destination label so 200% text does not overflow the rail.
class _RailLabel extends StatelessWidget {
  const _RailLabel(this.label);

  final String label;

  @override
  Widget build(BuildContext context) {
    return Text(
      label,
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      textAlign: TextAlign.center,
    );
  }
}

class _NavItem extends StatelessWidget {
  const _NavItem({
    required this.label,
    required this.icon,
    required this.activeIcon,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final IconData activeIcon;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final tokens = AppColors.of(context);
    final iconColor = selected ? tokens.textPrimary : tokens.textInactive;
    final labelColor = selected ? tokens.textPrimary : tokens.textSecondary;
    final textTheme = Theme.of(context).textTheme;

    return Expanded(
      child: Semantics(
        button: true,
        selected: selected,
        label: label,
        child: InkWell(
          onTap: onTap,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(selected ? activeIcon : icon, size: 21, color: iconColor),
              const SizedBox(height: 4),
              Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: textTheme.labelSmall?.copyWith(
                  color: labelColor,
                  fontWeight: selected ? FontWeight.w700 : FontWeight.w400,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
