import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import '../services/expense_service.dart';
import '../services/sms_service.dart';

class SmsSyncScreen extends StatefulWidget {
  final ExpenseService expenseService;
  final SmsService smsService;

  const SmsSyncScreen({
    super.key,
    required this.expenseService,
    required this.smsService,
  });

  @override
  State<SmsSyncScreen> createState() => _SmsSyncScreenState();
}

class _SmsSyncScreenState extends State<SmsSyncScreen> {
  bool _isSyncing = false;

  // List of bank sender IDs. Can be expanded or made editable later.
  final List<String> _bankSenderIds = [
    '8822', // HDFC Bank
    'HSBC'
    // 'ICICIB', // ICICI Bank
    // 'SBIBNK', // SBI Bank
    // 'AxisBk', // Axis Bank
    // Add more sender IDs here
  ];

  Future<void> _runSmsSync() async {
    setState(() { _isSyncing = true; });

    try {
      final newCount = await widget.smsService.syncExpensesFromSms(
        _bankSenderIds,
        widget.expenseService,
      );
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(newCount > 0 ? 'Successfully imported $newCount new expenses!' : 'No new expenses found to import.'),
        backgroundColor: Colors.green[700],
      ));
    } catch (e) {
      debugPrint("Error during sync ${e.toString()}");
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Error during sync: ${e.toString()}'),
        backgroundColor: Colors.red[700],
      ));
    } finally {
      if (mounted) {
        setState(() { _isSyncing = false; });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('SMS Sync'),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Target Senders',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            Text(
              'The app will scan for messages from the following senders. This list can be expanded in the future.',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 8.0,
              runSpacing: 8.0,
              children: _bankSenderIds.map((id) => Chip(
                label: Text(id),
                backgroundColor: Colors.grey[800],
              )).toList(),
            ),
            const Spacer(),
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
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  textStyle: Theme.of(context).textTheme.labelLarge,
                ),
              ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}
