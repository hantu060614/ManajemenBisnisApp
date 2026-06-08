import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../data/repositories/batch_repository.dart';
import '../../domain/models/batch.dart';
import '../../../feed/data/repositories/feed_repository.dart';
import '../../../health/data/repositories/health_repository.dart';
import '../../../cashflow/data/repositories/cashflow_repository.dart';
import '../../../cashflow/domain/models/cashflow.dart';
import '../../../cashflow/presentation/providers/cashflow_provider.dart';
import 'package:uuid/uuid.dart';
import '../../../feed/presentation/providers/feed_provider.dart';
import '../../../health/presentation/providers/health_provider.dart';
import '../../../../features/dashboard/data/repositories/dashboard_stats_repository.dart';

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
        .orderBy('startDate', descending: true)
        .limit(20)
        .snapshots()
        .map((snapshot) => snapshot.docs.map((doc) => Batch.fromMap(doc.data())).toList());
  }

  Future<void> addBatch(Batch batch) async {
    try {
      await _repository.insertBatch(batch);
      
      if (batch.isActive) {
        final statsRepo = DashboardStatsRepository();
        await statsRepo.updateBatchStats(activeDelta: 1, animalsDelta: batch.currentCount);
      }
      
      if (batch.initialCapital > 0) {
        final cashflowRepo = CashflowRepository();
        final cashflow = Cashflow(
          id: const Uuid().v4(),
          type: 'expense',
          amount: batch.initialCapital,
          category: 'Modal',
          description: 'Modal awal unit ternak: ${batch.name}',
          date: DateTime.now(),
          referenceId: batch.id,
        );
        await cashflowRepo.insertCashflow(cashflow);
      }
    } catch (e) {
      // throw error
    }
  }

  Future<void> updateBatch(Batch batch) async {
    try {
      final oldDocs = await FirebaseFirestore.instance
          .collection('users')
          .doc(FirebaseAuth.instance.currentUser?.uid)
          .collection('batches')
          .doc(batch.id)
          .get();

      if (oldDocs.exists) {
        final oldBatch = Batch.fromMap(oldDocs.data()!);
        
        int activeDelta = 0;
        int animalsDelta = 0;

        if (oldBatch.isActive && !batch.isActive) {
          activeDelta = -1;
          animalsDelta = -oldBatch.currentCount;
        } else if (!oldBatch.isActive && batch.isActive) {
          activeDelta = 1;
          animalsDelta = batch.currentCount;
        } else if (oldBatch.isActive && batch.isActive) {
          animalsDelta = batch.currentCount - oldBatch.currentCount;
        }

        if (activeDelta != 0 || animalsDelta != 0) {
          final statsRepo = DashboardStatsRepository();
          await statsRepo.updateBatchStats(activeDelta: activeDelta, animalsDelta: animalsDelta);
        }
      }

      await _repository.updateBatch(batch);
    } catch (e) {
      // throw error
    }
  }

  Future<void> deleteBatch(String id) async {
    try {
      final oldDocs = await FirebaseFirestore.instance
          .collection('users')
          .doc(FirebaseAuth.instance.currentUser?.uid)
          .collection('batches')
          .doc(id)
          .get();

      if (oldDocs.exists) {
        final oldBatch = Batch.fromMap(oldDocs.data()!);
        if (oldBatch.isActive) {
          final statsRepo = DashboardStatsRepository();
          await statsRepo.updateBatchStats(activeDelta: -1, animalsDelta: -oldBatch.currentCount);
        }
      }

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

      // Cascade delete Cashflows (Modal Awal & Panen)
      final cashflowRepo = CashflowRepository();
      final cashflows = await cashflowRepo.getAllCashflow();

      for (final c in cashflows) {
        if (c.referenceId == id) {
          await ref.read(cashflowProvider.notifier).deleteCashflow(c.id);
        }
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

        if (batch.isActive) {
          final animalsDelta = newCount - batch.currentCount;
          if (animalsDelta != 0) {
            final statsRepo = DashboardStatsRepository();
            await statsRepo.updateBatchStats(activeDelta: 0, animalsDelta: animalsDelta);
          }
        }

        await _repository.updateBatch(updatedBatch);
      }
    } catch (e) {
      // log error
    }
  }

}
