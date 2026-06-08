import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:uuid/uuid.dart';
import 'package:intl/intl.dart';
import '../../domain/models/feed_log.dart';
import '../providers/feed_provider.dart';
import '../providers/feed_stock_provider.dart';
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
  final _amountKgController = TextEditingController();
  final _amountOnsController = TextEditingController();
  final _amountGramController = TextEditingController();
  final _priceController = TextEditingController();
  final _notesController = TextEditingController();
  final _mortalityController = TextEditingController();
  final _estimatedWeightController = TextEditingController();

  String? _selectedBatchId;
  String? _selectedBatchName;
  String _feedingTime = 'Pagi'; // 'Pagi', 'Siang', or 'Sore'
  DateTime _selectedDate = DateTime.now();
  bool _isUpdatingAmount = false;
  
  String? _selectedFeedType;
  double _availableStockKg = 0;
  bool _isLoading = false;

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
      _selectedFeedType = log.feedType;
      
      _isUpdatingAmount = true;
      _amountKgController.text = log.amountKg.toString().replaceAll(RegExp(r'\.0$'), '');
      _amountOnsController.text = log.amountOns.toString().replaceAll(RegExp(r'\.0$'), '');
      _amountGramController.text = log.amountGram.toString().replaceAll(RegExp(r'\.0$'), '');
      _isUpdatingAmount = false;

      _priceController.text = NumberFormat.decimalPattern('id').format(log.pricePerKg);
      _notesController.text = log.notes ?? '';
      _mortalityController.text = log.mortalityCount > 0 ? log.mortalityCount.toString() : '';
      _estimatedWeightController.text = log.estimatedWeight > 0 ? log.estimatedWeight.toString() : '';
    }
  }

  @override
  void dispose() {
    _amountKgController.removeListener(_onKgChanged);
    _amountOnsController.removeListener(_onOnsChanged);
    _amountGramController.removeListener(_onGramChanged);
    _amountKgController.dispose();
    _amountOnsController.dispose();
    _amountGramController.dispose();
    _priceController.dispose();
    _notesController.dispose();
    _mortalityController.dispose();
    _estimatedWeightController.dispose();
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

  void _saveLog() async {
    if (_formKey.currentState!.validate()) {
      if (_isLoading) return;
      if (_selectedBatchId == null || _selectedBatchName == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Silakan pilih unit ternak terlebih dahulu.')),
        );
        return;
      }

      final batches = ref.read(batchProvider).value ?? [];
      final selectedBatch = batches.firstWhere((b) => b.id == _selectedBatchId, orElse: () => throw Exception('Batch not found'));
      final mortality = int.tryParse(_mortalityController.text) ?? 0;
      final realPopulation = selectedBatch.currentCount + (widget.existingFeedLog?.mortalityCount ?? 0);
      
      if (mortality > realPopulation) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Kematian ($mortality) melebihi populasi saat ini ($realPopulation).')),
        );
        return;
      }

      double amountKg = double.parse(_amountKgController.text);
      const double epsilon = 0.001;
      bool isSnapped = false;

      if (widget.existingFeedLog == null) {
        if ((amountKg - _availableStockKg).abs() <= epsilon) {
          amountKg = _availableStockKg; // snap ke nilai persis
          isSnapped = true;
        } else if (amountKg > _availableStockKg + epsilon) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Stok pakan tidak mencukupi. Stok tersisa hanya ${_availableStockKg.toStringAsFixed(2)} Kg. Silakan catat pembelian pakan baru terlebih dahulu.')),
          );
          return;
        }
      }

      final double finalAmountKg = isSnapped ? amountKg : double.parse(amountKg.toStringAsFixed(3));

      setState(() => _isLoading = true);

      try {
        final feedLog = FeedLog(
          id: widget.existingFeedLog?.id ?? const Uuid().v4(),
          batchId: _selectedBatchId!,
          batchName: _selectedBatchName!,
          date: _selectedDate,
          feedType: _selectedFeedType ?? '',
          amountKg: finalAmountKg,
          amountOns: double.parse(_amountOnsController.text),
          amountGram: double.parse(_amountGramController.text),
          pricePerKg: double.parse(_priceController.text.replaceAll('.', '')),
          notes: _notesController.text.trim().isEmpty ? null : _notesController.text.trim(),
          feedingTime: _feedingTime,
          mortalityCount: int.tryParse(_mortalityController.text) ?? 0,
          estimatedWeight: double.tryParse(_estimatedWeightController.text) ?? 0.0,
        );

        if (widget.existingFeedLog == null) {
          await ref.read(feedProvider.notifier).addFeedLog(feedLog);
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Pencatatan pakan berhasil ditambahkan!')),
            );
          }
        } else {
          await ref.read(feedProvider.notifier).updateFeedLog(feedLog);
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Pencatatan pakan berhasil diperbarui!')),
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
    final feedStocksAsync = ref.watch(feedStockProvider);

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
                    const SizedBox(width: 4),
                    Expanded(
                      child: ChoiceChip(
                        label: const Center(child: Text('Siang')),
                        selected: _feedingTime == 'Siang',
                        onSelected: (selected) {
                          if (selected) setState(() => _feedingTime = 'Siang');
                        },
                      ),
                    ),
                    const SizedBox(width: 4),
                    Expanded(
                      child: ChoiceChip(
                        label: const Center(child: Text('Sore')),
                        selected: _feedingTime == 'Sore',
                        onSelected: (selected) {
                          if (selected) setState(() => _feedingTime = 'Sore');
                        },
                      ),
                    ),
                    const SizedBox(width: 4),
                    Expanded(
                      child: ChoiceChip(
                        label: const Center(child: Text('Malam')),
                        selected: _feedingTime == 'Malam',
                        onSelected: (selected) {
                          if (selected) setState(() => _feedingTime = 'Malam');
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 18),

                // Jenis Pakan (Dropdown dari Stok)
                feedStocksAsync.when(
                  data: (stocks) {
                    final availableStocks = stocks.where((s) => s.currentStockKg > 0 && s.feedType != '-1' && s.feedType.trim().isNotEmpty).toList();
                    
                    if (availableStocks.isEmpty && widget.existingFeedLog == null) {
                      return Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.orange.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: Colors.orange),
                        ),
                        child: const Row(
                          children: [
                            Icon(Icons.warning_amber_rounded, color: Colors.orange),
                            SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                'Stok pakan kosong. Silakan catat pembelian pakan di menu Keuangan terlebih dahulu.',
                                style: TextStyle(color: Colors.orange, fontWeight: FontWeight.bold),
                              ),
                            ),
                          ],
                        ),
                      );
                    }

                    // For editing, we might need to show the old feedType even if stock is 0
                    if (widget.existingFeedLog != null && _selectedFeedType != null) {
                      final hasStock = availableStocks.any((s) => s.feedType == _selectedFeedType);
                      if (!hasStock) {
                        final oldStock = stocks.where((s) => s.feedType == _selectedFeedType).firstOrNull;
                        if (oldStock != null) availableStocks.add(oldStock);
                      }
                    }

                    return DropdownButtonFormField<String>(
                      value: _selectedFeedType,
                      decoration: const InputDecoration(
                        labelText: 'Jenis Pakan (Pilih dari stok)',
                        prefixIcon: Icon(Icons.category_outlined),
                      ),
                      dropdownColor: Theme.of(context).colorScheme.surface,
                      borderRadius: BorderRadius.circular(16),
                      icon: Icon(Icons.keyboard_arrow_down, color: Theme.of(context).colorScheme.secondary),
                      items: availableStocks.map((s) {
                        return DropdownMenuItem<String>(
                          value: s.feedType,
                          child: Text('${s.feedType} (Sisa: ${s.currentStockKg.toStringAsFixed(2)} Kg)', style: const TextStyle(fontWeight: FontWeight.w500)),
                        );
                      }).toList(),
                      onChanged: (value) {
                        if (value != null) {
                          setState(() {
                            _selectedFeedType = value;
                            final stock = availableStocks.firstWhere((s) => s.feedType == value);
                            _availableStockKg = stock.currentStockKg;
                          });
                        }
                      },
                      validator: (value) => value == null ? 'Wajib diisi' : null,
                    );
                  },
                  loading: () => const Center(child: CircularProgressIndicator()),
                  error: (err, stack) => Text('Gagal memuat stok: $err'),
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
                const SizedBox(height: 24),

                // Opsional: Catat Kematian & Pertumbuhan
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.error.withOpacity(0.05),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Theme.of(context).colorScheme.error.withOpacity(0.3)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.warning_amber_rounded, color: Theme.of(context).colorScheme.error),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Status Ikan (Isi Sekali Sehari)',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Theme.of(context).colorScheme.error,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _mortalityController,
                        keyboardType: TextInputType.number,
                        decoration: InputDecoration(
                          labelText: 'Angka Kematian (Ekor) - Opsional',
                          prefixIcon: const Icon(Icons.cruelty_free_outlined),
                          filled: true,
                          fillColor: Theme.of(context).colorScheme.surface,
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _estimatedWeightController,
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        decoration: InputDecoration(
                          labelText: 'Estimasi Berat Rata-rata (Kg) - Opsional',
                          prefixIcon: const Icon(Icons.monitor_weight_outlined),
                          filled: true,
                          fillColor: Theme.of(context).colorScheme.surface,
                        ),
                      ),
                    ],
                  ),
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
                      DateFormat('dd MMM yyyy').format(_selectedDate),
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
                    ),
                  ),
                ),
                const SizedBox(height: 30),

                // Simpan Button
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
                      : const Text('Simpan Catatan Pakan', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
