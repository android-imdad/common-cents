import 'dart:io';

import 'package:another_telephony/telephony.dart';
import 'package:common_cents/services/settings_service.dart';
import 'package:flutter/cupertino.dart';

import '../expense.dart';
import 'currency_conversion_service.dart';
import 'expense_service.dart';

class SmsService {
  final Telephony telephony = Telephony.instance;

  final List<String> debitKeywords = ['debited', 'spent', 'purchase of', 'payment of', 'sent'];
  final RegExp generalAmountRegex = RegExp(r'(?:Rs|INR)\.?\s*([\d,]+\.?\d*)', caseSensitive: false);

  final RegExp sampathAuthPmtRegex = RegExp(r'Auth Pmt\s+([A-Z]{3})\s+([\d,]+\.?\d*)(?:\s+at\s+(.*?))?(?:\s*;|\s+on)', caseSensitive: false);
  final RegExp sampathDebitRegex = RegExp(r'([a-z]{3})\s+([\d,]+\.?\d*)\s+debited from ac \*\*[\d*]+ (via (?:pos at|atm at)|for) (.*?)(?:\s*-|\n|$)', caseSensitive: false);

  final RegExp hsbcAuthRegex = RegExp(r'txn auth amt\s*([a-z]{3})([\d,]+\.?\d*).*?(?: at (.*?))? on', caseSensitive: false);
  final RegExp hsbcCeftsRegex = RegExp(r'cefts trf of\s+([a-z]{3})\s+([\d,]+\.?\d*)', caseSensitive: false);
  final RegExp hsbcOldAuthRegex = RegExp(r'trx for the auth value of\s*([a-z]{3})([\d,]+\.?\d*).*?(?: at (.*?))? on', caseSensitive: false);
  final RegExp hsbcOldCeftsRegex = RegExp(r'your cefts transfer of\s+([a-z]{3})\s+([\d,]+\.?\d*)', caseSensitive: false);

  Future<int> syncExpensesFromSms(List<String> senderIds, ExpenseService expenseService) async {
    if (Platform.isIOS) throw Exception("SMS sync is not supported on iOS.");
    if (await telephony.requestSmsPermissions != true) throw Exception("SMS permission not granted.");

    List<SmsMessage> allMessages = [];
    for (String senderId in senderIds) {
      try {
        allMessages.addAll(await telephony.getInboxSms(
          columns: [SmsColumn.ADDRESS, SmsColumn.BODY, SmsColumn.DATE],
          filter: SmsFilter.where(SmsColumn.ADDRESS).equals(senderId),
          sortOrder: [OrderBy(SmsColumn.DATE, sort: Sort.DESC)],
        ));
      } catch(e) { debugPrint("Could not fetch SMS for sender $senderId. Error: $e"); }
    }

    int newExpensesCount = 0;
    final existingExpenses = expenseService.getAllExpenses();
    final shouldSyncTransfers = SettingsService.getSyncBankTransfers();
    final shouldSyncAtm = SettingsService.getSyncAtmWithdrawals();
    final defaultCurrencyCode = SettingsService.getCurrencyCode();

    for (var message in allMessages) {
      final messageBody = message.body?.toLowerCase() ?? '';
      final messageAddress = message.address?.toUpperCase() ?? '';
      double? originalAmount;
      String? transactionCurrencyCode;
      String? description;
      String? bankName;
      TransactionType type = TransactionType.general;

      RegExpMatch? match;

      if (messageAddress == 'HSBC') {
        bankName = 'HSBC';
        match = hsbcAuthRegex.firstMatch(messageBody) ?? hsbcOldAuthRegex.firstMatch(messageBody);
        if (match != null) {
          transactionCurrencyCode = match.group(1);
          originalAmount = double.tryParse(match.group(2)?.replaceAll(',', '') ?? '0');
          description = match.group(3)?.trim();
          type = TransactionType.general;
        } else {
          match = hsbcCeftsRegex.firstMatch(messageBody) ?? hsbcOldCeftsRegex.firstMatch(messageBody);
          if (match != null) {
            transactionCurrencyCode = match.group(1);
            originalAmount = double.tryParse(match.group(2)?.replaceAll(',', '') ?? '0');
            description = "CEFTS Transfer";
            type = TransactionType.bankTransfer;
          }
        }
      }
      else if (message.address == '8822') {
        bankName = 'Sampath Bank';
        match = sampathAuthPmtRegex.firstMatch(messageBody);
        if (match != null) {
          transactionCurrencyCode = match.group(1);
          originalAmount = double.tryParse(match.group(2)?.replaceAll(',', '') ?? '0');
          description = match.group(3)?.trim();
          type = TransactionType.general;
        } else {
          match = sampathDebitRegex.firstMatch(messageBody);
          if (match != null) {
            transactionCurrencyCode = match.group(1);
            originalAmount = double.tryParse(match.group(2)?.replaceAll(',', '') ?? '0');
            description = match.group(4)?.trim();
            String method = match.group(3) ?? '';

            if (method.contains('atm')) type = TransactionType.atmWithdrawal;
            else if (method.contains('for')) type = TransactionType.bankTransfer;
            else type = TransactionType.general;
          }
        }
      }
      else { // General Parser
        if (debitKeywords.any((keyword) => messageBody.contains(keyword))) {
          match = generalAmountRegex.firstMatch(messageBody);
          if (match != null) {
            originalAmount = double.tryParse(match.group(1)?.replaceAll(',', '') ?? '0');
            transactionCurrencyCode = defaultCurrencyCode;
            type = TransactionType.general;
          }
        }
      }

      if (type == TransactionType.bankTransfer && !shouldSyncTransfers) continue;
      if (type == TransactionType.atmWithdrawal && !shouldSyncAtm) continue;

      if (originalAmount != null && originalAmount > 0 && transactionCurrencyCode != null) {
        final double finalAmount = await CurrencyConversionService.convert(originalAmount, transactionCurrencyCode, defaultCurrencyCode);
        final timestamp = message.date != null ? DateTime.fromMillisecondsSinceEpoch(message.date!) : DateTime.now();

        bool alreadyExists = existingExpenses.any((exp) =>
        (exp.amount - finalAmount).abs() < 0.01 &&
            exp.timestamp.year == timestamp.year &&
            exp.timestamp.month == timestamp.month &&
            exp.timestamp.day == timestamp.day);

        if (!alreadyExists) {
          await expenseService.addExpense(Expense(amount: finalAmount, timestamp: timestamp, transactionType: type, description: description, bankName: bankName));
          newExpensesCount++;
        }
      }
    }
    debugPrint("SMS Sync complete. Added $newExpensesCount new expenses.");
    return newExpensesCount;
  }
}