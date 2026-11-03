import 'package:flutter_test/flutter_test.dart';
import 'package:my_music_player/features/recap/domain/entities/recap_period.dart';

void main() {
  group('RecapPeriodRange.year', () {
    test('covers a half-open January-to-January range', () {
      final range = RecapPeriodRange.year(2026);

      expect(range.start, DateTime(2026, 1, 1));
      expect(range.end, DateTime(2027, 1, 1));
      expect(range.contains(DateTime(2026, 1, 1)), isTrue);
      expect(range.contains(DateTime(2026, 12, 31, 23, 59, 59)), isTrue);
      expect(range.contains(DateTime(2025, 12, 31, 23, 59, 59)), isFalse);
      expect(range.contains(DateTime(2027, 1, 1)), isFalse);
    });
  });

  group('RecapPeriodRange.month', () {
    test('31 January belongs to January, 1 February to February', () {
      final january = RecapPeriodRange.month(2026, 1);
      final february = RecapPeriodRange.month(2026, 2);

      expect(january.start, DateTime(2026, 1, 1));
      expect(january.end, DateTime(2026, 2, 1));
      expect(january.contains(DateTime(2026, 1, 31, 23, 59, 59)), isTrue);
      expect(january.contains(DateTime(2026, 2, 1)), isFalse);

      expect(february.start, DateTime(2026, 2, 1));
      expect(february.contains(DateTime(2026, 2, 1)), isTrue);
    });

    test('December rolls into January of the next year', () {
      final december = RecapPeriodRange.month(2026, 12);

      expect(december.start, DateTime(2026, 12, 1));
      expect(december.end, DateTime(2027, 1, 1));
      expect(december.contains(DateTime(2026, 12, 31, 23, 59, 59)), isTrue);
      expect(december.contains(DateTime(2027, 1, 1)), isFalse);
    });

    test('February includes the leap day in a leap year', () {
      final leapFebruary = RecapPeriodRange.month(2024, 2);
      final normalFebruary = RecapPeriodRange.month(2026, 2);

      expect(leapFebruary.start, DateTime(2024, 2, 1));
      expect(leapFebruary.end, DateTime(2024, 3, 1));
      expect(
        leapFebruary.contains(DateTime(2024, 2, 29, 23, 59, 59)),
        isTrue,
      );
      expect(leapFebruary.contains(DateTime(2024, 3, 1)), isFalse);

      expect(normalFebruary.end, DateTime(2026, 3, 1));
      expect(
        normalFebruary.contains(DateTime(2026, 2, 28, 23, 59, 59)),
        isTrue,
      );
      expect(normalFebruary.contains(DateTime(2026, 3, 1)), isFalse);
    });

    test('rejects a month outside 1..12', () {
      expect(() => RecapPeriodRange.month(2026, 0), throwsArgumentError);
      expect(() => RecapPeriodRange.month(2026, 13), throwsArgumentError);
    });
  });

  group('RecapPeriodRange.of', () {
    test('year scope ignores the month argument', () {
      final range = RecapPeriodRange.of(
        period: RecapPeriod.year,
        year: 2026,
        month: 10,
      );

      expect(range.start, DateTime(2026, 1, 1));
      expect(range.end, DateTime(2027, 1, 1));
    });

    test('month scope requires and uses the month argument', () {
      expect(
        () => RecapPeriodRange.of(period: RecapPeriod.month, year: 2026),
        throwsArgumentError,
      );

      final range = RecapPeriodRange.of(
        period: RecapPeriod.month,
        year: 2026,
        month: 10,
      );

      expect(range.start, DateTime(2026, 10, 1));
      expect(range.end, DateTime(2026, 11, 1));
    });
  });
}
