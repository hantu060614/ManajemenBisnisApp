import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../providers/batch_provider.dart';

class BatchesPage extends ConsumerWidget {
  const BatchesPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final batchesAsyncValue = ref.watch(batchProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Manajemen Siklus Ternak'),
      ),
      body: batchesAsyncValue.when(
        data: (batches) {
          if (batches.isEmpty) {
            return const Center(
              child: Text('Belum ada data. Silakan tambah data baru.'),
            );
          }
          return ListView.builder(
            itemCount: batches.length,
            itemBuilder: (context, index) {
              final batch = batches[index];
              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: ListTile(
                  title: Text(batch.name),
                  subtitle: Text(
                    '${batch.animalType} - Jumlah: ${batch.currentCount}\n'
                    'Mulai: ${DateFormat('dd MMM yyyy').format(batch.startDate)}',
                  ),
                  isThreeLine: true,
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (batch.isActive) ...[
                        IconButton(
                          onPressed: () {
                            context.push('/batches/daily-log', extra: batch);
                          },
                          icon: const Icon(Icons.edit_note),
                          color: Colors.blue,
                          tooltip: 'Catat Harian',
                        ),
                        IconButton(
                          onPressed: () {
                            context.push('/batches/harvest', extra: batch);
                          },
                          icon: const Icon(Icons.shopping_cart_checkout),
                          color: Colors.green,
                          tooltip: 'Panen',
                        ),
                      ] else ...[
                        const Icon(
                          Icons.check_circle,
                          color: Colors.grey,
                        ),
                      ],
                      const SizedBox(width: 8),
                      IconButton(
                        icon: const Icon(Icons.delete, color: Colors.red),
                        onPressed: () {
                          _confirmDelete(context, ref, batch.id);
                        },
                      ),
                    ],
                  ),
                  onTap: () {
                    context.push('/batches/add', extra: batch);
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
        onPressed: () {
          context.push('/batches/add');
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
        content: const Text('Apakah Anda yakin ingin menghapus data ini?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Batal'),
          ),
          TextButton(
            onPressed: () {
              ref.read(batchProvider.notifier).deleteBatch(id);
              Navigator.pop(ctx);
            },
            child: const Text('Hapus', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}
