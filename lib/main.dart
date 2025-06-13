import 'package:common_cents/services/settings_service.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hive/hive.dart';
import 'package:hive_flutter/adapters.dart';
import 'package:intl/intl.dart';

import 'app.dart';
import 'hive/expense.dart';
import 'hive/transaction_type.dart';
import 'services/expense_service.dart';


Future<void> main() async {

  WidgetsFlutterBinding.ensureInitialized();
  await Hive.initFlutter();

  // Ensure both adapters are registered before opening the box
  if (!Hive.isAdapterRegistered(ExpenseAdapter().typeId)) {
    Hive.registerAdapter(ExpenseAdapter());
  }
  if (!Hive.isAdapterRegistered(TransactionTypeAdapter().typeId)) {
    Hive.registerAdapter(TransactionTypeAdapter());
  }

  await Hive.openBox<Expense>('expensesBox');
  await SettingsService.init();
  await ExpenseService.initHive();
  runApp(const BudgetApp());
}