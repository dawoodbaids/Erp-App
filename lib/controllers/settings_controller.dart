import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../core/utils/exchange_rate_resolver.dart';
import '../core/utils/formatters.dart';
import '../models/currency.dart';
import '../models/exchange_rate.dart';
import '../models/product.dart';
import '../models/tax_rate.dart';
import '../services/currency_service.dart';
import '../services/exchange_rate_service.dart';
import '../services/firebase_service_exception.dart';
import '../services/tax_service.dart';

class SettingsController extends GetxController {
  final _locale = const Locale('en').obs;
  final _themeMode = ThemeMode.system.obs;
  final _isLoading = false.obs;
  final _errorMessage = Rxn<String>();

  final currencies = <Currency>[].obs;
  final exchangeRates = <ExchangeRate>[].obs;
  final taxes = <TaxRate>[].obs;

  final _currencyService = CurrencyService();
  final _exchangeRateService = ExchangeRateService();
  final _taxService = TaxService();

  Locale get locale => _locale.value;
  ThemeMode get themeMode => _themeMode.value;
  bool get isLoading => _isLoading.value;
  String? get errorMessage => _errorMessage.value;

  @override
  void onInit() {
    super.onInit();
    _loadThemeMode();
  }

  Future<void> _loadThemeMode() async {
    try {
      final preferences = await SharedPreferences.getInstance();
      final value = preferences.getString('themeMode');
      _themeMode.value = switch (value) {
        'light' => ThemeMode.light,
        'dark' => ThemeMode.dark,
        _ => ThemeMode.system,
      };
    } catch (_) {
      // Storage is unavailable in some unit-test environments.
    }
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    _themeMode.value = mode;
    try {
      final preferences = await SharedPreferences.getInstance();
      await preferences.setString('themeMode', mode.name);
    } catch (_) {
      // The visual change still applies for the current session.
    }
  }

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

  /// The code of the currency a product's price is stored in. Resolves
  /// legacy products that only store `currencyId`.
  String productCurrencyCode(Product product) {
    if (product.currencyCode.isNotEmpty) return product.currencyCode;
    return currencyById(product.currencyId)?.code ?? '';
  }

  /// Formats a product's stored price in its original currency, e.g.
  /// `JOD 100.00`. The stored price is never converted.
  String formatProductPrice(Product product) {
    final code = productCurrencyCode(product);
    return code.isEmpty
        ? Formatters.amount(product.price)
        : '$code ${Formatters.amount(product.price)}';
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

  Future<String?> createCurrency(Currency draft) async {
    try {
      await _currencyService.createCurrency(draft);
      await loadCurrenciesAndRates();
      return null;
    } on FirebaseServiceException catch (error) {
      debugPrint('Failed to create the currency: ${error.message}');
      return error.message;
    } catch (error) {
      debugPrint('Failed to create the currency: $error');
      return 'Could not create the currency. Please try again.';
    }
  }

  Future<String?> updateCurrency(Currency currency) async {
    try {
      await _currencyService.updateCurrency(currency);
      await loadCurrenciesAndRates();
      return null;
    } on FirebaseServiceException catch (error) {
      debugPrint('Failed to update the currency: ${error.message}');
      return error.message;
    } catch (error) {
      debugPrint('Failed to update the currency: $error');
      return 'Could not update the currency. Please try again.';
    }
  }

  Future<String?> deleteCurrency(String id) async {
    try {
      await _currencyService.deleteCurrency(id);
      await loadCurrenciesAndRates();
      return null;
    } on FirebaseServiceException catch (error) {
      debugPrint('Failed to delete the currency: ${error.message}');
      return error.message;
    } catch (error) {
      debugPrint('Failed to delete the currency: $error');
      return 'Could not delete the currency. Please try again.';
    }
  }

  Future<String?> createExchangeRate(String currencyId, double rate) async {
    try {
      await _exchangeRateService.createRate(currencyId, rate);
      await loadCurrenciesAndRates();
      return null;
    } on FirebaseServiceException catch (error) {
      debugPrint('Failed to create the exchange rate: ${error.message}');
      return error.message;
    } catch (error) {
      debugPrint('Failed to create the exchange rate: $error');
      return 'Could not create the exchange rate. Please try again.';
    }
  }

  Future<String?> deleteExchangeRate(String rateId) async {
    try {
      await _exchangeRateService.deleteRate(rateId);
      await loadCurrenciesAndRates();
      return null;
    } on FirebaseServiceException catch (error) {
      debugPrint('Failed to delete the exchange rate: ${error.message}');
      return error.message;
    } catch (error) {
      debugPrint('Failed to delete the exchange rate: $error');
      return 'Could not delete the exchange rate. Please try again.';
    }
  }

  Future<String?> createTax({required String name, required double rate}) async {
    try {
      await _taxService.createTax(name: name, rate: rate);
      await loadCurrenciesAndRates();
      return null;
    } on FirebaseServiceException catch (error) {
      debugPrint('Failed to create the tax: ${error.message}');
      return error.message;
    } catch (error) {
      debugPrint('Failed to create the tax: $error');
      return 'Could not create the tax. Please try again.';
    }
  }

  Future<String?> updateTax(TaxRate tax) async {
    try {
      await _taxService.updateTax(tax);
      await loadCurrenciesAndRates();
      return null;
    } on FirebaseServiceException catch (error) {
      debugPrint('Failed to update the tax: ${error.message}');
      return error.message;
    } catch (error) {
      debugPrint('Failed to update the tax: $error');
      return 'Could not update the tax. Please try again.';
    }
  }

  Future<String?> deleteTax(String id) async {
    try {
      await _taxService.deleteTax(id);
      await loadCurrenciesAndRates();
      return null;
    } on FirebaseServiceException catch (error) {
      debugPrint('Failed to delete the tax: ${error.message}');
      return error.message;
    } catch (error) {
      debugPrint('Failed to delete the tax: $error');
      return 'Could not delete the tax. Please try again.';
    }
  }

  /// Resolves a currency by its Firebase document ID or, when not found, by
  /// its code (case-insensitive). Existing data may store either form, e.g. a
  /// customer's `currencyId` or a rate's `currencyId` holding `JOD` instead
  /// of the document ID. Returns null when nothing matches.
  Currency? currencyById(String idOrCode) {
    if (idOrCode.isEmpty) return null;
    for (final currency in currencies) {
      if (currency.id == idOrCode) return currency;
    }
    for (final currency in currencies) {
      if (currency.code.toLowerCase() == idOrCode.toLowerCase()) {
        return currency;
      }
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
    final base = defaultCurrency;
    for (final rate in exchangeRates) {
      if (rate.isPair) {
        if (base == null) continue;
        for (final entry in rate.rateToBaseEntries(base.code).entries) {
          rates[entry.key] = entry.value;
          rates[entry.key.toLowerCase()] = entry.value;
          final currency = currencyById(entry.key);
          if (currency != null) rates[currency.id] = entry.value;
        }
        continue;
      }
      final value = rate.rateToBase;
      if (value > 0 && rate.currencyId.isNotEmpty) {
        rates[rate.currencyId] = value;
        final currency = currencyById(rate.currencyId);
        if (currency != null) {
          rates[currency.code] = value;
          rates[currency.code.toLowerCase()] = value;
        }
      }
    }
    return rates;
  }

  /// True when an exchange rate exists for [currency]: either a canonical
  /// rate document (keyed by document ID or code) or a pair document that
  /// covers the currency's code.
  bool hasRateFor(Currency currency) {
    final base = defaultCurrency;
    for (final rate in exchangeRates) {
      if (rate.rateToBase > 0 &&
          (rate.currencyId == currency.id ||
              rate.currencyId.toLowerCase() == currency.code.toLowerCase())) {
        return true;
      }
      if (base != null &&
          rate.rateToBaseEntries(base.code).containsKey(currency.code)) {
        return true;
      }
    }
    return false;
  }

  /// Rate lookup by currency document ID or code. Returns null when the
  /// currency is not the base and no rate is configured in Firebase. Never
  /// invents a rate.
  double? rateForCurrency(String currencyId) {
    return ExchangeRateResolver.rateToBaseAny(
      _ratesByCurrencyId,
      currencyId,
      currencyById(currencyId)?.code,
      defaultCurrencyId,
      defaultCurrency?.code,
    );
  }

  /// Rate lookup by currency document ID or code. Tolerates
  /// `exchange_rates` documents whose `currencyId` stores a code instead of
  /// a document ID.
  double? rateForCurrencyAny(String currencyId, String? currencyCode) {
    return ExchangeRateResolver.rateToBaseAny(
      _ratesByCurrencyId,
      currencyId,
      currencyCode,
      defaultCurrencyId,
      defaultCurrency?.code,
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

  /// Conversion rate between two currencies resolving each side by document
  /// ID or code.
  double? getExchangeRateAny(
    String fromCurrencyId,
    String? fromCurrencyCode,
    String toCurrencyId,
    String? toCurrencyCode,
  ) {
    return ExchangeRateResolver.rateBetweenAny(
      _ratesByCurrencyId,
      fromCurrencyId,
      fromCurrencyCode,
      toCurrencyId,
      toCurrencyCode,
      defaultCurrencyId,
      defaultCurrency?.code,
    );
  }

  /// Converts [amount] using rates from Firebase only. Resolves each side by
  /// document ID or code. Returns null when a required exchange rate is
  /// missing so callers never use a made-up rate.
  double? tryConvert(double amount, String fromCurrencyId, String toCurrencyId) {
    final from = currencyById(fromCurrencyId);
    final to = currencyById(toCurrencyId);
    final rate = getExchangeRateAny(
      fromCurrencyId,
      from?.code,
      toCurrencyId,
      to?.code,
    );
    if (rate == null) return null;
    return (amount * rate * 100).round() / 100;
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
