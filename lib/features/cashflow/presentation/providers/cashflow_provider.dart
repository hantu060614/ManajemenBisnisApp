import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../data/repositories/cashflow_repository.dart';
import '../../domain/models/cashflow.dart';
import '../../../feed/presentation/providers/feed_stock_provider.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../../features/dashboard/data/repositories/dashboard_stats_repository.dart';

final cashflowRepositoryProvider = Provider<CashflowRepository>((ref) {
  return CashflowRepository();
});

final cashflowProvider = StreamNotifierProvider<CashflowNotifier, List<Cashflow>>(() {
  return CashflowNotifier();
});

class CashflowNotifier extends StreamNotifier<List<Cashflow>> {
  CashflowRepository get _repository => ref.read(cashflowRepositoryProvider);

  @override
  Stream<List<Cashflow>> build() {
    final authState = ref.watch(authProvider);
    if (authState.userId == null) return Stream.value([]);
    
    return FirebaseFirestore.instance
        .collection('users')
        .doc(authState.userId)
        .collection('cashflows')
        .orderBy('date', descending: true)
        .limit(50)
        .snapshots()
        .map((snapshot) => snapshot.docs.map((doc) => Cashflow.fromMap(doc.data())).toList());
  }

  Future<void> addCashflow(Cashflow cashflow) async {
    try {
      await _repository.insertCashflow(cashflow);
      
      final statsRepo = DashboardStatsRepository();
      await statsRepo.updateCashflowStats(
        amount: cashflow.amount, 
        type: cashflow.type, 
        txDate: cashflow.date, 
        isDelete: false
      );
    } catch (e) {
      // throw error
    }
  }

  Future<void> updateCashflow(Cashflow cashflow) async {
    try {
      // Revert old cashflow first before applying new, normally handled if we fetch old, 
      // but since we don't fetch old here easily, we rely on the caller or just 
      // do a read. Since update isn't strictly defined if amount changes, 
      // we need the old amount to correctly adjust the stats.
      // Wait, dashboard stats update is hard if we don't know the old value.
      // Let's fetch the old value.
      final oldDocs = await FirebaseFirestore.instance
          .collection('users')
          .doc(FirebaseAuth.instance.currentUser?.uid)
          .collection('cashflows')
          .doc(cashflow.id)
          .get();
      
      if (oldDocs.exists) {
        final oldCf = Cashflow.fromMap(oldDocs.data()!);
        final statsRepo = DashboardStatsRepository();
        
        // Revert old
        await statsRepo.updateCashflowStats(
          amount: oldCf.amount,
          type: oldCf.type,
          txDate: oldCf.date,
          isDelete: true,
        );
        
        // Apply new
        await statsRepo.updateCashflowStats(
          amount: cashflow.amount,
          type: cashflow.type,
          txDate: cashflow.date,
          isDelete: false,
        );
      }

      await _repository.updateCashflow(cashflow);
    } catch (e) {
      // throw error
    }
  }

  Future<void> deleteCashflow(String id) async {
    try {
      // Need to fetch old to know amount to revert
      final oldDocs = await FirebaseFirestore.instance
          .collection('users')
          .doc(FirebaseAuth.instance.currentUser?.uid)
          .collection('cashflows')
          .doc(id)
          .get();
          
      if (oldDocs.exists) {
        final oldCf = Cashflow.fromMap(oldDocs.data()!);
        final statsRepo = DashboardStatsRepository();
        await statsRepo.updateCashflowStats(
          amount: oldCf.amount,
          type: oldCf.type,
          txDate: oldCf.date,
          isDelete: true,
        );
      }

      await _repository.deleteCashflow(id);
      await ref.read(feedStockProvider.notifier).revertStockTransaction(id);
    } catch (e) {
      // throw error
    }
  }
}
