import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:my_music_player/core/theme/app_colors.dart';
import 'package:my_music_player/core/theme/app_glass.dart';

import '../../helpers/pump_app.dart';

void main() {
  group('AppGlass tokens', () {
    test('dark values match DESIGN_SYSTEM §0.2', () {
      const tokens = AppGlass.dark;

      expect(tokens.backgroundBase, const Color(0xFF080808));
      expect(
        tokens.gradientStops,
        const <Color>[
          Color(0xFF151B24),
          Color(0xFF0A0D12),
          Color(0xFF050506),
        ],
      );
      expect(tokens.bloomWhite, const Color(0x24FFFFFF));
      expect(tokens.bloomCold, const Color(0x2A9FB7C9));

      expect(tokens.card.fill, const Color(0x10FFFFFF));
      expect(tokens.card.border, const Color(0x1FFFFFFF));
      expect(tokens.card.blurSigma, 16);
      expect(tokens.card.shadow, isEmpty);

      expect(tokens.chrome.fill, const Color(0x14FFFFFF));
      expect(tokens.chrome.border, const Color(0x24FFFFFF));
      expect(tokens.chrome.blurSigma, 26);
      final chromeShadow = tokens.chrome.shadow.single;
      expect(chromeShadow.color, const Color(0x59000000));
      expect(chromeShadow.offset, const Offset(0, 18));
      expect(chromeShadow.blurRadius, 40);

      expect(tokens.statusSuccess, const Color(0xFF63E6B0));
      expect(tokens.statusWarning, const Color(0xFFF4C46A));
      expect(tokens.statusError, const Color(0xFFFF6B7A));
      expect(tokens.statusInfo, const Color(0xFF77B7FF));

      expect(tokens.provisional, isFalse);
    });

    test('light values match DESIGN_SYSTEM §0.2 provisional table', () {
      const tokens = AppGlass.light;

      expect(tokens.backgroundBase, const Color(0xFFF4F6F8));
      expect(
        tokens.gradientStops,
        const <Color>[
          Color(0xFFFFFFFF),
          Color(0xFFEDF1F5),
          Color(0xFFE6EBF1),
        ],
      );
      expect(tokens.bloomWhite, const Color(0x4DFFFFFF));
      expect(tokens.bloomCold, const Color(0xA6B7D6E8));

      expect(tokens.card.fill, const Color(0x99FFFFFF));
      expect(tokens.card.border, const Color(0x240A1018));
      expect(tokens.card.blurSigma, 16);
      expect(tokens.card.shadow, isEmpty);

      expect(tokens.chrome.fill, const Color(0xCCFFFFFF));
      expect(tokens.chrome.border, const Color(0x1F0A1018));
      expect(tokens.chrome.blurSigma, 26);
      final chromeShadow = tokens.chrome.shadow.single;
      expect(chromeShadow.color, const Color(0x1F0A1018));
      expect(chromeShadow.offset, const Offset(0, 18));
      expect(chromeShadow.blurRadius, 40);

      expect(tokens.statusSuccess, const Color(0xFF0F7A55));
      expect(tokens.statusWarning, const Color(0xFF8A5A00));
      expect(tokens.statusError, const Color(0xFFB3263A));
      expect(tokens.statusInfo, const Color(0xFF1F5FA8));

      expect(tokens.provisional, isTrue);
    });

    test('light glass stays translucent and borders are tinted, not white', () {
      const tokens = AppGlass.light;

      // Fills must let the aurora through while keeping dark text readable.
      expect(tokens.card.fill.a, lessThanOrEqualTo(0.6));
      expect(tokens.chrome.fill.a, lessThanOrEqualTo(0.8));

      // Borders use the cold ink tint; pure white disappears on #FFFFFF.
      expect(tokens.card.border, isNot(Colors.white));
      expect(tokens.chrome.border, isNot(Colors.white));
      expect(tokens.card.border.a, greaterThanOrEqualTo(0.12));
      expect(tokens.chrome.border.a, greaterThanOrEqualTo(0.10));

      final cardComposite = Color.alphaBlend(
        tokens.card.fill,
        const Color(0xFFE6EBF1),
      );
      final borderComposite = Color.alphaBlend(
        tokens.card.border,
        cardComposite,
      );
      // Hairline visibility, not a 3:1 UI boundary.
      expect(_contrastRatio(borderComposite, cardComposite), greaterThan(1.2));
    });

    test('light chip tokens keep visible tinted hairline borders', () {
      const tokens = AppGlass.light;
      const background = Color(0xFFE6EBF1);

      final selectedComposite = Color.alphaBlend(
        tokens.chipSelectedFill,
        background,
      );
      final selectedBorder = Color.alphaBlend(
        tokens.chipSelectedBorder,
        selectedComposite,
      );
      final subtleComposite = Color.alphaBlend(
        tokens.chipSubtleFill,
        background,
      );
      final subtleBorder = Color.alphaBlend(
        tokens.chipSubtleBorder,
        subtleComposite,
      );

      expect(
          _contrastRatio(selectedBorder, selectedComposite), greaterThan(1.4));
      expect(_contrastRatio(subtleBorder, subtleComposite), greaterThan(1.15));

      // Dark label text stays AA on both chip fills.
      expect(
        _contrastRatio(AppColors.light.textPrimary, selectedComposite),
        greaterThanOrEqualTo(4.5),
      );
      expect(
        _contrastRatio(AppColors.light.textSecondary, subtleComposite),
        greaterThanOrEqualTo(4.5),
      );
    });

    test('light blur inherits the dark recipe until the audit completes', () {
      expect(AppGlass.light.card.blurSigma, AppGlass.dark.card.blurSigma);
      expect(AppGlass.light.chrome.blurSigma, AppGlass.dark.chrome.blurSigma);
    });

    test('both palettes expose the same token shape', () {
      for (final tokens in <AppGlassTokens>[
        AppGlass.dark,
        AppGlass.light,
      ]) {
        expect(tokens.gradientStops, hasLength(3));
        expect(tokens.card.blurSigma, greaterThan(0));
        expect(tokens.chrome.blurSigma, greaterThan(0));
        expect(tokens.card.shadow, isNotNull);
        expect(tokens.chrome.shadow, isNotNull);
        expect(tokens.backgroundGradient.colors, tokens.gradientStops);
      }
    });

    test('production cap is 3 layers and sigma 26', () {
      expect(AppGlass.maxBlurLayersPerScreen, 3);
      expect(AppGlass.maxBlurSigma, 26);
      for (final tokens in <AppGlassTokens>[
        AppGlass.dark,
        AppGlass.light,
      ]) {
        expect(
          tokens.card.blurSigma,
          lessThanOrEqualTo(AppGlass.maxBlurSigma),
        );
        expect(
          tokens.chrome.blurSigma,
          lessThanOrEqualTo(AppGlass.maxBlurSigma),
        );
      }
    });

    test('semantic status colours are distinct per palette', () {
      for (final tokens in <AppGlassTokens>[
        AppGlass.dark,
        AppGlass.light,
      ]) {
        final values = <Color>{
          tokens.statusSuccess,
          tokens.statusWarning,
          tokens.statusError,
          tokens.statusInfo,
        };
        expect(values, hasLength(4));
      }
    });
  });

  group('AppGlass resolver', () {
    testWidgets('resolves dark and light tokens from Theme brightness',
        (tester) async {
      late AppGlassTokens resolved;

      await pumpApp(
        tester,
        Builder(
          builder: (context) {
            resolved = AppGlass.of(context);
            return const SizedBox.shrink();
          },
        ),
      );
      expect(resolved, same(AppGlass.dark));

      await pumpApp(
        tester,
        Builder(
          builder: (context) {
            resolved = AppGlass.of(context);
            return const SizedBox.shrink();
          },
        ),
        themeMode: ThemeMode.light,
      );
      await tester.pumpAndSettle();
      expect(resolved, same(AppGlass.light));

      expect(AppGlass.ofBrightness(Brightness.dark), same(AppGlass.dark));
      expect(AppGlass.ofBrightness(Brightness.light), same(AppGlass.light));
    });
  });

  group('Glass contrast on the composite', () {
    const palettes = <String, (AppGlassTokens, AppColorTokens, Brightness)>{
      'dark': (AppGlass.dark, AppColors.dark, Brightness.dark),
      'light': (AppGlass.light, AppColors.light, Brightness.light),
    };

    for (final entry in palettes.entries) {
      final name = entry.key;
      final glass = entry.value.$1;
      final colors = entry.value.$2;
      final brightness = entry.value.$3;
      final background = _worstGradientStop(glass, brightness);
      final cardComposite = Color.alphaBlend(glass.card.fill, background);
      final chromeComposite = Color.alphaBlend(
        glass.chrome.fill,
        background,
      );

      test('$name text on card and chrome meets WCAG AA 4.5:1', () {
        final surfaces = <String, Color>{
          'card': cardComposite,
          'chrome': chromeComposite,
        };
        for (final surface in surfaces.entries) {
          expect(
            _contrastRatio(colors.textPrimary, surface.value),
            greaterThanOrEqualTo(4.5),
            reason: '$name textPrimary/${surface.key}',
          );
          expect(
            _contrastRatio(colors.textSecondary, surface.value),
            greaterThanOrEqualTo(4.5),
            reason: '$name textSecondary/${surface.key}',
          );
        }
      });

      test('$name accent pair meets WCAG AA 4.5:1', () {
        expect(
          _contrastRatio(colors.accent, colors.onAccent),
          greaterThanOrEqualTo(4.5),
        );
      });

      test('$name textInactive keeps 3:1 icon contrast on chrome', () {
        // At the lightest dark-gradient stop, textInactive on chrome is about
        // 4.3:1: use textSecondary for labels and textInactive for icons.
        expect(
          _contrastRatio(colors.textInactive, chromeComposite),
          greaterThanOrEqualTo(3.0),
        );
      });

      test('$name semantic status colours meet 4.5:1 on both recipes', () {
        final statuses = <String, Color>{
          'success': glass.statusSuccess,
          'warning': glass.statusWarning,
          'error': glass.statusError,
          'info': glass.statusInfo,
        };
        final surfaces = <String, Color>{
          'card': cardComposite,
          'chrome': chromeComposite,
        };
        for (final status in statuses.entries) {
          for (final surface in surfaces.entries) {
            expect(
              _contrastRatio(status.value, surface.value),
              greaterThanOrEqualTo(4.5),
              reason: '$name ${status.key}/${surface.key}',
            );
          }
        }
      });
    }
  });
}

/// Picks the gradient stop that gives the least contrast for the palette:
/// white text loses contrast on the lightest stop, dark text on the darkest.
Color _worstGradientStop(AppGlassTokens tokens, Brightness brightness) {
  return tokens.gradientStops.reduce((a, b) {
    final aLuminance = a.computeLuminance();
    final bLuminance = b.computeLuminance();
    if (brightness == Brightness.dark) {
      return aLuminance > bLuminance ? a : b;
    }
    return aLuminance < bLuminance ? a : b;
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
