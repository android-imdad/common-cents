import 'package:animated_digit/animated_digit.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class SpendingCard extends StatelessWidget {
  final String title;
  final double amount;
  final String currencySymbol;

  const SpendingCard({
    super.key,
    required this.title,
    required this.amount, required this.currencySymbol,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 24.0, horizontal: 16.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              title,
              style: theme.textTheme.titleLarge?.copyWith(
                color: Colors.tealAccent, // Use accent for title
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            AnimatedDigitWidget(
              value: amount,
              textStyle: theme.textTheme.headlineMedium,
              duration: const Duration(milliseconds: 500),
              fractionDigits: 2,
              enableSeparator: true,
              separateSymbol: ',',
            ),
          ],
        ),
      ),
    );
  }
}
