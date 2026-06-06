import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:uuid/uuid.dart';
import 'package:intl/intl.dart';
import '../../domain/models/feed_log.dart';
import '../providers/feed_provider.dart';
import '../../../batches/presentation/providers/batch_provider.dart';
import '../../../../core/utils/currency_formatter.dart';

class FeedFormPage extends ConsumerStatefulWidget {
  final FeedLog? existingFeedLog;

  const FeedFormPage({super.key, this.existingFeedLog});

  @override
  ConsumerState<FeedFormPage> createState() => _FeedFormPageState();
}

class _FeedFormPageState extends ConsumerState<FeedFormPage> {
  final _formKey = GlobalKey<FormState>();
  final _feedTypeController = TextEditingController();
  final _amountKgController = TextEditingController();
  final _amountOnsController = TextEditingController();
  final _amountGramController = TextEditingController();
  final _priceController = TextEditingController();
  final _notesController = TextEditingController();

  String? _selectedBatchId;
  String? _selectedBatchName;
  String _feedingTime = 'Pagi'; // 'Pagi', 'Siang', or 'Sore'
  DateTime _selectedDate = DateTime.now();
  bool _isUpdatingAmount = false;

  @override
  void initState() {
    super.initState();
    
    _amountKgController.addListener(_onKgChanged);
    _amountOnsController.addListener(_onOnsChanged);
    _amountGramController.addListener(_onGramChanged);

    if (widget.existingFeedLog != null) {
      final log = widget.existingFeedLog!;
      _selectedBatchId = log.batchId;
      _selectedBatchName = log.batchName;
      _feedingTime = log.feedingTime;
      _selectedDate = log.date;
      _feedTypeController.text = log.feedType;
      
      _isUpdatingAmount = true;
      _amountKgController.text = log.amountKg.toString();
      _amountOnsController.text = log.amountOns.toString();
      _amountGramController.text = log.amountGram.toString();
      _isUpdatingAmount = false;

      _priceController.text = NumberFormat.decimalPattern('id').format(log.pricePerKg);
      _notesController.text = log.notes ?? '';
    }
  }

  @override
  void dispose() {
    _amountKgController.removeListener(_onKgChanged);
    _amountOnsController.removeListener(_onOnsChanged);
    _amountGramController.removeListener(_onGramChanged);
    _feedTypeController.dispose();
    _amountKgController.dispose();
    _amountOnsController.dispose();
    _amountGramController.dispose();
    _priceController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  void _onKgChanged() {
    if (_isUpdatingAmount) return;
    final text = _amountKgController.text.trim();
    if (text.isEmpty) {
      _isUpdatingAmount = true;
      _amountOnsController.clear();
      _amountGramController.clear();
      _isUpdatingAmount = false;
      return;
    }
    final kg = double.tryParse(text);
    if (kg != null) {
      _isUpdatingAmount = true;
      _amountOnsController.text = (kg * 10).toStringAsFixed(1).replaceAll(RegExp(r'\.0$'), '');
      _amountGramController.text = (kg * 1000).toStringAsFixed(0);
      _isUpdatingAmount = false;
    }
  }

  void _onOnsChanged() {
    if (_isUpdatingAmount) return;
    final text = _amountOnsController.text.trim();
    if (text.isEmpty) {
      _isUpdatingAmount = true;
      _amountKgController.clear();
      _amountGramController.clear();
      _isUpdatingAmount = false;
      return;
    }
    final ons = double.tryParse(text);
    if (ons != null) {
      _isUpdatingAmount = true;
      _amountKgController.text = (ons / 10).toStringAsFixed(2).replaceAll(RegExp(r'\.00$|\.0$'), '');
      _amountGramController.text = (ons * 100).toStringAsFixed(0);
      _isUpdatingAmount = false;
    }
  }

  void _onGramChanged() {
    if (_isUpdatingAmount) return;
    final text = _amountGramController.text.trim();
    if (text.isEmpty) {
      _isUpdatingAmount = true;
      _amountKgController.clear();
      _amountOnsController.clear();
      _isUpdatingAmount = false;
      return;
    }
    final gram = double.tryParse(text);
    if (gram != null) {
      _isUpdatingAmount = true;
      _amountKgController.text = (gram / 1000).toStringAsFixed(3).replaceAll(RegExp(r'\.000$|\.00$|\.0$'), '');
      _amountOnsController.text = (gram / 100).toStringAsFixed(2).replaceAll(RegExp(r'\.00$|\.0$'), '');
      _isUpdatingAmount = false;
    }
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

  void _saveLog() {
    if (_formKey.currentState!.validate()) {
      if (_selectedBatchId == null || _selectedBatchName == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Silakan pilih unit ternak terlebih dahulu.')),
        );
        return;
      }

      final feedLog = FeedLog(
        id: widget.existingFeedLog?.id ?? const Uuid().v4(),
        batchId: _selectedBatchId!,
        batchName: _selectedBatchName!,
        date: _selectedDate,
        feedType: _feedTypeController.text.trim(),
        amountKg: double.parse(_amountKgController.text),
        amountOns: double.parse(_amountOnsController.text),
        amountGram: double.parse(_amountGramController.text),
        pricePerKg: double.parse(_priceController.text.replaceAll('.', '')),
        notes: _notesController.text.trim().isEmpty ? null : _notesController.text.trim(),
        feedingTime: _feedingTime,
      );

      if (widget.existingFeedLog == null) {
        ref.read(feedProvider.notifier).addFeedLog(feedLog);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Pencatatan pakan berhasil ditambahkan!')),
        );
      } else {
        ref.read(feedProvider.notifier).updateFeedLog(feedLog);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Pencatatan pakan berhasil diperbarui!')),
        );
      }
      context.pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final batchesAsync = ref.watch(batchProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.existingFeedLog == null ? 'Catat Pemberian Pakan' : 'Edit Pemberian Pakan'),
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
                  'Detail Pemberian Pakan',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ),
                const SizedBox(height: 20),
                
                // Kolam/Unit Ternak Dropdown
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
                        prefixIcon: Icon(Icons.waves),
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

                // Waktu Pemberian Pakan (Pagi, Siang, Sore)
                const Text(
                  'Waktu Pemberian Pakan',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: ChoiceChip(
                        label: const Center(child: Text('Pagi')),
                        selected: _feedingTime == 'Pagi',
                        onSelected: (selected) {
                          if (selected) setState(() => _feedingTime = 'Pagi');
                        },
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: ChoiceChip(
                        label: const Center(child: Text('Siang')),
                        selected: _feedingTime == 'Siang',
                        onSelected: (selected) {
                          if (selected) setState(() => _feedingTime = 'Siang');
                        },
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: ChoiceChip(
                        label: const Center(child: Text('Sore')),
                        selected: _feedingTime == 'Sore',
                        onSelected: (selected) {
                          if (selected) setState(() => _feedingTime = 'Sore');
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 18),

                // Jenis Pakan
                TextFormField(
                  controller: _feedTypeController,
                  decoration: const InputDecoration(
                    labelText: 'Jenis Pakan (Misal: PF 1000, Konsentrat)',
                    prefixIcon: Icon(Icons.category_outlined),
                  ),
                  validator: (value) => value == null || value.trim().isEmpty ? 'Wajib diisi' : null,
                ),
                const SizedBox(height: 18),

                // Jumlah Pakan (Kg, Ons, Gram)
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _amountKgController,
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        decoration: const InputDecoration(
                          labelText: 'Kg',
                          prefixIcon: Icon(Icons.scale_outlined),
                        ),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) return 'Wajib';
                          if (double.tryParse(value) == null) return 'Angka';
                          return null;
                        },
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: TextFormField(
                        controller: _amountOnsController,
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        decoration: const InputDecoration(
                          labelText: 'Ons',
                        ),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) return 'Wajib';
                          if (double.tryParse(value) == null) return 'Angka';
                          return null;
                        },
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: TextFormField(
                        controller: _amountGramController,
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        decoration: const InputDecoration(
                          labelText: 'Gram',
                        ),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) return 'Wajib';
                          if (double.tryParse(value) == null) return 'Angka';
                          return null;
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 18),

                // Harga Pakan per Kg
                TextFormField(
                  controller: _priceController,
                  keyboardType: TextInputType.number,
                  inputFormatters: [CurrencyInputFormatter()],
                  decoration: const InputDecoration(
                    labelText: 'Harga Pakan per Kg (Rp)',
                    prefixIcon: Icon(Icons.payments_outlined),
                    hintText: 'Contoh: 15.000',
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) return 'Wajib diisi';
                    if (double.tryParse(value.replaceAll('.', '')) == null) return 'Harus angka';
                    return null;
                  },
                ),
                const SizedBox(height: 18),

                // Keterangan
                TextFormField(
                  controller: _notesController,
                  decoration: const InputDecoration(
                    labelText: 'Keterangan (Opsional)',
                    prefixIcon: Icon(Icons.description_outlined),
                  ),
                  maxLines: 2,
                ),
                const SizedBox(height: 18),

                // Tanggal
                InkWell(
                  onTap: () => _selectDate(context),
                  borderRadius: BorderRadius.circular(16),
                  child: InputDecorator(
                    decoration: const InputDecoration(
                      labelText: 'Tanggal Pemberian',
                      prefixIcon: Icon(Icons.calendar_today_outlined),
                    ),
                    child: Text(
                      DateFormat('dd MMMM yyyy').format(_selectedDate),
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
                    ),
                  ),
                ),
                const SizedBox(height: 30),

                // Simpan Button
                ElevatedButton(
                  onPressed: _saveLog,
                  style: ElevatedButton.styleFrom(
                    minimumSize: const Size(double.infinity, 56),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: const Text('Simpan Catatan Pakan', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
