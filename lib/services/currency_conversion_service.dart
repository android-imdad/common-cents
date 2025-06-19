import 'dart:convert';

import 'package:flutter/cupertino.dart';
import 'package:http/http.dart' as http;

import '../logger.dart';

class CurrencyConversionService {
  static Map<String, dynamic>? _ratesCache;
  static const String TAG = "CurrencyConversionService";

  static Future<void> _fetchAndCacheRates() async {
    if (_ratesCache != null) return;
    try {
      final response = await http.get(Uri.parse('https://open.er-api.com/v6/latest/USD'));
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['result'] == 'success') _ratesCache = data['rates'];
      }
    } catch (e) {
      Logger.error(tag: TAG, text: "Error fetching currency rates: $e");
    }
  }

  static const Map<String, double> _fallbackRates = { 'USD': 1.0, 'LKR': 300.0, 'INR': 83.0, 'EUR': 0.92, 'GBP': 0.79, 'AUD': 0.66 };

  static Future<double> convert(double amount, String fromCurrency, String toCurrency) async {
    final from = fromCurrency.toUpperCase();
    final to = toCurrency.toUpperCase();
    if (from == to) return amount;

    await _fetchAndCacheRates();
    final rates = _ratesCache ?? _fallbackRates;

    final double? fromRate = rates[from]?.toDouble();
    final double? toRate = rates[to]?.toDouble();

    if (fromRate == null || toRate == null) return amount;

    double amountInUSD = amount / fromRate;
    return amountInUSD * toRate;
  }
}
