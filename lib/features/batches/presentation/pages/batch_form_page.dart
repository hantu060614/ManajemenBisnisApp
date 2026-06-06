import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:uuid/uuid.dart';
import 'package:intl/intl.dart';
import '../../domain/models/batch.dart';
import '../providers/batch_provider.dart';

class BatchFormPage extends ConsumerStatefulWidget {
  final Batch? existingBatch;

  const BatchFormPage({super.key, this.existingBatch});

  @override
  ConsumerState<BatchFormPage> createState() => _BatchFormPageState();
}

class _BatchFormPageState extends ConsumerState<BatchFormPage> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _animalTypeController = TextEditingController();
  final _initialCountController = TextEditingController();
  
  String _selectedCategory = 'Ikan';
  final List<String> _categories = ['Ikan', 'Sapi', 'Kambing', 'Unggas', 'Lainnya'];
  
  DateTime _selectedDate = DateTime.now();
  bool _isActive = true;

  @override
  void initState() {
    super.initState();
    if (widget.existingBatch != null) {
      _nameController.text = widget.existingBatch!.name;
      _selectedCategory = _categories.contains(widget.existingBatch!.animalCategory) 
          ? widget.existingBatch!.animalCategory 
          : 'Lainnya';
      _animalTypeController.text = widget.existingBatch!.animalType;
      _initialCountController.text = widget.existingBatch!.initialCount.toString();
      _selectedDate = widget.existingBatch!.startDate;
      _isActive = widget.existingBatch!.isActive;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _animalTypeController.dispose();
    _initialCountController.dispose();
    super.dispose();
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2000),
      lastDate: DateTime(2101),
    );
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  Widget _buildCategoryDropdownItem(String category) {
    IconData icon;
    Color color;
    switch (category) {
      case 'Ikan':
        icon = Icons.set_meal;
        color = Colors.blue;
        break;
      case 'Sapi':
        icon = Icons.pets;
        color = Colors.brown;
        break;
      case 'Kambing':
        icon = Icons.pets;
        color = Colors.grey;
        break;
      case 'Unggas':
        icon = Icons.egg;
        color = Colors.orange;
        break;
      default:
        icon = Icons.category;
        color = Colors.purple;
    }
    return Row(
      children: [
        Icon(icon, color: color, size: 20),
        const SizedBox(width: 12),
        Text(category, style: const TextStyle(fontWeight: FontWeight.w500)),
      ],
    );
  }

  void _saveBatch() {
    if (_formKey.currentState!.validate()) {
      final batch = Batch(
        id: widget.existingBatch?.id ?? const Uuid().v4(),
        name: _nameController.text,
        animalCategory: _selectedCategory,
        animalType: _animalTypeController.text,
        initialCount: int.parse(_initialCountController.text),
        currentCount: widget.existingBatch?.currentCount ?? int.parse(_initialCountController.text),
        startDate: _selectedDate,
        isActive: _isActive,
      );

      if (widget.existingBatch == null) {
        ref.read(batchProvider.notifier).addBatch(batch);
      } else {
        ref.read(batchProvider.notifier).updateBatch(batch);
      }
      context.pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.existingBatch == null ? 'Tambah Siklus Ternak' : 'Edit Siklus Ternak'),
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
                TextFormField(
                  controller: _nameController,
                  decoration: const InputDecoration(
                    labelText: 'Nama/ID Siklus (Contoh: Kandang A1)',
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) => value == null || value.isEmpty ? 'Wajib diisi' : null,
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  value: _selectedCategory,
                  isExpanded: true,
                  decoration: const InputDecoration(
                    labelText: 'Kategori Hewan',
                    prefixIcon: Icon(Icons.category_outlined),
                  ),
                  items: _categories.map((String category) {
                    return DropdownMenuItem<String>(
                      value: category,
                      child: _buildCategoryDropdownItem(category),
                    );
                  }).toList(),
                  onChanged: (String? newValue) {
                    if (newValue != null) {
                      setState(() {
                        _selectedCategory = newValue;
                      });
                    }
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _animalTypeController,
                  decoration: InputDecoration(
                    labelText: _selectedCategory == 'Ikan' 
                        ? 'Jenis Ikan (Contoh: Lele, Nila)'
                        : 'Jenis Spesifik/Ras (Contoh: Limousin)',
                    prefixIcon: const Icon(Icons.pets_outlined),
                  ),
                  validator: (value) => value == null || value.isEmpty ? 'Wajib diisi' : null,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _initialCountController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Jumlah Awal',
                    prefixIcon: Icon(Icons.numbers),
                  ),
                  validator: (value) => value == null || value.isEmpty ? 'Wajib diisi' : null,
                ),
                const SizedBox(height: 16),
                ListTile(
                  title: const Text('Tanggal Tebar/Beli'),
                  subtitle: Text(DateFormat('dd MMMM yyyy').format(_selectedDate)),
                  trailing: const Icon(Icons.calendar_today),
                  onTap: () => _selectDate(context),
                  shape: RoundedRectangleBorder(
                    side: const BorderSide(color: Colors.grey),
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
                const SizedBox(height: 32),
                ElevatedButton(
                  onPressed: _saveBatch,
                  style: ElevatedButton.styleFrom(
                    minimumSize: const Size(double.infinity, 56),
                  ),
                  child: Text(widget.existingBatch == null ? 'Simpan Data' : 'Perbarui Data'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
