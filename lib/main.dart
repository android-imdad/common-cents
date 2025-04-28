import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

import 'app.dart';
import 'expense_service.dart';


Future<void> main() async {
  debugPrint("App starting...");
  // Ensure Flutter bindings are initialized before using plugins
  WidgetsFlutterBinding.ensureInitialized();
  debugPrint("WidgetsFlutterBinding initialized.");
  // Initialize Hive before running the app
  await ExpenseService.initHive(); // Wait for initialization
  debugPrint("Hive initialization awaited in main.");
  runApp(const BudgetApp());
  debugPrint("runApp executed.");
}