import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/repositories/batch_repository.dart';
import '../../domain/models/batch.dart';
import '../../domain/models/daily_log.dart';

final batchRepositoryProvider = Provider<BatchRepository>((ref) {
  return BatchRepository();
});

final batchProvider = AsyncNotifierProvider<BatchNotifier, List<Batch>>(() {
  return BatchNotifier();
});

class BatchNotifier extends AsyncNotifier<List<Batch>> {
  late final BatchRepository _repository;

  @override
  Future<List<Batch>> build() async {
    _repository = ref.watch(batchRepositoryProvider);
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
          isActive: batch.isActive,
          synced: batch.synced,
        );
        await _repository.updateBatch(updatedBatch);
      }
      return _repository.getAllBatches();
    });
  }
}
