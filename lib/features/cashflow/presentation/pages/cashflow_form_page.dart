import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:uuid/uuid.dart';
import 'package:intl/intl.dart';
import '../../domain/models/cashflow.dart';
import '../providers/cashflow_provider.dart';

class CashflowFormPage extends ConsumerStatefulWidget {
  final Cashflow? existingCashflow;

  const CashflowFormPage({super.key, this.existingCashflow});

  @override
  ConsumerState<CashflowFormPage> createState() => _CashflowFormPageState();
}

class _CashflowFormPageState extends ConsumerState<CashflowFormPage> {
  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController();
  final _categoryController = TextEditingController();
  final _descriptionController = TextEditingController();
  
  String _type = 'income'; // 'income' or 'expense'
  DateTime _selectedDate = DateTime.now();

  @override
  void initState() {
    super.initState();
    if (widget.existingCashflow != null) {
      _amountController.text = widget.existingCashflow!.amount.toString();
      _categoryController.text = widget.existingCashflow!.category;
      _descriptionController.text = widget.existingCashflow!.description ?? '';
      _type = widget.existingCashflow!.type;
      _selectedDate = widget.existingCashflow!.date;
    }
  }

  @override
  void dispose() {
    _amountController.dispose();
    _categoryController.dispose();
    _descriptionController.dispose();
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

  void _saveCashflow() {
    if (_formKey.currentState!.validate()) {
      final cashflow = Cashflow(
        id: widget.existingCashflow?.id ?? const Uuid().v4(),
        type: _type,
        amount: double.parse(_amountController.text),
        category: _categoryController.text,
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
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.existingCashflow == null ? 'Tambah Keuangan' : 'Edit Keuangan'),
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
                Row(
                  children: [
                    Expanded(
                      child: RadioListTile<String>(
                        title: const Text('Pemasukan', style: TextStyle(fontSize: 14)),
                        value: 'income',
                        groupValue: _type,
                        contentPadding: EdgeInsets.zero,
                        onChanged: (value) {
                          setState(() {
                            _type = value!;
                          });
                        },
                      ),
                    ),
                    Expanded(
                      child: RadioListTile<String>(
                        title: const Text('Pengeluaran', style: TextStyle(fontSize: 14)),
                        value: 'expense',
                        groupValue: _type,
                        contentPadding: EdgeInsets.zero,
                        onChanged: (value) {
                          setState(() {
                            _type = value!;
                          });
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _amountController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Jumlah (Rp)',
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) => value == null || value.isEmpty ? 'Wajib diisi' : null,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _categoryController,
                  decoration: const InputDecoration(
                    labelText: 'Kategori (Misal: Pakan, Panen)',
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) => value == null || value.isEmpty ? 'Wajib diisi' : null,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _descriptionController,
                  decoration: const InputDecoration(
                    labelText: 'Catatan (Misal: Beli bibit dari Pak Wawa)',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 16),
                ListTile(
                  title: const Text('Tanggal'),
                  subtitle: Text(DateFormat('dd MMMM yyyy').format(_selectedDate)),
                  trailing: const Icon(Icons.calendar_today),
                  onTap: () => _selectDate(context),
                  shape: RoundedRectangleBorder(
                    side: const BorderSide(color: Colors.grey),
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: _saveCashflow,
                  style: ElevatedButton.styleFrom(
                    minimumSize: const Size(double.infinity, 50),
                  ),
                  child: const Text('Simpan'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
