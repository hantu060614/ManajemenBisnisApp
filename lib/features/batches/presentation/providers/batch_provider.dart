import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../data/repositories/batch_repository.dart';
import '../../domain/models/batch.dart';
import '../../../feed/data/repositories/feed_repository.dart';
import '../../../health/data/repositories/health_repository.dart';
import '../../../cashflow/data/repositories/cashflow_repository.dart';
import '../../../cashflow/domain/models/cashflow.dart';
import 'package:uuid/uuid.dart';

final batchRepositoryProvider = Provider<BatchRepository>((ref) {
  return BatchRepository();
});

final batchProvider = AsyncNotifierProvider<BatchNotifier, List<Batch>>(() {
  return BatchNotifier();
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
      
      if (batch.initialCapital > 0) {
        final cashflowRepo = CashflowRepository();
        final cashflow = Cashflow(
          id: const Uuid().v4(),
          type: 'expense',
          amount: batch.initialCapital,
          category: 'Modal',
          description: 'Modal awal unit ternak: ${batch.name}',
          date: DateTime.now(),
        );
        await cashflowRepo.insertCashflow(cashflow);
      }

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

  Future<void> recalculateBatchPopulation(String batchId) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      final batches = await _repository.getAllBatches();
      final batchIndex = batches.indexWhere((b) => b.id == batchId);
      if (batchIndex == -1) return batches;
      final batch = batches[batchIndex];

      final feedRepo = FeedRepository();
      final healthRepo = HealthRepository();
      
      final feedLogs = await feedRepo.getAllFeedLogs();
      final healthLogs = await healthRepo.getAllHealthLogs();

      int totalKematian = 0;
      for (final log in feedLogs.where((l) => l.batchId == batchId)) {
        totalKematian += log.mortalityCount;
      }
      for (final log in healthLogs.where((l) => l.batchId == batchId && l.type.toLowerCase() == 'kematian')) {
        totalKematian += log.amount;
      }

      int newCount = batch.initialCount - totalKematian;
      if (newCount < 0) newCount = 0;

      if (batch.currentCount != newCount) {
        final updatedBatch = Batch(
          id: batch.id,
          name: batch.name,
          animalCategory: batch.animalCategory,
          animalType: batch.animalType,
          initialCount: batch.initialCount,
          currentCount: newCount,
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

}
