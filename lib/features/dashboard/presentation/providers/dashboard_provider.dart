import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../batches/presentation/providers/batch_provider.dart';
import '../../../cashflow/presentation/providers/cashflow_provider.dart';

class DashboardData {
  final int totalAnimals;
  final int activeBatches;
  final double feedOut; // Placeholder until daily logs are implemented
  final double cashflowBalance;
  final double totalIncome;
  final double totalExpense;
  final double incomeToday;
  final double expenseToday;
  final double incomeThisMonth;
  final double expenseThisMonth;

  DashboardData({
    required this.totalAnimals,
    required this.activeBatches,
    required this.feedOut,
    required this.cashflowBalance,
    required this.totalIncome,
    required this.totalExpense,
    required this.incomeToday,
    required this.expenseToday,
    required this.incomeThisMonth,
    required this.expenseThisMonth,
  });
}

final dashboardProvider = Provider<AsyncValue<DashboardData>>((ref) {
  final batchesAsync = ref.watch(batchProvider);
  final cashflowAsync = ref.watch(cashflowProvider);
  final logsAsync = ref.watch(allDailyLogsProvider);

  if (batchesAsync.isLoading || cashflowAsync.isLoading || logsAsync.isLoading) {
    return const AsyncValue.loading();
  }

  if (batchesAsync.hasError) {
    return AsyncValue.error(batchesAsync.error!, batchesAsync.stackTrace!);
  }
  
  if (cashflowAsync.hasError) {
    return AsyncValue.error(cashflowAsync.error!, cashflowAsync.stackTrace!);
  }

  if (logsAsync.hasError) {
    return AsyncValue.error(logsAsync.error!, logsAsync.stackTrace!);
  }

  final batches = batchesAsync.value ?? [];
  final cashflows = cashflowAsync.value ?? [];
  final logs = logsAsync.value ?? [];

  int totalAnimals = 0;
  int activeBatches = 0;

  for (final batch in batches) {
    if (batch.isActive) {
      activeBatches++;
      totalAnimals += batch.currentCount;
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
  for (final log in logs) {
    final logDate = DateTime(log.logDate.year, log.logDate.month, log.logDate.day);
    if (logDate.isAtSameMomentAs(todayStart)) {
      feedOutToday += log.feedAmountInKg;
    }
  }

  return AsyncValue.data(DashboardData(
    totalAnimals: totalAnimals,
    activeBatches: activeBatches,
    feedOut: feedOutToday,
    cashflowBalance: cashflowBalance,
    totalIncome: totalIncome,
    totalExpense: totalExpense,
    incomeToday: incomeToday,
    expenseToday: expenseToday,
    incomeThisMonth: incomeThisMonth,
    expenseThisMonth: expenseThisMonth,
  ));
});
