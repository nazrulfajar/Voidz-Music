import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/entities/recap.dart';
import '../../domain/entities/recap_period.dart';
import '../../data/repositories/recap_repository.dart';

/// Cache key for a recap. `month == null` means the yearly recap.
typedef RecapQuery = ({int year, int? month});

final recapProvider = FutureProvider.family<Recap, RecapQuery>(
  (ref, query) async {
    final repo = ref.read(recapRepositoryProvider);
    return repo.getRecap(query.year, month: query.month);
  },
);

final recapYearsProvider = FutureProvider<List<int>>((ref) async {
  final repo = ref.read(recapRepositoryProvider);
  return repo.getAvailableYears();
});

final selectedRecapPeriodProvider = StateProvider<RecapPeriod>(
  (ref) => RecapPeriod.year,
);

final selectedRecapYearProvider = StateProvider<int>(
  (ref) => DateTime.now().year,
);

final selectedRecapMonthProvider = StateProvider<int>(
  (ref) => DateTime.now().month,
);
