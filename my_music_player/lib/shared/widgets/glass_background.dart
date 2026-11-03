import 'package:flutter/material.dart';

import '../../core/theme/app_glass.dart';

/// Static v3 background from `docs/DESIGN_SYSTEM.md` §0.4.
///
/// Paints the base colour, the vertical cool gradient and at most two radial
/// blooms (white plus cold-neutral). It never animates, so reduced motion is
/// naturally static, and the decoration sits behind a [RepaintBoundary] so
/// scrolling content above it does not repaint the gradient.
///
/// Reusable by every shell page. Put it at the bottom of the page stack; the
/// optional [child] is painted above the decoration.
class GlassBackground extends StatelessWidget {
  const GlassBackground({super.key, this.child});

  final Widget? child;

  @override
  Widget build(BuildContext context) {
    final tokens = AppGlass.of(context);

    return Stack(
      fit: StackFit.expand,
      children: [
        RepaintBoundary(
          child: ExcludeSemantics(
            child: _GlassBackgroundLayers(tokens: tokens),
          ),
        ),
        if (child != null) child!,
      ],
    );
  }
}

class _GlassBackgroundLayers extends StatelessWidget {
  const _GlassBackgroundLayers({required this.tokens});

  final AppGlassTokens tokens;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final height = constraints.maxHeight;
        final bloomSize = (width > height ? width : height) * 0.95;

        return Stack(
          fit: StackFit.expand,
          children: [
            ColoredBox(
              key: const Key('glass-background-base'),
              color: tokens.backgroundBase,
            ),
            DecoratedBox(
              key: const Key('glass-background-gradient'),
              decoration: BoxDecoration(gradient: tokens.backgroundGradient),
            ),
            Positioned(
              key: const Key('glass-bloom-white'),
              left: -bloomSize * 0.35,
              top: -bloomSize * 0.45,
              width: bloomSize,
              height: bloomSize,
              child: _Bloom(color: tokens.bloomWhite),
            ),
            Positioned(
              key: const Key('glass-bloom-cold'),
              right: -bloomSize * 0.30,
              top: height * 0.28,
              width: bloomSize,
              height: bloomSize,
              child: _Bloom(color: tokens.bloomCold),
            ),
          ],
        );
      },
    );
  }
}

/// Radial bloom, centre to transparent. Decorative only.
class _Bloom extends StatelessWidget {
  const _Bloom({required this.color});

  final Color color;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: RadialGradient(
          // Fade to transparent at the box edge (0.5 of the shortest side) so
          // the bloom layer never clips into a visible seam.
          radius: 0.5,
          colors: <Color>[color, color.withValues(alpha: 0)],
        ),
      ),
    );
  }
}
