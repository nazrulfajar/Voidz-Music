import 'package:isar/isar.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/providers/isar_provider.dart';
import '../models/queue_state_model.dart';
import '../models/queue_item_model.dart';

final queueRepositoryProvider = Provider<QueueRepository>((ref) {
  final isar = ref.watch(isarProvider);
  return QueueRepository(isar);
});

class QueueRepository {
  final Isar? _isar;
  QueueRepository(this._isar);

  /// Atomic replace — clear + putAll dalam satu writeTxn (crash-safe)
  Future<void> replaceQueue({
    required List<QueueItemModel> items,
    required QueueStateModel state,
  }) async {
    final isar = _isar;
    if (isar == null) return;
    await isar.writeTxn(() async {
      await isar.queueItemModels.clear();
      if (items.isNotEmpty) await isar.queueItemModels.putAll(items);
      await isar.queueStateModels.put(state);
    });
  }

  Future<QueueStateModel?> getState() async {
    final isar = _isar;
    if (isar == null) return null;
    return isar.queueStateModels.get(1);
  }

  Future<List<QueueItemModel>> getItems() async {
    final isar = _isar;
    if (isar == null) return [];
    return isar.queueItemModels.where().findAll();
  }

  Future<void> clear() async {
    final isar = _isar;
    if (isar == null) return;
    await isar.writeTxn(() async {
      await isar.queueItemModels.clear();
      await isar.queueStateModels.delete(1);
    });
  }
}
