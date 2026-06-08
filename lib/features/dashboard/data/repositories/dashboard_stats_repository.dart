import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../domain/models/dashboard_stats.dart';

class DashboardStatsRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  String? get _userId => FirebaseAuth.instance.currentUser?.uid;

  DocumentReference<Map<String, dynamic>>? get _statsDocRef {
    if (_userId == null) return null;
    return _firestore.collection('users').doc(_userId).collection('dashboard_stats').doc('main');
  }

  Stream<DashboardStats?> getStatsStream() {
    final ref = _statsDocRef;
    if (ref == null) return Stream.value(null);

    return ref.snapshots().map((snapshot) {
      if (!snapshot.exists || snapshot.data() == null) return null;
      return DashboardStats.fromMap(snapshot.data()!);
    });
  }

  Future<void> _runStatsTransaction(DashboardStats Function(DashboardStats current, DateTime now) updater) async {
    final ref = _statsDocRef;
    if (ref == null) return;

    await _firestore.runTransaction((transaction) async {
      final snapshot = await transaction.get(ref);
      DashboardStats stats;
      
      if (snapshot.exists && snapshot.data() != null) {
        stats = DashboardStats.fromMap(snapshot.data()!);
      } else {
        stats = DashboardStats.empty();
      }

      final now = DateTime.now();
      final todayStart = DateTime(now.year, now.month, now.day);
      final monthStart = DateTime(now.year, now.month, 1);
      
      final lastUpdate = stats.lastUpdatedDate;
      final lastUpdateStart = DateTime(lastUpdate.year, lastUpdate.month, lastUpdate.day);
      final lastUpdateMonthStart = DateTime(lastUpdate.year, lastUpdate.month, 1);

      // Rollover Logic
      if (lastUpdateStart.isBefore(todayStart)) {
        stats = stats.copyWith(
          incomeToday: 0,
          expenseToday: 0,
          feedOutToday: 0,
        );
      }
      
      if (lastUpdateMonthStart.isBefore(monthStart)) {
        stats = stats.copyWith(
          incomeThisMonth: 0,
          expenseThisMonth: 0,
        );
      }

      // Apply specific updates
      final updatedStats = updater(stats, now);
      
      // Always bump lastUpdatedDate
      final finalStats = updatedStats.copyWith(lastUpdatedDate: now);

      transaction.set(ref, finalStats.toMap());
    });
  }

  Future<void> updateCashflowStats({
    required double amount,
    required String type,
    required DateTime txDate,
    required bool isDelete,
  }) async {
    await _runStatsTransaction((stats, now) {
      double multiplier = isDelete ? -1.0 : 1.0;
      final txValue = amount * multiplier;

      final todayStart = DateTime(now.year, now.month, now.day);
      final monthStart = DateTime(now.year, now.month, 1);
      final txDateStart = DateTime(txDate.year, txDate.month, txDate.day);

      double newTotalIncome = stats.totalIncome;
      double newTotalExpense = stats.totalExpense;
      double newIncomeToday = stats.incomeToday;
      double newExpenseToday = stats.expenseToday;
      double newIncomeThisMonth = stats.incomeThisMonth;
      double newExpenseThisMonth = stats.expenseThisMonth;

      if (type == 'income') {
        newTotalIncome += txValue;
        if (txDateStart.isAtSameMomentAs(todayStart)) newIncomeToday += txValue;
        if (txDateStart.isAtSameMomentAs(monthStart) || txDateStart.isAfter(monthStart)) newIncomeThisMonth += txValue;
      } else {
        newTotalExpense += txValue;
        if (txDateStart.isAtSameMomentAs(todayStart)) newExpenseToday += txValue;
        if (txDateStart.isAtSameMomentAs(monthStart) || txDateStart.isAfter(monthStart)) newExpenseThisMonth += txValue;
      }

      return stats.copyWith(
        totalIncome: newTotalIncome,
        totalExpense: newTotalExpense,
        cashflowBalance: newTotalIncome - newTotalExpense,
        incomeToday: newIncomeToday,
        expenseToday: newExpenseToday,
        incomeThisMonth: newIncomeThisMonth,
        expenseThisMonth: newExpenseThisMonth,
      );
    });
  }

  Future<void> updateFeedOutStats({
    required double amountKg,
    required DateTime logDate,
    required bool isDelete,
  }) async {
    await _runStatsTransaction((stats, now) {
      double multiplier = isDelete ? -1.0 : 1.0;
      final value = amountKg * multiplier;

      final todayStart = DateTime(now.year, now.month, now.day);
      final logDateStart = DateTime(logDate.year, logDate.month, logDate.day);

      double newFeedOutToday = stats.feedOutToday;
      if (logDateStart.isAtSameMomentAs(todayStart)) {
        newFeedOutToday += value;
      }

      return stats.copyWith(feedOutToday: newFeedOutToday);
    });
  }

  Future<void> updateBatchStats({
    required int activeDelta,
    required int animalsDelta,
  }) async {
    await _runStatsTransaction((stats, now) {
      return stats.copyWith(
        activeBatches: stats.activeBatches + activeDelta,
        totalAnimals: stats.totalAnimals + animalsDelta,
      );
    });
  }

  Future<void> setMigratedStats(DashboardStats initialStats) async {
    final ref = _statsDocRef;
    if (ref == null) return;
    
    // Set directly, bypassing transaction for initial migration
    await ref.set(initialStats.copyWith(
      isMigrated: true,
      lastUpdatedDate: DateTime.now(),
    ).toMap());
  }

  Future<void> migrateLegacyData({
    required List<dynamic> cashflows,
    required List<dynamic> batches,
    required List<dynamic> feedLogs,
  }) async {
    int totalAnimals = 0;
    int activeBatches = 0;

    for (final b in batches) {
      if (b.isActive) {
        activeBatches++;
        totalAnimals += b.currentCount as int;
      }
    }

    double cashflowBalance = 0;
    double totalIncome = 0;
    double totalExpense = 0;
    double incomeToday = 0;
    double expenseToday = 0;
    double incomeThisMonth = 0;
    double expenseThisMonth = 0;

    final now = DateTime.now();
    final todayStart = DateTime(now.year, now.month, now.day);
    final startOfMonth = DateTime(now.year, now.month, 1);
    
    for (final cf in cashflows) {
      final cfDate = DateTime(cf.date.year, cf.date.month, cf.date.day);
      if (cf.type == 'income') {
        cashflowBalance += cf.amount;
        totalIncome += cf.amount;
        if (cfDate.isAtSameMomentAs(todayStart)) {
          incomeToday += cf.amount;
        }
        if (cfDate.isAfter(startOfMonth.subtract(const Duration(seconds: 1)))) {
          incomeThisMonth += cf.amount;
        }
      } else {
        cashflowBalance -= cf.amount;
        totalExpense += cf.amount;
        if (cfDate.isAtSameMomentAs(todayStart)) {
          expenseToday += cf.amount;
        }
        if (cfDate.isAfter(startOfMonth.subtract(const Duration(seconds: 1)))) {
          expenseThisMonth += cf.amount;
        }
      }
    }

    double feedOutToday = 0;
    for (final log in feedLogs) {
      final logDate = DateTime(log.date.year, log.date.month, log.date.day);
      if (logDate.isAtSameMomentAs(todayStart)) {
        feedOutToday += log.amountKg;
      }
    }

    final stats = DashboardStats(
      totalAnimals: totalAnimals,
      activeBatches: activeBatches,
      feedOutToday: feedOutToday,
      cashflowBalance: cashflowBalance,
      totalIncome: totalIncome,
      totalExpense: totalExpense,
      incomeToday: incomeToday,
      expenseToday: expenseToday,
      incomeThisMonth: incomeThisMonth,
      expenseThisMonth: expenseThisMonth,
      lastUpdatedDate: now,
      isMigrated: true,
    );

    await setMigratedStats(stats);
  }
}
