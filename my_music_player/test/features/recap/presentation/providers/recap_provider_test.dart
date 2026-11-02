import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:my_music_player/features/recap/data/repositories/recap_repository.dart';
import 'package:my_music_player/features/recap/domain/entities/recap.dart';
import 'package:my_music_player/features/recap/presentation/providers/recap_provider.dart';

class _MockRecapRepository extends Mock implements RecapRepository {}

void main() {
  late _MockRecapRepository repo;

  setUp(() {
    repo = _MockRecapRepository();
    when(() => repo.getRecap(2026, month: any(named: 'month')))
        .thenAnswer((_) async => Recap.empty(2026));
  });

  test('passes the selected month to the repository', () async {
    final container = ProviderContainer(
      overrides: [recapRepositoryProvider.overrideWithValue(repo)],
    );
    addTearDown(container.dispose);

    await container.read(recapProvider((year: 2026, month: 10)).future);

    verify(() => repo.getRecap(2026, month: 10)).called(1);
  });

  test('passes null month for a yearly recap', () async {
    final container = ProviderContainer(
      overrides: [recapRepositoryProvider.overrideWithValue(repo)],
    );
    addTearDown(container.dispose);

    await container.read(recapProvider((year: 2026, month: null)).future);

    verify(() => repo.getRecap(2026, month: null)).called(1);
  });
}
