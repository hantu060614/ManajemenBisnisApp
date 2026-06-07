import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/repositories/feed_stock_repository.dart';
import '../../domain/models/feed_stock.dart';
import '../../domain/models/feed_stock_transaction.dart';
import 'package:uuid/uuid.dart';

final feedStockRepositoryProvider = Provider<FeedStockRepository>((ref) {
  return FeedStockRepository();
});

final feedStockProvider = AsyncNotifierProvider<FeedStockNotifier, List<FeedStock>>(() {
  return FeedStockNotifier();
});

class FeedStockNotifier extends AsyncNotifier<List<FeedStock>> {
  FeedStockRepository get _repository => ref.read(feedStockRepositoryProvider);

  @override
  Future<List<FeedStock>> build() async {
    return _repository.getAllFeedStocks();
  }

  Future<void> addOrUpdateStockFromPurchase(String feedType, double amountKg, double totalPrice, String cashflowId, DateTime date) async {
    final stocks = state.value ?? [];
    
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

    // Refresh state
    state = await AsyncValue.guard(() => _repository.getAllFeedStocks());
    ref.invalidate(feedStockTransactionsProvider);
  }

  Future<void> deductStockFromUsage(String feedStockId, double amountKg, double pricePerKg, String feedLogId, DateTime date) async {
    final stocks = state.value ?? [];
    
    final existingStock = stocks.firstWhere((s) => s.id == feedStockId, orElse: () => throw Exception('Stock not found'));
    
    final newTotalStock = existingStock.currentStockKg - amountKg;
    
    final newStock = existingStock.copyWith(
      currentStockKg: newTotalStock < 0 ? 0 : newTotalStock,
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

    // Refresh state
    state = await AsyncValue.guard(() => _repository.getAllFeedStocks());
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

        final newStock = existingStock.copyWith(
          currentStockKg: newCurrentStockKg,
          averagePricePerKg: newAveragePrice,
        );
        await _repository.upsertFeedStock(newStock);
      }
      await _repository.deleteTransaction(tx.id);
    }
    
    state = await AsyncValue.guard(() => _repository.getAllFeedStocks());
    ref.invalidate(feedStockTransactionsProvider);
  }

  // Method for manual deletion from History UI (Cleanup orphaned transactions)
  Future<void> deleteTransactionDirectly(FeedStockTransaction tx) async {
    final stocks = await _repository.getAllFeedStocks();
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

      final newStock = existingStock.copyWith(
        currentStockKg: newCurrentStockKg,
        averagePricePerKg: newAveragePrice,
      );
      await _repository.upsertFeedStock(newStock);
    }
    await _repository.deleteTransaction(tx.id);
    
    state = await AsyncValue.guard(() => _repository.getAllFeedStocks());
    ref.invalidate(feedStockTransactionsProvider);
  }
}

// Stats Provider to get transactions history
final feedStockTransactionsProvider = FutureProvider<List<FeedStockTransaction>>((ref) async {
  final repository = ref.read(feedStockRepositoryProvider);
  return await repository.getAllTransactions();
});
