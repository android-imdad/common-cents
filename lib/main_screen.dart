import 'package:common_cents/screens/average_spending_view.dart';
import 'package:common_cents/screens/current_spending_view.dart';
import 'package:common_cents/screens/history_view.dart';
import 'package:common_cents/widgets/add_expense_dialog_content.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import 'expense.dart';
import 'expense_service.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _selectedIndex = 0;
  final ExpenseService _expenseService = ExpenseService(); // Instance of the service
  late final ValueNotifier<List<Expense>> _expensesNotifier;

  @override
  void initState() {
    super.initState();
    // Get the notifier from the service
    _expensesNotifier = _expenseService.expensesNotifier;
    debugPrint("MainScreen initState: Got expenses notifier.");
  }

  @override
  void dispose() {
    // Although the box listener within the notifier handles updates,
    // explicitly remove listeners or dispose notifier if necessary in complex scenarios.
    // Hive box closing is handled globally usually on app exit, not here.
    // _expenseService.close(); // Avoid closing the box here if used elsewhere
    debugPrint("MainScreen dispose");
    super.dispose();
  }


  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  void _showAddExpenseDialog() {
    // Create a GlobalKey for the content widget to access its state if needed,
    // but we'll primarily use the callback.
    final GlobalKey<AddExpenseDialogContentState> dialogContentKey = GlobalKey();

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Add New Expense'),
          // Use the new stateful widget for the content
          content: AddExpenseDialogContent(
            key: dialogContentKey, // Assign the key
            // Define the callback function
            onAdd: (amount, dateTime) {
              final newExpense = Expense(amount: amount, timestamp: dateTime);
              _expenseService.addExpense(newExpense).then((_) {
                Navigator.of(context).pop(); // Close dialog on success
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Expense of \$${amount.toStringAsFixed(2)} added for ${DateFormat.yMd().format(dateTime)}.'), // Updated message
                    backgroundColor: Colors.green[700],
                    duration: const Duration(seconds: 2),
                  ),
                );
              }).catchError((error) {
                // Don't close dialog on error, let user retry or cancel
                // Navigator.of(context).pop(); // Keep dialog open
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Error adding expense: $error'),
                    backgroundColor: Colors.red[700],
                    duration: const Duration(seconds: 3),
                  ),
                );
              });
            },
          ),
          actions: <Widget>[
            TextButton(
              style: TextButton.styleFrom(foregroundColor: Colors.grey),
              child: const Text('Cancel'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: const Text('Add'),
              onPressed: () {
                // Trigger the validation and callback via the content widget's state
                dialogContentKey.currentState?.tryAddExpense();
              },
            ),
          ],
        );
      },
    );
  }

  // --- Build Method ---
  @override
  Widget build(BuildContext context) {
    // List of Titles for the AppBar
    final List<String> titles = <String>[
      'Current Spending',
      'Average Stats',
      'Spending History',
    ];

    return Scaffold(
      appBar: AppBar(
        title: Text(titles[_selectedIndex]),
      ),
      // Use ValueListenableBuilder to react to changes in expenses
      body: ValueListenableBuilder<List<Expense>>(
        valueListenable: _expensesNotifier,
        builder: (context, expenses, child) {
          debugPrint("ValueListenableBuilder rebuilding with ${expenses.length} expenses.");
          // Pass the current list of expenses and the service to the views
          final List<Widget> widgetOptions = <Widget>[
            CurrentSpendingView(expenses: expenses, expenseService: _expenseService),
            AverageStatsView(expenses: expenses, expenseService: _expenseService),
            HistoryView(expenses: expenses, expenseService: _expenseService),
          ];

          // AnimatedSwitcher for smooth transitions between views
          return AnimatedSwitcher(
            duration: const Duration(milliseconds: 350),
            transitionBuilder: (Widget child, Animation<double> animation) {
              // Fade and slight slide transition
              return FadeTransition(
                opacity: animation,
                child: SlideTransition(
                  position: Tween<Offset>(
                    begin: const Offset(0.0, 0.05), // Slide from bottom slightly
                    end: Offset.zero,
                  ).animate(animation),
                  child: child,
                ),
              );
            },
            child: Container( // Use Container instead of Center
              key: ValueKey<int>(_selectedIndex), // Keep the key
              alignment: Alignment.topLeft, // Explicitly align top-left (optional)
              child: widgetOptions.elementAt(_selectedIndex),
            ),
          );
        },
      ),
      bottomNavigationBar: BottomNavigationBar(
        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(
            icon: Icon(Icons.data_usage),
            label: 'Current',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.query_stats),
            label: 'Averages',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.history),
            label: 'History',
          ),
        ],
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddExpenseDialog,
        tooltip: 'Add Expense',
        child: const Icon(Icons.add),
      ),
    );
  }
}