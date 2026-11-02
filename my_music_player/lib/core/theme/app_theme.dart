import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'app_colors.dart';
import 'app_radius.dart';
import 'app_typography.dart';

/// Builds the dark "Obsidian" and light "Warm Neutral" themes.
///
/// Tokens and rules: `docs/DESIGN_SYSTEM.md` §2, §3, §4, §6, §8, §11.
class AppTheme {
  const AppTheme._();

  static ThemeData get darkTheme => buildTheme(Brightness.dark);

  static ThemeData get lightTheme => buildTheme(Brightness.light);

  static ThemeData buildTheme(Brightness brightness) {
    final tokens =
        brightness == Brightness.dark ? AppColors.dark : AppColors.light;
    final scheme = ColorScheme(
      brightness: brightness,
      primary: tokens.accent,
      onPrimary: tokens.onAccent,
      primaryContainer: tokens.raised,
      onPrimaryContainer: tokens.textPrimary,
      secondary: tokens.textPrimary,
      onSecondary: tokens.background,
      secondaryContainer: tokens.raised,
      onSecondaryContainer: tokens.textPrimary,
      tertiary: tokens.textSecondary,
      onTertiary: tokens.background,
      error: tokens.textPrimary,
      onError: tokens.background,
      errorContainer: tokens.raised,
      onErrorContainer: tokens.textPrimary,
      surface: tokens.surface,
      onSurface: tokens.textPrimary,
      surfaceContainerLowest: tokens.background,
      surfaceContainerLow: tokens.panel,
      surfaceContainer: tokens.surface,
      surfaceContainerHigh: tokens.row,
      surfaceContainerHighest: tokens.raised,
      onSurfaceVariant: tokens.textSecondary,
      outline: tokens.border,
      outlineVariant: tokens.border,
      shadow: Colors.black,
      scrim: tokens.scrim,
      inverseSurface: tokens.textPrimary,
      onInverseSurface: tokens.background,
      inversePrimary: tokens.background,
    );

    final textTheme = AppTypography.textTheme(tokens);
    final borderRadius = BorderRadius.circular(AppRadius.lg);

    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      colorScheme: scheme,
      scaffoldBackgroundColor: tokens.background,
      canvasColor: tokens.background,
      dividerColor: tokens.border,
      fontFamily: AppTypography.fontFamily,
      textTheme: textTheme,
      primaryTextTheme: textTheme,
      applyElevationOverlayColor: false,
      splashColor: tokens.textPrimary.withValues(alpha: 0.08),
      highlightColor: tokens.textPrimary.withValues(alpha: 0.04),
      hoverColor: tokens.textPrimary.withValues(alpha: 0.04),
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        foregroundColor: tokens.textPrimary,
        titleTextStyle: textTheme.titleLarge,
        iconTheme: IconThemeData(color: tokens.textPrimary, size: 21),
        systemOverlayStyle: brightness == Brightness.dark
            ? SystemUiOverlayStyle.light
            : SystemUiOverlayStyle.dark,
      ),
      iconTheme: IconThemeData(color: tokens.textPrimary, size: 21),
      dividerTheme: DividerThemeData(
        color: tokens.border,
        thickness: 1,
        space: 1,
      ),
      textSelectionTheme: TextSelectionThemeData(
        cursorColor: tokens.accent,
        selectionColor: tokens.accent.withValues(alpha: 0.24),
        selectionHandleColor: tokens.accent,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: tokens.surface,
        hintStyle: textTheme.bodyMedium?.copyWith(color: tokens.textMuted),
        labelStyle: textTheme.bodyMedium?.copyWith(color: tokens.textSecondary),
        prefixIconColor: tokens.textSecondary,
        suffixIconColor: tokens.textSecondary,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 14,
          vertical: 12,
        ),
        border: OutlineInputBorder(
          borderRadius: borderRadius,
          borderSide: BorderSide(color: tokens.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: borderRadius,
          borderSide: BorderSide(color: tokens.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: borderRadius,
          borderSide: BorderSide(color: tokens.focusedBorder),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: borderRadius,
          borderSide: BorderSide(color: tokens.textSecondary),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: borderRadius,
          borderSide: BorderSide(color: tokens.focusedBorder),
        ),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: tokens.surface,
        selectedColor: tokens.raised,
        disabledColor: tokens.field,
        side: BorderSide(color: tokens.border),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.lg),
          side: BorderSide(color: tokens.border),
        ),
        labelStyle:
            textTheme.labelMedium?.copyWith(color: tokens.textSecondary),
        secondaryLabelStyle:
            textTheme.labelMedium?.copyWith(color: tokens.textPrimary),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 0),
        labelPadding: EdgeInsets.zero,
        showCheckmark: false,
      ),
      sliderTheme: SliderThemeData(
        trackHeight: 5,
        activeTrackColor: tokens.accent,
        inactiveTrackColor: tokens.track,
        thumbColor: tokens.accent,
        overlayColor: tokens.textPrimary.withValues(alpha: 0.08),
        thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6.5),
        overlayShape: const RoundSliderOverlayShape(overlayRadius: 16),
        trackShape: const RoundedRectSliderTrackShape(),
      ),
      progressIndicatorTheme: ProgressIndicatorThemeData(
        color: tokens.accent,
        linearTrackColor: tokens.track,
        circularTrackColor: tokens.track,
      ),
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith(
          (states) => states.contains(WidgetState.selected)
              ? tokens.onAccent
              : tokens.textSecondary,
        ),
        trackColor: WidgetStateProperty.resolveWith(
          (states) => states.contains(WidgetState.selected)
              ? tokens.accent
              : tokens.track,
        ),
        trackOutlineColor: WidgetStateProperty.all(Colors.transparent),
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: tokens.raised,
        contentTextStyle: textTheme.bodyMedium,
        actionTextColor: tokens.textPrimary,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.lg),
          side: BorderSide(color: tokens.border),
        ),
      ),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: tokens.panel,
        surfaceTintColor: Colors.transparent,
        modalBackgroundColor: tokens.panel,
        modalBarrierColor: tokens.scrim,
        elevation: 0,
        shape: const RoundedRectangleBorder(
          borderRadius:
              BorderRadius.vertical(top: Radius.circular(AppRadius.xxxl)),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: tokens.accent,
          foregroundColor: tokens.onAccent,
          minimumSize: const Size(0, 48),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.xxxl),
          ),
          textStyle: textTheme.labelLarge,
          elevation: 0,
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: tokens.accent,
          foregroundColor: tokens.onAccent,
          elevation: 0,
          minimumSize: const Size(0, 48),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.xxxl),
          ),
          textStyle: textTheme.labelLarge,
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: tokens.textPrimary,
          textStyle: textTheme.labelLarge,
          minimumSize: const Size(0, 48),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: tokens.textPrimary,
          side: BorderSide(color: tokens.border),
          minimumSize: const Size(0, 48),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.xxxl),
          ),
          textStyle: textTheme.labelLarge,
        ),
      ),
      popupMenuTheme: PopupMenuThemeData(
        color: tokens.raised,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.lg),
          side: BorderSide(color: tokens.border),
        ),
        textStyle: textTheme.bodyMedium,
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
        indicatorColor: Colors.transparent,
        elevation: 0,
        labelTextStyle: WidgetStateProperty.resolveWith(
          (states) => textTheme.labelSmall?.copyWith(
            color: states.contains(WidgetState.selected)
                ? tokens.textPrimary
                : tokens.textInactive,
            fontWeight: states.contains(WidgetState.selected)
                ? FontWeight.w700
                : FontWeight.w400,
          ),
        ),
        iconTheme: WidgetStateProperty.resolveWith(
          (states) => IconThemeData(
            color: states.contains(WidgetState.selected)
                ? tokens.textPrimary
                : tokens.textInactive,
            size: 21,
          ),
        ),
      ),
    );
  }
}
