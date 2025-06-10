import 'package:flutter/cupertino.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SettingsService {
  static late SharedPreferences _prefs;
  static const _currencyKey = 'selectedCurrency';
  static const _syncTransfersKey = 'syncBankTransfers';
  static const _syncAtmKey = 'syncAtmWithdrawals'; // New key

  static final Map<String, String> currencies = {
    'LKR': 'LKR',
    'USD': '\$',
    'INR': '₹',
    'EUR': '€',
    'GBP': '£',
  };

  static final ValueNotifier<String> currentCurrencySymbol = ValueNotifier<String>(currencies['LKR']!);
  static final ValueNotifier<bool> syncBankTransfers = ValueNotifier<bool>(true);
  static final ValueNotifier<bool> syncAtmWithdrawals = ValueNotifier<bool>(true); // New notifier
  static Future<void>? _initFuture;

  static Future<void> init() {
    if (_initFuture != null) return _initFuture!;
    _initFuture = () async {
      _prefs = await SharedPreferences.getInstance();

      final savedCurrencyCode = _prefs.getString(_currencyKey) ?? 'LKR';
      currentCurrencySymbol.value = currencies[savedCurrencyCode] ?? 'LKR';

      syncBankTransfers.value = _prefs.getBool(_syncTransfersKey) ?? true;
      syncAtmWithdrawals.value = _prefs.getBool(_syncAtmKey) ?? true; // Load new setting

      debugPrint("SettingsService initialized.");
    }();
    return _initFuture!;
  }

  static Future<void> setCurrency(String currencyCode) async {
    if (currencies.containsKey(currencyCode)) {
      await _prefs.setString(_currencyKey, currencyCode);
      currentCurrencySymbol.value = currencies[currencyCode]!;
    }
  }

  static Future<void> setSyncBankTransfers(bool value) async {
    await _prefs.setBool(_syncTransfersKey, value);
    syncBankTransfers.value = value;
  }

  static Future<void> setSyncAtmWithdrawals(bool value) async {
    await _prefs.setBool(_syncAtmKey, value);
    syncAtmWithdrawals.value = value;
  }

  static String getCurrencyCode() => _prefs.getString(_currencyKey) ?? 'LKR';
  static bool getSyncBankTransfers() => _prefs.getBool(_syncTransfersKey) ?? true;
  static bool getSyncAtmWithdrawals() => _prefs.getBool(_syncAtmKey) ?? true;
}