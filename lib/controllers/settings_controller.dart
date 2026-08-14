import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../core/utils/exchange_rate_resolver.dart';
import '../models/currency.dart';
import '../models/exchange_rate.dart';
import '../models/tax_rate.dart';
import '../services/currency_service.dart';
import '../services/exchange_rate_service.dart';
import '../services/firebase_service_exception.dart';
import '../services/tax_service.dart';

class SettingsController extends GetxController {
  final _locale = const Locale('en').obs;
  final _isLoading = false.obs;
  final _errorMessage = Rxn<String>();

  final currencies = <Currency>[].obs;
  final exchangeRates = <ExchangeRate>[].obs;
  final taxes = <TaxRate>[].obs;

  final _currencyService = CurrencyService();
  final _exchangeRateService = ExchangeRateService();
  final _taxService = TaxService();

  Locale get locale => _locale.value;
  bool get isLoading => _isLoading.value;
  String? get errorMessage => _errorMessage.value;

  /// The tax rate applied to new invoices, loaded from Firebase. Returns 0
  /// when no tax configuration exists in Firebase.
  double get defaultTaxRate => taxes.isEmpty ? 0 : taxes.first.rate;

  String get defaultCurrencyId => currencies.isEmpty
      ? ''
      : currencies
            .firstWhere(
              (currency) => currency.isBaseCurrency,
              orElse: () => currencies.first,
            )
            .id;

  Currency? get defaultCurrency {
    if (currencies.isEmpty) return null;
    return currencies.firstWhere(
      (currency) => currency.id == defaultCurrencyId,
      orElse: () => currencies.first,
    );
  }

  void setLocale(Locale locale) {
    _locale.value = locale;
    Get.updateLocale(locale);
  }

  /// Loads currencies if they are not loaded yet. Safe to call from any form;
  /// does nothing when a load is already running or the data is present.
  Future<void> ensureCurrenciesLoaded() async {
    if (currencies.isNotEmpty || _isLoading.value) return;
    await loadCurrenciesAndRates();
  }

  Future<String?> setDefaultCurrency(String id) async {
    try {
      await _currencyService.setBaseCurrency(id);
      await loadCurrenciesAndRates();
      return null;
    } on FirebaseServiceException catch (error) {
      debugPrint('Failed to change the base currency: ${error.message}');
      return error.message;
    } catch (error) {
      debugPrint('Failed to change the base currency: $error');
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

  Map<String, double> get _ratesByCurrencyId {
    final rates = <String, double>{};
    for (final rate in exchangeRates) {
      final value = rate.rateToBase;
      if (value > 0 && rate.currencyId.isNotEmpty) {
        rates[rate.currencyId] = value;
      }
    }
    return rates;
  }

  /// Strict rate lookup. The base currency always returns 1. Returns null
  /// when the currency is not the base and no exchange rate is configured in
  /// Firebase. Never invents a rate.
  double? rateForCurrency(String currencyId) {
    return ExchangeRateResolver.rateToBase(
      _ratesByCurrencyId,
      currencyId,
      defaultCurrencyId,
    );
  }

  /// Strict conversion rate between two currencies from Firebase. Returns 1
  /// for the same currency and null when a required rate is missing.
  double? getExchangeRate(String fromCurrencyId, String toCurrencyId) {
    return ExchangeRateResolver.rateBetween(
      _ratesByCurrencyId,
      fromCurrencyId,
      toCurrencyId,
      defaultCurrencyId,
    );
  }

  /// Converts [amount] using rates from Firebase only. Returns null when a
  /// required exchange rate is missing so callers never use a made-up rate.
  double? tryConvert(double amount, String fromCurrencyId, String toCurrencyId) {
    return ExchangeRateResolver.convertAmount(
      amount,
      _ratesByCurrencyId,
      fromCurrencyId,
      toCurrencyId,
      defaultCurrencyId,
    );
  }

  ExchangeRate? rateByCurrencyId(String currencyId) {
    for (final rate in exchangeRates) {
      if (rate.currencyId == currencyId) return rate;
    }
    return null;
  }

  /// Loads currencies, exchange rates and taxes from Firebase. Currencies and
  /// rates are loaded independently so one failing query never clears the
  /// others. Failures are logged with the real Firebase error.
  Future<void> loadCurrenciesAndRates() async {
    _isLoading.value = true;
    _errorMessage.value = null;

    try {
      currencies.value = await _currencyService.getCurrencies();
    } on FirebaseServiceException catch (error) {
      debugPrint('Failed to load currencies: ${error.message}');
      _errorMessage.value = error.message;
    } catch (error) {
      debugPrint('Failed to load currencies: $error');
      _errorMessage.value = 'Failed to load currencies. Please try again.';
    }

    try {
      exchangeRates.value = await _exchangeRateService.getExchangeRates();
    } on FirebaseServiceException catch (error) {
      debugPrint('Failed to load exchange rates: ${error.message}');
      _errorMessage.value ??= error.message;
    } catch (error) {
      debugPrint('Failed to load exchange rates: $error');
    }

    try {
      taxes.value = await _taxService.getTaxes();
    } on FirebaseServiceException catch (error) {
      debugPrint('Failed to load taxes: ${error.message}');
    } catch (error) {
      debugPrint('Failed to load taxes: $error');
    }

    _isLoading.value = false;
  }

  Future<String?> updateExchangeRate(String rateId, double newRate) async {
    try {
      await _exchangeRateService.updateRate(rateId, newRate);
      await loadCurrenciesAndRates();
      return null;
    } on FirebaseServiceException catch (error) {
      debugPrint('Failed to update the exchange rate: ${error.message}');
      return error.message;
    } catch (error) {
      debugPrint('Failed to update the exchange rate: $error');
      return 'Could not update the exchange rate. Please try again.';
    }
  }

  bool isBaseCurrency(String currencyId) => currencyId == defaultCurrencyId;
}
