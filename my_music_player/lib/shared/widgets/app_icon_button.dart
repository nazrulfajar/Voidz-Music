import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';

/// 44–48dp circular icon button on a raised surface.
class AppIconButton extends StatelessWidget {
  const AppIconButton({
    super.key,
    required this.icon,
    required this.semanticLabel,
    required this.onPressed,
    this.size = 48,
    this.iconSize = 20,
    this.filled = true,
    this.tooltip,
  });

  final IconData icon;

  /// Screen-reader label. Required so no icon control ships unlabeled.
  final String semanticLabel;
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

    final labeledButton =
        tooltip == null ? button : Tooltip(message: tooltip!, child: button);

    return Semantics(
      button: true,
      label: semanticLabel,
      enabled: onPressed != null,
      child: labeledButton,
    );
  }
}
