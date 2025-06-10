// --- Hive Type Adapter Generation ---
// This line tells the build_runner where to generate the adapter code.
// Make sure to run `flutter pub run build_runner build --delete-conflicting-outputs`
import 'package:hive/hive.dart';

part 'expense.g.dart'; // Generated file


@HiveType(typeId: 2)
enum TransactionType {
  @HiveField(0)
  general,

  @HiveField(1)
  bankTransfer,

  @HiveField(2)
  atmWithdrawal,
}

// --- Data Model ---
@HiveType(typeId: 0)
class Expense extends HiveObject {
  @HiveField(0)
  final double amount;

  @HiveField(1)
  final DateTime timestamp;

  @HiveField(2)
  final TransactionType transactionType;

  @HiveField(3)
  final String? description;

  @HiveField(4) // New field for bank name
  final String? bankName;

  Expense({
    required this.amount,
    required this.timestamp,
    this.transactionType = TransactionType.general,
    this.description,
    this.bankName,
  });

  @override
  String toString() {
    return 'Expense(amount: $amount, timestamp: $timestamp, type: $transactionType, desc: $description, bank: $bankName)';
  }
}