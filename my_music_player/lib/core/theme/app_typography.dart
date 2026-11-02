import 'package:flutter/material.dart';

import 'app_colors.dart';

/// Type scale from `docs/DESIGN_SYSTEM.md` §3.
///
/// The product family is Roboto (available on Android); the platform
/// sans-serif is the fallback. Only this file may name the family.
class AppTypography {
  const AppTypography._();

  static const String fontFamily = 'Roboto';

  static TextTheme textTheme(AppColorTokens tokens) {
    final base = TextTheme(
      displayLarge: _style(32, FontWeight.w700, 40, tokens.textPrimary),
      displayMedium: _style(24, FontWeight.w600, 32, tokens.textPrimary),
      displaySmall: _style(22, FontWeight.w700, 28, tokens.textPrimary),
      headlineLarge: _style(28, FontWeight.w700, 34, tokens.textPrimary,
          letterSpacing: -0.6),
      headlineMedium: _style(26, FontWeight.w700, 32, tokens.textPrimary),
      headlineSmall: _style(22, FontWeight.w600, 28, tokens.textPrimary),
      titleLarge: _style(20, FontWeight.w600, 28, tokens.textPrimary),
      titleMedium: _style(16, FontWeight.w500, 24, tokens.textPrimary),
      titleSmall: _style(14, FontWeight.w500, 20, tokens.textPrimary),
      bodyLarge: _style(16, FontWeight.w400, 24, tokens.textPrimary),
      bodyMedium: _style(14, FontWeight.w400, 20, tokens.textPrimary),
      bodySmall: _style(12, FontWeight.w400, 16, tokens.textSecondary),
      labelLarge: _style(14, FontWeight.w500, 20, tokens.textPrimary),
      labelMedium: _style(12, FontWeight.w500, 18, tokens.textSecondary),
      labelSmall: _style(11, FontWeight.w500, 16, tokens.textSecondary),
    );

    return base.apply(
      fontFamily: fontFamily,
      bodyColor: tokens.textPrimary,
      displayColor: tokens.textPrimary,
    );
  }

  static TextStyle _style(
    double size,
    FontWeight weight,
    double height,
    Color color, {
    double? letterSpacing,
  }) {
    return TextStyle(
      fontFamily: fontFamily,
      fontSize: size,
      fontWeight: weight,
      height: height / size,
      letterSpacing: letterSpacing,
      color: color,
    );
  }

  /// Overline / section label: 11sp Medium, +1.2 letter spacing.
  static TextStyle overline(AppColorTokens tokens) {
    return _style(11, FontWeight.w500, 17, tokens.textSecondary,
            letterSpacing: 1.2)
        .copyWith(fontFamily: fontFamily);
  }

  static TextStyle monospace(AppColorTokens tokens) {
    return TextStyle(
      fontFamily: 'monospace',
      fontSize: 12,
      height: 18 / 12,
      color: tokens.textSecondary,
    );
  }
}
