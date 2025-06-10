import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import '../expense.dart';
import '../services/expense_service.dart';
import '../widgets/spending_card.dart';

class AverageStatsView extends StatelessWidget {
  final List<Expense> expenses;
  final ExpenseService expenseService;
  final String currencySymbol;
  const AverageStatsView({super.key, required this.expenses, required this.expenseService, required this.currencySymbol});

  Widget _buildDescription(String text, BuildContext context) {
    return Text(
      text,
      textAlign: TextAlign.center,
      style: Theme.of(context).textTheme.bodySmall?.copyWith(
        color: Colors.grey[500],
        fontSize: 12,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final averages = expenseService.getAverageSpending(expenses);
    const cardPadding = EdgeInsets.symmetric(vertical: 4.0);
    const descriptionPadding = EdgeInsets.only(top: 4.0, bottom: 12.0);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Padding(
            padding: cardPadding,
            child: SpendingCard(
              title: 'Average Daily',
              amount: averages['daily'] ?? 0.0,
              currencySymbol: currencySymbol,
            ),
          ),
          Padding(
            padding: descriptionPadding,
            child: _buildDescription('(Based on last 2 months)', context),
          ),
          Padding(
            padding: cardPadding,
            child: SpendingCard(
              title: 'Average Weekly',
              amount: averages['weekly'] ?? 0.0,
              currencySymbol: currencySymbol,
            ),
          ),
          Padding(
            padding: descriptionPadding,
            child: _buildDescription('(Based on last 6 months)', context),
          ),
          Padding(
            padding: cardPadding,
            child: SpendingCard(
              title: 'Average Monthly',
              amount: averages['monthly'] ?? 0.0,
              currencySymbol: currencySymbol,
            ),
          ),
          Padding(
            padding: descriptionPadding,
            child: _buildDescription('(Based on last year)', context),
          ),
          Padding(
            padding: cardPadding,
            child: SpendingCard(
              title: 'Average Yearly',
              amount: averages['yearly'] ?? 0.0,
              currencySymbol: currencySymbol,
            ),
          ),
          Padding(
            padding: descriptionPadding,
            child: _buildDescription('(Based on last 3 years)', context),
          ),
        ],
      ),
    );
  }
}
