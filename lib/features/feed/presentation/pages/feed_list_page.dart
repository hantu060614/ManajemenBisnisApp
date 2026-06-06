import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../providers/feed_provider.dart';
import '../../../../core/theme/app_colors.dart';

class FeedListPage extends ConsumerWidget {
  const FeedListPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final feedLogsAsync = ref.watch(feedProvider);
    final stats = ref.watch(feedStatsProvider);
    final currencyFormatter = NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Manajemen Pakan'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () => context.push('/feed/add'),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(feedProvider);
        },
        child: CustomScrollView(
          slivers: [
            // Dashboard Ringkasan Pakan
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Hari Ini Card
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFF1E3C72), Color(0xFF2A5298)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFF1E3C72).withOpacity(0.3),
                            blurRadius: 15,
                            offset: const Offset(0, 8),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'Konsumsi Pakan Hari Ini',
                                style: TextStyle(color: Colors.white70, fontSize: 14, fontWeight: FontWeight.bold),
                              ),
                              Icon(Icons.restaurant, color: Colors.white70, size: 20),
                            ],
                          ),
                          const SizedBox(height: 16),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text('Pagi', style: TextStyle(color: Colors.white60, fontSize: 12), overflow: TextOverflow.ellipsis),
                                    const SizedBox(height: 4),
                                    Text('${stats.totalPakanPagiToday.toStringAsFixed(1)} Kg', style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold), overflow: TextOverflow.ellipsis),
                                  ],
                                ),
                              ),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text('Sore', style: TextStyle(color: Colors.white60, fontSize: 12), overflow: TextOverflow.ellipsis),
                                    const SizedBox(height: 4),
                                    Text('${stats.totalPakanSoreToday.toStringAsFixed(1)} Kg', style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold), overflow: TextOverflow.ellipsis),
                                  ],
                                ),
                              ),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text('Total Hari Ini', style: TextStyle(color: Colors.white60, fontSize: 12), overflow: TextOverflow.ellipsis),
                                    const SizedBox(height: 4),
                                    Text('${stats.totalPakanToday.toStringAsFixed(1)} Kg', style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold), overflow: TextOverflow.ellipsis),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          // Ratio Progress Bar
                          if (stats.totalPakanToday > 0) ...[
                            ClipRRect(
                              borderRadius: BorderRadius.circular(4),
                              child: LinearProgressIndicator(
                                value: stats.totalPakanToday > 0 ? stats.totalPakanPagiToday / stats.totalPakanToday : 0.5,
                                backgroundColor: Colors.white24,
                                valueColor: const AlwaysStoppedAnimation<Color>(AppColors.accent),
                                minHeight: 6,
                              ),
                            ),
                            const SizedBox(height: 8),
                            const Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text('Rasio Pagi (Biru)', style: TextStyle(color: Colors.white54, fontSize: 10)),
                                Text('Rasio Sore (Abu)', style: TextStyle(color: Colors.white54, fontSize: 10)),
                              ],
                            ),
                            const SizedBox(height: 12),
                          ],
                          const Divider(color: Colors.white12),
                          const SizedBox(height: 8),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text('Biaya Hari Ini', style: TextStyle(color: Colors.white60, fontSize: 12), overflow: TextOverflow.ellipsis),
                                    const SizedBox(height: 4),
                                    Text(currencyFormatter.format(stats.costToday), style: const TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.bold), overflow: TextOverflow.ellipsis),
                                  ],
                                ),
                              ),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  children: [
                                    const Text('Estimasi Bulan Ini', style: TextStyle(color: Colors.white60, fontSize: 12), overflow: TextOverflow.ellipsis),
                                    const SizedBox(height: 4),
                                    Text(currencyFormatter.format(stats.costThisMonth), style: const TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.bold), overflow: TextOverflow.ellipsis),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Statistik Lebih Lanjut Section
                    const Text(
                      'Statistik Pengeluaran & Pakan',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: _StatCard(
                            title: 'Pakan Minggu Ini',
                            value: '${stats.totalPakanThisWeek.toStringAsFixed(1)} Kg',
                            subtitle: currencyFormatter.format(stats.costThisWeek),
                            icon: Icons.date_range_outlined,
                            color: AppColors.primaryLight,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _StatCard(
                            title: 'Pakan Bulan Ini',
                            value: '${stats.totalPakanThisMonth.toStringAsFixed(1)} Kg',
                            subtitle: currencyFormatter.format(stats.costThisMonth),
                            icon: Icons.calendar_month_outlined,
                            color: AppColors.accent,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    const Text(
                      'Riwayat Pemberian Pakan',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ),
            ),

            // Riwayat Feed Logs List
            feedLogsAsync.when(
              data: (logs) {
                if (logs.isEmpty) {
                  return const SliverToBoxAdapter(
                    child: Padding(
                      padding: EdgeInsets.symmetric(vertical: 40.0),
                      child: Center(
                        child: Text('Belum ada catatan pakan. Silakan tambah catatan baru.'),
                      ),
                    ),
                  );
                }

                return SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      final log = logs[index];
                      final totalCost = log.amountKg * log.pricePerKg;
                      final isMorning = log.feedingTime.toLowerCase() == 'pagi';

                      return Card(
                        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        child: ListTile(
                          leading: CircleAvatar(
                            backgroundColor: isMorning ? Colors.orange.withOpacity(0.1) : Colors.indigo.withOpacity(0.1),
                            child: Icon(
                              isMorning ? Icons.wb_sunny : Icons.nightlight_round,
                              color: isMorning ? Colors.orange : Colors.indigo,
                            ),
                          ),
                          title: Row(
                            children: [
                              Expanded(
                                child: Text(
                                  log.batchName,
                                  style: const TextStyle(fontWeight: FontWeight.bold),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                decoration: BoxDecoration(
                                  color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Text(
                                  log.feedingTime,
                                  style: TextStyle(fontSize: 10, color: Theme.of(context).colorScheme.primary, fontWeight: FontWeight.bold),
                                ),
                              ),
                            ],
                          ),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const SizedBox(height: 4),
                              Text('Jenis: ${log.feedType} • ${log.amountKg.toStringAsFixed(1)} Kg (${log.amountOns.toStringAsFixed(0)} Ons)'),
                              const SizedBox(height: 2),
                              Text(
                                'Biaya: ${currencyFormatter.format(totalCost)}',
                                style: const TextStyle(fontWeight: FontWeight.w600),
                              ),
                              if (log.notes != null && log.notes!.isNotEmpty) ...[
                                const SizedBox(height: 4),
                                Text(
                                  'Catatan: ${log.notes}',
                                  style: TextStyle(fontSize: 12, color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6)),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                              const SizedBox(height: 2),
                              Text(
                                DateFormat('dd MMM yyyy').format(log.date),
                                style: const TextStyle(fontSize: 11, color: Colors.grey),
                              ),
                            ],
                          ),
                          isThreeLine: true,
                          trailing: PopupMenuButton<String>(
                            onSelected: (action) {
                              if (action == 'edit') {
                                context.push('/feed/add', extra: log);
                              } else if (action == 'delete') {
                                _confirmDelete(context, ref, log.id);
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
                          onTap: () {
                            context.push('/feed/add', extra: log);
                          },
                        ),
                      );
                    },
                    childCount: logs.length,
                  ),
                );
              },
              loading: () => const SliverToBoxAdapter(
                child: Center(child: Padding(padding: EdgeInsets.all(40.0), child: CircularProgressIndicator())),
              ),
              error: (err, stack) => SliverToBoxAdapter(
                child: Center(child: Padding(padding: const EdgeInsets.all(40.0), child: Text('Error: $err'))),
              ),
            ),
            
            // Bottom spacer
            const SliverToBoxAdapter(
              child: SizedBox(height: 40),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => context.push('/feed/add'),
        tooltip: 'Catat Pakan',
        child: const Icon(Icons.add),
      ),
    );
  }

  void _confirmDelete(BuildContext context, WidgetRef ref, String id) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Hapus Catatan Pakan'),
        content: const Text('Apakah Anda yakin ingin menghapus catatan pakan ini?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Batal'),
          ),
          TextButton(
            onPressed: () {
              ref.read(feedProvider.notifier).deleteFeedLog(id);
              Navigator.pop(ctx);
            },
            child: const Text('Hapus', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String title;
  final String value;
  final String subtitle;
  final IconData icon;
  final Color color;

  const _StatCard({
    required this.title,
    required this.value,
    required this.subtitle,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Theme.of(context).dividerColor.withOpacity(0.1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: color, size: 20),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            title,
            style: const TextStyle(fontSize: 12, color: Colors.grey, fontWeight: FontWeight.w500),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 2),
          Text(
            subtitle,
            style: TextStyle(fontSize: 12, color: color, fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }
}
