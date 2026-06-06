import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../domain/models/production_log.dart';

class ProductionRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  String? get _userId => FirebaseAuth.instance.currentUser?.uid;

  CollectionReference<Map<String, dynamic>>? get _productionLogsRef {
    if (_userId == null) return null;
    return _firestore.collection('users').doc(_userId).collection('production_logs');
  }

  Future<void> insertProductionLog(ProductionLog log) async {
    final ref = _productionLogsRef;
    if (ref == null) return;
    await ref.doc(log.id).set(log.toMap());
  }

  Future<List<ProductionLog>> getAllProductionLogs() async {
    final ref = _productionLogsRef;
    if (ref == null) return [];
    
    final snapshot = await ref.orderBy('date', descending: true).get();
    return snapshot.docs.map((doc) => ProductionLog.fromMap(doc.data())).toList();
  }

  Future<void> updateProductionLog(ProductionLog log) async {
    final ref = _productionLogsRef;
    if (ref == null) return;
    
    await ref.doc(log.id).update(log.toMap());
  }

  Future<void> deleteProductionLog(String id) async {
    final ref = _productionLogsRef;
    if (ref == null) return;
    
    await ref.doc(id).delete();
  }
}
