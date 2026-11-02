import 'dart:ui' show Tristate;

import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:my_music_player/shared/widgets/app_icon_button.dart';

import '../../helpers/pump_app.dart';

void main() {
  testWidgets('exposes its semantic label and a >= 48dp touch target',
      (tester) async {
    final semantics = tester.ensureSemantics();
    try {
      await pumpApp(
        tester,
        Scaffold(
          body: Center(
            child: AppIconButton(
              icon: Icons.play_arrow_rounded,
              semanticLabel: 'Play',
              onPressed: () {},
            ),
          ),
        ),
      );

      expect(find.bySemanticsLabel('Play'), findsOneWidget);

      final node = tester.getSemantics(find.bySemanticsLabel('Play'));
      final flags = node.getSemanticsData().flagsCollection;
      expect(flags.isButton, isTrue);
      expect(flags.isEnabled, Tristate.isTrue);
      expect(
        node.getSemanticsData().hasAction(SemanticsAction.tap),
        isTrue,
      );

      final size = tester.getSize(find.byType(AppIconButton));
      expect(size.width, greaterThanOrEqualTo(48));
      expect(size.height, greaterThanOrEqualTo(48));
    } finally {
      semantics.dispose();
    }
  });

  testWidgets('disabled button is announced disabled and ignores taps',
      (tester) async {
    final semantics = tester.ensureSemantics();
    try {
      await pumpApp(
        tester,
        const Scaffold(
          body: Center(
            child: AppIconButton(
              icon: Icons.skip_next_rounded,
              semanticLabel: 'Next track unavailable',
              onPressed: null,
            ),
          ),
        ),
      );

      final node = tester.getSemantics(
        find.bySemanticsLabel('Next track unavailable'),
      );
      final flags = node.getSemanticsData().flagsCollection;
      expect(flags.isButton, isTrue);
      expect(flags.isEnabled, Tristate.isFalse);
      expect(
        node.getSemanticsData().hasAction(SemanticsAction.tap),
        isFalse,
      );
    } finally {
      semantics.dispose();
    }
  });

  testWidgets('tooltip stays optional', (tester) async {
    await pumpApp(
      tester,
      Scaffold(
        body: Center(
          child: AppIconButton(
            icon: Icons.shuffle_rounded,
            semanticLabel: 'Shuffle',
            onPressed: () {},
          ),
        ),
      ),
    );

    expect(find.byType(Tooltip), findsNothing);
  });

  testWidgets('tooltip is rendered when provided', (tester) async {
    await pumpApp(
      tester,
      Scaffold(
        body: Center(
          child: AppIconButton(
            icon: Icons.shuffle_rounded,
            semanticLabel: 'Shuffle',
            tooltip: 'Shuffle queue',
            onPressed: () {},
          ),
        ),
      ),
    );

    expect(find.byType(Tooltip), findsOneWidget);
    expect(find.byTooltip('Shuffle queue'), findsOneWidget);
  });
}
