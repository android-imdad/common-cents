import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import '../services/expense_service.dart';
import '../services/settings_service.dart';
import '../services/sms_service.dart';

class SmsSyncScreen extends StatefulWidget {
  final ExpenseService expenseService;
  final SmsService smsService;
  const SmsSyncScreen({super.key, required this.expenseService, required this.smsService});
  @override
  State<SmsSyncScreen> createState() => _SmsSyncScreenState();
}

class _SmsSyncScreenState extends State<SmsSyncScreen> {
  bool _isSyncing = false;
  final Map<String, String> _bankSenders = {
    '+94767027625': 'HNB',
    'HSBC': 'HSBC',
    '8822': 'Sampath Bank',
    'BOC': 'BOC',
    'COMBANK':'Commercial Bank',
    'NationsSMS': 'NTB',
    // 'SBIBNK': 'SBI Bank',
    // 'AxisBk': 'Axis Bank',
  };

  Future<void> _runSmsSync() async {
    setState(() { _isSyncing = true; });
    try {
      final newCount = await widget.smsService.syncExpensesFromSms(_bankSenders, widget.expenseService);
      if(!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(newCount > 0 ? 'Successfully imported $newCount new expenses!' : 'No new expenses found to import.'),
        backgroundColor: Colors.green[700],
      ));
    } catch (e) {
      if(!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Error during sync: ${e.toString()}'),
        backgroundColor: Colors.red[700],
      ));
    } finally {
      if (mounted) { setState(() { _isSyncing = false; }); }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('SMS Sync'),
        centerTitle: true,
      ),
      body: ValueListenableBuilder<Set<String>>(
          valueListenable: SettingsService.disabledBankSenderIds,
          builder: (context, disabledIds, _) {
            return Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Text(
                    'Enable or disable banks for SMS sync. Only enabled banks will be scanned.',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ),
                Expanded(
                  child: ListView(
                    children: _bankSenders.entries.map((entry) {
                      final senderId = entry.key;
                      final bankName = entry.value;
                      final isEnabled = !disabledIds.contains(senderId);
                      return SwitchListTile.adaptive(
                        title: Text(bankName),
                        value: isEnabled,
                        onChanged: (bool value) {
                          SettingsService.toggleBankStatus(senderId);
                        },
                        activeColor: Colors.tealAccent,
                      );
                    }).toList(),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: _isSyncing
                      ? const Center(child: CircularProgressIndicator())
                      : ElevatedButton.icon(
                    onPressed: _runSmsSync,
                    icon: const Icon(Icons.sync),
                    label: const Text('Sync Expenses from SMS'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.tealAccent,
                      foregroundColor: Colors.black,
                      padding: const EdgeInsets.symmetric(vertical: 16,horizontal: 16),
                      textStyle: Theme.of(context).textTheme.labelLarge,
                    ),
                  ),
                ),
              ],
            );
          }
      ),
    );
  }
}