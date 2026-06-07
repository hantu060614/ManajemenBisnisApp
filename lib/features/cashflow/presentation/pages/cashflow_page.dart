import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../providers/cashflow_provider.dart';
import '../../../../core/theme/app_colors.dart';

class CashflowPage extends ConsumerWidget {
  const CashflowPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cashflowAsyncValue = ref.watch(cashflowProvider);
    final currencyFormatter = NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Keuangan (Cashflow)'),
      ),
      body: cashflowAsyncValue.when(
        data: (cashflows) {
          if (cashflows.isEmpty) {
            return const Center(
              child: Text('Belum ada data keuangan. Silakan tambah data baru.'),
            );
          }
          
          // Sort by date descending
          final sortedCashflows = List.of(cashflows)
            ..sort((a, b) => b.date.compareTo(a.date));

          return ListView.builder(
            itemCount: sortedCashflows.length,
            itemBuilder: (context, index) {
              final cashflow = sortedCashflows[index];
              final isIncome = cashflow.type == 'income';

              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: isIncome ? AppColors.success.withOpacity(0.1) : AppColors.error.withOpacity(0.1),
                    child: Icon(
                      isIncome ? Icons.arrow_downward : Icons.arrow_upward,
                      color: isIncome ? AppColors.success : AppColors.error,
                    ),
                  ),
                  title: Text(cashflow.category),
                  subtitle: Text(
                    '${DateFormat('dd MMM yyyy').format(cashflow.date)}\n'
                    '${cashflow.description ?? ""}',
                  ),
                  isThreeLine: cashflow.description != null && cashflow.description!.isNotEmpty,
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        '${isIncome ? '+' : '-'}${currencyFormatter.format(cashflow.amount)}',
                        style: TextStyle(
                          color: isIncome ? AppColors.success : AppColors.error,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(width: 8),
                      PopupMenuButton<String>(
                        onSelected: (action) {
                          if (action == 'edit') {
                            context.push('/cashflow/add', extra: cashflow);
                          } else if (action == 'delete') {
                            _confirmDelete(context, ref, cashflow.id);
                          }
                        },
                        itemBuilder: (context) => [
                          const PopupMenuItem(
                            value: 'edit',
                            child: Row(
                              children: [
                                Icon(Icons.edit, size: 18),
                                SizedBox(width: 8),
                                Text('Edit'),
                              ],
                            ),
                          ),
                          const PopupMenuItem(
                            value: 'delete',
                            child: Row(
                              children: [
                                Icon(Icons.delete, color: Colors.red, size: 18),
                                SizedBox(width: 8),
                                Text('Hapus', style: TextStyle(color: Colors.red)),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  onTap: () {
                    context.push('/cashflow/add', extra: cashflow);
                  },
                ),
              );
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(child: Text('Error: $error')),
      ),
      floatingActionButton: FloatingActionButton(
        heroTag: null,
        onPressed: () {
          context.push('/cashflow/add');
        },
        child: const Icon(Icons.add),
      ),
    );
  }

  void _confirmDelete(BuildContext context, WidgetRef ref, String id) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Hapus Data'),
        content: const Text('Apakah Anda yakin ingin menghapus data keuangan ini?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Batal'),
          ),
          TextButton(
            onPressed: () {
              ref.read(cashflowProvider.notifier).deleteCashflow(id);
              Navigator.pop(ctx);
            },
            child: const Text('Hapus', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}
