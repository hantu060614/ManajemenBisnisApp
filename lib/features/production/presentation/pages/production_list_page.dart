import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../providers/production_provider.dart';

class ProductionListPage extends ConsumerStatefulWidget {
  const ProductionListPage({super.key});

  @override
  ConsumerState<ProductionListPage> createState() => _ProductionListPageState();
}

class _ProductionListPageState extends ConsumerState<ProductionListPage> {
  String _selectedFilter = 'Semua';
  final List<String> _filters = ['Semua', 'Telur', 'Susu', 'Bobot Sampling'];

  Color _getTypeColor(String type) {
    switch (type) {
      case 'Telur':
        return Colors.amber;
      case 'Susu':
        return Colors.lightBlueAccent;
      case 'Bobot Sampling':
        return Colors.tealAccent;
      default:
        return Colors.grey;
    }
  }

  IconData _getTypeIcon(String type) {
    switch (type) {
      case 'Telur':
        return Icons.egg_outlined;
      case 'Susu':
        return Icons.local_cafe_outlined;
      case 'Bobot Sampling':
        return Icons.scale_outlined;
      default:
        return Icons.assignment_outlined;
    }
  }

  @override
  Widget build(BuildContext context) {
    final productionLogsAsync = ref.watch(productionProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Produksi & Sampling'),
        elevation: 0,
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push('/production/add'),
        icon: const Icon(Icons.add),
        label: const Text('Catat Produksi'),
      ),
      body: Column(
        children: [
          // Filter Chips Horizontal list
          Container(
            height: 60,
            padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: _filters.length,
              itemBuilder: (context, index) {
                final filter = _filters[index];
                final isSelected = _selectedFilter == filter;
                return Padding(
                  padding: const EdgeInsets.only(right: 8.0),
                  child: FilterChip(
                    label: Text(filter),
                    selected: isSelected,
                    onSelected: (selected) {
                      setState(() {
                        _selectedFilter = filter;
                      });
                    },
                  ),
                );
              },
            ),
          ),
          
          Expanded(
            child: productionLogsAsync.when(
              data: (logs) {
                final filteredLogs = _selectedFilter == 'Semua'
                    ? logs
                    : logs.where((log) => log.type == _selectedFilter).toList();

                if (filteredLogs.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.insights_outlined,
                          size: 72,
                          color: Theme.of(context).colorScheme.secondary.withOpacity(0.5),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Belum ada catatan produksi ${_selectedFilter == 'Semua' ? '' : _selectedFilter}',
                          style: TextStyle(
                            fontSize: 16,
                            color: Theme.of(context).colorScheme.secondary,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.all(16.0),
                  itemCount: filteredLogs.length,
                  itemBuilder: (context, index) {
                    final log = filteredLogs[index];
                    final color = _getTypeColor(log.type);
                    final icon = _getTypeIcon(log.type);

                    return Card(
                      margin: const EdgeInsets.only(bottom: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: ListTile(
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                        leading: CircleAvatar(
                          backgroundColor: color.withOpacity(0.15),
                          child: Icon(icon, color: color),
                        ),
                        title: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              log.type,
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: color,
                              ),
                            ),
                            Text(
                              '${log.amount} ${log.unit}',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const SizedBox(height: 4),
                            Text(
                              log.batchName,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 13,
                              ),
                            ),
                            if (log.notes != null) ...[
                              const SizedBox(height: 2),
                              Text(
                                log.notes!,
                                style: const TextStyle(fontSize: 13),
                              ),
                            ],
                            const SizedBox(height: 4),
                            Text(
                              DateFormat('dd MMMM yyyy').format(log.date),
                              style: TextStyle(
                                fontSize: 11,
                                color: Theme.of(context).colorScheme.secondary.withOpacity(0.7),
                              ),
                            ),
                          ],
                        ),
                        trailing: PopupMenuButton<String>(
                          icon: const Icon(Icons.more_vert),
                          onSelected: (value) async {
                            if (value == 'delete') {
                              final confirm = await showDialog<bool>(
                                context: context,
                                builder: (context) => AlertDialog(
                                  title: const Text('Hapus Log Produksi?'),
                                  content: const Text(
                                    'Apakah Anda yakin ingin menghapus data produksi ini?',
                                  ),
                                  actions: [
                                    TextButton(
                                      onPressed: () => Navigator.pop(context, false),
                                      child: const Text('Batal'),
                                    ),
                                    TextButton(
                                      onPressed: () => Navigator.pop(context, true),
                                      child: const Text('Hapus', style: TextStyle(color: Colors.red)),
                                    ),
                                  ],
                                ),
                              );
                              if (confirm == true) {
                                ref.read(productionProvider.notifier).deleteProductionLog(log.id);
                              }
                            }
                          },
                          itemBuilder: (context) => [
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
      ),
    );
  }
}
