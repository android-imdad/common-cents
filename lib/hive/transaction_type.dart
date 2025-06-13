import 'package:hive/hive.dart';


part 'transaction_type.g.dart'; // Generated file

@HiveType(typeId: 2)
enum TransactionType {
  @HiveField(0)
  general,

  @HiveField(1)
  bankTransfer,

  @HiveField(2)
  atmWithdrawal,
}