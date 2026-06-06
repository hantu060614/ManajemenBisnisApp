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

  DashboardData({
    required this.totalAnimals,
    required this.activeBatches,
    required this.feedOut,
    required this.cashflowBalance,
    required this.totalIncome,
    required this.totalExpense,
  });
}

final dashboardProvider = Provider<AsyncValue<DashboardData>>((ref) {
  final batchesAsync = ref.watch(batchProvider);
  final cashflowAsync = ref.watch(cashflowProvider);

  if (batchesAsync.isLoading || cashflowAsync.isLoading) {
    return const AsyncValue.loading();
  }

  if (batchesAsync.hasError) {
    return AsyncValue.error(batchesAsync.error!, batchesAsync.stackTrace!);
  }
  
  if (cashflowAsync.hasError) {
    return AsyncValue.error(cashflowAsync.error!, cashflowAsync.stackTrace!);
  }

  final batches = batchesAsync.value ?? [];
  final cashflows = cashflowAsync.value ?? [];

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
  
  for (final cf in cashflows) {
    if (cf.type == 'income') {
      cashflowBalance += cf.amount;
      totalIncome += cf.amount;
    } else {
      cashflowBalance -= cf.amount;
      totalExpense += cf.amount;
    }
  }

  return AsyncValue.data(DashboardData(
    totalAnimals: totalAnimals,
    activeBatches: activeBatches,
    feedOut: 0.0, // Placeholder
    cashflowBalance: cashflowBalance,
    totalIncome: totalIncome,
    totalExpense: totalExpense,
  ));
});
