import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import '../expense.dart';
import '../expense_service.dart';
import '../widgets/spending_card.dart';

class AverageStatsView extends StatelessWidget {
  final List<Expense> expenses;
  final ExpenseService expenseService;

  const AverageStatsView({
    super.key,
    required this.expenses,
    required this.expenseService,
  });

  // Helper widget for the description text
  Widget _buildDescription(String text, BuildContext context) {
    return Text(
      text,
      textAlign: TextAlign.center,
      style: Theme.of(context).textTheme.bodySmall?.copyWith(
        color: Colors.grey[500], // Lighter grey for description
        fontSize: 12, // Smaller font size
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    debugPrint("Building AverageStatsView with ${expenses.length} expenses.");
    final averages = expenseService.getAverageSpending(expenses);
    const cardPadding = EdgeInsets.symmetric(vertical: 4.0); // Reduced vertical padding between card and text
    const descriptionPadding = EdgeInsets.only(top: 4.0, bottom: 12.0); // Padding below description

    return SingleChildScrollView( // Added ScrollView in case content overflows on small screens
      padding: const EdgeInsets.all(16.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          // Daily Average Card + Description
          Padding(
            padding: cardPadding,
            child: SpendingCard(
              title: 'Average Daily',
              amount: averages['daily'] ?? 0.0,
            ),
          ),
          Padding(
            padding: descriptionPadding,
            child: _buildDescription('(Based on last 30 days)', context),
          ),
          // const SizedBox(height: 8), // Reduced space

          // Weekly Average Card + Description
          Padding(
            padding: cardPadding,
            child: SpendingCard(
              title: 'Average Weekly',
              amount: averages['weekly'] ?? 0.0,
            ),
          ),
          Padding(
            padding: descriptionPadding,
            child: _buildDescription('(Based on last 4 weeks)', context),
          ),
          // const SizedBox(height: 8),

          // Monthly Average Card + Description
          Padding(
            padding: cardPadding,
            child: SpendingCard(
              title: 'Average Monthly',
              amount: averages['monthly'] ?? 0.0,
            ),
          ),
          Padding(
            padding: descriptionPadding,
            child: _buildDescription('(Based on last 3 months)', context),
          ),
          // const SizedBox(height: 8),

          // Yearly Average Card + Description
          Padding(
            padding: cardPadding,
            child: SpendingCard(
              title: 'Average Yearly',
              amount: averages['yearly'] ?? 0.0,
            ),
          ),
          Padding(
            padding: descriptionPadding,
            child: _buildDescription('(Est. based on last 3 months avg)', context),
          ),
        ],
      ),
    );
  }
}
