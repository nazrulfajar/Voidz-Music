import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_radius.dart';

/// 44–48dp circular icon button on a raised surface.
class AppIconButton extends StatelessWidget {
  const AppIconButton({
    super.key,
    required this.icon,
    required this.onPressed,
    this.size = 48,
    this.iconSize = 20,
    this.filled = true,
    this.tooltip,
  });

  final IconData icon;
  final VoidCallback? onPressed;
  final double size;
  final double iconSize;
  final bool filled;
  final String? tooltip;

  @override
  Widget build(BuildContext context) {
    final tokens = AppColors.of(context);
    final button = SizedBox(
      width: size,
      height: size,
      child: Material(
        color: filled ? tokens.raised : Colors.transparent,
        shape: const CircleBorder(),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onPressed,
          child: Icon(icon, size: iconSize, color: tokens.textPrimary),
        ),
      ),
    );

    if (tooltip == null) return button;
    return Tooltip(message: tooltip!, child: button);
  }
}

/// Square-ish action button used by list rows and sheets.
class AppSquareIconButton extends StatelessWidget {
  const AppSquareIconButton({
    super.key,
    required this.icon,
    required this.onPressed,
    this.width = 40,
    this.height = 44,
    this.iconSize = 18,
    this.tooltip,
  });

  final IconData icon;
  final VoidCallback? onPressed;
  final double width;
  final double height;
  final double iconSize;
  final String? tooltip;

  @override
  Widget build(BuildContext context) {
    final tokens = AppColors.of(context);
    final button = SizedBox(
      width: width,
      height: height,
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(AppRadius.xxl),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onPressed,
          child: Icon(icon, size: iconSize, color: tokens.textSecondary),
        ),
      ),
    );

    if (tooltip == null) return button;
    return Tooltip(message: tooltip!, child: button);
  }
}
