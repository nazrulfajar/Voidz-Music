import 'package:flutter/material.dart';

import 'app_shadows.dart';

/// Glass render quality ladder from `docs/DESIGN_SYSTEM.md` §0.7.
///
/// Escalate one step at a time when a screen misses its frame budget:
/// blurred chrome -> blurred cards -> frosted cards/rows -> opaque chrome.
enum GlassQuality {
  /// Translucent tint over a [BackdropFilter]. Production cap: 2-3 blurred
  /// layers per screen.
  blurred,

  /// No backdrop filter. The tint is composited over the opaque v2 panel so
  /// text keeps its contrast on low-end devices.
  frosted,

  /// Opaque v2 panel plus a glass border. Lowest-cost fallback.
  opaque;

  /// Whether this quality paints a backdrop blur.
  bool get blurEnabled => this == GlassQuality.blurred;
}

/// One glass recipe: its translucent fill, border and blur signature.
///
/// Values are copied verbatim from `docs/DESIGN_SYSTEM.md` §0.2. Do not round
/// the blur sigma or replace it with a "close enough" value.
@immutable
class GlassRecipe {
  const GlassRecipe({
    required this.fill,
    required this.border,
    required this.blurSigma,
    required this.shadow,
  });

  final Color fill;
  final Color border;

  /// `backgroundBlur` radius from the board.
  final double blurSigma;
  final List<BoxShadow> shadow;

  /// Opaque approximation used by [GlassQuality.frosted].
  ///
  /// Blending the tint over the v2 panel keeps the recipe recognisable while
  /// removing the backdrop filter, so the result stays readable over content.
  Color frostedFill(Color base) => Color.alphaBlend(fill, base);
}

/// Glass material tokens from `docs/DESIGN_SYSTEM.md` §0.2.
///
/// Dark values are verified against the `08 · Glass direction — Logo_White`
/// board. Light values are provisional until the device contrast audit
/// (ADR-015); [provisional] marks that state.
@immutable
class AppGlassTokens {
  const AppGlassTokens({
    required this.backgroundBase,
    required this.gradientStops,
    required this.bloomWhite,
    required this.bloomCold,
    required this.card,
    required this.chrome,
    required this.chipSelectedFill,
    required this.chipSelectedBorder,
    required this.chipSubtleFill,
    required this.chipSubtleBorder,
    required this.statusSuccess,
    required this.statusWarning,
    required this.statusError,
    required this.statusInfo,
    required this.provisional,
  });

  /// Scaffold colour behind the gradient.
  final Color backgroundBase;

  /// Vertical gradient stops, top to bottom (§0.4).
  final List<Color> gradientStops;

  /// White radial bloom; render centre -> transparent.
  final Color bloomWhite;

  /// Cold-neutral radial bloom; render centre -> transparent.
  final Color bloomCold;

  /// Recipe for content cards.
  final GlassRecipe card;

  /// Recipe for floating chrome (mini-player, nav, dock, floating buttons).
  final GlassRecipe chrome;

  /// Selected filter chip fill. Chips never blur (§0.2 state & ornament).
  final Color chipSelectedFill;

  /// Selected filter chip 1px border.
  final Color chipSelectedBorder;

  /// Unselected / recent-search chip fill. No blur.
  final Color chipSubtleFill;

  /// Unselected / recent-search chip 1px border.
  final Color chipSubtleBorder;

  /// Semantic status colours. Use with icon + label, never as chrome/accent.
  final Color statusSuccess;
  final Color statusWarning;
  final Color statusError;
  final Color statusInfo;

  /// True when the token set has not completed its device contrast audit.
  final bool provisional;

  /// Background gradient resolved from [gradientStops].
  LinearGradient get backgroundGradient => LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: gradientStops,
      );
}

/// Resolves glass tokens for the active theme.
class AppGlass {
  const AppGlass._();

  /// Production cap from §0.7: count layers, not cards.
  static const int maxBlurLayersPerScreen = 3;

  /// Hard sigma ceiling from §0.7.
  static const double maxBlurSigma = 26;

  // -------------------------------------------------------------------------
  // Dark - verified on board 08.
  // -------------------------------------------------------------------------

  static const AppGlassTokens dark = AppGlassTokens(
    backgroundBase: Color(0xFF080808),
    gradientStops: <Color>[
      Color(0xFF151B24),
      Color(0xFF0A0D12),
      Color(0xFF050506),
    ],
    bloomWhite: Color(0x24FFFFFF),
    bloomCold: Color(0x2A9FB7C9),
    card: GlassRecipe(
      fill: Color(0x10FFFFFF),
      border: Color(0x1FFFFFFF),
      blurSigma: 16,
      shadow: AppShadows.none,
    ),
    chrome: GlassRecipe(
      fill: Color(0x14FFFFFF),
      border: Color(0x24FFFFFF),
      blurSigma: 26,
      shadow: AppShadows.glassChromeDark,
    ),
    chipSelectedFill: Color(0x26FFFFFF),
    chipSelectedBorder: Color(0x4DFFFFFF),
    chipSubtleFill: Color(0x0DFFFFFF),
    chipSubtleBorder: Color(0x14FFFFFF),
    statusSuccess: Color(0xFF63E6B0),
    statusWarning: Color(0xFFF4C46A),
    statusError: Color(0xFFFF6B7A),
    statusInfo: Color(0xFF77B7FF),
    provisional: false,
  );

  // -------------------------------------------------------------------------
  // Light - provisional values from §0.2; blur sigmas inherit the dark
  // recipe until the light board is audited on device. The borders are tinted
  // with the cold shadow ink so they stay visible on the #FFFFFF..#E6EBF1
  // gradient; the fills stay translucent enough to show the aurora.
  // -------------------------------------------------------------------------

  static const AppGlassTokens light = AppGlassTokens(
    backgroundBase: Color(0xFFF4F6F8),
    gradientStops: <Color>[
      Color(0xFFFFFFFF),
      Color(0xFFEDF1F5),
      Color(0xFFE6EBF1),
    ],
    bloomWhite: Color(0x4DFFFFFF),
    bloomCold: Color(0xA6B7D6E8),
    card: GlassRecipe(
      fill: Color(0x99FFFFFF),
      border: Color(0x240A1018),
      blurSigma: 16,
      shadow: AppShadows.none,
    ),
    chrome: GlassRecipe(
      fill: Color(0xCCFFFFFF),
      border: Color(0x1F0A1018),
      blurSigma: 26,
      shadow: AppShadows.glassChromeLight,
    ),
    // Chips do not blur. Tinted borders match the card/chrome hairline so
    // selected and subtle states stay visible on the light gradient.
    chipSelectedFill: Color(0xD9FFFFFF),
    chipSelectedBorder: Color(0x2E0A1018),
    chipSubtleFill: Color(0xCCFFFFFF),
    chipSubtleBorder: Color(0x1A0A1018),
    statusSuccess: Color(0xFF0F7A55),
    statusWarning: Color(0xFF8A5A00),
    statusError: Color(0xFFB3263A),
    statusInfo: Color(0xFF1F5FA8),
    provisional: true,
  );

  /// Resolves the token set for the current [Theme] brightness.
  static AppGlassTokens of(BuildContext context) {
    return ofBrightness(Theme.of(context).brightness);
  }

  /// Resolves the token set for an explicit [Brightness].
  static AppGlassTokens ofBrightness(Brightness brightness) {
    return brightness == Brightness.dark ? dark : light;
  }
}
