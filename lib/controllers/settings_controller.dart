import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../core/utils/currency_converter.dart';
import '../models/currency.dart';
import '../models/exchange_rate.dart';
import '../services/currency_service.dart';
import '../services/exchange_rate_service.dart';
import '../services/firebase_service_exception.dart';

class SettingsController extends GetxController {
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

  String get defaultCurrencyId => currencies.isEmpty
      ? ''
      : currencies.firstWhere(
          (currency) => currency.isBaseCurrency,
          orElse: () => currencies.first,
        ).id;

  Currency? get defaultCurrency {
    if (currencies.isEmpty) return null;
    return currencies.firstWhere(
      (currency) => currency.id == defaultCurrencyId,
      orElse: () => currencies.first,
    );
  }

  void setThemeMode(ThemeMode mode) => _themeMode.value = mode;

  void setLocale(Locale locale) {
    _locale.value = locale;
    Get.updateLocale(locale);
  }

  Future<String?> setDefaultCurrency(String id) async {
    try {
      await _currencyService.setBaseCurrency(id);
      await loadCurrenciesAndRates();
      return null;
    } on FirebaseServiceException catch (error) {
      return error.message;
    } catch (_) {
      return 'Could not change the base currency. Please try again.';
    }
  }

  Currency? currencyById(String id) {
    for (final currency in currencies) {
      if (currency.id == id) return currency;
    }
    return null;
  }

  Currency? currencyByCode(String code) {
    for (final currency in currencies) {
      if (currency.code == code) return currency;
    }
    return null;
  }

  double rateFor(String currencyId) {
    if (currencyId == defaultCurrencyId) return 1;
    for (final rate in exchangeRates) {
      if (rate.currencyId == currencyId) return rate.rateToBase;
    }
    return 1;
  }

  double convert(double amount, String fromCurrencyId, String toCurrencyId) {
    return CurrencyConverter.convert(
      amount,
      rateFor(fromCurrencyId),
      rateFor(toCurrencyId),
    );
  }

  ExchangeRate? rateByCurrencyId(String currencyId) {
    for (final rate in exchangeRates) {
      if (rate.currencyId == currencyId) return rate;
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
    } on FirebaseServiceException catch (error) {
      _errorMessage.value = error.message;
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
    } on FirebaseServiceException catch (error) {
      return error.message;
    } catch (_) {
      return 'Could not update the exchange rate. Please try again.';
    }
  }

  bool isBaseCurrency(String currencyId) => currencyId == defaultCurrencyId;
}
