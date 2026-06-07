import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../domain/models/health_log.dart';

class HealthRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  String? get _userId => FirebaseAuth.instance.currentUser?.uid;

  CollectionReference<Map<String, dynamic>>? get _healthLogsRef {
    if (_userId == null) return null;
    return _firestore.collection('users').doc(_userId).collection('health_logs');
  }

  Future<void> insertHealthLog(HealthLog log) async {
    final ref = _healthLogsRef;
    if (ref == null) return;
    await ref.doc(log.id).set(log.toMap());
  }

  Future<List<HealthLog>> getAllHealthLogs() async {
    final ref = _healthLogsRef;
    if (ref == null) return [];
    
    final snapshot = await ref.orderBy('date', descending: true).get();
    return snapshot.docs.map((doc) => HealthLog.fromMap(doc.data())).toList();
  }

  Future<void> updateHealthLog(HealthLog log) async {
    final ref = _healthLogsRef;
    if (ref == null) return;
    
    await ref.doc(log.id).update(log.toMap());
  }

  Future<void> deleteHealthLog(HealthLog log) async {
    final ref = _healthLogsRef;
    if (ref == null) return;
    
    await ref.doc(log.id).delete();
  }
}
