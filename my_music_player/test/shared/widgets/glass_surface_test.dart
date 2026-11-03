import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:my_music_player/core/theme/app_colors.dart';
import 'package:my_music_player/core/theme/app_glass.dart';
import 'package:my_music_player/shared/widgets/glass_surface.dart';

import '../../helpers/pump_app.dart';

void main() {
  group('GlassSurface.card', () {
    testWidgets('paints the card fill, border and backdrop blur',
        (tester) async {
      await pumpApp(
        tester,
        const Scaffold(
          body: Center(
            child: GlassSurface.card(
              child: SizedBox(width: 160, height: 48),
            ),
          ),
        ),
      );

      final container = _surfaceContainer(tester);
      final decoration = _decoration(container);
      expect(decoration.color, AppGlass.dark.card.fill);
      expect(decoration.borderRadius, GlassSurface.defaultBorderRadius);
      expect(decoration.boxShadow, isEmpty);

      final border = _border(container);
      expect(border.top.color, AppGlass.dark.card.border);
      expect(border.top.width, 1);

      expect(
        find.descendant(
          of: find.byType(GlassSurface),
          matching: find.byType(BackdropFilter),
        ),
        findsOneWidget,
      );
    });

    testWidgets('frosted fallback is opaque and has no BackdropFilter',
        (tester) async {
      await pumpApp(
        tester,
        const Scaffold(
          body: Center(
            child: GlassSurface.card(
              quality: GlassQuality.frosted,
              child: SizedBox(width: 160, height: 48),
            ),
          ),
        ),
      );

      final decoration = _decoration(_surfaceContainer(tester));
      expect(
        decoration.color,
        AppGlass.dark.card.frostedFill(AppColors.dark.surface),
      );
      expect(decoration.color!.a, 1.0);
      expect(
        find.descendant(
          of: find.byType(GlassSurface),
          matching: find.byType(BackdropFilter),
        ),
        findsNothing,
      );
    });

    testWidgets('opaque fallback uses the v2 panel and glass border',
        (tester) async {
      await pumpApp(
        tester,
        const Scaffold(
          body: Center(
            child: GlassSurface.card(
              quality: GlassQuality.opaque,
              child: SizedBox(width: 160, height: 48),
            ),
          ),
        ),
      );

      final container = _surfaceContainer(tester);
      final decoration = _decoration(container);
      expect(decoration.color, AppColors.dark.surface);
      expect(_border(container).top.color, AppGlass.dark.card.border);
      expect(
        find.descendant(
          of: find.byType(GlassSurface),
          matching: find.byType(BackdropFilter),
        ),
        findsNothing,
      );
    });

    testWidgets('disableAnimations falls back to frosted without blur',
        (tester) async {
      await pumpApp(
        tester,
        Scaffold(
          body: Builder(
            builder: (context) => MediaQuery(
              data: MediaQuery.of(context).copyWith(disableAnimations: true),
              child: const Center(
                child: GlassSurface.card(
                  child: SizedBox(width: 160, height: 48),
                ),
              ),
            ),
          ),
        ),
      );

      final decoration = _decoration(_surfaceContainer(tester));
      expect(
        decoration.color,
        AppGlass.dark.card.frostedFill(AppColors.dark.surface),
      );
      expect(
        find.descendant(
          of: find.byType(GlassSurface),
          matching: find.byType(BackdropFilter),
        ),
        findsNothing,
      );
    });

    testWidgets('light theme resolves the provisional card tokens',
        (tester) async {
      await pumpApp(
        tester,
        const Scaffold(
          body: Center(
            child: GlassSurface.card(
              child: SizedBox(width: 160, height: 48),
            ),
          ),
        ),
        themeMode: ThemeMode.light,
      );

      final container = _surfaceContainer(tester);
      expect(_decoration(container).color, AppGlass.light.card.fill);
      expect(_border(container).top.color, AppGlass.light.card.border);
    });

    testWidgets('survives 360x640 at text scale 2.0', (tester) async {
      await pumpApp(
        tester,
        const Scaffold(
          body: Center(
            child: SizedBox(
              width: 320,
              child: GlassSurface.card(
                padding: EdgeInsets.all(16),
                child: Text(
                  'A long glass surface label that should wrap without '
                  'overflowing at two hundred percent text scale.',
                ),
              ),
            ),
          ),
        ),
        textScale: 2.0,
      );

      expect(tester.takeException(), isNull);
      expect(find.textContaining('A long glass surface'), findsOneWidget);
    });

    testWidgets('does not shrink or clip a 48dp child', (tester) async {
      await pumpApp(
        tester,
        const Scaffold(
          body: Center(
            child: GlassSurface.card(
              child: SizedBox(
                key: Key('glass-48dp-child'),
                width: 48,
                height: 48,
              ),
            ),
          ),
        ),
      );

      expect(
        tester.getSize(find.byKey(const Key('glass-48dp-child'))),
        const Size(48, 48),
      );
      expect(tester.getSize(find.byType(GlassSurface)), const Size(48, 48));
      expect(tester.takeException(), isNull);
    });

    testWidgets('semanticsLabel labels the whole surface', (tester) async {
      final handle = tester.ensureSemantics();

      await pumpApp(
        tester,
        const Scaffold(
          body: Center(
            child: GlassSurface.card(
              semanticsLabel: 'Now playing',
              child: SizedBox(width: 160, height: 48),
            ),
          ),
        ),
      );

      expect(find.bySemanticsLabel('Now playing'), findsOneWidget);
      handle.dispose();
    });
  });

  group('GlassSurface.chrome', () {
    testWidgets('paints the chrome fill, border, shadow and blur',
        (tester) async {
      await pumpApp(
        tester,
        const Scaffold(
          body: Center(
            child: GlassSurface.chrome(
              child: SizedBox(width: 220, height: 64),
            ),
          ),
        ),
      );

      final container = _surfaceContainer(tester);
      final decoration = _decoration(container);
      expect(decoration.color, AppGlass.dark.chrome.fill);
      expect(decoration.boxShadow, AppGlass.dark.chrome.shadow);
      expect(_border(container).top.color, AppGlass.dark.chrome.border);
      expect(
        find.descendant(
          of: find.byType(GlassSurface),
          matching: find.byType(BackdropFilter),
        ),
        findsOneWidget,
      );
    });

    testWidgets('opaque chrome uses the mini-player panel plus glass border',
        (tester) async {
      await pumpApp(
        tester,
        const Scaffold(
          body: Center(
            child: GlassSurface.chrome(
              quality: GlassQuality.opaque,
              child: SizedBox(width: 220, height: 64),
            ),
          ),
        ),
      );

      final container = _surfaceContainer(tester);
      expect(_decoration(container).color, AppColors.dark.miniPlayer);
      expect(_border(container).top.color, AppGlass.dark.chrome.border);
      expect(
        find.descendant(
          of: find.byType(GlassSurface),
          matching: find.byType(BackdropFilter),
        ),
        findsNothing,
      );
    });
  });

  group('GlassQuality', () {
    test('only blurred requests a backdrop filter', () {
      expect(GlassQuality.blurred.blurEnabled, isTrue);
      expect(GlassQuality.frosted.blurEnabled, isFalse);
      expect(GlassQuality.opaque.blurEnabled, isFalse);
    });
  });
}

Container _surfaceContainer(WidgetTester tester) {
  final finder = find.descendant(
    of: find.byType(GlassSurface),
    matching: find.byType(Container),
  );
  return tester.widget<Container>(finder.first);
}

BoxDecoration _decoration(Container container) {
  return container.decoration! as BoxDecoration;
}

Border _border(Container container) {
  final foreground = container.foregroundDecoration! as BoxDecoration;
  return foreground.border! as Border;
}
