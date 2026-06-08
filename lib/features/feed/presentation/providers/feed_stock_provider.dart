import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../data/repositories/feed_stock_repository.dart';
import '../../domain/models/feed_stock.dart';
import '../../domain/models/feed_stock_transaction.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import 'package:uuid/uuid.dart';
import '../../../cashflow/presentation/providers/cashflow_provider.dart';
import './feed_provider.dart';
import '../../data/repositories/feed_repository.dart';

final feedStockRepositoryProvider = Provider<FeedStockRepository>((ref) {
  return FeedStockRepository();
});

final feedStockProvider = StreamNotifierProvider<FeedStockNotifier, List<FeedStock>>(() {
  return FeedStockNotifier();
});

class FeedStockNotifier extends StreamNotifier<List<FeedStock>> {
  FeedStockRepository get _repository => ref.read(feedStockRepositoryProvider);

  @override
  Stream<List<FeedStock>> build() {
    final authState = ref.watch(authProvider);
    if (authState.userId == null) return Stream.value([]);
    
    return FirebaseFirestore.instance
        .collection('users')
        .doc(authState.userId)
        .collection('feed_stocks')
        .snapshots()
        .map((snapshot) => snapshot.docs.map((doc) => FeedStock.fromMap(doc.data())).toList());
  }

  Future<void> addOrUpdateStockFromPurchase(String feedType, double amountKg, double totalPrice, String cashflowId, DateTime date) async {
    final stocks = await _repository.getAllFeedStocks();
    // Deterministic sorting to always prioritize the absolute oldest entry for duplicates
    stocks.sort((a, b) {
      int cmp = a.createdAt.compareTo(b.createdAt);
      if (cmp == 0) {
        cmp = a.id.compareTo(b.id);
      }
      return cmp;
    });
    
    // Find existing stock by feed type (case insensitive matching)
    FeedStock? existingStock;
    for (final stock in stocks) {
      if (stock.feedType.toLowerCase() == feedType.toLowerCase()) {
        existingStock = stock;
        break;
      }
    }

    final double pricePerKg = amountKg > 0 ? totalPrice / amountKg : 0;

    FeedStock newStock;
    if (existingStock != null) {
      // Calculate weighted average
      final double totalValueOld = existingStock.currentStockKg * existingStock.averagePricePerKg;
      final double totalValueNew = amountKg * pricePerKg;
      final double newTotalStock = existingStock.currentStockKg + amountKg;
      final double newAveragePrice = newTotalStock > 0 ? (totalValueOld + totalValueNew) / newTotalStock : existingStock.averagePricePerKg;

      newStock = existingStock.copyWith(
        currentStockKg: newTotalStock,
        averagePricePerKg: newAveragePrice,
        lastRestockDate: date,
      );
    } else {
      newStock = FeedStock(
        id: const Uuid().v4(),
        feedType: feedType,
        currentStockKg: amountKg,
        averagePricePerKg: pricePerKg,
        lastRestockDate: date,
        createdAt: DateTime.now(),
      );
    }

    // Save stock
    await _repository.upsertFeedStock(newStock);

    // Save transaction
    final transaction = FeedStockTransaction(
      id: const Uuid().v4(),
      feedStockId: newStock.id,
      transactionType: 'buy',
      amountKg: amountKg,
      pricePerKg: pricePerKg,
      totalPrice: totalPrice,
      date: date,
      referenceId: cashflowId,
    );
    await _repository.insertTransaction(transaction);

    // Refresh state tidak diperlukan karena Stream otomatis update
    ref.invalidate(feedStockTransactionsProvider);
  }

  Future<void> deductStockFromUsage(String feedStockId, double amountKg, double pricePerKg, String feedLogId, DateTime date) async {
    final stocks = await _repository.getAllFeedStocks();
    
    final existingStock = stocks.firstWhere((s) => s.id == feedStockId, orElse: () => throw Exception('Stock not found'));
    
    double newTotalStock = existingStock.currentStockKg - amountKg;
    
    // Clean up floating point inaccuracies and very small remainders (less than 10 grams)
    if (newTotalStock < 0.01) {
      newTotalStock = 0.0;
    }
    
    final newStock = existingStock.copyWith(
      currentStockKg: newTotalStock,
    );

    // Save stock
    await _repository.upsertFeedStock(newStock);

    // Save transaction
    final transaction = FeedStockTransaction(
      id: const Uuid().v4(),
      feedStockId: newStock.id,
      transactionType: 'use',
      amountKg: amountKg,
      pricePerKg: pricePerKg,
      totalPrice: amountKg * pricePerKg,
      date: date,
      referenceId: feedLogId,
    );
    await _repository.insertTransaction(transaction);

    // Refresh state tidak diperlukan karena Stream otomatis update
    ref.invalidate(feedStockTransactionsProvider);
  }

  Future<void> revertStockTransaction(String referenceId) async {
    final transactions = await _repository.getAllTransactions();
    final txsToRevert = transactions.where((t) => t.referenceId == referenceId).toList();
    if (txsToRevert.isEmpty) return;

    final stocks = await _repository.getAllFeedStocks();
    for (final tx in txsToRevert) {
      final existingStock = stocks.where((s) => s.id == tx.feedStockId).firstOrNull;

      if (existingStock != null) {
        double newCurrentStockKg = existingStock.currentStockKg;
        double newAveragePrice = existingStock.averagePricePerKg;

        if (tx.transactionType == 'buy') {
          newCurrentStockKg -= tx.amountKg;
          if (newCurrentStockKg < 0) newCurrentStockKg = 0;
          
          final totalValue = (existingStock.currentStockKg * existingStock.averagePricePerKg) - (tx.amountKg * tx.pricePerKg);
          if (newCurrentStockKg > 0) {
            newAveragePrice = totalValue / newCurrentStockKg;
            if (newAveragePrice < 0) newAveragePrice = existingStock.averagePricePerKg; 
          } else {
            newAveragePrice = existingStock.averagePricePerKg;
          }
        } else if (tx.transactionType == 'use') {
          newCurrentStockKg += tx.amountKg;
        }

        // Clean up floating point inaccuracies
        if (newCurrentStockKg < 0.01) {
          newCurrentStockKg = 0.0;
        }

        final newStock = existingStock.copyWith(
          currentStockKg: newCurrentStockKg,
          averagePricePerKg: newAveragePrice,
        );
        
        await _repository.deleteTransaction(tx.id);
        
        // Check if there are any other transactions left for this stock
        final remainingTxs = await _repository.getAllTransactions();
        // Cek sisa transaksi dan secara lokal ABAIKAN transaksi yang baru saja kita minta Firebase hapus
        final stockTxs = remainingTxs.where((t) => t.feedStockId == existingStock.id && t.id != tx.id).toList();
        
        if (stockTxs.isEmpty) {
          await _repository.deleteFeedStock(existingStock.id);
        } else {
          await _repository.upsertFeedStock(newStock);
        }
      } else {
        await _repository.deleteTransaction(tx.id);
      }
    }
    // Refresh state tidak diperlukan karena Stream otomatis update
    ref.invalidate(feedStockTransactionsProvider);
  }

  // Method for manual deletion from History UI (Cleanup orphaned transactions)
  Future<void> deleteTransactionDirectly(FeedStockTransaction tx) async {
    if (tx.transactionType == 'buy' && tx.referenceId != null) {
      // Just delete the cashflow, which will cascade and call revertStockTransaction automatically
      await ref.read(cashflowProvider.notifier).deleteCashflow(tx.referenceId!);
      return;
    } else if (tx.transactionType == 'use' && tx.referenceId != null) {
      // Find the FeedLog and delete it, which will cascade
      final feedRepo = FeedRepository();
      final logs = await feedRepo.getAllFeedLogs();
      final log = logs.where((l) => l.id == tx.referenceId).firstOrNull;
      if (log != null) {
        await ref.read(feedProvider.notifier).deleteFeedLog(log);
      }
      return;
    }
    
    // Fallback if no referenceId
    await revertStockTransaction(tx.referenceId ?? tx.id);
  }

  Future<void> deleteFeedStockAndTransactions(String feedStockId) async {
    final remainingTxs = await _repository.getAllTransactions();
    final stockTxs = remainingTxs.where((t) => t.feedStockId == feedStockId).toList();
    for (var tx in stockTxs) {
      await _repository.deleteTransaction(tx.id);
    }
    await _repository.deleteFeedStock(feedStockId);
    ref.invalidate(feedStockTransactionsProvider);
  }
}

// Stats Provider to get transactions history
final feedStockTransactionsProvider = FutureProvider<List<FeedStockTransaction>>((ref) async {
  final repository = ref.read(feedStockRepositoryProvider);
  return await repository.getAllTransactions();
});
