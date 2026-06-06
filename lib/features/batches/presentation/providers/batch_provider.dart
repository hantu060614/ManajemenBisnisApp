import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../data/repositories/batch_repository.dart';
import '../../domain/models/batch.dart';
import '../../domain/models/daily_log.dart';

final batchRepositoryProvider = Provider<BatchRepository>((ref) {
  return BatchRepository();
});

final batchProvider = AsyncNotifierProvider<BatchNotifier, List<Batch>>(() {
  return BatchNotifier();
});

final dailyLogsProvider = FutureProvider.family<List<DailyLog>, String>((ref, batchId) async {
  final authState = ref.watch(authProvider);
  if (!authState.isAuthenticated || authState.userId == null) {
    return [];
  }
  final repository = ref.watch(batchRepositoryProvider);
  return repository.getDailyLogs(batchId);
});

final allDailyLogsProvider = FutureProvider<List<DailyLog>>((ref) async {
  final batchesAsync = ref.watch(batchProvider);
  final batches = batchesAsync.value ?? [];
  final repository = ref.read(batchRepositoryProvider);
  
  final List<DailyLog> allLogs = [];
  for (final batch in batches) {
    final logs = await repository.getDailyLogs(batch.id);
    allLogs.addAll(logs);
  }
  allLogs.sort((a, b) => b.logDate.compareTo(a.logDate));
  return allLogs;
});

class BatchNotifier extends AsyncNotifier<List<Batch>> {
  BatchRepository get _repository => ref.read(batchRepositoryProvider);

  @override
  Future<List<Batch>> build() async {
    final authState = ref.watch(authProvider);
    if (!authState.isAuthenticated || authState.userId == null) {
      return [];
    }
    return _repository.getAllBatches();
  }

  Future<void> addBatch(Batch batch) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      await _repository.insertBatch(batch);
      return _repository.getAllBatches();
    });
  }

  Future<void> updateBatch(Batch batch) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      await _repository.updateBatch(batch);
      return _repository.getAllBatches();
    });
  }

  Future<void> deleteBatch(String id) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      await _repository.deleteBatch(id);
      return _repository.getAllBatches();
    });
  }

  Future<void> addDailyLog(DailyLog log, Batch batch) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      await _repository.insertDailyLog(log);
      
      // Kurangi jumlah ternak jika ada yang mati
      if (log.mortalityCount > 0) {
        final newCount = batch.currentCount - log.mortalityCount;
        final updatedBatch = Batch(
          id: batch.id,
          name: batch.name,
          animalCategory: batch.animalCategory,
          animalType: batch.animalType,
          initialCount: batch.initialCount,
          currentCount: newCount < 0 ? 0 : newCount,
          startDate: batch.startDate,
          initialCapital: batch.initialCapital,
          isActive: batch.isActive,
          synced: batch.synced,
        );
        await _repository.updateBatch(updatedBatch);
      }
      return _repository.getAllBatches();
    });
  }

  Future<void> deleteDailyLog(String batchId, String logId) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      await _repository.deleteDailyLog(batchId, logId);
      return _repository.getAllBatches();
    });
  }
}
