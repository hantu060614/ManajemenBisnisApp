import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/repositories/production_repository.dart';
import '../../domain/models/production_log.dart';

final productionRepositoryProvider = Provider<ProductionRepository>((ref) {
  return ProductionRepository();
});

final productionProvider = AsyncNotifierProvider<ProductionNotifier, List<ProductionLog>>(() {
  return ProductionNotifier();
});

class ProductionNotifier extends AsyncNotifier<List<ProductionLog>> {
  late final ProductionRepository _repository;

  @override
  Future<List<ProductionLog>> build() async {
    _repository = ref.watch(productionRepositoryProvider);
    return _repository.getAllProductionLogs();
  }

  Future<void> addProductionLog(ProductionLog log) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      await _repository.insertProductionLog(log);
      return _repository.getAllProductionLogs();
    });
  }

  Future<void> updateProductionLog(ProductionLog log) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      await _repository.updateProductionLog(log);
      return _repository.getAllProductionLogs();
    });
  }

  Future<void> deleteProductionLog(String id) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      await _repository.deleteProductionLog(id);
      return _repository.getAllProductionLogs();
    });
  }
}
