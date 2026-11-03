import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:my_music_player/core/constants/enums.dart' show TrackSource;
import 'package:my_music_player/features/player/domain/entities/track.dart';
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
    Recap? recap,
    Locale locale = const Locale('id'),
  }) async {
    lastQuery = null;
    await pumpApp(
      tester,
      const RecapScreen(),
      locale: locale,
      overrides: [
        selectedRecapPeriodProvider.overrideWith((ref) => period),
        selectedRecapYearProvider.overrideWith((ref) => 2026),
        selectedRecapMonthProvider.overrideWith((ref) => month),
        recapProvider.overrideWith((ref, query) async {
          lastQuery = query;
          return recap ?? Recap.empty(query.year);
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

  testWidgets('empty copy follows the app locale', (tester) async {
    await pumpRecap(tester, locale: const Locale('en'));

    expect(find.text('Recap'), findsOneWidget);
    expect(find.text('No recap for 2026'), findsOneWidget);
    expect(find.text('Month'), findsOneWidget);

    await pumpRecap(tester, locale: const Locale('id'));

    expect(find.text('Rekap'), findsOneWidget);
    expect(find.text('Belum ada rekap 2026'), findsOneWidget);
    expect(find.text('Bulan'), findsOneWidget);
  });

  testWidgets('stats, badge and play counts follow the app locale',
      (tester) async {
    const track = Track(
      sourceId: 'recap-track',
      title: 'Blinding Lights',
      artist: 'The Weeknd',
      durationMs: 200000,
      source: TrackSource.youtube,
    );
    const recap = Recap(
      year: 2026,
      mostPlayed: track,
      mostPlayedCount: 9,
      topSongs: [],
      topSongCounts: [],
      topArtists: [],
      topAlbums: [],
      totalPlays: 45,
      totalTracks: 12,
    );

    await pumpRecap(tester, recap: recap, locale: const Locale('en'));

    expect(find.text('Total plays'), findsOneWidget);
    expect(find.text('Unique songs'), findsOneWidget);
    expect(find.text('#1 MOST PLAYED 2026'), findsOneWidget);
    expect(find.text('9× played'), findsWidgets);

    await pumpRecap(tester, recap: recap, locale: const Locale('id'));

    expect(find.text('Total Putar'), findsOneWidget);
    expect(find.text('Lagu Unik'), findsOneWidget);
    expect(find.text('#1 PALING SERING 2026'), findsOneWidget);
    expect(find.text('9× diputar'), findsWidgets);
  });
}
