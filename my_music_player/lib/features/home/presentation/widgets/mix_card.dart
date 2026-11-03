import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_glass.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../../shared/widgets/glass_surface.dart';
import '../../../../shared/widgets/playlist_mosaic_cover.dart';
import '../../domain/entities/daily_mix.dart';

/// Cover artwork for a Daily Mix card or detail header.
///
/// Uses the four-image mosaic when available; otherwise falls back to the
/// branded gradient and waveform placeholder.
class MixArtwork extends StatelessWidget {
  const MixArtwork({
    super.key,
    required this.mood,
    required this.artworkUrls,
    this.width = 164,
    this.height = 112,
  });

  final DailyMixMood mood;
  final List<String> artworkUrls;
  final double width;
  final double height;

  @override
  Widget build(BuildContext context) {
    final tokens = AppColors.of(context);
    final radius = BorderRadius.circular(AppRadius.md);

    final Widget artwork = artworkUrls.length >= 4
        ? PlaylistMosaicCover(
            imageUrls: artworkUrls,
            width: width,
            height: height,
          )
        : _MixPlaceholder(mood: mood, width: width, height: height);

    return SizedBox(
      width: width,
      height: height,
      child: ClipRRect(
        borderRadius: radius,
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: tokens.artwork,
            borderRadius: radius,
          ),
          child: artwork,
        ),
      ),
    );
  }
}

class _MixPlaceholder extends StatelessWidget {
  const _MixPlaceholder({
    required this.mood,
    required this.width,
    required this.height,
  });

  static const List<double> _waveHeights = <double>[
    40,
    64,
    32,
    80,
    56,
    48,
    72,
    40,
    88,
    52,
    68,
    36,
    60,
    76,
    44,
    56,
    64,
    48,
  ];

  final DailyMixMood mood;
  final double width;
  final double height;

  @override
  Widget build(BuildContext context) {
    final tokens = AppColors.of(context);
    return DecoratedBox(
      decoration: BoxDecoration(gradient: tokens.artworkGradient),
      child: Stack(
        children: [
          Center(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                for (final waveHeight in _waveHeights)
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 1.5),
                    child: Container(
                      width: 4,
                      height: waveHeight * 0.9,
                      decoration: BoxDecoration(
                        color: tokens.waveform,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
              ],
            ),
          ),
          Positioned(
            top: 6,
            left: 6,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(AppRadius.sm),
                border: Border.all(color: tokens.border),
              ),
              child: Text(
                AppLocalizations.of(context).dailyMixBadge(
                  (mood.index + 1).toString().padLeft(2, '0'),
                ),
                style: TextStyle(
                  fontSize: 9,
                  fontWeight: FontWeight.w500,
                  color: tokens.textPrimary.withValues(alpha: 0.6),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// 184×181 mood card for the Home Daily Mix rail.
class MixCard extends StatelessWidget {
  const MixCard({
    super.key,
    required this.mood,
    required this.artworkUrls,
    required this.onTap,
  });

  final DailyMixMood mood;
  final List<String> artworkUrls;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final tokens = AppColors.of(context);
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context);
    final radius = BorderRadius.circular(AppRadius.xl);

    return Semantics(
      button: true,
      excludeSemantics: true,
      label: l10n.dailyMixSemantics(mood.label),
      child: SizedBox(
        width: 184,
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: 181),
          child: GlassSurface.card(
            // Horizontal rail: glass fill + border without another blur
            // layer, per the performance ladder.
            quality: GlassQuality.frosted,
            borderRadius: radius,
            child: Material(
              type: MaterialType.transparency,
              borderRadius: radius,
              child: InkWell(
                borderRadius: radius,
                onTap: onTap,
                child: Padding(
                  padding: const EdgeInsets.all(AppSpacing.space3),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      MixArtwork(mood: mood, artworkUrls: artworkUrls),
                      const SizedBox(height: AppSpacing.space2),
                      Text(
                        mood.label,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w500,
                          color: tokens.textPrimary,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.space1),
                      Text(
                        l10n.dailyMixLabel,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: tokens.textSecondary,
                          fontSize: 11,
                          letterSpacing: 0,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
