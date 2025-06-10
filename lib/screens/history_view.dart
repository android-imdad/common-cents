import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../expense.dart';
import '../services/expense_service.dart';

class HistoryView extends StatelessWidget {
  final List<Expense> expenses;
  final ExpenseService expenseService;
  final String currencySymbol;
  const HistoryView({super.key, required this.expenses, required this.expenseService, required this.currencySymbol});

  void _deleteExpenseItem(BuildContext context, Expense expense) {
    showDialog(context: context, builder: (ctx) {
      return AlertDialog(
        title: const Text('Confirm Deletion'),
        content: const Text('Are you sure you want to delete this expense?'),
        actions: <Widget>[
          TextButton(child: const Text('Cancel'), onPressed: () => Navigator.of(ctx).pop()),
          TextButton(
            style: TextButton.styleFrom(foregroundColor: Colors.redAccent),
            child: const Text('Delete'),
            onPressed: () async {
              await expenseService.deleteExpense(expense.key);
              Navigator.of(ctx).pop();
            },
          ),
        ],
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    if (expenses.isEmpty) return const Center(child: Text('No expenses recorded yet.', style: TextStyle(fontSize: 18, color: Colors.grey)));

    final sortedExpenses = List<Expense>.from(expenses)..sort((a, b) => b.timestamp.compareTo(a.timestamp));

    return ListView.builder(
      padding: const EdgeInsets.all(8.0),
      itemCount: sortedExpenses.length,
      itemBuilder: (context, index) {
        final expense = sortedExpenses[index];

        IconData leadingIcon;
        String primarySubtitle;
        String? secondarySubtitle;

        String bankText = expense.bankName != null ? ' • ${expense.bankName}' : '';
        String dateText = DateFormat.yMMMd().add_jm().format(expense.timestamp);

        switch(expense.transactionType) {
          case TransactionType.atmWithdrawal:
            leadingIcon = Icons.local_atm_outlined;
            primarySubtitle = expense.description ?? "Cash Withdrawal";
            break;
          case TransactionType.bankTransfer:
            leadingIcon = Icons.swap_horiz_outlined;
            primarySubtitle = expense.description ?? "Bank Transfer";
            break;
          default:
            leadingIcon = Icons.monetization_on_outlined;
            primarySubtitle = expense.description ?? "General Expense";
        }

        secondarySubtitle = '$dateText$bankText';

        return Card(
          margin: const EdgeInsets.symmetric(vertical: 6.0, horizontal: 8.0),
          child: ListTile(
            leading: Icon(leadingIcon, color: Colors.tealAccent),
            title: Text(
              NumberFormat.currency(locale: 'en_US', symbol: '$currencySymbol ').format(expense.amount),
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  primarySubtitle,
                  style: const TextStyle(fontSize: 14, color: Colors.white, fontWeight: FontWeight.w500),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                if (secondarySubtitle.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 2.0),
                    child: Text(
                      secondarySubtitle,
                      style: const TextStyle(fontSize: 12, color: Colors.white70),
                    ),
                  ),
              ],
            ),
            isThreeLine: true,
            trailing: IconButton(
              icon: Icon(Icons.delete_outline, color: Colors.red[300]),
              onPressed: () => _deleteExpenseItem(context, expense),
            ),
          ),
        );
      },
    );
  }
}