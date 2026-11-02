import 'package:flutter/material.dart';

/// Named colour tokens from `docs/DESIGN_SYSTEM.md` §2.2.
///
/// Every UI surface must resolve a colour through [AppColors.dark] or
/// [AppColors.light] (directly or through `AppColors.of(context)`). Widgets
/// must not hardcode hex values.
@immutable
class AppColorTokens {
  const AppColorTokens({
    required this.background,
    required this.panel,
    required this.field,
    required this.surface,
    required this.row,
    required this.raised,
    required this.miniPlayer,
    required this.navigation,
    required this.well,
    required this.artwork,
    required this.border,
    required this.focusedBorder,
    required this.frameBorder,
    required this.textPrimary,
    required this.textSecondary,
    required this.textInactive,
    required this.textMuted,
    required this.track,
    required this.qualityOutline,
    required this.waveform,
    required this.mosaic1,
    required this.mosaic2,
    required this.mosaic3,
    required this.mosaic4,
    required this.accent,
    required this.onAccent,
    required this.scrim,
    required this.artworkGradient,
  });

  final Color background;
  final Color panel;
  final Color field;
  final Color surface;
  final Color row;
  final Color raised;
  final Color miniPlayer;
  final Color navigation;
  final Color well;
  final Color artwork;
  final Color border;
  final Color focusedBorder;
  final Color frameBorder;
  final Color textPrimary;
  final Color textSecondary;
  final Color textInactive;
  final Color textMuted;
  final Color track;
  final Color qualityOutline;
  final Color waveform;
  final Color mosaic1;
  final Color mosaic2;
  final Color mosaic3;
  final Color mosaic4;
  final Color accent;
  final Color onAccent;
  final Color scrim;
  final LinearGradient artworkGradient;
}

/// Palette v2 — monochrome Obsidian (dark) and Warm Neutral (light).
class AppColors {
  const AppColors._();

  static const AppColorTokens dark = AppColorTokens(
    background: Color(0xFF080808),
    panel: Color(0xFF0B0B0B),
    field: Color(0xFF121314),
    surface: Color(0xFF131416),
    row: Color(0xFF151618),
    raised: Color(0xFF1B1C1E),
    miniPlayer: Color(0xFF111214),
    navigation: Color(0xFF0D0E0F),
    well: Color(0xFF252629),
    artwork: Color(0xFF242528),
    border: Color(0xFF343538),
    focusedBorder: Color(0xFF49494D),
    frameBorder: Color(0xFF37373A),
    textPrimary: Color(0xFFFFFFFF),
    textSecondary: Color(0xFFA6A6AE),
    textInactive: Color(0xFF8F8F97),
    textMuted: Color(0xFF73737A),
    track: Color(0xFF292A2E),
    qualityOutline: Color(0xFFCCCCCC),
    waveform: Color(0xFFB3B4BC),
    mosaic1: Color(0xFF5C5D66),
    mosaic2: Color(0xFF42434B),
    mosaic3: Color(0xFF35363E),
    mosaic4: Color(0xFF25262D),
    accent: Color(0xFFFFFFFF),
    onAccent: Color(0xFF080808),
    scrim: Color(0x8C000000),
    artworkGradient: LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: [Color(0xFF252629), Color(0xFF111214)],
    ),
  );

  static const AppColorTokens light = AppColorTokens(
    background: Color(0xFFF5F5F3),
    panel: Color(0xFFFFFFFF),
    field: Color(0xFFEEEEEB),
    surface: Color(0xFFEEEEEB),
    row: Color(0xFFEBEBE8),
    raised: Color(0xFFE1E1DE),
    miniPlayer: Color(0xFFFFFFFF),
    navigation: Color(0xFFFFFFFF),
    well: Color(0xFFDADAD7),
    artwork: Color(0xFFDDDDDA),
    border: Color(0xFFCECECC),
    focusedBorder: Color(0xFFA5A5AB),
    frameBorder: Color(0xFFCECECC),
    textPrimary: Color(0xFF0A0A0A),
    textSecondary: Color(0xFF606068),
    textInactive: Color(0xFF64646C),
    textMuted: Color(0xFF8A8A92),
    track: Color(0xFFCDCDCA),
    qualityOutline: Color(0xFF64646C),
    waveform: Color(0xFF65656D),
    mosaic1: Color(0xFF96969A),
    mosaic2: Color(0xFFB1B1B3),
    mosaic3: Color(0xFFC2C2C2),
    mosaic4: Color(0xFFD0D0CE),
    accent: Color(0xFF0A0A0A),
    onAccent: Color(0xFFFFFFFF),
    scrim: Color(0x8C000000),
    artworkGradient: LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: [Color(0xFFDADAD7), Color(0xFFFFFFFF)],
    ),
  );

  /// Resolves the active token set for the current [Theme].
  static AppColorTokens of(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark ? dark : light;
  }

  // ---------------------------------------------------------------------
  // Legacy aliases. They keep screens that have not been migrated yet on the
  // new monochrome palette instead of the removed v1 zinc/sky palette.
  // New code should use `AppColors.of(context)`.
  // ---------------------------------------------------------------------

  static const Color surfaceBase = Color(0xFF080808);
  static const Color surfaceElevated = Color(0xFF131416);
  static const Color surfaceOverlay = Color(0xFF1B1C1E);
  static const Color surfaceHover = Color(0xFF252629);

  static const Color accentPrimary = Color(0xFFFFFFFF);
  static const Color accentPrimaryVariant = Color(0xFFE6E6E6);
  static const Color accentSecondary = Color(0xFFA6A6AE);
  static const Color accentTertiary = Color(0xFF73737A);

  static const Color glowColor = Color(0x00000000);
  static const Color blurBackground = Color(0xE6080808);
  static const Color glassBorder = Color(0xFF343538);

  static const Color textPrimary = Color(0xFFFFFFFF);
  static const Color textSecondary = Color(0xFFA6A6AE);
  static const Color textTertiary = Color(0xFF8F8F97);
  static const Color textOnAccent = Color(0xFF080808);

  // Status is communicated with icon + label, never hue.
  static const Color statusSuccess = textPrimary;
  static const Color statusWarning = textPrimary;
  static const Color statusError = textPrimary;
  static const Color statusInfo = textSecondary;

  static const Color transparent = Colors.transparent;
}
