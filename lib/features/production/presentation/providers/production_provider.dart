import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../data/repositories/production_repository.dart';
import '../../domain/models/production_log.dart';
import '../../../auth/presentation/providers/auth_provider.dart';

final productionRepositoryProvider = Provider<ProductionRepository>((ref) {
  return ProductionRepository();
});

final productionProvider = StreamNotifierProvider<ProductionNotifier, List<ProductionLog>>(() {
  return ProductionNotifier();
});

class ProductionNotifier extends StreamNotifier<List<ProductionLog>> {
  ProductionRepository get _repository => ref.read(productionRepositoryProvider);

  @override
  Stream<List<ProductionLog>> build() {
    final authState = ref.watch(authProvider);
    if (authState.userId == null) return Stream.value([]);
    
    return FirebaseFirestore.instance
        .collection('users')
        .doc(authState.userId)
        .collection('production_logs')
        .orderBy('date', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs.map((doc) => ProductionLog.fromMap(doc.data())).toList());
  }

  Future<void> addProductionLog(ProductionLog log) async {
    try {
      await _repository.insertProductionLog(log);
    } catch (e) {
      // throw error
    }
  }

  Future<void> updateProductionLog(ProductionLog log) async {
    try {
      await _repository.updateProductionLog(log);
    } catch (e) {
      // throw error
    }
  }

  Future<void> deleteProductionLog(String id) async {
    try {
      await _repository.deleteProductionLog(id);
    } catch (e) {
      // throw error
    }
  }
}
