import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/entities/recap.dart';
import '../../data/repositories/recap_repository.dart';

final recapProvider = FutureProvider.family<Recap, int>((ref, year) async {
  final repo = ref.read(recapRepositoryProvider);
  return repo.getRecap(year);
});

final recapYearsProvider = FutureProvider<List<int>>((ref) async {
  final repo = ref.read(recapRepositoryProvider);
  return repo.getAvailableYears();
});

final selectedRecapYearProvider = StateProvider<int>((ref) => DateTime.now().year);
