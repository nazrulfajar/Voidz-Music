import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:my_music_player/features/recap/domain/entities/recap.dart';
import 'package:my_music_player/features/recap/domain/entities/recap_period.dart';
import 'package:my_music_player/features/recap/presentation/providers/recap_provider.dart';
import 'package:my_music_player/features/recap/presentation/screens/recap_screen.dart';

import '../../../../helpers/pump_app.dart';

void main() {
  late RecapQuery? lastQuery;

  Future<void> pumpRecap(
    WidgetTester tester, {
    RecapPeriod period = RecapPeriod.year,
    int month = 10,
  }) async {
    lastQuery = null;
    await pumpApp(
      tester,
      const RecapScreen(),
      overrides: [
        selectedRecapPeriodProvider.overrideWith((ref) => period),
        selectedRecapYearProvider.overrideWith((ref) => 2026),
        selectedRecapMonthProvider.overrideWith((ref) => month),
        recapProvider.overrideWith((ref, query) async {
          lastQuery = query;
          return Recap.empty(query.year);
        }),
        recapYearsProvider.overrideWith((ref) async => [2026, 2025]),
      ],
    );
    await tester.pumpAndSettle();
  }

  testWidgets('defaults to a yearly recap label', (tester) async {
    await pumpRecap(tester);

    expect(find.text('Belum ada rekap 2026'), findsOneWidget);
    expect(find.text('2026'), findsWidgets);
    expect(lastQuery?.month, isNull);
  });

  testWidgets('switching to month sends the month and shows its label',
      (tester) async {
    await pumpRecap(tester);
    expect(find.text('Oktober 2026'), findsNothing);

    await tester.tap(find.text('Bulan'));
    await tester.pumpAndSettle();

    expect(find.text('Oktober 2026'), findsOneWidget);
    expect(find.text('Belum ada rekap Oktober 2026'), findsOneWidget);
    expect(lastQuery?.month, 10);
  });

  testWidgets('year mode shows one dropdown, month mode shows two',
      (tester) async {
    await pumpRecap(tester);
    expect(find.byType(DropdownButton<int>), findsOneWidget);

    await tester.tap(find.text('Bulan'));
    await tester.pumpAndSettle();

    expect(find.byType(DropdownButton<int>), findsNWidgets(2));
  });

  testWidgets('out-of-range month is clamped instead of throwing',
      (tester) async {
    await pumpRecap(tester, period: RecapPeriod.month, month: 13);

    expect(tester.takeException(), isNull);
    expect(find.text('Desember 2026'), findsOneWidget);
    expect(lastQuery?.month, 12);
  });
}
