import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../domain/models/batch.dart';
import '../../domain/models/daily_log.dart';

class BatchRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  String? get _userId => FirebaseAuth.instance.currentUser?.uid;

  CollectionReference<Map<String, dynamic>>? get _batchesRef {
    if (_userId == null) return null;
    return _firestore.collection('users').doc(_userId).collection('batches');
  }

  Future<void> insertBatch(Batch batch) async {
    final ref = _batchesRef;
    if (ref == null) return;
    await ref.doc(batch.id).set(batch.toMap());
  }

  Future<List<Batch>> getAllBatches() async {
    final ref = _batchesRef;
    if (ref == null) return [];
    
    final snapshot = await ref.get();
    return snapshot.docs.map((doc) => Batch.fromMap(doc.data())).toList();
  }

  Future<void> updateBatch(Batch batch) async {
    final ref = _batchesRef;
    if (ref == null) return;
    
    await ref.doc(batch.id).update(batch.toMap());
  }

  Future<void> deleteBatch(String id) async {
    final ref = _batchesRef;
    if (ref == null) return;
    
    await ref.doc(id).delete();
  }

  // --- Daily Logs ---
  Future<void> insertDailyLog(DailyLog log) async {
    final ref = _batchesRef;
    if (ref == null) return;
    
    await ref.doc(log.batchId).collection('daily_logs').doc(log.id).set(log.toMap());
  }

  Future<List<DailyLog>> getDailyLogs(String batchId) async {
    final ref = _batchesRef;
    if (ref == null) return [];
    
    final snapshot = await ref.doc(batchId).collection('daily_logs').orderBy('logDate', descending: true).get();
    return snapshot.docs.map((doc) => DailyLog.fromMap(doc.data())).toList();
  }
}
