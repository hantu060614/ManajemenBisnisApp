import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../domain/models/feed_log.dart';

class FeedRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  String? get _userId => FirebaseAuth.instance.currentUser?.uid;

  CollectionReference<Map<String, dynamic>>? get _feedLogsRef {
    if (_userId == null) return null;
    return _firestore.collection('users').doc(_userId).collection('feed_logs');
  }

  Future<void> insertFeedLog(FeedLog log) async {
    final ref = _feedLogsRef;
    if (ref == null) return;
    await ref.doc(log.id).set(log.toMap());
  }

  Future<List<FeedLog>> getAllFeedLogs() async {
    final ref = _feedLogsRef;
    if (ref == null) return [];
    
    final snapshot = await ref.orderBy('date', descending: true).get();
    return snapshot.docs.map((doc) => FeedLog.fromMap(doc.data())).toList();
  }

  Future<void> updateFeedLog(FeedLog log) async {
    final ref = _feedLogsRef;
    if (ref == null) return;
    
    await ref.doc(log.id).update(log.toMap());
  }

  Future<void> deleteFeedLog(String id) async {
    final ref = _feedLogsRef;
    if (ref == null) return;
    
    await ref.doc(id).delete();
  }
}
