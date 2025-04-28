// --- Hive Type Adapter Generation ---
// This line tells the build_runner where to generate the adapter code.
// Make sure to run `flutter pub run build_runner build --delete-conflicting-outputs`
import 'package:hive/hive.dart';

part 'expense.g.dart'; // Generated file

// --- Data Model ---
@HiveType(typeId: 0) // Unique typeId for Hive
class Expense extends HiveObject { // Extend HiveObject for easy access to key/delete
  @HiveField(0) // Index for the field
  final double amount;

  @HiveField(1)
  final DateTime timestamp;

  Expense({required this.amount, required this.timestamp});

  @override
  String toString() {
    return 'Expense(amount: $amount, timestamp: $timestamp)';
  }
}