import 'package:background_fetch/background_fetch.dart';
import 'package:flutter/cupertino.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../logger.dart';

class SettingsService {

  static const String TAG = "SettingsService";

  static late SharedPreferences _prefs;
  static const _currencyKey = 'selectedCurrency';
  static const _syncTransfersKey = 'syncBankTransfers';
  static const _syncAtmKey = 'syncAtmWithdrawals'; // New key
  static const _disabledBanksKey = 'disabledBankSenderIds'; // New key
  static const _autoSmsSyncKey = 'autoSmsSync'; // New key

  static final Map<String, String> currencies = { 'LKR': 'LKR', 'USD': '\$', 'INR': '₹', 'EUR': '€', 'GBP': '£', 'AUD': 'A\$' };

  static final ValueNotifier<String> currentCurrencySymbol = ValueNotifier<String>(currencies['LKR']!);
  static final ValueNotifier<bool> syncBankTransfers = ValueNotifier<bool>(false);
  static final ValueNotifier<bool> syncAtmWithdrawals = ValueNotifier<bool>(true);
  static final ValueNotifier<Set<String>> disabledBankSenderIds = ValueNotifier<Set<String>>({}); // New notifier
  static final ValueNotifier<bool> autoSmsSync = ValueNotifier<bool>(false); // New notifier

  static Future<void>? _initFuture;

  static Future<void> init() {
    if (_initFuture != null) return _initFuture!;
    _initFuture = () async {
      _prefs = await SharedPreferences.getInstance();

      final savedCurrencyCode = _prefs.getString(_currencyKey) ?? 'LKR';
      currentCurrencySymbol.value = currencies[savedCurrencyCode] ?? 'LKR';

      syncBankTransfers.value = _prefs.getBool(_syncTransfersKey) ?? false;
      syncAtmWithdrawals.value = _prefs.getBool(_syncAtmKey) ?? true; // Load new setting
      autoSmsSync.value = _prefs.getBool(_autoSmsSyncKey) ?? false;

      final disabledList = _prefs.getStringList(_disabledBanksKey) ?? [];
      disabledBankSenderIds.value = disabledList.toSet();
      Logger.info(tag: TAG, text: "SettingsService initialized.");
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

  static Future<void> toggleBankStatus(String senderId) async {
    final newSet = Set<String>.from(disabledBankSenderIds.value);
    if (newSet.contains(senderId)) {
      newSet.remove(senderId);
    } else {
      newSet.add(senderId);
    }
    await _prefs.setStringList(_disabledBanksKey, newSet.toList());
    disabledBankSenderIds.value = newSet;
  }

  static Future<void> setAutoSmsSync(bool value) async {
    await _prefs.setBool(_autoSmsSyncKey, value);
    autoSmsSync.value = value;
    if (value) {
      BackgroundFetch.start();
    } else {
      BackgroundFetch.stop();
    }
  }

  static String getCurrencyCode() => _prefs.getString(_currencyKey) ?? 'LKR';
  static bool getSyncBankTransfers() => _prefs.getBool(_syncTransfersKey) ?? false;
  static bool getSyncAtmWithdrawals() => _prefs.getBool(_syncAtmKey) ?? true;
  static bool isBankEnabled(String senderId) => !disabledBankSenderIds.value.contains(senderId);
  static bool getAutoSmsSync() => _prefs.getBool(_autoSmsSyncKey) ?? false;

}