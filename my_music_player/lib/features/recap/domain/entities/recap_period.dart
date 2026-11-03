/// Granularity of a listening recap.
enum RecapPeriod { month, year }

/// Half-open date interval `[start, end)` used to filter play history.
///
/// Pure Dart helper: no Isar or Flutter dependency. `end` is exclusive, so a
/// play at `2026-02-01 00:00` belongs to February, not January.
class RecapPeriodRange {
  const RecapPeriodRange._({required this.start, required this.end});

  final DateTime start;
  final DateTime end;

  /// `[January 1 of [year], January 1 of [year] + 1)`.
  factory RecapPeriodRange.year(int year) {
    return RecapPeriodRange._(
      start: DateTime(year),
      end: DateTime(year + 1),
    );
  }

  /// `[first day of [month], first day of the next month)`.
  ///
  /// December rolls over to January of `year + 1`; February follows the
  /// calendar (leap years include February 29).
  factory RecapPeriodRange.month(int year, int month) {
    if (month < 1 || month > 12) {
      throw ArgumentError.value(
        month,
        'month',
        'Month must be between 1 and 12',
      );
    }
    return RecapPeriodRange._(
      start: DateTime(year, month),
      end: DateTime(year, month + 1),
    );
  }

  /// Resolves a [period] into a range. Month scope requires [month].
  factory RecapPeriodRange.of({
    required RecapPeriod period,
    required int year,
    int? month,
  }) {
    switch (period) {
      case RecapPeriod.year:
        return RecapPeriodRange.year(year);
      case RecapPeriod.month:
        if (month == null) {
          throw ArgumentError.notNull('month');
        }
        return RecapPeriodRange.month(year, month);
    }
  }

  /// Whether [instant] falls inside `[start, end)`.
  bool contains(DateTime instant) {
    return !instant.isBefore(start) && instant.isBefore(end);
  }
}
