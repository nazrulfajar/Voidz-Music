import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:my_music_player/core/theme/app_colors.dart';
import 'package:my_music_player/shared/widgets/app_empty_state.dart';

import '../../helpers/pump_app.dart';

void main() {
  testWidgets('keeps the legacy action widget working', (tester) async {
    var tapped = false;
    await pumpApp(
      tester,
      Scaffold(
        body: AppEmptyState(
          icon: Icons.folder_open_rounded,
          title: 'No songs yet',
          subtitle: 'Import songs to get started',
          action: TextButton(
            onPressed: () => tapped = true,
            child: const Text('Import'),
          ),
        ),
      ),
    );

    expect(find.text('No songs yet'), findsOneWidget);
    expect(find.text('Import songs to get started'), findsOneWidget);
    expect(find.text('Import'), findsOneWidget);

    await tester.tap(find.text('Import'));
    expect(tapped, isTrue);
  });

  testWidgets('renders primary and secondary actions', (tester) async {
    var primaryTaps = 0;
    var secondaryTaps = 0;
    await pumpApp(
      tester,
      Scaffold(
        body: AppEmptyState(
          icon: Icons.search_off_rounded,
          title: 'Nothing here',
          subtitle: 'Try another filter',
          actionLabel: 'Retry',
          onAction: () => primaryTaps++,
          secondaryLabel: 'Clear filters',
          onSecondaryAction: () => secondaryTaps++,
        ),
      ),
    );

    expect(find.widgetWithText(FilledButton, 'Retry'), findsOneWidget);
    expect(find.widgetWithText(TextButton, 'Clear filters'), findsOneWidget);

    await tester.tap(find.text('Retry'));
    await tester.tap(find.text('Clear filters'));
    expect(primaryTaps, 1);
    expect(secondaryTaps, 1);
  });

  testWidgets('uses theme tokens in light mode', (tester) async {
    await pumpApp(
      tester,
      const Scaffold(
        body: AppEmptyState(icon: Icons.inbox_rounded, title: 'Empty'),
      ),
      themeMode: ThemeMode.light,
    );

    final title = tester.widget<Text>(find.text('Empty'));
    expect(title.style?.color, AppColors.light.textPrimary);
  });
}
