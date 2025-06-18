import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../hive/expense.dart';
import '../widgets/indicator.dart';

class AnalyticsPage extends StatelessWidget {
  final List<Expense> expenses;
  final String currencySymbol;

  const AnalyticsPage({
    super.key,
    required this.expenses,
    required this.currencySymbol,
  });

  @override
  Widget build(BuildContext context) {
    final Map<String, double> bankSpending = {};
    for (var expense in expenses) {
      final bank = expense.bankName ?? 'Other';
      bankSpending.update(bank, (value) => value + expense.amount, ifAbsent: () => expense.amount);
    }

    if (bankSpending.isEmpty) {
      return Scaffold(appBar: AppBar(title: const Text("Analytics")), body: const Center(child: Text("No data available for analytics.")));
    }

    final totalSpend = bankSpending.values.fold(0.0, (sum, amount) => sum + amount);

    return Scaffold(
      appBar: AppBar(title: const Text("Analytics"), centerTitle: true),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text("Spending by Bank (Percentage)", style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 32),
            SizedBox(
              height: 200,
              child: PieChart(
                PieChartData(
                  sections: bankSpending.entries.map((entry) {
                    final percentage = (entry.value / totalSpend) * 100;
                    return PieChartSectionData(
                      value: percentage,
                      title: '${percentage.toStringAsFixed(1)}%',
                      color: Colors.primaries[bankSpending.keys.toList().indexOf(entry.key) % Colors.primaries.length],
                      radius: 80,
                      titleStyle: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
                    );
                  }).toList(),
                  centerSpaceRadius: 40,
                  sectionsSpace: 2,
                ),
              ),
            ),
            const SizedBox(height: 24),
            Wrap(
              spacing: 8.0,
              runSpacing: 4.0,
              alignment: WrapAlignment.center,
              children: bankSpending.keys.map((bank) {
                return Indicator(
                  color: Colors.primaries[bankSpending.keys.toList().indexOf(bank) % Colors.primaries.length],
                  text: bank,
                  isSquare: false,
                );
              }).toList(),
            ),
            const Divider(height: 48, color: Colors.white24),
            Text("Spending by Bank (Amount)", style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 32),
            SizedBox(
              height: 250,
              child: BarChart(
                BarChartData(
                  alignment: BarChartAlignment.spaceEvenly,
                  maxY: (bankSpending.values.reduce((a, b) => a > b ? a : b) / 1000000).ceil() * 1000000,
                  barGroups: bankSpending.entries.map((entry) {
                    final index = bankSpending.keys.toList().indexOf(entry.key);
                    return BarChartGroupData(
                      x: index,
                      barRods: [ BarChartRodData(toY: entry.value.ceilToDouble(), color: Colors.tealAccent, width: 16) ],
                    );
                  }).toList(),
                  titlesData: FlTitlesData(
                    bottomTitles: AxisTitles(sideTitles: SideTitles(showTitles: true, getTitlesWidget: (value, meta) {
                      final index = value.toInt();
                      if (index >= 0 && index < bankSpending.keys.length) {
                        return Padding(padding: const EdgeInsets.only(top: 6.0), child: Text(bankSpending.keys.elementAt(index), style: const TextStyle(color: Colors.white70, fontSize: 10)));
                      }
                      return const Text('');
                    }, reservedSize: 38)),
                    leftTitles: AxisTitles(sideTitles: SideTitles(showTitles: true, reservedSize: 45)),
                    topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  ),
                  borderData: FlBorderData(show: false),
                  gridData: FlGridData(show: true, drawVerticalLine: false),
                ),
              ),
            ),
            const Divider(height: 48, color: Colors.white24),
            Text("Spending Summary", style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 16),
            ...bankSpending.entries.map((entry) {
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 4.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(entry.key, style: Theme.of(context).textTheme.bodyLarge),
                    Text(
                      NumberFormat.currency(locale: 'en_US', symbol: '$currencySymbol ').format(entry.value),
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              );
            }),
          ],
        ),
      ),
    );
  }
}