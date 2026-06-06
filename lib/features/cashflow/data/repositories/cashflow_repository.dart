import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../domain/models/cashflow.dart';

class CashflowRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  String? get _userId => FirebaseAuth.instance.currentUser?.uid;

  CollectionReference<Map<String, dynamic>>? get _cashflowsRef {
    if (_userId == null) return null;
    return _firestore.collection('users').doc(_userId).collection('cashflows');
  }

  Future<void> insertCashflow(Cashflow cashflow) async {
    final ref = _cashflowsRef;
    if (ref == null) return;
    await ref.doc(cashflow.id).set(cashflow.toMap());
  }

  Future<List<Cashflow>> getAllCashflow() async {
    final ref = _cashflowsRef;
    if (ref == null) return [];
    
    final snapshot = await ref.get();
    return snapshot.docs.map((doc) => Cashflow.fromMap(doc.data())).toList();
  }

  Future<void> updateCashflow(Cashflow cashflow) async {
    final ref = _cashflowsRef;
    if (ref == null) return;
    
    await ref.doc(cashflow.id).update(cashflow.toMap());
  }

  Future<void> deleteCashflow(String id) async {
    final ref = _cashflowsRef;
    if (ref == null) return;
    
    await ref.doc(id).delete();
  }
}
