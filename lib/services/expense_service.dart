import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'package:hive/hive.dart';
import 'package:hive_flutter/adapters.dart';
import 'package:path_provider/path_provider.dart';

import '../hive/expense.dart';
import '../logger.dart';

class ExpenseService {
  static const String TAG = "ExpenseService";

  static const String _boxName = 'expensesBox';
  static bool _isHiveInitialized = false; // Track initialization

  // --- Initialization ---
  static Future<void> initHive() async {
    // Prevent re-initialization
    if (_isHiveInitialized) {
      Logger.info(tag: TAG, text: "Hive already initialized.");
      // Ensure box is open if already initialized (e.g., hot restart)
      if (!Hive.isBoxOpen(_boxName)) {
        try {
          await Hive.openBox<Expense>(_boxName);
          Logger.info(tag: TAG, text: "Hive box '$_boxName' reopened successfully.");
        } catch (e) {
          Logger.error(tag: TAG, text: "Error reopening Hive box '$_boxName': $e");
        }
      }
      return;
    }

    Logger.info(tag: TAG, text: "Attempting to initialize Hive...");
    try {
      final Directory appDocumentDir = await getApplicationDocumentsDirectory();
      await Hive.initFlutter(appDocumentDir.path);
      Logger.info(tag: TAG, text: "Hive.initFlutter completed at path: ${appDocumentDir.path}");

      // Register the adapter generated by build_runner
      if (!Hive.isAdapterRegistered(ExpenseAdapter().typeId)) {
        Logger.info(tag: TAG, text: "Registering ExpenseAdapter...");
        Hive.registerAdapter(ExpenseAdapter());
        Logger.info(tag: TAG, text: "ExpenseAdapter registered.");
      } else {
        Logger.info(tag: TAG, text: "ExpenseAdapter already registered.");
      }

      // Open the box
      Logger.info(tag: TAG, text: "Opening Hive box '$_boxName'...");

      await Hive.openBox<Expense>(_boxName);
      _isHiveInitialized = true; // Mark as initialized

      Logger.info(tag: TAG, text: "Hive initialized and box '$_boxName' opened successfully.");
      Logger.info(tag: TAG, text: "Initial data in box: ${Hive.box<Expense>(_boxName).values.length} items.");

    } catch (e, stacktrace) {
      // Log detailed error during initialization
      Logger.error(tag: TAG, text: "############# HIVE INITIALIZATION ERROR #############");
      Logger.error(tag: TAG, text: "Error initializing Hive: $e");
      Logger.error(tag: TAG, text: "Stacktrace: $stacktrace");
      Logger.error(tag: TAG, text: "############# END HIVE ERROR #############");
      // Consider showing an error message to the user
    }
  }

  // --- Get Hive Box ---
  Box<Expense> get _expenseBox {
    if (!_isHiveInitialized || !Hive.isBoxOpen(_boxName)) {
      Logger.debug(tag: TAG, text: "WARNING: Accessing _expenseBox before Hive is fully initialized or box is open!");
      try {
        return Hive.box<Expense>(_boxName);
      } catch (e) {
        Logger.error(tag: TAG, text: "FATAL: Could not get Hive box '$_boxName'. Error: $e");
        // Depending on app structure, might need to throw or handle differently
        rethrow; // Rethrow the error to make the problem visible
      }
    }
    return Hive.box<Expense>(_boxName);
  }

  // --- Add Expense ---
  Future<void> addExpense(Expense expense) async {
    Logger.info(tag: TAG, text: "Attempting to add expense: $expense");
    try {
      final box = _expenseBox; // Get box instance
      final key = await box.add(expense);
      Logger.info(tag: TAG, text: "Expense added successfully with key: $key. Box size: ${box.length}");
    } catch (e, stacktrace) {
      Logger.error(tag: TAG, text: "############# HIVE ADD ERROR #############");
      Logger.error(tag: TAG, text: "Error adding expense: $e");
      Logger.error(tag: TAG, text: "Stacktrace: $stacktrace");
      Logger.error(tag: TAG, text: "############# END HIVE ERROR #############");
      // Rethrow or handle error appropriately
      rethrow;
    }
  }

  // --- Delete Expense ---
  Future<void> deleteExpense(dynamic key) async {
    Logger.info(tag: TAG, text: "Attempting to delete expense with key: $key");
    try {
      final box = _expenseBox; // Get box instance
      await box.delete(key);
      Logger.info(tag: TAG, text: "Expense deleted with key: $key. Box size: ${box.length}");
    } catch (e, stacktrace) {
      Logger.error(tag: TAG, text: "############# HIVE DELETE ERROR #############");
      Logger.error(tag: TAG, text: "Error deleting expense with key $key: $e");
      Logger.error(tag: TAG, text: "Stacktrace: $stacktrace");
      Logger.error(tag: TAG, text: "############# END HIVE ERROR #############");
      rethrow;
    }
  }

  // --- Get All Expenses ---
  ValueNotifier<List<Expense>> get expensesNotifier {
    Logger.info(tag: TAG, text: "Creating expensesNotifier...");

    if (!_isHiveInitialized || !_expenseBox.isOpen) {
      Logger.debug(tag: TAG, text: "WARNING: Creating expensesNotifier, but Hive box might not be ready.");
      // Return a notifier with an empty list initially if box isn't ready
      return ValueNotifier<List<Expense>>([]);
    }

    // Initial load
    final List<Expense> initialExpenses = _expenseBox.values.toList();
    Logger.info(tag: TAG, text: "Notifier initial load: ${initialExpenses.length} expenses from box.");
    final notifier = ValueNotifier<List<Expense>>(initialExpenses);

    // Listen for changes in the box and update the notifier
    try {
      final listener = _expenseBox.listenable();
      listener.addListener(() {
        final currentExpenses = _expenseBox.values.toList();
        Logger.info(tag: TAG, text: "Hive box listener triggered. Updating notifier with ${currentExpenses.length} expenses.");
        notifier.value = currentExpenses;
      });
      Logger.info(tag: TAG, text: "Attached listener to Hive box.");

    } catch (e) {
      Logger.error(tag: TAG, text: "Error attaching Hive listener: $e");
    }

    return notifier;
  }

  // --- Calculation Logic ---

  // Helper to check if a date is today
  bool _isToday(DateTime date) {
    final now = DateTime.now();
    return date.year == now.year && date.month == now.month && date.day == now.day;
  }

  // Helper to check if a date is within the current week (assuming Monday is start)
  bool _isThisWeek(DateTime date) {
    final now = DateTime.now();
    // Adjust 'now' to the start of the current week (Monday)
    final startOfWeek = now.subtract(Duration(days: now.weekday - 1));
    // Adjust 'date' to the start of its day to avoid time issues
    final dateOnly = DateTime(date.year, date.month, date.day);
    final startOfWeekOnly = DateTime(startOfWeek.year, startOfWeek.month, startOfWeek.day);
    // End of the week (Sunday)
    final endOfWeek = startOfWeekOnly.add(const Duration(days: 6));

    return dateOnly.isAfter(startOfWeekOnly.subtract(const Duration(days: 1))) && // >= Start of week
        dateOnly.isBefore(endOfWeek.add(const Duration(days: 1))); // <= End of week
  }


  // Helper to check if a date is within the last 30 days
  bool _isThisMonth(DateTime date) {
    final now = DateTime.now();
    return date.year == now.year && date.month == now.month;
  }

  // Helper to check if a date is within the current year
  bool _isThisYear(DateTime date) {
    final now = DateTime.now();
    return date.year == now.year;
  }

  // Calculate total spend for a given period filter
  double _calculateTotalSpend(bool Function(DateTime) filter, List<Expense> expenses) {
    return expenses
        .where((e) => filter(e.timestamp))
        .fold(0.0, (sum, item) => sum + item.amount);
  }

  // Calculate Daily Spend
  double getDailySpend(List<Expense> expenses) => _calculateTotalSpend(_isToday, expenses);

  // Calculate Weekly Spend
  double getWeeklySpend(List<Expense> expenses) => _calculateTotalSpend(_isThisWeek, expenses);

  // Calculate Monthly Spend
  double getMonthlySpend(List<Expense> expenses) => _calculateTotalSpend(_isThisMonth, expenses);

  // Calculate Yearly Spend
  double getYearlySpend(List<Expense> expenses) => _calculateTotalSpend(_isThisYear, expenses);


  // --- Average Calculation Logic ---
  Map<String, double> getAverageSpending(List<Expense> expenses) {
    if (expenses.isEmpty) {
      return {'daily': 0.0, 'weekly': 0.0, 'monthly': 0.0, 'yearly': 0.0};
    }

    final now = DateTime.now();

    // Helper function to calculate average over a period
    double calculateAverage(DateTime startDate, double divisor) {
      final relevantExpenses = expenses.where((e) => !e.timestamp.isBefore(startDate) && !e.timestamp.isAfter(now));
      if (relevantExpenses.isEmpty) return 0.0;
      final totalSpend = relevantExpenses.fold(0.0, (sum, item) => sum + item.amount);
      return totalSpend / divisor;
    }

    // Average Daily (last 2 months)
    final twoMonthsAgo = DateTime(now.year, now.month - 2, now.day);
    final daysInLastTwoMonths = now.difference(twoMonthsAgo).inDays;
    final avgDaily = calculateAverage(twoMonthsAgo, daysInLastTwoMonths > 0 ? daysInLastTwoMonths.toDouble() : 1.0);

    // Average Weekly (last 6 months)
    final sixMonthsAgo = DateTime(now.year, now.month - 6, now.day);
    final weeksInLastSixMonths = now.difference(sixMonthsAgo).inDays / 7;
    final avgWeekly = calculateAverage(sixMonthsAgo, weeksInLastSixMonths > 0 ? weeksInLastSixMonths : 1.0);

    // Average Monthly (last year)
    final lastYear = DateTime(now.year - 1, now.month, now.day);
    final avgMonthly = calculateAverage(lastYear, 12);

    // Average Yearly (last 3 years)
    final threeYearsAgo = DateTime(now.year - 3, now.month, now.day);
    final avgYearly = calculateAverage(threeYearsAgo, 3);

    return {
      'daily': avgDaily,
      'weekly': avgWeekly,
      'monthly': avgMonthly,
      'yearly': avgYearly,
    };
  }

  // --- Clear All Expenses ---
  Future<void> clearAllExpenses() async {
    Logger.info(tag: TAG, text: "Attempting to clear all expenses...");
    try {
      final box = _expenseBox;
      await box.clear();
      Logger.info(tag: TAG, text: "All expenses cleared successfully. Box size: ${box.length}");
    } catch (e, stacktrace) {

      Logger.error(tag: TAG, text: "############# HIVE CLEAR ERROR #############");
      Logger.error(tag: TAG, text: "Error clearing expense: $e");
      Logger.error(tag: TAG, text: "Stacktrace: $stacktrace");
      Logger.error(tag: TAG, text: "############# END HIVE ERROR #############");
      rethrow;
    }
  }

  List<Expense> getAllExpenses() {
    return _expenseBox.values.toList();
  }

  // --- Close Box ---
  Future<void> close() async {
    // Generally not needed to call manually unless specific cleanup is required
    try {
      if (_expenseBox.isOpen) {
        Logger.info(tag: TAG, text: "Attempting to close Hive box '$_boxName'...");
        await _expenseBox.close();
        Logger.info(tag: TAG, text: "Hive box '$_boxName' closed.");
      } else {
        Logger.info(tag: TAG, text: "Hive box '$_boxName' was already closed.");
      }
    } catch (e) {
      Logger.error(tag: TAG, text: "Error closing Hive box: $e");
    }
  }
}
