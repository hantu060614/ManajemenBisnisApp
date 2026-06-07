import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:uuid/uuid.dart';
import 'package:intl/intl.dart';
import '../../domain/models/health_log.dart';
import '../providers/health_provider.dart';
import '../../../batches/presentation/providers/batch_provider.dart';

class HealthFormPage extends ConsumerStatefulWidget {
  final HealthLog? existingHealthLog;

  const HealthFormPage({super.key, this.existingHealthLog});

  @override
  ConsumerState<HealthFormPage> createState() => _HealthFormPageState();
}

class _HealthFormPageState extends ConsumerState<HealthFormPage> {
  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController();
  final _notesController = TextEditingController();

  String? _selectedBatchId;
  String? _selectedBatchName;
  String _selectedType = 'Obat'; // 'Vaksin', 'Obat', 'Penyakit', 'Kematian'
  DateTime _selectedDate = DateTime.now();
  bool _isLoading = false;

  final List<String> _healthTypes = ['Vaksin', 'Obat', 'Penyakit', 'Kematian'];

  @override
  void initState() {
    super.initState();
    if (widget.existingHealthLog != null) {
      final log = widget.existingHealthLog!;
      _selectedBatchId = log.batchId;
      _selectedBatchName = log.batchName;
      _selectedType = log.type;
      _selectedDate = log.date;
      _amountController.text = log.amount > 0 ? log.amount.toString() : '';
      _notesController.text = log.notes;
    }
  }

  @override
  void dispose() {
    _amountController.dispose();
    _notesController.dispose();
    super.dispose();
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
        final amountVal = int.tryParse(_amountController.text) ?? 0;

        final healthLog = HealthLog(
          id: widget.existingHealthLog?.id ?? const Uuid().v4(),
          batchId: _selectedBatchId!,
          batchName: _selectedBatchName!,
          date: _selectedDate,
          type: _selectedType,
          amount: amountVal,
          notes: _notesController.text.trim(),
        );

        if (widget.existingHealthLog == null) {
          await ref.read(healthProvider.notifier).addHealthLog(healthLog);
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Catatan kesehatan berhasil ditambahkan!')),
            );
          }
        } else {
          await ref.read(healthProvider.notifier).updateHealthLog(healthLog);
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Catatan kesehatan berhasil diperbarui!')),
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
        title: Text(widget.existingHealthLog == null ? 'Catat Kesehatan Ternak' : 'Edit Kesehatan Ternak'),
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
                  'Log Kesehatan',
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
                        setState(() {
                          _selectedBatchId = value;
                          _selectedBatchName = activeBatches.firstWhere((b) => b.id == value).name;
                        });
                      },
                      validator: (value) => value == null ? 'Wajib diisi' : null,
                    );
                  },
                  loading: () => const Center(child: CircularProgressIndicator()),
                  error: (err, stack) => Text('Gagal mengambil data ternak: $err'),
                ),
                const SizedBox(height: 18),

                // Kategori Kesehatan Dropdown
                DropdownButtonFormField<String>(
                  value: _selectedType,
                  decoration: const InputDecoration(
                    labelText: 'Jenis Log Kesehatan',
                    prefixIcon: Icon(Icons.health_and_safety_outlined),
                  ),
                  dropdownColor: Theme.of(context).colorScheme.surface,
                  borderRadius: BorderRadius.circular(16),
                  icon: Icon(Icons.keyboard_arrow_down, color: Theme.of(context).colorScheme.secondary),
                  items: _healthTypes.map((type) {
                    return DropdownMenuItem<String>(
                      value: type,
                      child: Text(type, style: const TextStyle(fontWeight: FontWeight.w500)),
                    );
                  }).toList(),
                  onChanged: (value) {
                    if (value != null) {
                      setState(() {
                        _selectedType = value;
                      });
                    }
                  },
                ),
                const SizedBox(height: 18),

                // Amount (Show if Kematian)
                if (_selectedType == 'Kematian') ...[
                  TextFormField(
                    controller: _amountController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'Jumlah Kematian (Ekor)',
                      prefixIcon: Icon(Icons.trending_down_outlined),
                    ),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) return 'Wajib diisi';
                      final count = int.tryParse(value);
                      if (count == null || count <= 0) return 'Harus angka lebih besar dari 0';
                      return null;
                    },
                  ),
                  const SizedBox(height: 18),
                ],

                // Notes / Keterangan
                TextFormField(
                  controller: _notesController,
                  decoration: const InputDecoration(
                    labelText: 'Detail / Keterangan',
                    prefixIcon: Icon(Icons.edit_note),
                    hintText: 'Contoh: Vaksin ND gumboro, Flu Burung, Obat anti jamur',
                  ),
                  maxLines: 3,
                  validator: (value) => value == null || value.trim().isEmpty ? 'Wajib diisi' : null,
                ),
                const SizedBox(height: 18),

                // Date
                InkWell(
                  onTap: () => _selectDate(context),
                  borderRadius: BorderRadius.circular(16),
                  child: InputDecorator(
                    decoration: const InputDecoration(
                      labelText: 'Tanggal Catat',
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
                          'Simpan Catatan Kesehatan',
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
