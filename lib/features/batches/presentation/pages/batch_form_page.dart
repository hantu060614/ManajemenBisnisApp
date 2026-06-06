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
  final _initialCountController = TextEditingController();
  final _initialCapitalController = TextEditingController();
  
  String _selectedCategory = 'Perikanan';
  final List<String> _categories = ['Perikanan', 'Unggas', 'Ruminansia'];
  
  String _selectedAnimalType = 'Lele';
  
  final Map<String, List<String>> _animalTypes = {
    'Perikanan': ['Lele', 'Nila', 'Patin', 'Gurame', 'Mujair'],
    'Unggas': ['Ayam Petelur', 'Ayam Pedaging', 'Bebek', 'Puyuh'],
    'Ruminansia': ['Sapi', 'Kambing', 'Domba'],
  };

  DateTime _selectedDate = DateTime.now();
  bool _isActive = true;

  @override
  void initState() {
    super.initState();
    if (widget.existingBatch != null) {
      _nameController.text = widget.existingBatch!.name;
      _selectedCategory = _categories.contains(widget.existingBatch!.animalCategory) 
          ? widget.existingBatch!.animalCategory 
          : 'Perikanan';
      
      final availableTypes = _animalTypes[_selectedCategory] ?? [];
      _selectedAnimalType = availableTypes.contains(widget.existingBatch!.animalType)
          ? widget.existingBatch!.animalType
          : (availableTypes.isNotEmpty ? availableTypes.first : '');
          
      _initialCountController.text = widget.existingBatch!.initialCount.toString();
      _initialCapitalController.text = widget.existingBatch!.initialCapital.toStringAsFixed(0);
      _selectedDate = widget.existingBatch!.startDate;
      _isActive = widget.existingBatch!.isActive;
    } else {
      _selectedAnimalType = _animalTypes[_selectedCategory]!.first;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _initialCountController.dispose();
    _initialCapitalController.dispose();
    super.dispose();
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2000),
      lastDate: DateTime(2101),
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

  Widget _buildCategoryDropdownItem(String category) {
    IconData icon;
    Color color;
    switch (category) {
      case 'Perikanan':
        icon = Icons.set_meal_outlined;
        color = Colors.blueAccent;
        break;
      case 'Unggas':
        icon = Icons.egg_outlined;
        color = Colors.orangeAccent;
        break;
      case 'Ruminansia':
        icon = Icons.pets_outlined;
        color = Colors.brown;
        break;
      default:
        icon = Icons.category_outlined;
        color = Colors.purpleAccent;
    }
    return Row(
      children: [
        Icon(icon, color: color, size: 22),
        const SizedBox(width: 12),
        Text(category, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15)),
      ],
    );
  }

  void _saveBatch() {
    if (_formKey.currentState!.validate()) {
      final batch = Batch(
        id: widget.existingBatch?.id ?? const Uuid().v4(),
        name: _nameController.text,
        animalCategory: _selectedCategory,
        animalType: _selectedAnimalType,
        initialCount: int.parse(_initialCountController.text),
        currentCount: widget.existingBatch?.currentCount ?? int.parse(_initialCountController.text),
        startDate: _selectedDate,
        initialCapital: double.tryParse(_initialCapitalController.text) ?? 0.0,
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
    final availableTypes = _animalTypes[_selectedCategory] ?? [];

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.existingBatch == null ? 'Tambah Unit Ternak' : 'Edit Unit Ternak'),
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
                  'Informasi Unit Ternak',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ),
                const SizedBox(height: 20),
                TextFormField(
                  controller: _nameController,
                  decoration: const InputDecoration(
                    labelText: 'Nama Unit Ternak',
                    hintText: 'Contoh: Kolam Lele A1, Kandang Sapi B',
                    prefixIcon: Icon(Icons.drive_file_rename_outline),
                  ),
                  validator: (value) => value == null || value.isEmpty ? 'Wajib diisi' : null,
                ),
                const SizedBox(height: 18),
                DropdownButtonFormField<String>(
                  value: _selectedCategory,
                  isExpanded: true,
                  decoration: const InputDecoration(
                    labelText: 'Kategori Usaha',
                    prefixIcon: Icon(Icons.category_outlined),
                  ),
                  dropdownColor: Theme.of(context).colorScheme.surface,
                  borderRadius: BorderRadius.circular(16),
                  icon: Icon(Icons.keyboard_arrow_down, color: Theme.of(context).colorScheme.secondary),
                  items: _categories.map((String category) {
                    return DropdownMenuItem<String>(
                      value: category,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 4.0),
                        child: _buildCategoryDropdownItem(category),
                      ),
                    );
                  }).toList(),
                  onChanged: (String? newValue) {
                    if (newValue != null) {
                      setState(() {
                        _selectedCategory = newValue;
                        final newTypes = _animalTypes[_selectedCategory] ?? [];
                        _selectedAnimalType = newTypes.isNotEmpty ? newTypes.first : '';
                      });
                    }
                  },
                ),
                const SizedBox(height: 18),
                DropdownButtonFormField<String>(
                  value: _selectedAnimalType,
                  isExpanded: true,
                  decoration: const InputDecoration(
                    labelText: 'Jenis/Tipe Ternak',
                    prefixIcon: Icon(Icons.pets_outlined),
                  ),
                  dropdownColor: Theme.of(context).colorScheme.surface,
                  borderRadius: BorderRadius.circular(16),
                  icon: Icon(Icons.keyboard_arrow_down, color: Theme.of(context).colorScheme.secondary),
                  items: availableTypes.map((String type) {
                    return DropdownMenuItem<String>(
                      value: type,
                      child: Text(type, style: const TextStyle(fontWeight: FontWeight.w500)),
                    );
                  }).toList(),
                  onChanged: (String? newValue) {
                    if (newValue != null) {
                      setState(() {
                        _selectedAnimalType = newValue;
                      });
                    }
                  },
                ),
                const SizedBox(height: 18),
                TextFormField(
                  controller: _initialCountController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Populasi Awal (Ekor)',
                    prefixIcon: Icon(Icons.numbers_outlined),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) return 'Wajib diisi';
                    if (int.tryParse(value) == null) return 'Harus angka bulat';
                    return null;
                  },
                ),
                const SizedBox(height: 18),
                TextFormField(
                  controller: _initialCapitalController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Modal Awal (Rp)',
                    prefixIcon: Icon(Icons.payments_outlined),
                    hintText: 'Contoh: 5000000',
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) return 'Wajib diisi';
                    if (double.tryParse(value) == null) return 'Harus angka';
                    return null;
                  },
                ),
                const SizedBox(height: 18),
                InkWell(
                  onTap: () => _selectDate(context),
                  borderRadius: BorderRadius.circular(16),
                  child: InputDecorator(
                    decoration: const InputDecoration(
                      labelText: 'Tanggal Mulai',
                      prefixIcon: Icon(Icons.calendar_today_outlined),
                    ),
                    child: Text(
                      DateFormat('dd MMMM yyyy').format(_selectedDate),
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
                    ),
                  ),
                ),
                const SizedBox(height: 30),
                ElevatedButton(
                  onPressed: _saveBatch,
                  style: ElevatedButton.styleFrom(
                    minimumSize: const Size(double.infinity, 56),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: Text(
                    widget.existingBatch == null ? 'Simpan Unit Ternak' : 'Perbarui Data',
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
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
