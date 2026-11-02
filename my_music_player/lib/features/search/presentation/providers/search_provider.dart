import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:isar/isar.dart';
import '../../../../core/network/api_service.dart';
import '../../../../core/providers/isar_provider.dart';
import '../../../player/domain/entities/track.dart';
import '../../data/models/search_history_model.dart';

final searchQueryProvider = StateProvider<String>((ref) => '');
final searchFilterProvider = StateProvider<String>((ref) => 'top');

final searchLimitProvider = StateProvider<int>((ref) => 20);

List<dynamic> _previousResults = [];
String _previousQuery = '';
String _previousFilter = '';

final searchResultsProvider = FutureProvider.autoDispose<List<dynamic>>((ref) async {
  final query = ref.watch(searchQueryProvider);
  final filter = ref.watch(searchFilterProvider);
  final limit = ref.watch(searchLimitProvider);
  
  if (query.trim().isEmpty) {
    return [];
  }
  
  // Save to history when a search is executed
  ref.read(searchHistoryControllerProvider).addHistory(query.trim());
  
  final apiService = ref.read(apiServiceProvider);
  final isSameSearch = query == _previousQuery && filter == _previousFilter;
  
  List<dynamic> newResults;
  if (filter == 'songs') {
    newResults = await apiService.search(query, limit: limit);
  } else {
    newResults = await apiService.searchArtistsOrAlbums(query, filter, limit: limit);
  }
  
  if (isSameSearch && _previousResults.isNotEmpty && limit > 20) {
    // Merge to preserve order
    final Set<String> existingIds = {};
    for (var item in _previousResults) {
      if (item is Track) {
        existingIds.add(item.sourceId);
      } else if (item is Map) {
        final id = item['browse_id'] ?? item['source_id'];
        if (id != null) existingIds.add(id);
      }
    }
    
    final List<dynamic> merged = List.from(_previousResults);
    for (var item in newResults) {
      String? id;
      if (item is Track) {
        id = item.sourceId;
      } else if (item is Map) {
        id = item['browse_id'] ?? item['source_id'];
      }
      
      if (id != null && !existingIds.contains(id)) {
        merged.add(item);
        existingIds.add(id);
      }
    }
    _previousResults = merged;
    return merged;
  } else {
    _previousQuery = query;
    _previousFilter = filter;
    _previousResults = newResults;
    return newResults;
  }
});

final searchHistoryProvider = StreamProvider.autoDispose<List<SearchHistoryModel>>((ref) {
  final isar = ref.watch(isarProvider);
  return isar.searchHistoryModels.where().sortByTimestampDesc().watch(fireImmediately: true);
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
        final oldest = await _isar.searchHistoryModels.where().sortByTimestamp().findAll();
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
