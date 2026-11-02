import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_radius.dart';

/// Floating pill navigation from `docs/DESIGN_SYSTEM.md` §6.1.
///
/// 380 × 72, r36, navigation surface, 1px border, three equal items.
class AppBottomNav extends StatelessWidget {
  const AppBottomNav({
    super.key,
    required this.currentIndex,
    required this.onSelected,
  });

  final int currentIndex;
  final ValueChanged<int> onSelected;

  @override
  Widget build(BuildContext context) {
    final tokens = AppColors.of(context);

    return Align(
      alignment: Alignment.bottomCenter,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 420),
          child: Container(
            height: 72,
            decoration: BoxDecoration(
              color: tokens.navigation,
              borderRadius: BorderRadius.circular(AppRadius.x5xl),
              border: Border.all(color: tokens.border),
            ),
            clipBehavior: Clip.antiAlias,
            child: Row(
              children: [
                _NavItem(
                  label: 'Home',
                  icon: Icons.home_outlined,
                  activeIcon: Icons.home_rounded,
                  selected: currentIndex == 0,
                  onTap: () => onSelected(0),
                ),
                _NavItem(
                  label: 'Search',
                  icon: Icons.search_rounded,
                  activeIcon: Icons.search_rounded,
                  selected: currentIndex == 1,
                  onTap: () => onSelected(1),
                ),
                _NavItem(
                  label: 'Library',
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
    final color = selected ? tokens.textPrimary : tokens.textInactive;
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
              Icon(selected ? activeIcon : icon, size: 21, color: color),
              const SizedBox(height: 4),
              Text(
                label,
                style: textTheme.labelSmall?.copyWith(
                  color: color,
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
