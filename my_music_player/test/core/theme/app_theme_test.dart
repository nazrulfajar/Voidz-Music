import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:my_music_player/core/theme/app_colors.dart';
import 'package:my_music_player/core/theme/app_theme.dart';

void main() {
  group('AppColors', () {
    test('dark palette is monochrome', () {
      const tokens = AppColors.dark;
      final colors = <Color>[
        tokens.background,
        tokens.panel,
        tokens.field,
        tokens.surface,
        tokens.row,
        tokens.raised,
        tokens.miniPlayer,
        tokens.navigation,
        tokens.well,
        tokens.artwork,
        tokens.border,
        tokens.focusedBorder,
        tokens.frameBorder,
        tokens.textPrimary,
        tokens.textSecondary,
        tokens.textInactive,
        tokens.textMuted,
        tokens.track,
        tokens.qualityOutline,
        tokens.waveform,
        tokens.mosaic1,
        tokens.mosaic2,
        tokens.mosaic3,
        tokens.mosaic4,
        tokens.accent,
        tokens.onAccent,
      ];
      for (final color in colors) {
        final r = (color.r * 255).round();
        final g = (color.g * 255).round();
        final b = (color.b * 255).round();
        final spread = [r, g, b].reduce((a, b) => a > b ? a : b) -
            [r, g, b].reduce((a, b) => a < b ? a : b);
        expect(
          spread,
          lessThanOrEqualTo(10),
          reason: '$color should stay within the cool-grey range',
        );
      }
    });

    test('legacy aliases resolve to the monochrome palette', () {
      expect(AppColors.accentPrimary, AppColors.dark.accent);
      expect(AppColors.surfaceBase, AppColors.dark.background);
      expect(AppColors.statusSuccess, AppColors.dark.textPrimary);
    });
  });

  group('AppTheme', () {
    test('dark theme uses Obsidian surface and accent tokens', () {
      final theme = AppTheme.darkTheme;
      expect(theme.brightness, Brightness.dark);
      expect(theme.scaffoldBackgroundColor, AppColors.dark.background);
      expect(theme.colorScheme.primary, AppColors.dark.accent);
      expect(theme.colorScheme.onPrimary, AppColors.dark.onAccent);
      expect(theme.sliderTheme.trackHeight, 5);
      expect(
        theme.bottomSheetTheme.backgroundColor,
        AppColors.dark.panel,
      );
    });

    test('light theme uses Warm Neutral surface and accent tokens', () {
      final theme = AppTheme.lightTheme;
      expect(theme.brightness, Brightness.light);
      expect(theme.scaffoldBackgroundColor, AppColors.light.background);
      expect(theme.colorScheme.primary, AppColors.light.accent);
      expect(theme.colorScheme.onPrimary, AppColors.light.onAccent);
      expect(theme.colorScheme.surface, AppColors.light.surface);
      expect(
        theme.bottomSheetTheme.backgroundColor,
        AppColors.light.panel,
      );
    });

    testWidgets('AppColors.of resolves tokens from Theme brightness',
        (tester) async {
      late AppColorTokens resolved;
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.darkTheme,
          home: Builder(
            builder: (context) {
              resolved = AppColors.of(context);
              return const SizedBox.shrink();
            },
          ),
        ),
      );
      expect(resolved.background, AppColors.dark.background);
    });

    testWidgets('AppColors.of resolves light tokens', (tester) async {
      late AppColorTokens resolved;
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          home: Builder(
            builder: (context) {
              resolved = AppColors.of(context);
              return const SizedBox.shrink();
            },
          ),
        ),
      );
      expect(resolved.background, AppColors.light.background);
      expect(resolved.textPrimary, AppColors.light.textPrimary);
    });
  });

  group('Documented contrast pairs (DESIGN_SYSTEM §2.5)', () {
    final palettes = <String, AppColorTokens>{
      'dark': AppColors.dark,
      'light': AppColors.light,
    };

    for (final entry in palettes.entries) {
      final name = entry.key;
      final tokens = entry.value;

      test('$name essential text pairs meet WCAG AA 4.5:1', () {
        final pairs = <String, (Color, Color)>{
          'textPrimary/background': (tokens.textPrimary, tokens.background),
          'textSecondary/background': (
            tokens.textSecondary,
            tokens.background,
          ),
          'textSecondary/surface': (tokens.textSecondary, tokens.surface),
          'textSecondary/row': (tokens.textSecondary, tokens.row),
          'textInactive/navigation': (tokens.textInactive, tokens.navigation),
          'onAccent/accent': (tokens.onAccent, tokens.accent),
        };

        pairs.forEach((pair, colors) {
          expect(
            _contrastRatio(colors.$1, colors.$2),
            greaterThanOrEqualTo(4.5),
            reason: '$name $pair must meet the documented AA ratio',
          );
        });
      });

      test('$name textMuted stays a documented non-essential exception', () {
        expect(
          _contrastRatio(tokens.textMuted, tokens.background),
          lessThan(4.5),
          reason: 'textMuted is hint/placeholder only, never metadata',
        );
        expect(
          _contrastRatio(tokens.textMuted, tokens.surface),
          lessThan(4.5),
          reason: 'textMuted is hint/placeholder only, never metadata',
        );
      });

      test('$name accent and progress pairs meet 3:1', () {
        expect(
          _contrastRatio(tokens.accent, tokens.track),
          greaterThanOrEqualTo(3.0),
        );
      });
    }
  });
}

/// WCAG 2.x relative-luminance contrast ratio.
double _contrastRatio(Color foreground, Color background) {
  final foregroundLuminance = foreground.computeLuminance();
  final backgroundLuminance = background.computeLuminance();
  final lighter = foregroundLuminance > backgroundLuminance
      ? foregroundLuminance
      : backgroundLuminance;
  final darker = foregroundLuminance > backgroundLuminance
      ? backgroundLuminance
      : foregroundLuminance;
  return (lighter + 0.05) / (darker + 0.05);
}
