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
  });
}
