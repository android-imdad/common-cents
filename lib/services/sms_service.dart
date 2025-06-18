import 'dart:io';

import 'package:another_telephony/telephony.dart';
import 'package:common_cents/services/settings_service.dart';
import 'package:flutter/cupertino.dart';

import '../hive/expense.dart';
import '../hive/transaction_type.dart';
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

  final RegExp hnbAtmRegex = RegExp(r'hnb atm withdrawal e-receipt.*?amt\(approx\.\):\s*([\d,]+\.?\d*)\s*([a-z]{3}).*?location:\s*(.*?),\s*lka', caseSensitive: false, dotAll: true);
  final RegExp hnbPurchaseRegex = RegExp(r'purchase,.*?location:(.*?),.*?amount\(approx\.\):([\d,]+\.?\d*)\s*([a-z]{3})', caseSensitive: false);
  final RegExp hnbDebitReasonRegex = RegExp(r'([a-z]{3})\s+([\d,]+\.?\d*)\s+debited.*?reason:mb:(.*?)\s+bal:', caseSensitive: false);
  final RegExp hnbDebitOnlineRegex = RegExp(r'([a-z]{3})\s+([\d,]+\.?\d*)\s+debited.*?reason:(.*?)\/', caseSensitive: false);
  final RegExp hnbDebitChargeRegex = RegExp(r'a transaction for\s+([a-z]{3})\s+([\d,]+\.?\d*)\s+has been debit ed.*?remarks\s*:(.*?)\.bal:', caseSensitive: false);

  final RegExp ntbCeftsRegex = RegExp(r'other bank transfer \(cefts\) was performed.*? for ([a-z]{3})\s+([\d,]+\.?\d*)', caseSensitive: false);
  final RegExp ntbPosRegex = RegExp(r'master dr card foreign pos was performed.*? for ([a-z]{3})\s+([\d,]+\.?\d*)', caseSensitive: false);
  final RegExp ntbPerformedRegex = RegExp(r'^(.*?) was performed.*? for ([a-z]{3})\s+([\d,]+\.?\d*)', caseSensitive: false);
  final RegExp ntbApprovedRegex = RegExp(r'a transaction of ([a-z]{3})\s+([\d,]+\.?\d*) was approved.*? at (.*?)\. current bal', caseSensitive: false);

  final RegExp bocTransferRegex = RegExp(r'(online transfer debit|transfer debit|transfer order debit)\s+(?:(rs|lkr|aud)\s+)?([\d,]+\.?\d*)', caseSensitive: false);
  final RegExp bocPosAtmRegex = RegExp(r'(pos\/atm transaction|atm withdrawal) rs\s+([\d,]+\.?\d*)', caseSensitive: false);
  final RegExp bocApprovedRegex = RegExp(r'a transaction of ([a-z]{3})\s+([\d,]+\.?\d*) was approved.*? at (.*?)\. current bal', caseSensitive: false);

  final RegExp commBankPurchaseRegex = RegExp(r'purchase at (.*?) for ([a-z]{3})\s+([\d,]+\.?\d*)', caseSensitive: false);

  Future<int> syncExpensesFromSms(Map<String, String> senderMap, ExpenseService expenseService) async {
    if (Platform.isIOS) throw Exception("SMS sync is not supported on iOS.");
    if (await telephony.requestSmsPermissions != true) throw Exception("SMS permission not granted.");

    List<SmsMessage> allMessages = [];
    List<String> enabledSenderIds = senderMap.keys.where((id) => SettingsService.isBankEnabled(id)).toList();

    for (String senderId in enabledSenderIds) {
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
    debugPrint("SMS in progress. allMessages ${allMessages.length}.");

    for (var message in allMessages) {
      final messageBody = message.body?.toLowerCase() ?? '';
      final messageAddress = message.address?.toUpperCase() ?? '';
      double? originalAmount;
      String? transactionCurrencyCode;
      String? description;
      String? bankName = senderMap[message.address];
      TransactionType type = TransactionType.general;

      RegExpMatch? match;
      if (bankName == 'Commercial Bank') {
        match = commBankPurchaseRegex.firstMatch(messageBody);
        if (match != null) {
          description = match.group(1)?.trim();
          transactionCurrencyCode = match.group(2);
          originalAmount = double.tryParse(match.group(3)?.replaceAll(',', '') ?? '0');
          type = TransactionType.general;
        }
      } else if (bankName == 'BOC') {
        match = bocTransferRegex.firstMatch(messageBody);
        if (match != null) {
          description = match.group(1)?.trim();
          transactionCurrencyCode = match.group(2) ?? 'LKR';
          originalAmount = double.tryParse(match.group(3)?.replaceAll(',', '') ?? '0');
          type = TransactionType.bankTransfer;
        } else {
          match = bocPosAtmRegex.firstMatch(messageBody);
          if (match != null) {
            description = match.group(1)?.trim();
            originalAmount = double.tryParse(match.group(2)?.replaceAll(',', '') ?? '0');
            transactionCurrencyCode = 'LKR';
            type = messageBody.contains('atm withdrawal') ? TransactionType.atmWithdrawal : TransactionType.general;
          } else {
            match = bocApprovedRegex.firstMatch(messageBody);
            if (match != null) {
              transactionCurrencyCode = match.group(1);
              originalAmount = double.tryParse(match.group(2)?.replaceAll(',', '') ?? '0');
              description = match.group(3)?.trim();
              type = TransactionType.general;
            }
          }
        }
      } else if (bankName == 'NTB') {
        match = ntbCeftsRegex.firstMatch(messageBody);
        if (match != null) {
          transactionCurrencyCode = match.group(1);
          originalAmount = double.tryParse(match.group(2)?.replaceAll(',', '') ?? '0');
          description = "Other Bank Transfer (CEFTS)";
          type = TransactionType.bankTransfer;
        } else {
          match = ntbPosRegex.firstMatch(messageBody);
          if (match != null) {
            transactionCurrencyCode = match.group(1);
            originalAmount = double.tryParse(match.group(2)?.replaceAll(',', '') ?? '0');
            description = "Foreign POS Transaction";
            type = TransactionType.general;
          } else {
            match = ntbPerformedRegex.firstMatch(messageBody);
            if (match != null) {
              description = match.group(1)?.trim();
              transactionCurrencyCode = match.group(2);
              originalAmount = double.tryParse(match.group(3)?.replaceAll(',', '') ?? '0');
              type = TransactionType.general;
            } else {
              match = ntbApprovedRegex.firstMatch(messageBody);
              if (match != null) {
                transactionCurrencyCode = match.group(1);
                originalAmount = double.tryParse(match.group(2)?.replaceAll(',', '') ?? '0');
                description = match.group(3)?.trim();
                type = TransactionType.general;
              }
            }
          }
        }
      } else if (bankName == 'HNB') {
        match = hnbAtmRegex.firstMatch(messageBody);
        if (match != null) {
          originalAmount = double.tryParse(match.group(1)?.replaceAll(',', '') ?? '0');
          transactionCurrencyCode = match.group(2);
          description = match.group(3)?.trim();
          type = TransactionType.atmWithdrawal;
        } else {
          match = hnbDebitReasonRegex.firstMatch(messageBody);
          if (match != null) {
            transactionCurrencyCode = match.group(1);
            originalAmount = double.tryParse(match.group(2)?.replaceAll(',', '') ?? '0');
            description = match.group(3)?.trim();
            type = TransactionType.bankTransfer;
          } else {
            match = hnbPurchaseRegex.firstMatch(messageBody);
            if (match != null) {
              description = match.group(1)?.trim();
              originalAmount = double.tryParse(match.group(2)?.replaceAll(',', '') ?? '0');
              transactionCurrencyCode = match.group(3);
              type = TransactionType.general;
            } else {
              match = hnbDebitOnlineRegex.firstMatch(messageBody);
              if (match != null) {
                transactionCurrencyCode = match.group(1);
                originalAmount = double.tryParse(match.group(2)?.replaceAll(',', '') ?? '0');
                description = match.group(3)?.trim();
                type = TransactionType.general;
              } else {
                match = hnbDebitChargeRegex.firstMatch(messageBody);
                if (match != null) {
                  transactionCurrencyCode = match.group(1);
                  originalAmount = double.tryParse(match.group(2)?.replaceAll(',', '') ?? '0');
                  description = match.group(3)?.trim();
                  type = TransactionType.general;
                }
              }
            }
          }
        }
      }
      else if (bankName == 'HSBC') {
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
      else if (bankName == 'Sampath Bank') {
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