import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../data/repositories/batch_repository.dart';
import '../../domain/models/batch.dart';
import '../../../feed/data/repositories/feed_repository.dart';
import '../../../health/data/repositories/health_repository.dart';
import '../../../cashflow/data/repositories/cashflow_repository.dart';
import '../../../cashflow/domain/models/cashflow.dart';
import 'package:uuid/uuid.dart';
import '../../../feed/presentation/providers/feed_provider.dart';
import '../../../health/presentation/providers/health_provider.dart';

final batchRepositoryProvider = Provider<BatchRepository>((ref) {
  return BatchRepository();
});

final batchProvider = StreamNotifierProvider<BatchNotifier, List<Batch>>(() {
  return BatchNotifier();
});

class BatchNotifier extends StreamNotifier<List<Batch>> {
  BatchRepository get _repository => ref.read(batchRepositoryProvider);

  @override
  Stream<List<Batch>> build() {
    final authState = ref.watch(authProvider);
    if (!authState.isAuthenticated || authState.userId == null) {
      return Stream.value([]);
    }
    
    return FirebaseFirestore.instance
        .collection('users')
        .doc(authState.userId)
        .collection('batches')
        .snapshots()
        .map((snapshot) => snapshot.docs.map((doc) => Batch.fromMap(doc.data())).toList());
  }

  Future<void> addBatch(Batch batch) async {
    try {
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
    } catch (e) {
      // throw error
    }
  }

  Future<void> updateBatch(Batch batch) async {
    try {
      await _repository.updateBatch(batch);
    } catch (e) {
      // throw error
    }
  }

  Future<void> deleteBatch(String id) async {
    try {
      await _repository.deleteBatch(id);
      
      // Cascade delete Feed Logs
      final feedRepo = FeedRepository();
      final feedLogs = await feedRepo.getAllFeedLogs();
      for (final log in feedLogs.where((l) => l.batchId == id)) {
        await ref.read(feedProvider.notifier).deleteFeedLog(log);
      }

      // Cascade delete Health Logs
      final healthRepo = HealthRepository();
      final healthLogs = await healthRepo.getAllHealthLogs();
      for (final log in healthLogs.where((l) => l.batchId == id)) {
        await ref.read(healthProvider.notifier).deleteHealthLog(log);
      }
    } catch (e) {
      // throw error
    }
  }

  Future<void> recalculateBatchPopulation(String batchId) async {
    try {
      final batches = await _repository.getAllBatches();
      final batchIndex = batches.indexWhere((b) => b.id == batchId);
      if (batchIndex == -1) return;
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
    } catch (e) {
      // log error
    }
  }

}
