// --- Settings View --- (NEW WIDGET)
import 'dart:io';

import 'package:common_cents/screens/sms_sync_screen.dart';
import 'package:csv/csv.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:share_plus/share_plus.dart';

import '../services/expense_service.dart';
import '../services/settings_service.dart';
import '../services/sms_service.dart';

// --- Settings View --- //
class SettingsView extends StatelessWidget {
  final ExpenseService expenseService;
  const SettingsView({super.key, required this.expenseService});

  void _showCurrencyPicker(BuildContext context) {
    showDialog(context: context, builder: (context) {
      return SimpleDialog(title: const Text('Select Currency'), children: SettingsService.currencies.entries.map((entry) {
        return SimpleDialogOption(
          onPressed: () { SettingsService.setCurrency(entry.key); Navigator.of(context).pop(); },
          child: ListTile(title: Text('${entry.key} (${entry.value})'), trailing: SettingsService.getCurrencyCode() == entry.key ? const Icon(Icons.check, color: Colors.tealAccent) : null),
        );
      }).toList());
    });
  }

  void _goToSmsSync(BuildContext context) {
    if (Platform.isIOS) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('SMS Sync is not available on iOS.')));
      return;
    }
    Navigator.of(context).push(MaterialPageRoute(builder: (context) => SmsSyncScreen(expenseService: expenseService, smsService: SmsService())));
  }

  Future<void> _exportData(BuildContext context) async {
    final expenses = expenseService.getAllExpenses();
    if (expenses.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('No expenses to export.')));
      return;
    }
    List<List<dynamic>> rows = [['Amount (${SettingsService.getCurrencyCode()})', 'Timestamp', 'Type']];
    for (var expense in expenses) { rows.add([expense.amount, expense.timestamp.toIso8601String(), expense.transactionType.toString().split('.').last]); }
    String csv = const ListToCsvConverter().convert(rows);
    try {
      final tempDir = await getTemporaryDirectory();
      final path = '${tempDir.path}/expenses_export_${DateTime.now().millisecondsSinceEpoch}.csv';
      final file = File(path);
      await file.writeAsString(csv);
      await Share.shareXFiles([XFile(path, mimeType: 'text/csv')], text: 'Here is your expense data.');
    } catch (e) { debugPrint("Error exporting data: $e"); }
  }

  void _confirmResetData(BuildContext context) {
    showDialog(context: context, builder: (ctx) {
      return AlertDialog(
        title: const Text('Confirm Reset'),
        content: const Text('Are you sure you want to delete all expenses? This action cannot be undone.'),
        actions: <Widget>[
          TextButton(child: const Text('Cancel'), onPressed: () => Navigator.of(ctx).pop()),
          TextButton(
            style: TextButton.styleFrom(foregroundColor: Colors.redAccent),
            child: const Text('Reset Data'),
            onPressed: () async {
              await expenseService.clearAllExpenses();
              Navigator.of(ctx).pop();
            },
          ),
        ],
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
      future: SettingsService.init(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
        if (snapshot.hasError) return Center(child: Text("Error loading settings: ${snapshot.error}"));

        return AnimatedBuilder(
          animation: Listenable.merge([
            SettingsService.currentCurrencySymbol,
            SettingsService.syncBankTransfers,
            SettingsService.syncAtmWithdrawals
          ]),
          builder: (context, _) {
            final currentCode = SettingsService.getCurrencyCode();
            final currencySymbol = SettingsService.currencies[currentCode] ?? '';
            final syncTransfers = SettingsService.getSyncBankTransfers();
            final syncAtm = SettingsService.getSyncAtmWithdrawals();

            return ListView(
              padding: const EdgeInsets.all(16.0),
              children: [
                ListTile(
                  leading: const Icon(Icons.currency_exchange_outlined, color: Colors.white70),
                  title: const Text('Currency'),
                  subtitle: Text('Current: $currentCode ($currencySymbol)'),
                  onTap: () => {},
                ),
                const Divider(color: Colors.white24),
                SwitchListTile.adaptive(
                  title: const Text('Sync Bank Transfers'),
                  subtitle: const Text('Import outgoing bank transfers as expense'),
                  value: syncTransfers,
                  onChanged: (bool value) => SettingsService.setSyncBankTransfers(value),
                  activeColor: Colors.tealAccent,
                ),
                SwitchListTile.adaptive(
                  title: const Text('Sync ATM Withdrawals'),
                  subtitle: const Text('Import cash withdrawals as expenses'),
                  value: syncAtm,
                  onChanged: (bool value) => SettingsService.setSyncAtmWithdrawals(value),
                  activeColor: Colors.tealAccent,
                ),
                const Divider(color: Colors.white24),
                ListTile(
                  leading: const Icon(Icons.sms_outlined, color: Colors.white70),
                  title: const Text('Manual SMS Sync'),
                  subtitle: const Text('Run the SMS import process now.'),
                  onTap: () => _goToSmsSync(context),
                ),
                const Divider(color: Colors.white24),
                ListTile(
                  leading: const Icon(Icons.upload_file_outlined, color: Colors.white70),
                  title: const Text('Export Data'),
                  onTap: () => _exportData(context),
                ),
                const Divider(color: Colors.white24),
                ListTile(
                  leading: Icon(Icons.delete_forever_outlined, color: Colors.red[300]),
                  title: Text('Reset All Data', style: TextStyle(color: Colors.red[300])),
                  onTap: () => _confirmResetData(context),
                ),
              ],
            );
          },
        );
      },
    );
  }
}