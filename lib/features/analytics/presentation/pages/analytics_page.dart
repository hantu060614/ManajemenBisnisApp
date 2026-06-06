import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import '../../../cashflow/presentation/providers/cashflow_provider.dart';
import '../../../batches/presentation/providers/batch_provider.dart';

class AnalyticsPage extends ConsumerWidget {
  const AnalyticsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cashflowAsync = ref.watch(cashflowProvider);
    final batchesAsync = ref.watch(batchProvider);
    final currencyFormatter = NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Analisis Bisnis'),
        elevation: 0,
      ),
      body: batchesAsync.when(
        data: (batches) => cashflowAsync.when(
          data: (cashflows) {
            // Calculations
            double initialCapitalTotal = 0;
            for (final b in batches) {
              initialCapitalTotal += b.initialCapital;
            }

            double totalIncome = 0;
            double totalExpense = 0;
            for (final cf in cashflows) {
              if (cf.type == 'income') {
                totalIncome += cf.amount;
              } else {
                totalExpense += cf.amount;
              }
            }

            double totalCapital = initialCapitalTotal + totalExpense;
            double netProfit = totalIncome - totalExpense;

            // ROI
            double roi = totalCapital > 0 ? (netProfit / totalCapital) * 100 : 0.0;
            // Profit Margin
            double profitMargin = totalIncome > 0 ? (netProfit / totalIncome) * 100 : 0.0;
            // BEP progress
            double bepProgress = totalCapital > 0 ? (totalIncome / totalCapital) * 100 : 0.0;
            if (bepProgress > 100.0) bepProgress = 100.0;

            final maxVal = (totalIncome > totalExpense ? totalIncome : totalExpense) * 1.2;

            return SingleChildScrollView(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Performa Finansial Peternakan 📊',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  ),
                  const SizedBox(height: 16),

                  // ROI Card
                  _buildMetricCard(
                    context,
                    title: 'Return on Investment (ROI)',
                    value: '${roi.toStringAsFixed(1)}%',
                    subtitle: 'Pengembalian modal dari total investasi usaha.',
                    icon: Icons.trending_up_outlined,
                    gradientColors: roi >= 0 
                        ? [const Color(0xFF10B981), const Color(0xFF059669)] 
                        : [const Color(0xFFEF4444), const Color(0xFFDC2626)],
                  ),
                  const SizedBox(height: 16),

                  // BEP progress Card
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.surface,
                      borderRadius: BorderRadius.circular(24),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Progress Break Even Point (BEP)',
                          style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.grey),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Titik Impas Terbantu',
                              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Theme.of(context).colorScheme.primary),
                            ),
                            Text(
                              '${bepProgress.toStringAsFixed(1)}%',
                              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: LinearProgressIndicator(
                            value: bepProgress / 100,
                            minHeight: 12,
                            backgroundColor: Colors.white12,
                            valueColor: const AlwaysStoppedAnimation<Color>(Colors.blueAccent),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          bepProgress >= 100
                              ? 'Selamat! Usaha Anda telah melewati titik impas modal.'
                              : 'Tingkatkan penjualan sebesar ${currencyFormatter.format(totalCapital - totalIncome)} untuk mencapai BEP.',
                          style: const TextStyle(fontSize: 12, color: Colors.white38),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Profit Margin & Capital Summary Row
                  Row(
                    children: [
                      Expanded(
                        child: Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Theme.of(context).colorScheme.surface,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('Profit Margin', style: TextStyle(fontSize: 12, color: Colors.grey)),
                              const SizedBox(height: 6),
                              Text(
                                '${profitMargin.toStringAsFixed(1)}%',
                                style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.tealAccent),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Theme.of(context).colorScheme.surface,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('Modal Terinvestasi', style: TextStyle(fontSize: 12, color: Colors.grey)),
                              const SizedBox(height: 6),
                              FittedBox(
                                fit: BoxFit.scaleDown,
                                child: Text(
                                  currencyFormatter.format(totalCapital),
                                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.orangeAccent),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // Summary breakdown
                  Text(
                    'Rincian Laba Rugi Usaha',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.surface,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Column(
                      children: [
                        _buildSummaryRow('Modal Awal Ternak', currencyFormatter.format(initialCapitalTotal)),
                        const Divider(height: 20),
                        _buildSummaryRow('Biaya Operasional (Pakan dll)', currencyFormatter.format(totalExpense)),
                        const Divider(height: 20),
                        _buildSummaryRow('Total Modal Usaha', currencyFormatter.format(totalCapital), isBold: true),
                        const Divider(height: 24, thickness: 1.5),
                        _buildSummaryRow('Total Pemasukan Kas', currencyFormatter.format(totalIncome), color: Colors.greenAccent),
                        const Divider(height: 20),
                        _buildSummaryRow(
                          'Keuntungan / Laba Bersih',
                          currencyFormatter.format(netProfit),
                          color: netProfit >= 0 ? Colors.blueAccent : Colors.redAccent,
                          isBold: true,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Cashflow Chart
                  Text(
                    'Arus Kas Masuk vs Keluar',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 12),
                  Container(
                    height: 220,
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.surface,
                      borderRadius: BorderRadius.circular(24),
                    ),
                    child: BarChart(
                      BarChartData(
                        alignment: BarChartAlignment.spaceAround,
                        maxY: maxVal > 0 ? maxVal : 1000,
                        barTouchData: BarTouchData(enabled: true),
                        titlesData: FlTitlesData(
                          show: true,
                          bottomTitles: AxisTitles(
                            sideTitles: SideTitles(
                              showTitles: true,
                              getTitlesWidget: (double value, TitleMeta meta) {
                                const style = TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.grey);
                                String text = value == 0 ? 'Pemasukan' : 'Pengeluaran';
                                return SideTitleWidget(
                                  axisSide: meta.axisSide,
                                  child: Text(text, style: style),
                                );
                              },
                            ),
                          ),
                          leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                          topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                          rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                        ),
                        borderData: FlBorderData(show: false),
                        barGroups: [
                          BarChartGroupData(
                            x: 0,
                            barRods: [
                              BarChartRodData(
                                toY: totalIncome,
                                color: Colors.greenAccent,
                                width: 30,
                                borderRadius: BorderRadius.circular(6),
                              )
                            ],
                          ),
                          BarChartGroupData(
                            x: 1,
                            barRods: [
                              BarChartRodData(
                                toY: totalExpense,
                                color: Colors.redAccent,
                                width: 30,
                                borderRadius: BorderRadius.circular(6),
                              )
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 32),
                ],
              ),
            );
          },
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (err, stack) => Center(child: Text('Gagal menghitung analitik: $err')),
        ),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(child: Text('Gagal mengambil data unit ternak: $err')),
      ),
    );
  }

  Widget _buildMetricCard(
    BuildContext context, {
    required String title,
    required String value,
    required String subtitle,
    required IconData icon,
    required List<Color> gradientColors,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: gradientColors,
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                title,
                style: const TextStyle(fontSize: 14, color: Colors.white70, fontWeight: FontWeight.w500),
              ),
              Icon(icon, color: Colors.white70, size: 22),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            value,
            style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.white),
          ),
          const SizedBox(height: 6),
          Text(
            subtitle,
            style: const TextStyle(fontSize: 12, color: Colors.white60),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryRow(String label, String value, {Color? color, bool isBold = false}) {
    final style = TextStyle(
      fontSize: isBold ? 14 : 13,
      fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
      color: color,
    );
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: style),
        Text(value, style: style),
      ],
    );
  }
}
