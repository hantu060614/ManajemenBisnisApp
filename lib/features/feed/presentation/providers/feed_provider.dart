import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/repositories/feed_repository.dart';
import '../../domain/models/feed_log.dart';

final feedRepositoryProvider = Provider<FeedRepository>((ref) {
  return FeedRepository();
});

final feedProvider = AsyncNotifierProvider<FeedNotifier, List<FeedLog>>(() {
  return FeedNotifier();
});

class FeedNotifier extends AsyncNotifier<List<FeedLog>> {
  late final FeedRepository _repository;

  @override
  Future<List<FeedLog>> build() async {
    _repository = ref.watch(feedRepositoryProvider);
    return _repository.getAllFeedLogs();
  }

  Future<void> addFeedLog(FeedLog log) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      await _repository.insertFeedLog(log);
      return _repository.getAllFeedLogs();
    });
  }

  Future<void> updateFeedLog(FeedLog log) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      await _repository.updateFeedLog(log);
      return _repository.getAllFeedLogs();
    });
  }

  Future<void> deleteFeedLog(String id) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      await _repository.deleteFeedLog(id);
      return _repository.getAllFeedLogs();
    });
  }
}

// Derived stats helper
class FeedStats {
  final double totalPakanPagiToday;
  final double totalPakanSiangToday;
  final double totalPakanSoreToday;
  final double totalPakanToday;
  final double totalPakanThisWeek;
  final double totalPakanThisMonth;

  final double costToday;
  final double costThisWeek;
  final double costThisMonth;

  FeedStats({
    required this.totalPakanPagiToday,
    required this.totalPakanSiangToday,
    required this.totalPakanSoreToday,
    required this.totalPakanToday,
    required this.totalPakanThisWeek,
    required this.totalPakanThisMonth,
    required this.costToday,
    required this.costThisWeek,
    required this.costThisMonth,
  });
}

final feedStatsProvider = Provider<FeedStats>((ref) {
  final feedLogsAsync = ref.watch(feedProvider);
  final feedLogs = feedLogsAsync.value ?? [];

  final now = DateTime.now();
  final todayStart = DateTime(now.year, now.month, now.day);
  final startOfWeek = todayStart.subtract(Duration(days: now.weekday - 1));
  final startOfMonth = DateTime(now.year, now.month, 1);

  double totalPakanPagiToday = 0;
  double totalPakanSiangToday = 0;
  double totalPakanSoreToday = 0;
  double totalPakanToday = 0;
  double totalPakanThisWeek = 0;
  double totalPakanThisMonth = 0;

  double costToday = 0;
  double costThisWeek = 0;
  double costThisMonth = 0;

  for (final log in feedLogs) {
    final logDate = DateTime(log.date.year, log.date.month, log.date.day);
    final logCost = log.amountKg * log.pricePerKg;

    // Daily checks
    if (logDate.isAtSameMomentAs(todayStart)) {
      totalPakanToday += log.amountKg;
      costToday += logCost;
      if (log.feedingTime.toLowerCase() == 'pagi') {
        totalPakanPagiToday += log.amountKg;
      } else if (log.feedingTime.toLowerCase() == 'siang') {
        totalPakanSiangToday += log.amountKg;
      } else if (log.feedingTime.toLowerCase() == 'sore') {
        totalPakanSoreToday += log.amountKg;
      }
    }

    // Weekly checks
    if (logDate.isAfter(startOfWeek.subtract(const Duration(seconds: 1))) && logDate.isBefore(todayStart.add(const Duration(days: 1)))) {
      totalPakanThisWeek += log.amountKg;
      costThisWeek += logCost;
    }

    // Monthly checks
    if (logDate.isAfter(startOfMonth.subtract(const Duration(seconds: 1))) && logDate.isBefore(todayStart.add(const Duration(days: 1)))) {
      totalPakanThisMonth += log.amountKg;
      costThisMonth += logCost;
    }
  }

  return FeedStats(
    totalPakanPagiToday: totalPakanPagiToday,
    totalPakanSiangToday: totalPakanSiangToday,
    totalPakanSoreToday: totalPakanSoreToday,
    totalPakanToday: totalPakanToday,
    totalPakanThisWeek: totalPakanThisWeek,
    totalPakanThisMonth: totalPakanThisMonth,
    costToday: costToday,
    costThisWeek: costThisWeek,
    costThisMonth: costThisMonth,
  );
});

// Selector for cycle total pakan cost
final batchFeedCostProvider = Provider.family<double, String>((ref, batchId) {
  final feedLogsAsync = ref.watch(feedProvider);
  final feedLogs = feedLogsAsync.value ?? [];

  double totalCost = 0;
  for (final log in feedLogs) {
    if (log.batchId == batchId) {
      totalCost += log.amountKg * log.pricePerKg;
    }
  }
  return totalCost;
});
