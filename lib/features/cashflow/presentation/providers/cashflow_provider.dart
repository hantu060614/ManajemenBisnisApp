import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../data/repositories/cashflow_repository.dart';
import '../../domain/models/cashflow.dart';
import '../../../feed/presentation/providers/feed_stock_provider.dart';
import '../../../auth/presentation/providers/auth_provider.dart';

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
        .snapshots()
        .map((snapshot) => snapshot.docs.map((doc) => Cashflow.fromMap(doc.data())).toList());
  }

  Future<void> addCashflow(Cashflow cashflow) async {
    try {
      await _repository.insertCashflow(cashflow);
    } catch (e) {
      // throw error
    }
  }

  Future<void> updateCashflow(Cashflow cashflow) async {
    try {
      await _repository.updateCashflow(cashflow);
    } catch (e) {
      // throw error
    }
  }

  Future<void> deleteCashflow(String id) async {
    try {
      await _repository.deleteCashflow(id);
      await ref.read(feedStockProvider.notifier).revertStockTransaction(id);
    } catch (e) {
      // throw error
    }
  }
}
