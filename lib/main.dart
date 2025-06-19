import 'package:background_fetch/background_fetch.dart';
import 'package:common_cents/constants.dart';
import 'package:common_cents/services/settings_service.dart';
import 'package:common_cents/services/sms_service.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hive/hive.dart';
import 'package:hive_flutter/adapters.dart';
import 'package:intl/intl.dart';

import 'app.dart';
import 'hive/expense.dart';
import 'hive/transaction_type.dart';
import 'logger.dart';
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

  BackgroundFetch.registerHeadlessTask(backgroundFetchHeadlessTask);

}

@pragma('vm:entry-point')
void backgroundFetchHeadlessTask(HeadlessTask task) async {
  String taskId = task.taskId;
  bool isTimeout = task.timeout;
  if (isTimeout) {
    Logger.info(tag: "BackgroundFetchHeadlessTask",text: "timed out: $taskId");
    BackgroundFetch.finish(taskId);
    return;
  }

  Logger.info(tag: "BackgroundFetchHeadlessTask",text: "HeadlessTask: $taskId");

  // Initialize services for the background task
  await Hive.initFlutter();
  if (!Hive.isAdapterRegistered(ExpenseAdapter().typeId)) Hive.registerAdapter(ExpenseAdapter());
  if (!Hive.isAdapterRegistered(TransactionTypeAdapter().typeId)) Hive.registerAdapter(TransactionTypeAdapter());
  await Hive.openBox<Expense>('expensesBox');
  await SettingsService.init();
  await ExpenseService.initHive();

  // Only run the sync if the setting is enabled
  if (SettingsService.getAutoSmsSync()) {
    try {
      final smsService = SmsService();
      final expenseService = ExpenseService();

      int newCount = await smsService.syncExpensesFromSms(Constants.banksMap, expenseService);
      Logger.info(tag: "BackgroundFetchHeadlessTask",text: "Background SMS sync complete. Added $newCount new expenses.");
    } catch (e) {
      Logger.error(tag: "BackgroundFetchHeadlessTask",text: "Background SMS sync failed: $e");
    }
  } else {
    Logger.info(tag: "BackgroundFetchHeadlessTask",text: "Auto SMS sync is disabled. Skipping task.");
  }

  BackgroundFetch.finish(taskId);
}