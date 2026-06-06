import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:csv/csv.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import '../../../cashflow/presentation/providers/cashflow_provider.dart';

class ReportsPage extends ConsumerWidget {
  const ReportsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cashflowAsync = ref.watch(cashflowProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Laporan Keuangan'),
      ),
      body: cashflowAsync.when(
        data: (cashflows) {
          if (cashflows.isEmpty) {
            return const Center(child: Text('Belum ada data keuangan.'));
          }

          double totalIncome = 0;
          double totalExpense = 0;

          for (var c in cashflows) {
            if (c.type == 'income') {
              totalIncome += c.amount;
            } else {
              totalExpense += c.amount;
            }
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Grafik Arus Kas',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 16),
                Container(
                  height: 250,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.surface,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 15,
                        offset: const Offset(0, 5),
                      ),
                    ],
                  ),
                  child: BarChart(
                    BarChartData(
                      alignment: BarChartAlignment.spaceAround,
                      maxY: (totalIncome > totalExpense ? totalIncome : totalExpense) * 1.2,
                      barTouchData: BarTouchData(enabled: false),
                      titlesData: FlTitlesData(
                        show: true,
                        bottomTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            getTitlesWidget: (double value, TitleMeta meta) {
                              const style = TextStyle(fontWeight: FontWeight.bold, fontSize: 14);
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
                              color: Colors.green,
                              width: 25,
                              borderRadius: BorderRadius.circular(4),
                            )
                          ],
                        ),
                        BarChartGroupData(
                          x: 1,
                          barRods: [
                            BarChartRodData(
                              toY: totalExpense,
                              color: Colors.red,
                              width: 25,
                              borderRadius: BorderRadius.circular(4),
                            )
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 32),
                Text(
                  'Ekspor Data',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () => _exportToPDF(context, cashflows),
                        icon: const Icon(Icons.picture_as_pdf),
                        label: const Text('Export PDF'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.redAccent,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () => _exportToCSV(context, cashflows),
                        icon: const Icon(Icons.table_chart),
                        label: const Text('Export Excel'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(child: Text('Error: $err')),
      ),
    );
  }

  Future<void> _exportToPDF(BuildContext context, List<dynamic> cashflows) async {
    final pdf = pw.Document();
    final currencyFormatter = NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0);
    
    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        build: (pw.Context ctx) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text('Laporan Keuangan', style: pw.TextStyle(fontSize: 24, fontWeight: pw.FontWeight.bold)),
              pw.SizedBox(height: 20),
              pw.TableHelper.fromTextArray(
                context: ctx,
                headers: ['Tanggal', 'Tipe', 'Kategori', 'Jumlah'],
                data: cashflows.map((c) {
                  return [
                    DateFormat('dd/MM/yyyy').format(c.date),
                    c.type == 'income' ? 'Pemasukan' : 'Pengeluaran',
                    c.category,
                    currencyFormatter.format(c.amount),
                  ];
                }).toList(),
              ),
            ],
          );
        },
      ),
    );

    try {
      final dir = await getApplicationDocumentsDirectory();
      final file = File('${dir.path}/Laporan_Keuangan.pdf');
      await file.writeAsBytes(await pdf.save());
      
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('PDF Berhasil disimpan di ${file.path}')),
        );
        // Bisa menggunakan Printing untuk share/print
        await Printing.sharePdf(bytes: await pdf.save(), filename: 'Laporan_Keuangan.pdf');
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal export PDF: $e')),
        );
      }
    }
  }

  Future<void> _exportToCSV(BuildContext context, List<dynamic> cashflows) async {
    List<List<dynamic>> rows = [];
    rows.add(['Tanggal', 'Tipe', 'Kategori', 'Catatan', 'Jumlah']);
    
    for (var c in cashflows) {
      rows.add([
        DateFormat('yyyy-MM-dd').format(c.date),
        c.type == 'income' ? 'Pemasukan' : 'Pengeluaran',
        c.category,
        c.description ?? '',
        c.amount,
      ]);
    }

    String csv = const ListToCsvConverter().convert(rows);

    try {
      final dir = await getApplicationDocumentsDirectory();
      final file = File('${dir.path}/Laporan_Keuangan.csv');
      await file.writeAsString(csv);
      
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('CSV Berhasil disimpan di ${file.path}')),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal export CSV: $e')),
        );
      }
    }
  }
}
