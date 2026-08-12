import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../core/network/api_client.dart';
import '../core/utils/currency_converter.dart';
import '../models/currency.dart';
import '../models/exchange_rate.dart';
import '../services/currency_service.dart';
import '../services/exchange_rate_service.dart';

class SettingsController extends GetxController {
  static const _fallbackCurrency = Currency(
    id: '1',
    code: 'JOD',
    name: 'Jordanian Dinar',
    symbol: 'JOD',
    isBaseCurrency: true,
  );

  final _themeMode = ThemeMode.light.obs;
  final _locale = const Locale('en').obs;
  final _isLoading = false.obs;
  final _errorMessage = Rxn<String>();

  final currencies = <Currency>[].obs;
  final exchangeRates = <ExchangeRate>[].obs;

  final _currencyService = CurrencyService();
  final _exchangeRateService = ExchangeRateService();

  ThemeMode get themeMode => _themeMode.value;
  Locale get locale => _locale.value;
  bool get isLoading => _isLoading.value;
  String? get errorMessage => _errorMessage.value;

  /// The base currency is configured in the database
  /// (exactly one currency has IsBaseCurrency = 1).
  String get defaultCurrencyId {
    for (final c in currencies) {
      if (c.isBaseCurrency) return c.id;
    }
    return currencies.isEmpty ? _fallbackCurrency.id : currencies.first.id;
  }

  Currency get defaultCurrency {
    if (currencies.isEmpty) return _fallbackCurrency;
    return currencies.firstWhere(
      (c) => c.id == defaultCurrencyId,
      orElse: () => currencies.first,
    );
  }

  void setThemeMode(ThemeMode mode) {
    _themeMode.value = mode;
  }

  void setLocale(Locale locale) {
    _locale.value = locale;
    Get.updateLocale(locale);
  }

  Future<String?> setDefaultCurrency(String id) async {
    try {
      await _currencyService.setBaseCurrency(id);
      await loadCurrenciesAndRates();
      return null;
    } on ApiException catch (e) {
      return e.message;
    } catch (_) {
      return 'Could not change the base currency. Please try again.';
    }
  }

  Currency currencyById(String id) {
    return currencies.firstWhere(
      (c) => c.id == id,
      orElse: () => _fallbackCurrency,
    );
  }

  Currency? currencyByCode(String code) {
    for (final c in currencies) {
      if (c.code == code) return c;
    }
    return null;
  }

  /// RateToBase of a currency: how much BASE currency equals 1 unit of it.
  double rateFor(String currencyId) {
    final baseId = defaultCurrencyId;
    if (currencyId == baseId) return 1.0;
    for (final rate in exchangeRates) {
      if (rate.currencyId == currencyId) {
        return rate.rateToBase;
      }
    }
    return 1.0;
  }

  /// Universal conversion between any two currencies.
  /// Converted = amount * sourceRateToBase / targetRateToBase.
  double convert(double amount, String fromCurrencyId, String toCurrencyId) {
    return CurrencyConverter.convert(
      amount,
      rateFor(fromCurrencyId),
      rateFor(toCurrencyId),
    );
  }

  ExchangeRate? rateByCurrencyId(String currencyId) {
    for (final rate in exchangeRates) {
      if (rate.currencyId == currencyId) {
        return rate;
      }
    }
    return null;
  }

  Future<void> loadCurrenciesAndRates() async {
    _isLoading.value = true;
    _errorMessage.value = null;
    try {
      final currencyList = await _currencyService.getCurrencies();
      final rateList = await _exchangeRateService.getExchangeRates();
      currencies.value = currencyList;
      exchangeRates.value = rateList;
    } on ApiException catch (e) {
      _errorMessage.value = e.message;
    } catch (_) {
      _errorMessage.value = 'Could not load currencies. Please try again.';
    } finally {
      _isLoading.value = false;
    }
  }

  Future<String?> updateExchangeRate(String rateId, double newRate) async {
    try {
      await _exchangeRateService.updateRate(rateId, newRate);
      await loadCurrenciesAndRates();
      return null;
    } on ApiException catch (e) {
      return e.message;
    } catch (_) {
      return 'Could not update the exchange rate. Please try again.';
    }
  }

  bool isBaseCurrency(String currencyId) => currencyId == defaultCurrencyId;
}
