import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../domain/models/feed_stock.dart';
import '../../domain/models/feed_stock_transaction.dart';

class FeedStockRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  String? get _userId => FirebaseAuth.instance.currentUser?.uid;

  CollectionReference<Map<String, dynamic>>? get _feedStocksRef {
    if (_userId == null) return null;
    return _firestore.collection('users').doc(_userId).collection('feed_stocks');
  }

  CollectionReference<Map<String, dynamic>>? get _feedStockTransactionsRef {
    if (_userId == null) return null;
    return _firestore.collection('users').doc(_userId).collection('feed_stock_transactions');
  }

  // --- Feed Stock ---

  Future<void> upsertFeedStock(FeedStock stock) async {
    final ref = _feedStocksRef;
    if (ref == null) return;
    await ref.doc(stock.id).set(stock.toMap());
  }

  Future<List<FeedStock>> getAllFeedStocks() async {
    final ref = _feedStocksRef;
    if (ref == null) return [];
    
    final snapshot = await ref.get();
    return snapshot.docs.map((doc) => FeedStock.fromMap(doc.data())).toList();
  }

  Future<void> deleteFeedStock(String id) async {
    final ref = _feedStocksRef;
    if (ref == null) return;
    await ref.doc(id).delete();
  }

  // --- Feed Stock Transactions ---

  Future<void> insertTransaction(FeedStockTransaction transaction) async {
    final ref = _feedStockTransactionsRef;
    if (ref == null) return;
    await ref.doc(transaction.id).set(transaction.toMap());
  }

  Future<List<FeedStockTransaction>> getAllTransactions() async {
    final ref = _feedStockTransactionsRef;
    if (ref == null) return [];
    
    final snapshot = await ref.orderBy('date', descending: true).get();
    return snapshot.docs.map((doc) => FeedStockTransaction.fromMap(doc.data())).toList();
  }

  Future<void> deleteTransaction(String id) async {
    final ref = _feedStockTransactionsRef;
    if (ref == null) return;
    await ref.doc(id).delete();
  }
}
