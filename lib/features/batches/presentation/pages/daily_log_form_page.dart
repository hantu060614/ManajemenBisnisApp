import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:uuid/uuid.dart';
import 'package:intl/intl.dart';
import '../../domain/models/batch.dart';
import '../../domain/models/daily_log.dart';
import '../providers/batch_provider.dart';

class DailyLogFormPage extends ConsumerStatefulWidget {
  final Batch batch;

  const DailyLogFormPage({super.key, required this.batch});

  @override
  ConsumerState<DailyLogFormPage> createState() => _DailyLogFormPageState();
}

class _DailyLogFormPageState extends ConsumerState<DailyLogFormPage> {
  final _formKey = GlobalKey<FormState>();
  final _feedAmountController = TextEditingController();
  final _mortalityCountController = TextEditingController();
  final _estimatedWeightController = TextEditingController();
  
  DateTime _selectedDate = DateTime.now();

  @override
  void dispose() {
    _feedAmountController.dispose();
    _mortalityCountController.dispose();
    _estimatedWeightController.dispose();
    super.dispose();
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: widget.batch.startDate,
      lastDate: DateTime.now(),
    );
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  void _saveLog() {
    if (_formKey.currentState!.validate()) {
      final log = DailyLog(
        id: const Uuid().v4(),
        batchId: widget.batch.id,
        logDate: _selectedDate,
        feedAmount: double.tryParse(_feedAmountController.text) ?? 0.0,
        mortalityCount: int.tryParse(_mortalityCountController.text) ?? 0,
        estimatedWeight: double.tryParse(_estimatedWeightController.text) ?? 0.0,
      );

      ref.read(batchProvider.notifier).addDailyLog(log, widget.batch);
      context.pop();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Catatan harian berhasil disimpan!')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Catat Harian (Pakan/Kematian)'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Container(
          padding: const EdgeInsets.all(24.0),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
                blurRadius: 15,
                offset: const Offset(0, 5),
              ),
            ],
          ),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Siklus: ${widget.batch.name}',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).primaryColor,
                  ),
                ),
                const SizedBox(height: 24),
                TextFormField(
                  controller: _feedAmountController,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  decoration: const InputDecoration(
                    labelText: 'Jumlah Pakan (Kg)',
                    prefixIcon: Icon(Icons.scale),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) return 'Wajib diisi';
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _mortalityCountController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Angka Kematian (Ekor)',
                    prefixIcon: Icon(Icons.warning_amber),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) return 'Wajib diisi (isi 0 jika tidak ada)';
                    if (int.tryParse(value) == null) return 'Harus berupa angka';
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _estimatedWeightController,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  decoration: const InputDecoration(
                    labelText: 'Estimasi Berat Rata-rata (Kg)',
                    prefixIcon: Icon(Icons.monitor_weight_outlined),
                  ),
                ),
                const SizedBox(height: 16),
                ListTile(
                  title: const Text('Tanggal Pencatatan'),
                  subtitle: Text(DateFormat('dd MMMM yyyy').format(_selectedDate)),
                  trailing: const Icon(Icons.calendar_today),
                  onTap: () => _selectDate(context),
                  shape: RoundedRectangleBorder(
                    side: const BorderSide(color: Colors.grey),
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                const SizedBox(height: 32),
                ElevatedButton(
                  onPressed: _saveLog,
                  style: ElevatedButton.styleFrom(
                    minimumSize: const Size(double.infinity, 56),
                  ),
                  child: const Text('Simpan Catatan'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
