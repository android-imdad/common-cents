import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../expense.dart';
import '../expense_service.dart';

class HistoryView extends StatelessWidget { // Can be StatelessWidget now
  final List<Expense> expenses;
  final ExpenseService expenseService;

  const HistoryView({
    super.key,
    required this.expenses,
    required this.expenseService,
  });

  // Method to handle deletion
  void _deleteExpenseItem(BuildContext context, Expense expense) {
    // Show confirmation dialog before deleting
    showDialog(
      context: context,
      builder: (BuildContext ctx) {
        return AlertDialog(
          title: const Text('Confirm Deletion'),
          content: Text('Are you sure you want to delete this expense of \$${expense.amount.toStringAsFixed(2)}?'),
          actions: <Widget>[
            TextButton(
              style: TextButton.styleFrom(foregroundColor: Colors.grey),
              child: const Text('Cancel'),
              onPressed: () {
                Navigator.of(ctx).pop(); // Close the dialog
              },
            ),
            TextButton(
              style: TextButton.styleFrom(foregroundColor: Colors.redAccent),
              child: const Text('Delete'),
              onPressed: () {
                // Use the expense's key (available because it extends HiveObject)
                expenseService.deleteExpense(expense.key).then((_) {
                  Navigator.of(ctx).pop(); // Close the dialog
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: const Text('Expense deleted.'),
                      backgroundColor: Colors.red[700],
                      duration: const Duration(seconds: 2),
                    ),
                  );
                }).catchError((error){
                  Navigator.of(ctx).pop(); // Close the dialog
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Error deleting expense: $error'),
                      backgroundColor: Colors.orange[800],
                      duration: const Duration(seconds: 3),
                    ),
                  );
                });
              },
            ),
          ],
        );
      },
    );
  }


  @override
  Widget build(BuildContext context) {
    debugPrint("Building HistoryView with ${expenses.length} expenses.");
    if (expenses.isEmpty) {
      return const Center(
        child: Text(
          'No expenses recorded yet.',
          style: TextStyle(fontSize: 18, color: Colors.grey),
        ),
      );
    }

    // Sort expenses by date, newest first (consider doing this in the service if list is large)
    final sortedExpenses = List<Expense>.from(expenses)
      ..sort((a, b) => b.timestamp.compareTo(a.timestamp));

    return ListView.builder(
      padding: const EdgeInsets.all(8.0),
      itemCount: sortedExpenses.length,
      itemBuilder: (context, index) {
        final expense = sortedExpenses[index];
        return Card(
          margin: const EdgeInsets.symmetric(vertical: 6.0, horizontal: 8.0),
          child: ListTile(
            leading: const Icon(Icons.monetization_on, color: Colors.tealAccent),
            title: Text(
              NumberFormat.currency(locale: 'en_US', symbol: '\$').format(expense.amount),
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
            ),
            subtitle: Text(
              DateFormat.yMMMd().add_jm().format(expense.timestamp), // Format date and time
              style: const TextStyle(fontSize: 14, color: Colors.white70),
            ),
            trailing: IconButton(
              icon: Icon(Icons.delete_outline, color: Colors.red[300]),
              onPressed: () => _deleteExpenseItem(context, expense), // Pass context and expense
              tooltip: 'Delete Expense',
            ),
          ),
        );
      },
    );
  }
}