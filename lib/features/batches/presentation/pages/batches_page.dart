import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../domain/models/batch.dart';
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
          return _buildBatchesList(context, ref, batches);
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(child: Text('Error: $error')),
      ),
      floatingActionButton: FloatingActionButton(
        heroTag: null,
        onPressed: () {
          context.push('/batches/add');
        },
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildBatchesList(BuildContext context, WidgetRef ref, List<Batch> batches) {
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
            trailing: PopupMenuButton<String>(
              onSelected: (action) {
                if (action == 'harvest') {
                  context.push('/batches/harvest', extra: batch);
                } else if (action == 'edit') {
                  context.push('/batches/add', extra: batch);
                } else if (action == 'delete') {
                  _confirmDelete(context, ref, batch.id);
                }
              },
              itemBuilder: (context) => [
                if (batch.isActive)
                  const PopupMenuItem(
                    value: 'harvest',
                    child: Row(
                      children: [
                        Icon(Icons.shopping_cart_checkout, color: Colors.green, size: 20),
                        SizedBox(width: 8),
                        Text('Panen'),
                      ],
                    ),
                  )
                else
                  const PopupMenuItem(
                    enabled: false,
                    child: Row(
                      children: [
                        Icon(Icons.check_circle, color: Colors.grey, size: 20),
                        SizedBox(width: 8),
                        Text('Siklus Selesai', style: TextStyle(color: Colors.grey)),
                      ],
                    ),
                  ),
                const PopupMenuItem(
                  value: 'edit',
                  child: Row(
                    children: [
                      Icon(Icons.edit, size: 20),
                      SizedBox(width: 8),
                      Text('Edit Siklus'),
                    ],
                  ),
                ),
                const PopupMenuItem(
                  value: 'delete',
                  child: Row(
                    children: [
                      Icon(Icons.delete, color: Colors.red, size: 20),
                      SizedBox(width: 8),
                      Text('Hapus', style: TextStyle(color: Colors.red)),
                    ],
                  ),
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
