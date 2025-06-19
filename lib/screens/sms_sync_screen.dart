import 'package:another_telephony/telephony.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import '../constants.dart';
import '../services/expense_service.dart';
import '../services/settings_service.dart';
import '../services/sms_service.dart';

class SmsSyncScreen extends StatefulWidget {
  final ExpenseService expenseService;
  final SmsService smsService;

  const SmsSyncScreen(
      {super.key, required this.expenseService, required this.smsService});

  @override
  State<SmsSyncScreen> createState() => _SmsSyncScreenState();
}

class _SmsSyncScreenState extends State<SmsSyncScreen> {
  bool _isSyncing = false;

  Future<void> _runSmsSync({bool fromToggle = false}) async {
    if (!fromToggle) {
      setState(() {
        _isSyncing = true;
      });
    }
    try {
      final newCount = await widget.smsService
          .syncExpensesFromSms(Constants.banksMap, widget.expenseService);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(newCount > 0
            ? 'Successfully imported $newCount new expenses!'
            : 'No new expenses found to import.'),
        backgroundColor: Colors.green[700],
      ));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Error during sync: ${e.toString()}'),
        backgroundColor: Colors.red[700],
      ));
    } finally {
      if (mounted && !fromToggle) {
        setState(() {
          _isSyncing = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('SMS Sync Settings'),
        centerTitle: true,
      ),
      body: ValueListenableBuilder<Set<String>>(
          valueListenable: SettingsService.disabledBankSenderIds,
          builder: (context, disabledIds, _) {
            return Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                  child: Text(
                    'Enable or disable banks for SMS sync. Only enabled banks will be scanned.',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ),
                Expanded(
                  child: ListView(
                    children: [
                      ValueListenableBuilder<bool>(
                          valueListenable: SettingsService.autoSmsSync,
                          builder: (context, autoSyncEnabled, _) {
                            return SwitchListTile.adaptive(
                              title: const Text('Auto SMS Sync'),
                              subtitle: const Text(
                                  'Periodically sync in the background'),
                              value: autoSyncEnabled,
                              onChanged: (bool value) async {
                                if (value) {
                                  final bool? permissionsGranted =
                                      await Telephony
                                          .instance.requestSmsPermissions;
                                  if (permissionsGranted == true) {
                                    await SettingsService.setAutoSmsSync(value);
                                    _runSmsSync(fromToggle: true);
                                  } else {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                        const SnackBar(
                                            content: Text(
                                                'SMS Permission denied. Auto-sync cannot be enabled.')));
                                  }
                                } else {
                                  await SettingsService.setAutoSmsSync(value);
                                }
                              },
                              activeColor: Colors.tealAccent,
                            );
                          }),
                      const Divider(color: Colors.white24),
                      Padding(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16.0, vertical: 8.0),
                        child: Text("Enabled Banks",
                            style: Theme.of(context).textTheme.titleSmall),
                      ),
                      ...Constants.banksMap.entries.map((entry) {
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
                    ],
                  ),
                ),
                if (_isSyncing)
                  const Center(child: CircularProgressIndicator())
                else
                  ElevatedButton.icon(
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
                const SizedBox(height: 16),
              ],
            );
          }),
    );
  }
}
