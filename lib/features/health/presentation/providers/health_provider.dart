import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/repositories/health_repository.dart';
import '../../domain/models/health_log.dart';
import '../../../batches/presentation/providers/batch_provider.dart';

final healthRepositoryProvider = Provider<HealthRepository>((ref) {
  return HealthRepository();
});

final healthProvider = AsyncNotifierProvider<HealthNotifier, List<HealthLog>>(() {
  return HealthNotifier();
});

class HealthNotifier extends AsyncNotifier<List<HealthLog>> {
  HealthRepository get _repository => ref.read(healthRepositoryProvider);

  @override
  Future<List<HealthLog>> build() async {
    return _repository.getAllHealthLogs();
  }

  Future<void> addHealthLog(HealthLog log) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      await _repository.insertHealthLog(log);
      
      if (log.type.toLowerCase() == 'kematian' && log.amount > 0) {
        await ref.read(batchProvider.notifier).recalculateBatchPopulation(log.batchId);
      }
      
      return _repository.getAllHealthLogs();
    });
  }

  Future<void> updateHealthLog(HealthLog log) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      await _repository.updateHealthLog(log);

      if (log.type.toLowerCase() == 'kematian') {
        await ref.read(batchProvider.notifier).recalculateBatchPopulation(log.batchId);
      }

      return _repository.getAllHealthLogs();
    });
  }

  Future<void> deleteHealthLog(HealthLog log) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      await _repository.deleteHealthLog(log);

      if (log.type.toLowerCase() == 'kematian' && log.amount > 0) {
        await ref.read(batchProvider.notifier).recalculateBatchPopulation(log.batchId);
      }

      return _repository.getAllHealthLogs();
    });
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
