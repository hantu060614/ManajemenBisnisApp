import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../providers/feed_stock_provider.dart';

class FeedStockHistoryPage extends ConsumerWidget {
  const FeedStockHistoryPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final transactionsAsync = ref.watch(feedStockTransactionsProvider);
    final currencyFormatter = NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Riwayat Stok Pakan'),
        elevation: 0,
      ),
      body: transactionsAsync.when(
        data: (transactions) {
          if (transactions.isEmpty) {
            return const Center(
              child: Text('Belum ada riwayat transaksi stok.'),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: transactions.length,
            itemBuilder: (context, index) {
              final tx = transactions[index];
              final isBuy = tx.transactionType == 'buy';

              return Card(
                margin: const EdgeInsets.only(bottom: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                child: ListTile(
                  contentPadding: const EdgeInsets.all(16),
                  leading: CircleAvatar(
                    backgroundColor: isBuy ? Colors.green.withOpacity(0.1) : Colors.orange.withOpacity(0.1),
                    child: Icon(
                      isBuy ? Icons.arrow_downward : Icons.arrow_upward,
                      color: isBuy ? Colors.green : Colors.orange,
                    ),
                  ),
                  title: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        isBuy ? 'Pembelian Pakan' : 'Pemakaian Pakan',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      Text(
                        '${isBuy ? '+' : '-'}${tx.amountKg.toStringAsFixed(2)} Kg',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: isBuy ? Colors.green : Colors.orange,
                        ),
                      ),
                    ],
                  ),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 8),
                      Text('Harga: ${currencyFormatter.format(tx.pricePerKg)}/kg'),
                      Text('Total: ${currencyFormatter.format(tx.totalPrice)}'),
                      const SizedBox(height: 8),
                      Text(
                        DateFormat('dd MMM yyyy, HH:mm').format(tx.date),
                        style: const TextStyle(fontSize: 12, color: Colors.grey),
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(child: Text('Error: $err')),
      ),
    );
  }
}
