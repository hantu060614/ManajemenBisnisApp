import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../data/repositories/feed_repository.dart';
import '../../domain/models/feed_log.dart';
import '../../../batches/presentation/providers/batch_provider.dart';
import './feed_stock_provider.dart';
import '../../../auth/presentation/providers/auth_provider.dart';

final feedRepositoryProvider = Provider<FeedRepository>((ref) {
  return FeedRepository();
});

final feedProvider = StreamNotifierProvider<FeedNotifier, List<FeedLog>>(() {
  return FeedNotifier();
});

class FeedNotifier extends StreamNotifier<List<FeedLog>> {
  FeedRepository get _repository => ref.read(feedRepositoryProvider);

  @override
  Stream<List<FeedLog>> build() {
    final authState = ref.watch(authProvider);
    if (authState.userId == null) return Stream.value([]);
    
    return FirebaseFirestore.instance
        .collection('users')
        .doc(authState.userId)
        .collection('feed_logs')
        .orderBy('date', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs.map((doc) => FeedLog.fromMap(doc.data())).toList());
  }

  Future<void> addFeedLog(FeedLog log) async {
    try {
      await _repository.insertFeedLog(log);

      final stocks = ref.read(feedStockProvider).value ?? [];
      final stock = stocks.where((s) => s.feedType == log.feedType).firstOrNull;
      if (stock != null) {
        await ref.read(feedStockProvider.notifier).deductStockFromUsage(
          stock.id,
          log.amountKg,
          log.pricePerKg,
          log.id,
          log.date,
        );
      }
      await ref.read(batchProvider.notifier).recalculateBatchPopulation(log.batchId);
    } catch (e) {
      // throw error
    }
  }

  Future<void> updateFeedLog(FeedLog log) async {
    try {
      await _repository.updateFeedLog(log);

      await ref.read(feedStockProvider.notifier).revertStockTransaction(log.id);
      final stocks = ref.read(feedStockProvider).value ?? [];
      final stock = stocks.where((s) => s.feedType == log.feedType).firstOrNull;
      if (stock != null) {
        await ref.read(feedStockProvider.notifier).deductStockFromUsage(
          stock.id,
          log.amountKg,
          log.pricePerKg,
          log.id,
          log.date,
        );
      }
      await ref.read(batchProvider.notifier).recalculateBatchPopulation(log.batchId);
    } catch (e) {
      // throw error
    }
  }

  Future<void> deleteFeedLog(FeedLog log) async {
    try {
      await _repository.deleteFeedLog(log.id);
      await ref.read(feedStockProvider.notifier).revertStockTransaction(log.id);
      await ref.read(batchProvider.notifier).recalculateBatchPopulation(log.batchId);
    } catch (e) {
      // throw error
    }
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
  final double estimatedCostThisMonth;

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
    required this.estimatedCostThisMonth,
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

  // Hitung Estimasi Bulan Ini
  int daysInMonth = DateTime(now.year, now.month + 1, 0).day;
  int daysPassed = now.day;
  double rataRataHarian = daysPassed > 0 ? costThisMonth / daysPassed : 0;
  double estimasiSisa = rataRataHarian * (daysInMonth - daysPassed);
  double totalEstimasiBulanIni = costThisMonth + estimasiSisa;

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
    estimatedCostThisMonth: totalEstimasiBulanIni,
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
