import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class AddExpenseDialogContent extends StatefulWidget {
  final Function(double amount, DateTime dateTime) onAdd; // Callback
  final String currencySymbol;
  const AddExpenseDialogContent({super.key, required this.onAdd, required this.currencySymbol});

  @override
  State<AddExpenseDialogContent> createState() => AddExpenseDialogContentState();
}

class AddExpenseDialogContentState extends State<AddExpenseDialogContent> {
  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController();
  late DateTime _selectedDateTime; // State variable for selected date/time

  @override
  void initState() {
    super.initState();
    _selectedDateTime = DateTime.now(); // Initialize with current date/time
  }

  @override
  void dispose() {
    _amountController.dispose();
    super.dispose();
  }

  // Function to show Date Picker
  Future<void> _pickDate(BuildContext context) async {
    final DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: _selectedDateTime,
      firstDate: DateTime(2000), // Allow picking dates far back
      lastDate: DateTime.now().add(const Duration(days: 365)), // Allow up to 1 year in future
      builder: (context, child) { // Optional: Theme the picker
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: Theme.of(context).colorScheme.copyWith(
              primary: Colors.tealAccent, // Header background
              onPrimary: Colors.black, // Header text
              onSurface: Colors.white70, // Body text
            ),
            dialogBackgroundColor: Colors.grey[850],
            textButtonTheme: TextButtonThemeData(
              style: TextButton.styleFrom(
                foregroundColor: Colors.tealAccent, // Button text
              ),
            ),
          ),
          child: child!,
        );
      },
    );
    if (pickedDate != null) {
      // Keep the time part from the original _selectedDateTime
      setState(() {
        _selectedDateTime = DateTime(
          pickedDate.year,
          pickedDate.month,
          pickedDate.day,
          _selectedDateTime.hour,
          _selectedDateTime.minute,
        );
      });
    }
  }

  // Function to show Time Picker
  Future<void> _pickTime(BuildContext context) async {
    final TimeOfDay? pickedTime = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(_selectedDateTime),
      builder: (context, child) { // Optional: Theme the picker
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: Theme.of(context).colorScheme.copyWith(
              primary: Colors.tealAccent, // Header background / Dial Hand
              onPrimary: Colors.black, // Header text
              onSurface: Colors.white, // Clock Dial text
              surface: Colors.grey[850], // Background of Dial
            ),
            dialogBackgroundColor: Colors.grey[850],
            timePickerTheme: TimePickerThemeData(
              dialHandColor: Colors.tealAccent,
              hourMinuteTextColor: MaterialStateColor.resolveWith((states) => states.contains(MaterialState.selected) ? Colors.black : Colors.white),
              hourMinuteColor: MaterialStateColor.resolveWith((states) => states.contains(MaterialState.selected) ? Colors.tealAccent : Colors.grey[800]!),
              dayPeriodTextColor: MaterialStateColor.resolveWith((states) => states.contains(MaterialState.selected) ? Colors.black : Colors.white),
              dayPeriodColor: MaterialStateColor.resolveWith((states) => states.contains(MaterialState.selected) ? Colors.tealAccent : Colors.grey[800]!),
              helpTextStyle: const TextStyle(color: Colors.white70), // "Select time" text
            ),
            textButtonTheme: TextButtonThemeData(
              style: TextButton.styleFrom(
                foregroundColor: Colors.tealAccent, // Button text
              ),
            ),
          ),
          child: child!,
        );
      },
    );
    if (pickedTime != null) {
      setState(() {
        _selectedDateTime = DateTime(
          _selectedDateTime.year,
          _selectedDateTime.month,
          _selectedDateTime.day,
          pickedTime.hour,
          pickedTime.minute,
        );
      });
    }
  }

  // Function to handle adding the expense
  void tryAddExpense() {
    if (_formKey.currentState!.validate()) {
      final double amount = double.parse(_amountController.text);
      widget.onAdd(amount, _selectedDateTime); // Use the callback
    }
  }

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat.yMMMd().add_jm(); // Format for displaying date/time

    return Form(
      key: _formKey,
      child: Column(
        mainAxisSize: MainAxisSize.min, // Prevent column from expanding infinitely
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Amount Input
          TextFormField(
            controller: _amountController,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            style: const TextStyle(color: Colors.white, fontSize: 18),
            decoration: InputDecoration(
              hintText: 'Enter amount',
              suffixText: widget.currencySymbol, // Use dynamic currency
            ),
            autofocus: true,
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Please enter an amount';
              }
              final double? amount = double.tryParse(value);
              if (amount == null) {
                return 'Please enter a valid number';
              }
              if (amount <= 0) {
                return 'Amount must be positive';
              }
              return null;
            },
          ),
          const SizedBox(height: 20),

          // Date Time Picker Row
          Text(
            'Date & Time:',
            style: Theme.of(context).textTheme.titleSmall?.copyWith(color: Colors.grey[400]),
          ),
          const SizedBox(height: 8),
          InkWell(
            onTap: () async {
              await _pickDate(context);
              // Check if mounted before calling async gap for time picker
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
                    dateFormat.format(_selectedDateTime),
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(color: Colors.white),
                  ),
                  const Icon(Icons.edit_calendar_outlined, color: Colors.tealAccent, size: 20),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}