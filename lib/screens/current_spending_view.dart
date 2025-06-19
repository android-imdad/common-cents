import 'package:animated_digit/animated_digit.dart';
import 'package:common_cents/screens/analytics_screen.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../hive/expense.dart';
import '../logger.dart';
import '../services/expense_service.dart';

class CurrentSpendingView extends StatelessWidget {
  static const String TAG = "CurrentSpendingView";


  final List<Expense> expenses;
  final ExpenseService expenseService;
  final String currencySymbol;

  const CurrentSpendingView({
    super.key,
    required this.expenses,
    required this.expenseService, required this.currencySymbol,
  });

  // Helper widget for building each spending item (label above amount)
  Widget _buildSpendingItem(BuildContext context, String label, double amount) {
    final theme = Theme.of(context);
    final currencyFormat = NumberFormat.currency(locale: 'en_US', symbol: '\$');

    return Padding(
      // Add padding below each item
      padding: const EdgeInsets.only(bottom: 24.0),
      child: Column(
        // Align children to the start (left)
        crossAxisAlignment: CrossAxisAlignment.center,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            label,
            // Use a smaller text style for the label
            style: theme.textTheme.titleMedium?.copyWith(color: Colors.teal), // e.g., 16pt normal greyish
          ),
          const SizedBox(height: 4), // Small space between label and amount
          AnimatedDigitWidget(
            value: amount,
            textStyle: theme.textTheme.headlineMedium?.copyWith(fontSize: 40), // e.g., 32pt bold white
            duration: const Duration(milliseconds: 500), // Animation duration
            fractionDigits: 2,
            enableSeparator: true, // Adds commas for thousands
            separateSymbol: ',',
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    Logger.info(tag: TAG, text: "Building CurrentSpendingView with ${expenses.length} expenses.");
    return Scaffold(
      backgroundColor: Colors.black,
      body: Center( // Center the scrollable content
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: <Widget>[
              _buildSpendingItem(context, 'Daily Spend', expenseService.getDailySpend(expenses)),
              _buildSpendingItem(context, 'Weekly Spend', expenseService.getWeeklySpend(expenses)),
              _buildSpendingItem(context, 'Monthly Spend', expenseService.getMonthlySpend(expenses)),
              _buildSpendingItem(context, 'Yearly Spend', expenseService.getYearlySpend(expenses)),
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          Navigator.of(context).push(MaterialPageRoute(
            builder: (context) => AnalyticsPage(
              expenses: expenses,
              currencySymbol: currencySymbol,
            ),
          ));
        },
        heroTag: 'analytics_fab',
        label: const Text('Analytics'),
        icon: const Icon(Icons.analytics_outlined),
        backgroundColor: Colors.grey[850],
        foregroundColor: Colors.white,
      ),
    );
  }
}
