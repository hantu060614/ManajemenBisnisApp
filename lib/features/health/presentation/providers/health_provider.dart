import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../data/repositories/health_repository.dart';
import '../../domain/models/health_log.dart';
import '../../../batches/presentation/providers/batch_provider.dart';
import '../../../auth/presentation/providers/auth_provider.dart';

final healthRepositoryProvider = Provider<HealthRepository>((ref) {
  return HealthRepository();
});

final healthProvider = StreamNotifierProvider<HealthNotifier, List<HealthLog>>(() {
  return HealthNotifier();
});

class HealthNotifier extends StreamNotifier<List<HealthLog>> {
  HealthRepository get _repository => ref.read(healthRepositoryProvider);

  @override
  Stream<List<HealthLog>> build() {
    final authState = ref.watch(authProvider);
    if (authState.userId == null) return Stream.value([]);
    
    return FirebaseFirestore.instance
        .collection('users')
        .doc(authState.userId)
        .collection('health_logs')
        .orderBy('date', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs.map((doc) => HealthLog.fromMap(doc.data())).toList());
  }

  Future<void> addHealthLog(HealthLog log) async {
    try {
      await _repository.insertHealthLog(log);
      if (log.type.toLowerCase() == 'kematian' && log.amount > 0) {
        await ref.read(batchProvider.notifier).recalculateBatchPopulation(log.batchId);
      }
    } catch (e) {
      // log error
    }
  }

  Future<void> updateHealthLog(HealthLog log) async {
    try {
      await _repository.updateHealthLog(log);
      if (log.type.toLowerCase() == 'kematian') {
        await ref.read(batchProvider.notifier).recalculateBatchPopulation(log.batchId);
      }
    } catch (e) {
      // log error
    }
  }

  Future<void> deleteHealthLog(HealthLog log) async {
    try {
      await _repository.deleteHealthLog(log);
      if (log.type.toLowerCase() == 'kematian' && log.amount > 0) {
        await ref.read(batchProvider.notifier).recalculateBatchPopulation(log.batchId);
      }
    } catch (e) {
      // log error
    }
  }
}

// Selector for daily vaccination/medicine task checks
final todayHealthLogsProvider = Provider<List<HealthLog>>((ref) {
  final logsAsync = ref.watch(healthProvider);
  final logs = logsAsync.value ?? [];
  final now = DateTime.now();
  final todayStart = DateTime(now.year, now.month, now.day);
  
  return logs.where((log) {
    final logDate = DateTime(log.date.year, log.date.month, log.date.day);
    return logDate.isAtSameMomentAs(todayStart);
  }).toList();
});
