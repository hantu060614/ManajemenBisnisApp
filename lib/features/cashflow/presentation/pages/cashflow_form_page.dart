import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:uuid/uuid.dart';
import 'package:intl/intl.dart';
import '../../domain/models/cashflow.dart';
import '../providers/cashflow_provider.dart';
import '../../../../core/utils/currency_formatter.dart';

class CashflowFormPage extends ConsumerStatefulWidget {
  final Cashflow? existingCashflow;

  const CashflowFormPage({super.key, this.existingCashflow});

  @override
  ConsumerState<CashflowFormPage> createState() => _CashflowFormPageState();
}

class _CashflowFormPageState extends ConsumerState<CashflowFormPage> {
  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController();
  final _descriptionController = TextEditingController();
  
  String _type = 'income'; // 'income' or 'expense'
  String _selectedCategory = 'Penjualan ternak';
  DateTime _selectedDate = DateTime.now();

  final List<String> _incomeCategories = [
    'Penjualan ternak',
    'Penjualan telur',
    'Penjualan susu',
    'Penjualan ikan',
    'Penjualan hasil samping',
    'Lainnya',
  ];

  final List<String> _expenseCategories = [
    'Pakan',
    'Obat',
    'Vitamin',
    'Bibit',
    'Listrik',
    'Air',
    'Transportasi',
    'Karyawan',
    'Lainnya',
  ];

  @override
  void initState() {
    super.initState();
    if (widget.existingCashflow != null) {
      _amountController.text = NumberFormat.decimalPattern('id').format(widget.existingCashflow!.amount);
      _descriptionController.text = widget.existingCashflow!.description ?? '';
      _type = widget.existingCashflow!.type;
      _selectedDate = widget.existingCashflow!.date;
      
      final currentCategories = _type == 'income' ? _incomeCategories : _expenseCategories;
      if (currentCategories.contains(widget.existingCashflow!.category)) {
        _selectedCategory = widget.existingCashflow!.category;
      } else {
        _selectedCategory = currentCategories.first;
      }
    } else {
      _selectedCategory = _incomeCategories.first;
    }
  }

  @override
  void dispose() {
    _amountController.dispose();
    _descriptionController.dispose();
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

  void _saveCashflow() {
    if (_formKey.currentState!.validate()) {
      final cashflow = Cashflow(
        id: widget.existingCashflow?.id ?? const Uuid().v4(),
        type: _type,
        amount: double.parse(_amountController.text.replaceAll('.', '')),
        category: _selectedCategory,
        description: _descriptionController.text.isEmpty ? null : _descriptionController.text,
        date: _selectedDate,
      );

      if (widget.existingCashflow == null) {
        ref.read(cashflowProvider.notifier).addCashflow(cashflow);
      } else {
        ref.read(cashflowProvider.notifier).updateCashflow(cashflow);
      }
      context.pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentCategories = _type == 'income' ? _incomeCategories : _expenseCategories;

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.existingCashflow == null ? 'Tambah Transaksi' : 'Edit Transaksi'),
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
                  'Detail Transaksi',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ),
                const SizedBox(height: 20),
                Row(
                  children: [
                    Expanded(
                      child: ChoiceChip(
                        label: const Center(
                          child: Text(
                            'Pemasukan',
                            style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                          ),
                        ),
                        selected: _type == 'income',
                        selectedColor: Colors.green.withOpacity(0.2),
                        checkmarkColor: Colors.green,
                        labelStyle: TextStyle(
                          color: _type == 'income' ? Colors.green : Colors.grey,
                        ),
                        onSelected: (selected) {
                          if (selected) {
                            setState(() {
                              _type = 'income';
                              _selectedCategory = _incomeCategories.first;
                            });
                          }
                        },
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ChoiceChip(
                        label: const Center(
                          child: Text(
                            'Pengeluaran',
                            style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                          ),
                        ),
                        selected: _type == 'expense',
                        selectedColor: Colors.red.withOpacity(0.2),
                        checkmarkColor: Colors.red,
                        labelStyle: TextStyle(
                          color: _type == 'expense' ? Colors.red : Colors.grey,
                        ),
                        onSelected: (selected) {
                          if (selected) {
                            setState(() {
                              _type = 'expense';
                              _selectedCategory = _expenseCategories.first;
                            });
                          }
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                TextFormField(
                  controller: _amountController,
                  keyboardType: TextInputType.number,
                  inputFormatters: [CurrencyInputFormatter()],
                  decoration: const InputDecoration(
                    labelText: 'Jumlah Transaksi (Rp)',
                    prefixIcon: Icon(Icons.payments_outlined),
                    hintText: 'Contoh: 150.000',
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) return 'Wajib diisi';
                    if (double.tryParse(value.replaceAll('.', '')) == null) return 'Harus berupa angka';
                    return null;
                  },
                ),
                const SizedBox(height: 18),
                DropdownButtonFormField<String>(
                  value: _selectedCategory,
                  isExpanded: true,
                  decoration: const InputDecoration(
                    labelText: 'Kategori Transaksi',
                    prefixIcon: Icon(Icons.category_outlined),
                  ),
                  dropdownColor: Theme.of(context).colorScheme.surface,
                  borderRadius: BorderRadius.circular(16),
                  icon: Icon(Icons.keyboard_arrow_down, color: Theme.of(context).colorScheme.secondary),
                  items: currentCategories.map((String category) {
                    return DropdownMenuItem<String>(
                      value: category,
                      child: Text(category, style: const TextStyle(fontWeight: FontWeight.w500)),
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
                const SizedBox(height: 18),
                TextFormField(
                  controller: _descriptionController,
                  decoration: const InputDecoration(
                    labelText: 'Keterangan / Catatan',
                    prefixIcon: Icon(Icons.description_outlined),
                    hintText: 'Contoh: Penjualan 10kg lele konsumsi',
                  ),
                ),
                const SizedBox(height: 18),
                InkWell(
                  onTap: () => _selectDate(context),
                  borderRadius: BorderRadius.circular(16),
                  child: InputDecorator(
                    decoration: const InputDecoration(
                      labelText: 'Tanggal Transaksi',
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
                  onPressed: _saveCashflow,
                  style: ElevatedButton.styleFrom(
                    minimumSize: const Size(double.infinity, 56),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: const Text(
                    'Simpan Transaksi',
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
