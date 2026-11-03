import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/entities/recap.dart';
import '../../domain/entities/recap_period.dart';
import '../../data/repositories/recap_repository.dart';

/// Cache key for a recap. `month == null` means the yearly recap.
typedef RecapQuery = ({int year, int? month});

/// Computes a monthly or yearly recap for the given [RecapQuery].
final recapProvider = FutureProvider.autoDispose.family<Recap, RecapQuery>(
  (ref, query) async {
    final repo = ref.read(recapRepositoryProvider);
    return repo.getRecap(query.year, month: query.month);
  },
);

/// Available years that have play history, newest first.
final recapYearsProvider = FutureProvider.autoDispose<List<int>>((ref) async {
  final repo = ref.read(recapRepositoryProvider);
  return repo.getAvailableYears();
});

/// Selected recap granularity (month or year).
final selectedRecapPeriodProvider =
    StateProvider.autoDispose<RecapPeriod>((ref) => RecapPeriod.year);

/// Selected recap year.
final selectedRecapYearProvider =
    StateProvider.autoDispose<int>((ref) => DateTime.now().year);

/// Selected month (1..12) used when [RecapPeriod.month] is active.
final selectedRecapMonthProvider =
    StateProvider.autoDispose<int>((ref) => DateTime.now().month);
