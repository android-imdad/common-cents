import 'package:background_fetch/background_fetch.dart';
import 'package:common_cents/screens/average_spending_view.dart';
import 'package:common_cents/screens/current_spending_view.dart';
import 'package:common_cents/screens/history_view.dart';
import 'package:common_cents/screens/settings_view.dart';
import 'package:common_cents/services/settings_service.dart';
import 'package:common_cents/services/sms_service.dart';
import 'package:common_cents/widgets/add_expense_dialog_content.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import 'constants.dart';
import 'hive/expense.dart';
import 'logger.dart';
import 'services/expense_service.dart';

class MainScreen extends StatefulWidget {
  static const String TAG = "MainScreen";

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
    initPlatformState();
  }

  @override
  void dispose() {
    super.dispose();
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  // --- ADD EXPENSE DIALOG ---
  void _showAddExpenseDialog() {
    showGeneralDialog(
      context: context,
      transitionDuration: const Duration(milliseconds: 400),
      pageBuilder: (context, animation, secondaryAnimation) {
        final GlobalKey<AddExpenseDialogContentState> dialogKey = GlobalKey();
        return AlertDialog(
          scrollable: true,
          title: const Text('Add New Expense'),
          content: AddExpenseDialogContent(
            key: dialogKey,
            currencySymbol: SettingsService.currentCurrencySymbol.value,
            onAdd: (amount, dateTime, type, description, bankName) {
              _expenseService.addExpense(Expense(
                amount: amount,
                timestamp: dateTime,
                transactionType: type,
                description: description,
                bankName: bankName,
              ));
              Navigator.of(context).pop();
            },
          ),
          actions: [
            TextButton(child: const Text('Cancel'), onPressed: () => Navigator.of(context).pop()),
            TextButton(child: const Text('Add'), onPressed: () => dialogKey.currentState?.tryAddExpense()),
          ],
        );
      },
      transitionBuilder: (context, anim, _, child) => ScaleTransition(scale: CurvedAnimation(parent: anim, curve: Curves.easeOutBack), child: child),
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
        heroTag: "add_exp_fab",
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

  Future<void> initPlatformState() async {
    // Configure BackgroundFetch.
    int status = await BackgroundFetch.configure(BackgroundFetchConfig(
        minimumFetchInterval: 15,
        stopOnTerminate: false,
        enableHeadless: true,
        requiresBatteryNotLow: false,
        requiresCharging: false,
        requiresStorageNotLow: false,
        requiresDeviceIdle: false,
        requiredNetworkType: NetworkType.NONE
    ), (String taskId) async {  // <-- Event handler
      Logger.info(tag: "BackgroundFetch", text: "Event received $taskId");
      // This is the FG event. The headless task is separate.
      // Could trigger a manual sync here if needed.
      BackgroundFetch.finish(taskId);
    }, (String taskId) async {  // <-- Task timeout handler
      Logger.info(tag: "BackgroundFetch", text: "TASK TIMEOUT: $taskId");

      BackgroundFetch.finish(taskId);
    });
    Logger.info(tag: "BackgroundFetch", text: "configure success: $status");

    // If the user has auto-sync enabled, start the background fetch.
    if (SettingsService.getAutoSmsSync()) {
      BackgroundFetch.start();
      _syncOnStartup();
    }
  }


  Future<void> _syncOnStartup() async {
    Logger.info(tag: MainScreen.TAG, text: "_syncOnStartup Running auto-sync on startup...");
    try {
      final smsService = SmsService();
      int newCount = await smsService.syncExpensesFromSms(Constants.banksMap, _expenseService);
      Logger.info(tag: MainScreen.TAG, text: "_syncOnStartup Startup SMS sync complete. Added $newCount new expenses.");
    } catch (e) {
      Logger.error(tag: MainScreen.TAG, text: "_syncOnStartup Startup SMS sync failed: $e");
    }
  }

}