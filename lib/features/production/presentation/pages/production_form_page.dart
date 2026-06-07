import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:uuid/uuid.dart';
import 'package:intl/intl.dart';
import '../../domain/models/production_log.dart';
import '../providers/production_provider.dart';
import '../../../batches/presentation/providers/batch_provider.dart';

class ProductionFormPage extends ConsumerStatefulWidget {
  final ProductionLog? existingProductionLog;

  const ProductionFormPage({super.key, this.existingProductionLog});

  @override
  ConsumerState<ProductionFormPage> createState() => _ProductionFormPageState();
}

class _ProductionFormPageState extends ConsumerState<ProductionFormPage> {
  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController();
  final _notesController = TextEditingController();

  String? _selectedBatchId;
  String? _selectedBatchName;
  String _type = 'Bobot Sampling'; // 'Telur', 'Susu', 'Bobot Sampling'
  String _unit = 'Gram/Ekor'; // 'Butir', 'Liter', 'Gram/Ekor'
  DateTime _selectedDate = DateTime.now();
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    if (widget.existingProductionLog != null) {
      final log = widget.existingProductionLog!;
      _selectedBatchId = log.batchId;
      _selectedBatchName = log.batchName;
      _type = log.type;
      _unit = log.unit;
      _selectedDate = log.date;
      _amountController.text = log.amount.toString();
      _notesController.text = log.notes ?? '';
    }
  }

  @override
  void dispose() {
    _amountController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  void _onBatchSelected(String batchId, String category) {
    setState(() {
      _selectedBatchId = batchId;
      if (category == 'Perikanan') {
        _type = 'Bobot Sampling';
        _unit = 'Gram/Ekor';
      } else if (category == 'Unggas') {
        _type = 'Telur';
        _unit = 'Butir';
      } else if (category == 'Ruminansia') {
        _type = 'Susu';
        _unit = 'Liter';
      } else {
        _type = 'Bobot Sampling';
        _unit = 'Gram/Ekor';
      }
    });
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            dialogTheme: DialogTheme(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(24),
              ),
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  void _saveLog() async {
    if (_formKey.currentState!.validate()) {
      if (_isLoading) return;
      if (_selectedBatchId == null || _selectedBatchName == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Silakan pilih unit ternak terlebih dahulu.')),
        );
        return;
      }

      setState(() => _isLoading = true);

      try {
        final amountVal = double.tryParse(_amountController.text) ?? 0.0;

        final log = ProductionLog(
          id: widget.existingProductionLog?.id ?? const Uuid().v4(),
          batchId: _selectedBatchId!,
          batchName: _selectedBatchName!,
          date: _selectedDate,
          type: _type,
          amount: amountVal,
          unit: _unit,
          notes: _notesController.text.trim().isEmpty ? null : _notesController.text.trim(),
        );

        if (widget.existingProductionLog == null) {
          await ref.read(productionProvider.notifier).addProductionLog(log);
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Catatan produksi berhasil ditambahkan!')),
            );
          }
        } else {
          await ref.read(productionProvider.notifier).updateProductionLog(log);
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Catatan produksi berhasil diperbarui!')),
            );
          }
        }
        if (mounted) context.pop();
      } finally {
        if (mounted) setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final batchesAsync = ref.watch(batchProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.existingProductionLog == null ? 'Catat Produksi Harian' : 'Edit Produksi Harian'),
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Container(
          padding: const EdgeInsets.all(24.0),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.2),
                blurRadius: 20,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Log Hasil Produksi / Sampling',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ),
                const SizedBox(height: 20),

                // Unit Ternak Dropdown
                batchesAsync.when(
                  data: (batches) {
                    final activeBatches = batches.where((b) => b.isActive).toList();
                    if (activeBatches.isEmpty) {
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 16.0),
                        child: Text(
                          'Belum ada unit ternak aktif. Silakan tambahkan unit ternak aktif terlebih dahulu.',
                          style: TextStyle(color: Theme.of(context).colorScheme.error),
                        ),
                      );
                    }

                    if (_selectedBatchId == null && activeBatches.length == 1) {
                      _selectedBatchId = activeBatches.first.id;
                      _selectedBatchName = activeBatches.first.name;
                      // Trigger state change after frame build to avoid setState during build.
                      WidgetsBinding.instance.addPostFrameCallback((_) {
                        _onBatchSelected(activeBatches.first.id, activeBatches.first.animalCategory);
                      });
                    }

                    return DropdownButtonFormField<String>(
                      value: _selectedBatchId,
                      decoration: const InputDecoration(
                        labelText: 'Pilih Unit Ternak',
                        prefixIcon: Icon(Icons.pets),
                      ),
                      dropdownColor: Theme.of(context).colorScheme.surface,
                      borderRadius: BorderRadius.circular(16),
                      icon: Icon(Icons.keyboard_arrow_down, color: Theme.of(context).colorScheme.secondary),
                      items: activeBatches.map((b) {
                        return DropdownMenuItem<String>(
                          value: b.id,
                          child: Text(b.name, style: const TextStyle(fontWeight: FontWeight.w500)),
                        );
                      }).toList(),
                      onChanged: (value) {
                        if (value != null) {
                          final batch = activeBatches.firstWhere((b) => b.id == value);
                          _selectedBatchName = batch.name;
                          _onBatchSelected(value, batch.animalCategory);
                        }
                      },
                      validator: (value) => value == null ? 'Wajib diisi' : null,
                    );
                  },
                  loading: () => const Center(child: CircularProgressIndicator()),
                  error: (err, stack) => Text('Gagal mengambil data ternak: $err'),
                ),
                const SizedBox(height: 18),

                // Auto-populated fields info
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.secondary.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.info_outline, color: Theme.of(context).colorScheme.primary, size: 20),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Tipe Produksi: $_type ($_unit)',
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 18),

                // Amount
                TextFormField(
                  controller: _amountController,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  decoration: InputDecoration(
                    labelText: 'Jumlah Produksi / Hasil ($_unit)',
                    prefixIcon: const Icon(Icons.production_quantity_limits),
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) return 'Wajib diisi';
                    if (double.tryParse(value) == null) return 'Harus berupa angka';
                    return null;
                  },
                ),
                const SizedBox(height: 18),

                // Notes / Keterangan
                TextFormField(
                  controller: _notesController,
                  decoration: const InputDecoration(
                    labelText: 'Catatan / Keterangan (Opsional)',
                    prefixIcon: Icon(Icons.edit_note),
                    hintText: 'Contoh: Sampling bobot rata-rata 300g per ekor',
                  ),
                  maxLines: 2,
                ),
                const SizedBox(height: 18),

                // Date
                InkWell(
                  onTap: () => _selectDate(context),
                  borderRadius: BorderRadius.circular(16),
                  child: InputDecorator(
                    decoration: const InputDecoration(
                      labelText: 'Tanggal Produksi',
                      prefixIcon: Icon(Icons.calendar_today_outlined),
                    ),
                    child: Text(
                      DateFormat('dd MMMM yyyy').format(_selectedDate),
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
                    ),
                  ),
                ),
                const SizedBox(height: 30),

                // Save Button
                ElevatedButton(
                  onPressed: _isLoading ? null : _saveLog,
                  style: ElevatedButton.styleFrom(
                    minimumSize: const Size(double.infinity, 56),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: _isLoading 
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text(
                          'Simpan Catatan Produksi',
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
