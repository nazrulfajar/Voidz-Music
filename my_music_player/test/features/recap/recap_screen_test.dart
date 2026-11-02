import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:my_music_player/core/theme/app_theme.dart';
import 'package:my_music_player/features/recap/domain/entities/recap.dart';
import 'package:my_music_player/features/recap/domain/entities/recap_period.dart';
import 'package:my_music_player/features/recap/presentation/providers/recap_provider.dart';
import 'package:my_music_player/features/recap/presentation/screens/recap_screen.dart';

void main() {
  Future<void> pumpRecap(WidgetTester tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          selectedRecapPeriodProvider.overrideWith((ref) => RecapPeriod.year),
          selectedRecapYearProvider.overrideWith((ref) => 2026),
          selectedRecapMonthProvider.overrideWith((ref) => 10),
          recapProvider.overrideWith(
            (ref, query) async => Recap.empty(query.year),
          ),
          recapYearsProvider.overrideWith((ref) async => [2026, 2025]),
        ],
        child: MaterialApp(
          theme: AppTheme.darkTheme,
          home: const RecapScreen(),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('defaults to a yearly recap label', (tester) async {
    await pumpRecap(tester);

    expect(find.text('Belum ada rekap 2026'), findsOneWidget);
    expect(find.text('2026'), findsWidgets);
  });

  testWidgets('switching to month shows the month and year label',
      (tester) async {
    await pumpRecap(tester);
    expect(find.text('Oktober 2026'), findsNothing);

    await tester.tap(find.text('Bulan'));
    await tester.pumpAndSettle();

    expect(find.text('Oktober 2026'), findsOneWidget);
    expect(find.text('Belum ada rekap Oktober 2026'), findsOneWidget);
  });
}
