import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:uuid/uuid.dart';
import '../../domain/models/batch.dart';
import '../providers/batch_provider.dart';
import '../../../cashflow/domain/models/cashflow.dart';
import '../../../cashflow/presentation/providers/cashflow_provider.dart';
import 'package:intl/intl.dart';

class BatchHarvestFormPage extends ConsumerStatefulWidget {
  final Batch batch;

  const BatchHarvestFormPage({super.key, required this.batch});

  @override
  ConsumerState<BatchHarvestFormPage> createState() => _BatchHarvestFormPageState();
}

class _BatchHarvestFormPageState extends ConsumerState<BatchHarvestFormPage> {
  final _formKey = GlobalKey<FormState>();
  final _notesController = TextEditingController();
  
  // Controllers untuk Ikan/Unggas (Borongan/Timbangan Umum)
  final _quantityController = TextEditingController(); // Jumlah Panen
  final _priceController = TextEditingController(); // Harga per Satuan
  String _selectedUnit = 'Kg';
  final List<String> _units = ['Kg', 'Ekor', 'Gram', 'Ton', 'Liter'];

  // Controllers untuk Sapi/Kambing (Dinamis Ekor / Timbangan)
  final _headCountController = TextEditingController(); // Jumlah Ekor Keluar
  final _totalWeightController = TextEditingController(); // Total Berat (Kg)
  
  String _salesSystem = 'Per Ekor'; // 'Per Ekor' atau 'Timbangan (Kg)'
  final List<String> _salesSystems = ['Per Ekor', 'Timbangan (Kg)'];

  double _total = 0;
  late bool _isLargeAnimal;

  @override
  void initState() {
    super.initState();
    _isLargeAnimal = widget.batch.animalCategory == 'Sapi' || widget.batch.animalCategory == 'Kambing';
    
    // Default unit based on category
    if (!_isLargeAnimal) {
      if (widget.batch.animalCategory == 'Ikan') {
        _selectedUnit = 'Kg';
      } else {
        _selectedUnit = 'Ekor';
      }
    }

    // Add listeners
    _quantityController.addListener(_calculateTotal);
    _priceController.addListener(_calculateTotal);
    _headCountController.addListener(_calculateTotal);
    _totalWeightController.addListener(_calculateTotal);
  }

  void _calculateTotal() {
    setState(() {
      if (_isLargeAnimal) {
        if (_salesSystem == 'Per Ekor') {
          final heads = double.tryParse(_headCountController.text) ?? 0;
          final pricePerHead = double.tryParse(_priceController.text) ?? 0;
          _total = heads * pricePerHead;
        } else {
          final weight = double.tryParse(_totalWeightController.text) ?? 0;
          final pricePerKg = double.tryParse(_priceController.text) ?? 0;
          _total = weight * pricePerKg;
        }
      } else {
        final qty = double.tryParse(_quantityController.text) ?? 0;
        final price = double.tryParse(_priceController.text) ?? 0;
        _total = qty * price;
      }
    });
  }

  @override
  void dispose() {
    _notesController.dispose();
    _quantityController.dispose();
    _priceController.dispose();
    _headCountController.dispose();
    _totalWeightController.dispose();
    super.dispose();
  }

  void _saveHarvest() {
    if (_formKey.currentState!.validate()) {
      // 1. Mark batch as inactive
      final updatedBatch = Batch(
        id: widget.batch.id,
        name: widget.batch.name,
        animalCategory: widget.batch.animalCategory,
        animalType: widget.batch.animalType,
        initialCount: widget.batch.initialCount,
        currentCount: widget.batch.currentCount,
        startDate: widget.batch.startDate,
        initialCapital: widget.batch.initialCapital,
        isActive: false, // End cycle
        synced: widget.batch.synced,
      );
      ref.read(batchProvider.notifier).updateBatch(updatedBatch);

      // 2. Add cashflow income
      final priceStr = NumberFormat.currency(locale: 'id', symbol: 'Rp ', decimalDigits: 0).format(double.tryParse(_priceController.text) ?? 0);
      String desc = '';

      if (_isLargeAnimal) {
        final heads = _headCountController.text;
        if (_salesSystem == 'Per Ekor') {
          desc = 'Panen ${widget.batch.name} - ${_notesController.text}. Dijual $heads Ekor x $priceStr/Ekor';
        } else {
          final weight = _totalWeightController.text;
          desc = 'Panen ${widget.batch.name} - ${_notesController.text}. Dijual $heads Ekor (Timbangan: $weight Kg) x $priceStr/Kg';
        }
      } else {
        final qty = _quantityController.text;
        desc = 'Panen ${widget.batch.name} - ${_notesController.text}. Total: $qty $_selectedUnit x $priceStr/$_selectedUnit';
      }
      
      final cashflow = Cashflow(
        id: const Uuid().v4(),
        type: 'income',
        amount: _total,
        category: 'Panen',
        description: desc,
        date: DateTime.now(),
      );
      
      ref.read(cashflowProvider.notifier).addCashflow(cashflow);

      // 3. Show success and back
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Panen berhasil dicatat dan siklus diakhiri!')),
      );
      context.pop();
    }
  }

  Widget _buildLargeAnimalForm() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextFormField(
          controller: _headCountController,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(
            labelText: 'Jumlah Keluar (Ekor)',
            prefixIcon: Icon(Icons.pets),
          ),
          validator: (value) => value == null || value.isEmpty ? 'Wajib diisi' : null,
        ),
        const SizedBox(height: 16),
        DropdownButtonFormField<String>(
          value: _salesSystem,
          isExpanded: true,
          decoration: const InputDecoration(
            labelText: 'Sistem Penjualan',
            prefixIcon: Icon(Icons.handshake_outlined),
          ),
          dropdownColor: Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(16),
          icon: Icon(Icons.keyboard_arrow_down, color: Theme.of(context).colorScheme.secondary),
          items: _salesSystems.map((String sys) {
            return DropdownMenuItem<String>(
              value: sys,
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 4.0),
                child: Row(
                  children: [
                    Icon(sys == 'Per Ekor' ? Icons.tag : Icons.scale, size: 18, color: Theme.of(context).colorScheme.secondary),
                    const SizedBox(width: 12),
                    Text(sys, style: const TextStyle(fontWeight: FontWeight.w500)),
                  ],
                ),
              ),
            );
          }).toList(),
          onChanged: (String? newValue) {
            if (newValue != null) {
              setState(() {
                _salesSystem = newValue;
                _priceController.clear();
                _calculateTotal();
              });
            }
          },
        ),
        const SizedBox(height: 16),
        if (_salesSystem == 'Timbangan (Kg)') ...[
          TextFormField(
            controller: _totalWeightController,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: const InputDecoration(
              labelText: 'Total Berat Keseluruhan (Kg)',
              prefixIcon: Icon(Icons.scale),
            ),
            validator: (value) => value == null || value.isEmpty ? 'Wajib diisi' : null,
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _priceController,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(
              labelText: 'Harga per Kg (Rp)',
              prefixIcon: Icon(Icons.attach_money),
            ),
            validator: (value) => value == null || value.isEmpty ? 'Wajib diisi' : null,
          ),
        ] else ...[
          TextFormField(
            controller: _priceController,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(
              labelText: 'Harga per Ekor (Rp)',
              prefixIcon: Icon(Icons.attach_money),
            ),
            validator: (value) => value == null || value.isEmpty ? 'Wajib diisi' : null,
          ),
        ],
      ],
    );
  }

  Widget _buildGeneralAnimalForm() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              flex: 2,
              child: TextFormField(
                controller: _quantityController,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                decoration: const InputDecoration(
                  labelText: 'Jumlah Panen',
                  prefixIcon: Icon(Icons.scale),
                ),
                validator: (value) => value == null || value.isEmpty ? 'Wajib diisi' : null,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              flex: 1,
              child: DropdownButtonFormField<String>(
                value: _selectedUnit,
                isExpanded: true,
                decoration: const InputDecoration(
                  labelText: 'Satuan',
                ),
                dropdownColor: Theme.of(context).colorScheme.surface,
                borderRadius: BorderRadius.circular(16),
                icon: Icon(Icons.keyboard_arrow_down, color: Theme.of(context).colorScheme.secondary),
                items: _units.map((String unit) {
                  return DropdownMenuItem<String>(
                    value: unit,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4.0),
                      child: Text(unit, style: const TextStyle(fontWeight: FontWeight.w500)),
                    ),
                  );
                }).toList(),
                onChanged: (String? newValue) {
                  if (newValue != null) {
                    setState(() {
                      _selectedUnit = newValue;
                      _calculateTotal(); // trigger rebuild for label update
                    });
                  }
                },
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        TextFormField(
          controller: _priceController,
          keyboardType: TextInputType.number,
          decoration: InputDecoration(
            labelText: 'Harga per $_selectedUnit (Rp)',
            prefixIcon: const Icon(Icons.attach_money),
          ),
          validator: (value) => value == null || value.isEmpty ? 'Wajib diisi' : null,
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final currencyFormatter = NumberFormat.currency(locale: 'id', symbol: 'Rp ', decimalDigits: 0);
    
    return Scaffold(
      appBar: AppBar(
        title: Text('Panen: ${widget.batch.name}'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextFormField(
                controller: _notesController,
                decoration: const InputDecoration(
                  labelText: 'Catatan Pembeli (Misal: Jual ke Pak Wawa)',
                  prefixIcon: Icon(Icons.person_outline),
                ),
                validator: (value) => value == null || value.isEmpty ? 'Wajib diisi' : null,
              ),
              const SizedBox(height: 24),
              
              if (_isLargeAnimal) 
                _buildLargeAnimalForm()
              else 
                _buildGeneralAnimalForm(),
                
              const SizedBox(height: 32),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primaryContainer,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  children: [
                    Text(
                      'Total Pendapatan',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: Theme.of(context).colorScheme.onPrimaryContainer,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      currencyFormatter.format(_total),
                      style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                        color: Theme.of(context).colorScheme.onPrimaryContainer,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),
              ElevatedButton(
                onPressed: _saveHarvest,
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size(double.infinity, 56),
                ),
                child: const Text('Simpan & Akhiri Siklus'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
