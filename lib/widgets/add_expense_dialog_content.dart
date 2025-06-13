import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../hive/expense.dart';
import '../hive/transaction_type.dart';

class AddExpenseDialogContent extends StatefulWidget {
  final Function(double, DateTime, TransactionType, String?, String?) onAdd;
  final String currencySymbol;
  const AddExpenseDialogContent({super.key, required this.onAdd, required this.currencySymbol});
  @override
  State<AddExpenseDialogContent> createState() => AddExpenseDialogContentState();
}
class AddExpenseDialogContentState extends State<AddExpenseDialogContent> {
  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController();
  final _bankNameController = TextEditingController();
  final _descriptionController = TextEditingController();
  late DateTime _selectedDateTime;
  TransactionType _selectedType = TransactionType.general;

  @override
  void initState() { super.initState(); _selectedDateTime = DateTime.now(); }
  @override
  void dispose() {
    _amountController.dispose();
    _bankNameController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  void tryAddExpense() {
    if (_formKey.currentState!.validate()) {
      final String? bankName = _bankNameController.text.isNotEmpty ? _bankNameController.text : null;
      final String? description = _descriptionController.text.isNotEmpty ? _descriptionController.text : null;
      widget.onAdd(
        double.parse(_amountController.text),
        _selectedDateTime,
        _selectedType,
        description,
        bankName,
      );
    }
  }

  Future<void> _pickDate(BuildContext context) async {
    final DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: _selectedDateTime,
      firstDate: DateTime(2000),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (pickedDate != null) {
      setState(() {
        _selectedDateTime = DateTime(
          pickedDate.year, pickedDate.month, pickedDate.day,
          _selectedDateTime.hour, _selectedDateTime.minute,
        );
      });
    }
  }

  Future<void> _pickTime(BuildContext context) async {
    final TimeOfDay? pickedTime = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(_selectedDateTime),
    );
    if (pickedTime != null) {
      setState(() {
        _selectedDateTime = DateTime(
          _selectedDateTime.year, _selectedDateTime.month, _selectedDateTime.day,
          pickedTime.hour, pickedTime.minute,
        );
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    String toBeginningOfSentenceCase(String input) {
      if (input.isEmpty) return '';
      return input[0].toUpperCase() + input.substring(1);
    }

    return Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextFormField(
              controller: _amountController,
              decoration: InputDecoration(prefixText: '${widget.currencySymbol} ', labelText: "Amount"),
              keyboardType: TextInputType.numberWithOptions(decimal: true),
              autofocus: true,
              validator: (value) {
                if (value == null || value.isEmpty) return 'Please enter an amount';
                if (double.tryParse(value) == null) return 'Please enter a valid number';
                return null;
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _descriptionController,
              decoration: const InputDecoration(labelText: 'Description'),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _bankNameController,
              decoration: const InputDecoration(labelText: 'Bank Name (Optional)'),
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<TransactionType>(
              value: _selectedType,
              decoration: const InputDecoration(labelText: 'Transaction Type'),
              items: TransactionType.values.map((type) {
                return DropdownMenuItem(
                  value: type,
                  child: Text(toBeginningOfSentenceCase(type.toString().split('.').last)),
                );
              }).toList(),
              onChanged: (TransactionType? newValue) {
                if (newValue != null) {
                  setState(() { _selectedType = newValue; });
                }
              },
            ),
            const SizedBox(height: 16),
            InkWell(
              onTap: () async {
                await _pickDate(context);
                if (!mounted) return;
                await _pickTime(context);
              },
              borderRadius: BorderRadius.circular(8.0),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 8.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      DateFormat.yMMMd().add_jm().format(_selectedDateTime),
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const Icon(Icons.edit_calendar_outlined, color: Colors.tealAccent, size: 20),
                  ],
                ),
              ),
            ),
          ],
        )
    );
  }
}