import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_radius.dart';
import '../../core/theme/app_spacing.dart';

/// Returns true when the platform asks for reduced motion.
bool _animationsDisabled(BuildContext context) {
  return MediaQuery.maybeOf(context)?.disableAnimations ?? false;
}

/// A single skeleton block. The shimmer is replaced by a static fill when
/// `MediaQuery.disableAnimations` is true (design system §6.7 / §10).
class ShimmerBox extends StatelessWidget {
  final double? width;
  final double height;
  final double radius;
  final double opacity;

  const ShimmerBox({
    super.key,
    this.width,
    required this.height,
    this.radius = AppRadius.sm,
    this.opacity = 0.08,
  });

  @override
  Widget build(BuildContext context) {
    final tokens = AppColors.of(context);
    final base = tokens.textPrimary.withValues(alpha: opacity);
    final box = Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: base,
        borderRadius: BorderRadius.circular(radius),
      ),
    );
    if (_animationsDisabled(context)) return box;
    return Shimmer.fromColors(
      baseColor: base,
      highlightColor: tokens.textPrimary.withValues(
        alpha: (opacity + 0.04).clamp(0.0, 1.0),
      ),
      child: box,
    );
  }
}

/// Content-shaped skeleton for a track row: 46dp artwork, title and subtitle.
class ShimmerTrackTile extends StatelessWidget {
  const ShimmerTrackTile({super.key});

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.symmetric(
        horizontal: AppSpacing.space4,
        vertical: AppSpacing.space2,
      ),
      child: Row(
        children: [
          ShimmerBox(
            key: Key('shimmer-track-artwork'),
            width: 46,
            height: 46,
            radius: 12,
            opacity: 0.10,
          ),
          SizedBox(width: AppSpacing.space3),
          Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ShimmerBox(
                key: Key('shimmer-track-line'),
                width: 180,
                height: 10,
                radius: 5,
                opacity: 0.08,
              ),
              SizedBox(height: AppSpacing.space2),
              ShimmerBox(
                key: Key('shimmer-track-subline'),
                width: 120,
                height: 8,
                radius: 4,
                opacity: 0.05,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class ShimmerPlaylistCard extends StatelessWidget {
  const ShimmerPlaylistCard({super.key});

  @override
  Widget build(BuildContext context) {
    return const ShimmerBox(
      height: double.infinity,
      radius: AppRadius.md,
      opacity: 0.08,
    );
  }
}

/// Content-shaped skeleton for the Home "Continue Listening" card.
class ShimmerContinueCard extends StatelessWidget {
  const ShimmerContinueCard({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(minHeight: 98),
      padding: const EdgeInsets.all(AppSpacing.space3),
      decoration: BoxDecoration(
        color: AppColors.of(context).field,
        borderRadius: BorderRadius.circular(AppRadius.xxl),
      ),
      child: const Row(
        children: [
          ShimmerBox(
            width: 68,
            height: 68,
            radius: AppRadius.artworkSmall,
            opacity: 0.10,
          ),
          SizedBox(width: AppSpacing.space3),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ShimmerBox(width: 180, height: 12, radius: 6),
                SizedBox(height: AppSpacing.space2),
                ShimmerBox(width: 120, height: 9, radius: 5, opacity: 0.05),
                SizedBox(height: AppSpacing.space3),
                ShimmerBox(height: 3, radius: 2, opacity: 0.05),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class ShimmerSection extends StatelessWidget {
  final int itemCount;
  final bool isGrid;

  const ShimmerSection({super.key, this.itemCount = 5, this.isGrid = false});

  @override
  Widget build(BuildContext context) {
    if (isGrid) {
      return GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        padding: const EdgeInsets.all(AppSpacing.md),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          crossAxisSpacing: AppSpacing.md,
          mainAxisSpacing: AppSpacing.md,
          childAspectRatio: 0.8,
        ),
        itemCount: itemCount,
        itemBuilder: (_, __) => const ShimmerPlaylistCard(),
      );
    }

    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      padding: EdgeInsets.zero,
      itemCount: itemCount,
      itemBuilder: (_, __) => const ShimmerTrackTile(),
    );
  }
}
