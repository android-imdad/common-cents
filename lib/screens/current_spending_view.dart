import 'package:animated_digit/animated_digit.dart';
import 'package:common_cents/screens/analytics_screen.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../hive/expense.dart';
import '../logger.dart';
import '../services/expense_service.dart';

class CurrentSpendingView extends StatefulWidget {
  final List<Expense> expenses;
  final ExpenseService expenseService;
  final String currencySymbol;
  const CurrentSpendingView({super.key, required this.expenses, required this.expenseService, required this.currencySymbol});

  @override
  State<CurrentSpendingView> createState() => _CurrentSpendingViewState();
}

class _CurrentSpendingViewState extends State<CurrentSpendingView> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Widget _buildSpendingItem(BuildContext context, String label, double amount) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Text(label, style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 4),
          AnimatedDigitWidget(value: amount, textStyle: Theme.of(context).textTheme.headlineMedium, duration: const Duration(milliseconds: 500), prefix: '${widget.currencySymbol} ', fractionDigits: 2, enableSeparator: true)
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: NestedScrollView(
        headerSliverBuilder: (context, innerBoxIsScrolled) {
          return [
            SliverToBoxAdapter(
              child: Column(
                children: [
                  TabBar(
                    controller: _tabController,
                    labelColor: Colors.tealAccent,
                    unselectedLabelColor: Colors.grey,
                    indicatorColor: Colors.tealAccent,
                    tabs: const [
                      Tab(text: "Week"),
                      Tab(text: "Month"),
                      Tab(text: "Year"),
                    ],
                  ),
                  SizedBox(
                    height: 300,
                    child: TabBarView(
                      controller: _tabController,
                      children: [
                        _buildBarChart(context, _getWeeklyChartData(), (value) => DateFormat('EEE').format(DateTime.now().subtract(Duration(days: 6 - value.toInt())))),
                        _buildBarChart(context, _getMonthlyChartData(), (value) => "W${value.toInt() + 1}"),
                        _buildBarChart(context, _getYearlyChartData(), (value) => DateFormat('MMM').format(DateTime(0, value.toInt() + 1))),
                      ],
                    ),
                  ),
                  const Divider(color: Colors.white24, height: 32),
                ],
              ),
            )
          ];
        },
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: <Widget>[
              _buildSpendingItem(context, 'Daily Spend', widget.expenseService.getDailySpend(widget.expenses)),
              _buildSpendingItem(context, 'Weekly Spend', widget.expenseService.getWeeklySpend(widget.expenses)),
              _buildSpendingItem(context, 'Monthly Spend (${DateFormat('MMM').format(DateTime.now())})', widget.expenseService.getMonthlySpend(widget.expenses)),
              _buildSpendingItem(context, 'Yearly Spend', widget.expenseService.getYearlySpend(widget.expenses)),
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        heroTag: "analytics_fab",
        onPressed: () {
          Navigator.of(context).push(MaterialPageRoute(
            builder: (context) => AnalyticsPage(
              expenses: widget.expenses,
              currencySymbol: widget.currencySymbol,
            ),
          ));
        },
        label: const Text('Analytics'),
        icon: const Icon(Icons.analytics_outlined),
        backgroundColor: Colors.grey[850],
        foregroundColor: Colors.white,
      ),
    );
  }

  // Data processing methods for charts
  List<double> _getWeeklyChartData() {
    final now = DateTime.now();
    List<double> dailyTotals = List.filled(7, 0.0);
    for (var expense in widget.expenses) {
      final daysAgo = now.difference(expense.timestamp).inDays;
      if (daysAgo >= 0 && daysAgo < 7) {
        dailyTotals[6 - daysAgo] += expense.amount.ceilToDouble();
      }
    }
    return dailyTotals;
  }

  List<double> _getMonthlyChartData() {
    final now = DateTime.now();
    List<double> weeklyTotals = List.filled(4, 0.0);
    for (var expense in widget.expenses) {
      final daysAgo = now.difference(expense.timestamp).inDays;
      if (daysAgo >= 0 && daysAgo < 28) {
        final weekIndex = (daysAgo / 7).floor();
        weeklyTotals[3 - weekIndex] += expense.amount.ceilToDouble();
      }
    }
    return weeklyTotals;
  }

  List<double> _getYearlyChartData() {
    final now = DateTime.now();
    List<double> monthlyTotals = List.filled(12, 0.0);
    for (var expense in widget.expenses) {
      if (expense.timestamp.year == now.year) {
        monthlyTotals[expense.timestamp.month - 1] += expense.amount.ceilToDouble();
      }
    }
    return monthlyTotals;
  }

  Widget _buildBarChart(BuildContext context, List<double> data, String Function(double) getTitle) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: BarChart(
        BarChartData(
          alignment: BarChartAlignment.spaceAround,
          maxY: data.isEmpty ? 10 : data.reduce((a, b) => a > b ? a : b) * 1.2,
          barTouchData: BarTouchData(
            touchTooltipData: BarTouchTooltipData(
              getTooltipItem: (group, groupIndex, rod, rodIndex) {
                String amountText = NumberFormat.currency(
                    locale: 'en_US',
                    symbol: '${widget.currencySymbol} '
                ).format(rod.toY);

                return BarTooltipItem(
                  amountText,
                  const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                );
              },
            ),
          ),
          barGroups: data.asMap().entries.map((entry) {
            return BarChartGroupData(
              x: entry.key,
              barRods: [ BarChartRodData(toY: entry.value, color: Colors.tealAccent, width: 16, borderRadius: BorderRadius.circular(4)) ],
            );
          }).toList(),
          titlesData: FlTitlesData(
            bottomTitles: AxisTitles(sideTitles: SideTitles(showTitles: true, getTitlesWidget: (value, meta) => Padding(padding: const EdgeInsets.only(top: 6.0), child: Text(getTitle(value), style: const TextStyle(color: Colors.white70, fontSize: 10))), reservedSize: 38)),
            leftTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
            topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
            rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
          ),
          borderData: FlBorderData(show: false),
          gridData: FlGridData(show: false),
        ),
      ),
    );
  }
}

