import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../domain/models/batch.dart';
import '../../domain/models/daily_log.dart';
import '../providers/batch_provider.dart';

class BatchesPage extends ConsumerWidget {
  const BatchesPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final batchesAsyncValue = ref.watch(batchProvider);

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Manajemen Siklus Ternak'),
          bottom: const TabBar(
            tabs: [
              Tab(text: 'Daftar Siklus', icon: Icon(Icons.inventory_2_outlined)),
              Tab(text: 'Riwayat Harian', icon: Icon(Icons.history)),
            ],
          ),
        ),
        body: batchesAsyncValue.when(
          data: (batches) {
            return TabBarView(
              children: [
                // Tab 1: Daftar Siklus
                _buildBatchesList(context, ref, batches),
                // Tab 2: Riwayat Harian
                _DailyLogsHistoryTab(batches: batches),
              ],
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
                if (action == 'daily-log') {
                  context.push('/batches/daily-log', extra: batch);
                } else if (action == 'harvest') {
                  context.push('/batches/harvest', extra: batch);
                } else if (action == 'edit') {
                  context.push('/batches/add', extra: batch);
                } else if (action == 'delete') {
                  _confirmDelete(context, ref, batch.id);
                }
              },
              itemBuilder: (context) => [
                if (batch.isActive) ...[
                  const PopupMenuItem(
                    value: 'daily-log',
                    child: Row(
                      children: [
                        Icon(Icons.edit_note, color: Colors.blue, size: 20),
                        SizedBox(width: 8),
                        Text('Catat Harian'),
                      ],
                    ),
                  ),
                  const PopupMenuItem(
                    value: 'harvest',
                    child: Row(
                      children: [
                        Icon(Icons.shopping_cart_checkout, color: Colors.green, size: 20),
                        SizedBox(width: 8),
                        Text('Panen'),
                      ],
                    ),
                  ),
                ] else ...[
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
                ],
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

class _DailyLogsHistoryTab extends ConsumerStatefulWidget {
  final List<Batch> batches;

  const _DailyLogsHistoryTab({required this.batches});

  @override
  ConsumerState<_DailyLogsHistoryTab> createState() => _DailyLogsHistoryTabState();
}

class _DailyLogsHistoryTabState extends ConsumerState<_DailyLogsHistoryTab> {
  String _selectedBatchId = 'all';

  @override
  Widget build(BuildContext context) {
    final allLogsAsync = ref.watch(allDailyLogsProvider);

    return Column(
      children: [
        // Dropdown Filter
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: DropdownButtonFormField<String>(
            value: _selectedBatchId,
            isExpanded: true,
            decoration: const InputDecoration(
              labelText: 'Filter berdasarkan Siklus',
              prefixIcon: Icon(Icons.filter_list),
            ),
            dropdownColor: Theme.of(context).colorScheme.surface,
            borderRadius: BorderRadius.circular(16),
            icon: Icon(Icons.keyboard_arrow_down, color: Theme.of(context).colorScheme.secondary),
            items: [
              const DropdownMenuItem(
                value: 'all',
                child: Text('Semua Siklus'),
              ),
              ...widget.batches.map((batch) {
                return DropdownMenuItem(
                  value: batch.id,
                  child: Text(batch.name),
                );
              }),
            ],
            onChanged: (value) {
              if (value != null) {
                setState(() {
                  _selectedBatchId = value;
                });
              }
            },
          ),
        ),

        // Logs List
        Expanded(
          child: allLogsAsync.when(
            data: (logs) {
              final filteredLogs = _selectedBatchId == 'all'
                  ? logs
                  : logs.where((log) => log.batchId == _selectedBatchId).toList();

              if (filteredLogs.isEmpty) {
                return const Center(
                  child: Text(
                    'Belum ada riwayat pencatatan harian.',
                    style: TextStyle(color: Colors.grey),
                  ),
                );
              }

              return ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: filteredLogs.length,
                itemBuilder: (context, index) {
                  final log = filteredLogs[index];
                  // Find batch name
                  final batchName = widget.batches
                      .firstWhere((b) => b.id == log.batchId,
                          orElse: () => Batch(
                                id: '',
                                name: 'Siklus Tidak Dikenal',
                                animalCategory: '',
                                animalType: '',
                                initialCount: 0,
                                currentCount: 0,
                                startDate: DateTime.now(),
                                initialCapital: 0,
                                isActive: false,
                              ))
                      .name;

                  return Card(
                    margin: const EdgeInsets.only(bottom: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: ListTile(
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      title: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(
                              batchName,
                              style: const TextStyle(fontWeight: FontWeight.bold),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          Text(
                            DateFormat('dd MMM yyyy').format(log.logDate),
                            style: const TextStyle(fontSize: 12, color: Colors.grey),
                          ),
                        ],
                      ),
                      subtitle: Padding(
                        padding: const EdgeInsets.only(top: 8.0),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text('Pakan', style: TextStyle(fontSize: 11, color: Colors.grey)),
                                const SizedBox(height: 2),
                                Text(
                                  '${log.feedAmount} ${log.feedUnit}',
                                  style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                                ),
                              ],
                            ),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text('Kematian', style: TextStyle(fontSize: 11, color: Colors.grey)),
                                const SizedBox(height: 2),
                                Text(
                                  '${log.mortalityCount} ekor',
                                  style: TextStyle(
                                    fontWeight: FontWeight.w600,
                                    fontSize: 13,
                                    color: log.mortalityCount > 0 ? Colors.redAccent : null,
                                  ),
                                ),
                              ],
                            ),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text('Est. Berat', style: TextStyle(fontSize: 11, color: Colors.grey)),
                                const SizedBox(height: 2),
                                Text(
                                  log.estimatedWeight > 0 ? '${log.estimatedWeight} Kg' : '-',
                                  style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      trailing: IconButton(
                        icon: const Icon(Icons.delete_outline, color: Colors.redAccent),
                        onPressed: () => _confirmDeleteLog(context, ref, log),
                      ),
                    ),
                  );
                },
              );
            },
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (err, stack) => Center(child: Text('Terjadi kesalahan: $err')),
          ),
        ),
      ],
    );
  }

  void _confirmDeleteLog(BuildContext context, WidgetRef ref, DailyLog log) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Hapus Catatan Harian'),
        content: const Text('Apakah Anda yakin ingin menghapus catatan harian ini?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Batal'),
          ),
          TextButton(
            onPressed: () {
              ref.read(batchProvider.notifier).deleteDailyLog(log.batchId, log.id);
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Catatan harian berhasil dihapus!')),
              );
            },
            child: const Text('Hapus', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}
