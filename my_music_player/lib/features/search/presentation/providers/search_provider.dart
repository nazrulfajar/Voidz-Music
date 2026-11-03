import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:isar/isar.dart';
import '../../../../core/network/api_service.dart';
import '../../../../core/providers/isar_provider.dart';
import '../../data/models/search_history_model.dart';

final searchQueryProvider = StateProvider<String>((ref) => '');
final searchFilterProvider = StateProvider<String>((ref) => 'top');

final searchLimitProvider = StateProvider<int>((ref) => 20);

/// One explicit search state. The screen maps each variant to exactly one
/// surface, so idle, loading, empty, error, and data cannot be confused.
sealed class SearchState {
  const SearchState();
}

final class SearchIdle extends SearchState {
  const SearchIdle();
}

final class SearchLoading extends SearchState {
  const SearchLoading();
}

final class SearchEmpty extends SearchState {
  const SearchEmpty({required this.query});

  final String query;
}

final class SearchError extends SearchState {
  const SearchError({required this.query, required this.error});

  final String query;
  final Object error;
}

final class SearchData extends SearchState {
  const SearchData(this.items, {this.isLoadingMore = false});

  final List<dynamic> items;

  /// True while the current result set is loading an extra page.
  final bool isLoadingMore;
}

final searchResultsProvider =
    FutureProvider.autoDispose<List<dynamic>>((ref) async {
  final query = ref.watch(searchQueryProvider).trim();
  final filter = ref.watch(searchFilterProvider);
  final limit = ref.watch(searchLimitProvider);

  if (query.isEmpty) {
    return const <dynamic>[];
  }

  // Save to history when a search is executed.
  ref.read(searchHistoryControllerProvider).addHistory(query);

  final apiService = ref.read(apiServiceProvider);
  if (filter == 'songs') {
    return apiService.search(query, limit: limit);
  }
  return apiService.searchArtistsOrAlbums(query, filter, limit: limit);
});

final searchStateProvider = Provider.autoDispose<SearchState>((ref) {
  final query = ref.watch(searchQueryProvider).trim();
  if (query.isEmpty) {
    return const SearchIdle();
  }

  final results = ref.watch(searchResultsProvider);
  final limit = ref.watch(searchLimitProvider);
  if (results.isLoading) {
    final previous = results.valueOrNull;
    if (limit > 20 && previous != null && previous.isNotEmpty) {
      return SearchData(previous, isLoadingMore: true);
    }
    return const SearchLoading();
  }
  if (results.hasError) {
    return SearchError(query: query, error: results.error!);
  }

  final items = results.valueOrNull ?? const <dynamic>[];
  if (items.isEmpty) {
    return SearchEmpty(query: query);
  }
  return SearchData(items);
});

final searchHistoryProvider =
    StreamProvider.autoDispose<List<SearchHistoryModel>>((ref) {
  final isar = ref.watch(isarProvider);
  return isar.searchHistoryModels
      .where()
      .sortByTimestampDesc()
      .watch(fireImmediately: true);
});

final searchHistoryControllerProvider = Provider.autoDispose((ref) {
  return SearchHistoryController(ref.watch(isarProvider));
});

class SearchHistoryController {
  final Isar _isar;
  SearchHistoryController(this._isar);

  Future<void> addHistory(String query) async {
    if (query.isEmpty) return;

    await _isar.writeTxn(() async {
      // Create new history
      final newHistory = SearchHistoryModel()
        ..query = query
        ..timestamp = DateTime.now();

      // Put (replace if exists due to unique index)
      await _isar.searchHistoryModels.put(newHistory);

      // Keep only top 10
      final allCount = await _isar.searchHistoryModels.count();
      if (allCount > 10) {
        final oldest =
            await _isar.searchHistoryModels.where().sortByTimestamp().findAll();
        final toDelete = oldest.take(allCount - 10).map((e) => e.id).toList();
        await _isar.searchHistoryModels.deleteAll(toDelete);
      }
    });
  }

  Future<void> deleteHistory(int id) async {
    await _isar.writeTxn(() async {
      await _isar.searchHistoryModels.delete(id);
    });
  }

  Future<void> clearHistory() async {
    await _isar.writeTxn(() async {
      await _isar.searchHistoryModels.clear();
    });
  }
}
