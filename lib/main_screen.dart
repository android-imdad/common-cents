import 'package:common_cents/screens/average_spending_view.dart';
import 'package:common_cents/screens/current_spending_view.dart';
import 'package:common_cents/screens/history_view.dart';
import 'package:common_cents/screens/settings_view.dart';
import 'package:common_cents/services/settings_service.dart';
import 'package:common_cents/widgets/add_expense_dialog_content.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import 'expense.dart';
import 'services/expense_service.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});
  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _selectedIndex = 0;
  final ExpenseService _expenseService = ExpenseService();
  late final ValueNotifier<List<Expense>> _expensesNotifier;

  @override
  void initState() {
    super.initState();
    _expensesNotifier = _expenseService.expensesNotifier;
    _expensesNotifier.addListener(_handleNotifierChange);
  }

  void _handleNotifierChange(){
  }

  @override
  void dispose() {
    _expensesNotifier.removeListener(_handleNotifierChange);
    super.dispose();
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  // --- ADD EXPENSE DIALOG ---
  void _showAddExpenseDialog() {
    final GlobalKey<AddExpenseDialogContentState> dialogContentKey = GlobalKey();

    showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: MaterialLocalizations.of(context).modalBarrierDismissLabel,
      transitionDuration: const Duration(milliseconds: 400),
      pageBuilder: (context, animation, secondaryAnimation) {
        return AlertDialog(
          title: const Text('Add New Expense'),
          content: AddExpenseDialogContent(
            key: dialogContentKey,
            onAdd: (amount, dateTime) {
              final newExpense = Expense(amount: amount, timestamp: dateTime);
              _expenseService.addExpense(newExpense).then((_) {
                Navigator.of(context).pop();
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Expense of ${amount.toStringAsFixed(2)} ${SettingsService.currentCurrencySymbol.value} added for ${DateFormat.yMd().format(dateTime)}.'),
                    backgroundColor: Colors.green[700],
                    duration: const Duration(seconds: 2),
                  ),
                );
              }).catchError((error) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Error adding expense: $error'),
                    backgroundColor: Colors.red[700],
                    duration: const Duration(seconds: 3),
                  ),
                );
              });
            }, currencySymbol: SettingsService.currentCurrencySymbol.value,
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
                dialogContentKey.currentState?.tryAddExpense();
              },
            ),
          ],
        );
      },
      transitionBuilder: (context, animation, secondaryAnimation, child) {
        // Use a scale transition for a "zoom" effect
        return ScaleTransition(
          scale: CurvedAnimation(
            parent: animation,
            curve: Curves.easeOutBack, // A nice "bouncy" curve
            reverseCurve: Curves.easeOutBack,
          ),
          child: child,
        );
      },
    );
  }

  // Helper widget for building navigation items
  Widget _buildNavItem({required IconData icon, required int index, required String label}) {
    final isSelected = _selectedIndex == index;
    final color = isSelected ? Colors.tealAccent : Colors.grey[600];
    return InkWell(
      onTap: () => _onItemTapped(index),
      borderRadius: BorderRadius.circular(50), // For a circular ripple effect
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: color),
            const SizedBox(height: 4),
            Text(label, style: TextStyle(color: color, fontSize: 12)),
          ],
        ),
      ),
    );
  }

  // --- MODIFIED Build Method ---
  @override
  Widget build(BuildContext context) {
    final List<String> titles = <String>[
      'Current Spending (${SettingsService.currentCurrencySymbol.value})',
      'Average Stats (${SettingsService.currentCurrencySymbol.value})',
      'Spending History (${SettingsService.currentCurrencySymbol.value})',
      'Settings'
    ];

    return Scaffold(
      appBar: AppBar(
        title: Text(titles[_selectedIndex]),
        centerTitle: true,
      ),
      body: ValueListenableBuilder<String>(
          valueListenable: SettingsService.currentCurrencySymbol,
          builder: (context, currencySymbol, _) {
            return ValueListenableBuilder<List<Expense>>(
              valueListenable: _expensesNotifier,
              builder: (context, expenses, child) {
                final List<Widget> widgetOptions = [
                  CurrentSpendingView(expenses: expenses, expenseService: _expenseService, currencySymbol: currencySymbol),
                  AverageStatsView(expenses: expenses, expenseService: _expenseService, currencySymbol: currencySymbol),
                  HistoryView(expenses: expenses, expenseService: _expenseService, currencySymbol: currencySymbol),
                  SettingsView(expenseService: _expenseService),
                ];
                return AnimatedSwitcher(
                  duration: const Duration(milliseconds: 350),
                  transitionBuilder: (Widget child, Animation<double> animation) {
                    return FadeTransition(opacity: animation, child: SlideTransition(position: Tween<Offset>(begin: const Offset(0.0, 0.05), end: Offset.zero).animate(animation), child: child));
                  },
                  child: Center(key: ValueKey<int>(_selectedIndex), child: widgetOptions.elementAt(_selectedIndex)),
                );
              },
            );
          }
      ),
      // --- INTEGRATED FAB AND BOTTOM APP BAR ---
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddExpenseDialog,
        tooltip: 'Add Expense',
        shape: const CircleBorder(),
        child: const Icon(Icons.add),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      bottomNavigationBar: BottomAppBar(
        shape: const CircularNotchedRectangle(),
        notchMargin: 8.0,
        color: Colors.grey[900],
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: <Widget>[
            _buildNavItem(icon: Icons.data_usage, index: 0, label: 'Current'),
            _buildNavItem(icon: Icons.query_stats, index: 1, label: 'Averages'),
            const SizedBox(width: 48), // The space for the notch
            _buildNavItem(icon: Icons.history, index: 2, label: 'History'),
            _buildNavItem(icon: Icons.settings_outlined, index: 3, label: 'Settings'),
          ],
        ),
      ),
    );
  }
}