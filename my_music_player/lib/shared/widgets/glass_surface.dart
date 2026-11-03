import 'dart:ui' show ImageFilter;

import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_glass.dart';
import '../../core/theme/app_radius.dart';

/// Glass material surface from `docs/DESIGN_SYSTEM.md` §0.3.
///
/// [GlassSurface.card] is for content cards; [GlassSurface.chrome] is for
/// floating chrome (mini-player, navigation, dock, floating buttons). List
/// rows should not blur by default - pass [GlassQuality.frosted] or
/// [GlassQuality.opaque] instead.
///
/// Production cap: at most [AppGlass.maxBlurLayersPerScreen] blurred layers
/// per screen, never nest a [BackdropFilter] inside another glass surface.
/// Use [GlassQuality.frosted] / [GlassQuality.opaque] for the performance
/// fallback path; the widget must stay readable without blur.
class GlassSurface extends StatelessWidget {
  /// Content-card recipe: `glassCardFill`, `glassCardBorder`, blur 16.
  const GlassSurface.card({
    super.key,
    this.child,
    this.padding = EdgeInsets.zero,
    this.borderRadius = defaultBorderRadius,
    this.quality = GlassQuality.blurred,
    this.semanticsLabel,
  }) : _kind = _GlassKind.card;

  /// Floating-chrome recipe: `glassChromeFill`, `glassChromeBorder`, blur 26,
  /// chrome shadow.
  const GlassSurface.chrome({
    super.key,
    this.child,
    this.padding = EdgeInsets.zero,
    this.borderRadius = defaultBorderRadius,
    this.quality = GlassQuality.blurred,
    this.semanticsLabel,
  }) : _kind = _GlassKind.chrome;

  /// v2 content-card radius. Callers may override it for chrome.
  static const BorderRadius defaultBorderRadius = BorderRadius.all(
    Radius.circular(AppRadius.lg),
  );

  final Widget? child;
  final EdgeInsetsGeometry padding;
  final BorderRadius borderRadius;

  /// Rendering quality. Defaults to the full glass recipe.
  final GlassQuality quality;

  /// Optional label for the whole surface.
  final String? semanticsLabel;

  final _GlassKind _kind;

  @override
  Widget build(BuildContext context) {
    final glass = AppGlass.of(context);
    final colors = AppColors.of(context);
    final recipe = _kind == _GlassKind.card ? glass.card : glass.chrome;
    final base = _kind == _GlassKind.card ? colors.surface : colors.miniPlayer;

    // Reduced motion also drops the backdrop filter: the material is static
    // and the opaque fallback is the cheapest, most readable path.
    final effectiveQuality = quality == GlassQuality.blurred &&
            MediaQuery.disableAnimationsOf(context)
        ? GlassQuality.frosted
        : quality;

    final fill = switch (effectiveQuality) {
      GlassQuality.blurred => recipe.fill,
      GlassQuality.frosted => recipe.frostedFill(base),
      GlassQuality.opaque => base,
    };

    Widget content = Padding(padding: padding, child: child);
    if (effectiveQuality.blurEnabled) {
      content = BackdropFilter(
        filter: ImageFilter.blur(
          sigmaX: recipe.blurSigma,
          sigmaY: recipe.blurSigma,
        ),
        child: content,
      );
    }

    final surface = Container(
      decoration: BoxDecoration(
        color: fill,
        borderRadius: borderRadius,
        boxShadow: recipe.shadow,
      ),
      foregroundDecoration: BoxDecoration(
        borderRadius: borderRadius,
        border: Border.all(color: recipe.border),
      ),
      child: ClipRRect(
        borderRadius: borderRadius,
        child: content,
      ),
    );

    if (semanticsLabel == null) return surface;
    return Semantics(
      label: semanticsLabel,
      container: true,
      child: surface,
    );
  }
}

enum _GlassKind { card, chrome }
