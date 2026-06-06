import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/repositories/cashflow_repository.dart';
import '../../domain/models/cashflow.dart';

final cashflowRepositoryProvider = Provider<CashflowRepository>((ref) {
  return CashflowRepository();
});

final cashflowProvider = AsyncNotifierProvider<CashflowNotifier, List<Cashflow>>(() {
  return CashflowNotifier();
});

class CashflowNotifier extends AsyncNotifier<List<Cashflow>> {
  CashflowRepository get _repository => ref.read(cashflowRepositoryProvider);

  @override
  Future<List<Cashflow>> build() async {
    return _repository.getAllCashflow();
  }

  Future<void> addCashflow(Cashflow cashflow) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      await _repository.insertCashflow(cashflow);
      return _repository.getAllCashflow();
    });
  }

  Future<void> updateCashflow(Cashflow cashflow) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      await _repository.updateCashflow(cashflow);
      return _repository.getAllCashflow();
    });
  }

  Future<void> deleteCashflow(String id) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      await _repository.deleteCashflow(id);
      return _repository.getAllCashflow();
    });
  }
}
