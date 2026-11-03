import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_glass.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../shared/widgets/glass_surface.dart';

/// Full-width source card used by the browse hub and the Search entry point.
///
/// Keeps a 48dp tap target, a single screen-reader label, and grows with the
/// text scale instead of using a fixed height. Pass [glassQuality] to render
/// the card on the v3 glass material; null keeps the opaque v2 surface.
class BrowseSourceCard extends StatelessWidget {
  const BrowseSourceCard({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.semanticLabel,
    required this.onTap,
    this.glassQuality,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final String semanticLabel;
  final VoidCallback onTap;

  /// Optional glass recipe. The browse hub leaves this null (v2 surface).
  final GlassQuality? glassQuality;

  @override
  Widget build(BuildContext context) {
    final t = AppColors.of(context);

    Widget body = InkWell(
      onTap: onTap,
      child: ConstrainedBox(
        constraints: const BoxConstraints(minHeight: 72),
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.space3,
            vertical: AppSpacing.space3,
          ),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: t.well,
                  borderRadius: BorderRadius.circular(AppRadius.md),
                ),
                child: Icon(icon, size: 20, color: t.textPrimary),
              ),
              const SizedBox(width: AppSpacing.space3),
              Expanded(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: t.textPrimary,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xxs),
                    Text(
                      subtitle,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 12,
                        color: t.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: AppSpacing.space2),
              Icon(
                Icons.chevron_right_rounded,
                size: 20,
                color: t.textSecondary,
              ),
            ],
          ),
        ),
      ),
    );

    final quality = glassQuality;
    if (quality == null) {
      body = Material(
        color: t.row,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.xl),
          side: BorderSide(color: t.border),
        ),
        clipBehavior: Clip.antiAlias,
        child: body,
      );
    } else {
      body = GlassSurface.card(
        quality: quality,
        borderRadius: BorderRadius.circular(AppRadius.xl),
        child: Material(
          color: Colors.transparent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.xl),
          ),
          clipBehavior: Clip.antiAlias,
          child: body,
        ),
      );
    }

    return Semantics(
      button: true,
      label: semanticLabel,
      excludeSemantics: true,
      child: body,
    );
  }
}
