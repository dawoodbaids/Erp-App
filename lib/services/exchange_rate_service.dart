import 'package:cloud_firestore/cloud_firestore.dart';

import '../core/utils/exchange_rate_resolver.dart';
import '../core/utils/firestore_helpers.dart';
import '../models/exchange_rate.dart';
import 'firebase_service_exception.dart';

/// Reads exchange rates from the Firebase `exchange_rates` collection.
///
/// Structure: one document per currency with `currencyId` (the `currencies`
/// document ID) and `rateToBase` (units of the base currency per 1 unit of
/// this currency). Rates are never hardcoded.
class ExchangeRateService {
  FirebaseFirestore get _db => FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> get _rates =>
      _db.collection('exchange_rates');

  CollectionReference<Map<String, dynamic>> get _currencies =>
      _db.collection('currencies');

  Future<List<ExchangeRate>> getExchangeRates() {
    return runFirebase(() async {
      final snapshot = await _rates.get();
      final rates = snapshot.docs
          .map((doc) => ExchangeRate.fromFirestore(doc.id, doc.data()))
          .toList();
      rates.sort((a, b) => a.currencyId.compareTo(b.currencyId));
      return rates;
    }, 'Could not load exchange rates. Please try again.');
  }

  /// Resolves the conversion rate between two currencies directly from
  /// Firebase.
  ///
  /// - Same currency returns 1.
  /// - Otherwise both currencies need a valid `rateToBase` (or be the base
  ///   currency), else null. Inverse directions are handled by the
  ///   rateToBase formula and are never guessed.
  Future<double?> getExchangeRate(
    String fromCurrencyId,
    String toCurrencyId,
  ) {
    return runFirebase(() async {
      if (fromCurrencyId.isEmpty || toCurrencyId.isEmpty) return null;
      if (fromCurrencyId == toCurrencyId) return 1;

      final currenciesSnapshot = await _currencies.get();
      String baseCurrencyId = '';
      for (final doc in currenciesSnapshot.docs) {
        if (firestoreBool(doc.data()['isBaseCurrency'])) {
          baseCurrencyId = doc.id;
          break;
        }
      }
      if (baseCurrencyId.isEmpty) {
        if (currenciesSnapshot.docs.isNotEmpty) {
          baseCurrencyId = currenciesSnapshot.docs.first.id;
        } else {
          return null;
        }
      }

      final ratesSnapshot = await _rates.get();
      final rates = <String, double>{};
      final currenciesByCode = <String, String>{};
      for (final doc in currenciesSnapshot.docs) {
        final code = firestoreString(doc.data()['code']);
        if (code.isNotEmpty) currenciesByCode[code.toLowerCase()] = doc.id;
      }
      for (final doc in ratesSnapshot.docs) {
        final data = doc.data();
        final currencyId = firestoreString(data['currencyId']);
        if (currencyId.isEmpty) continue;
        final rate = firestoreDouble(data['rateToBase']);
        if (rate > 0) {
          rates[currencyId] = rate;
          final idForCode = currenciesByCode[currencyId.toLowerCase()];
          if (idForCode != null) rates[idForCode] = rate;
        }
      }

      final resolvedFrom = ExchangeRateResolver.resolveCurrencyId(
        rates,
        fromCurrencyId,
        currenciesByCode,
      );
      final resolvedTo = ExchangeRateResolver.resolveCurrencyId(
        rates,
        toCurrencyId,
        currenciesByCode,
      );

      return ExchangeRateResolver.rateBetween(
        rates,
        resolvedFrom,
        resolvedTo,
        baseCurrencyId,
      );
    }, 'Could not load the exchange rate. Please try again.');
  }

  /// Creates an exchange rate document for a currency (rate against the
  /// base currency). Fails when the currency is the base currency or a rate
  /// already exists for it.
  Future<ExchangeRate> createRate(String currencyId, double rate) {
    return runFirebase(() async {
      if (rate <= 0) {
        throw const FirebaseServiceException(
          'Rate must be greater than zero.',
          code: 'invalid-argument',
        );
      }
      final currency = await _currencies.doc(currencyId).get();
      if (!currency.exists || currency.data() == null) {
        throw const FirebaseServiceException(
          'The currency was not found.',
          code: 'not-found',
        );
      }
      if (currency.data()!['isBaseCurrency'] == true) {
        throw const FirebaseServiceException(
          'The base currency rate is always 1.',
          code: 'invalid-argument',
        );
      }
      final existing = await _rates
          .where('currencyId', isEqualTo: currencyId)
          .limit(1)
          .get();
      if (existing.docs.isNotEmpty) {
        throw const FirebaseServiceException(
          'An exchange rate already exists for this currency.',
          code: 'already-exists',
        );
      }
      final reference = _rates.doc();
      await reference.set({
        'currencyId': currencyId,
        'rateToBase': rate,
        'effectiveDate': FieldValue.serverTimestamp(),
      });
      return ExchangeRate(
        id: reference.id,
        currencyId: currencyId,
        rateToBase: rate,
        effectiveDate: DateTime.now(),
      );
    }, 'Could not create the exchange rate. Please try again.');
  }

  Future<void> deleteRate(String id) {
    return runFirebase(() async {
      final reference = _rates.doc(id);
      final snapshot = await reference.get();
      if (!snapshot.exists || snapshot.data() == null) {
        throw const FirebaseServiceException(
          'The exchange rate was not found.',
          code: 'not-found',
        );
      }
      await reference.delete();
    }, 'Could not delete the exchange rate. Please try again.');
  }

  Future<ExchangeRate> updateRate(String id, double rate) {
    return runFirebase(() async {
      if (rate <= 0) {
        throw const FirebaseServiceException(
          'Rate must be greater than zero.',
          code: 'invalid-argument',
        );
      }
      final reference = _rates.doc(id);
      final snapshot = await reference.get();
      if (!snapshot.exists || snapshot.data() == null) {
        throw const FirebaseServiceException(
          'The exchange rate was not found.',
          code: 'not-found',
        );
      }
      final currencyId = snapshot.data()!['currencyId']?.toString() ?? '';
      final currency = await _currencies.doc(currencyId).get();
      if (currency.data()?['isBaseCurrency'] == true) {
        throw const FirebaseServiceException(
          'The base currency rate cannot be changed.',
          code: 'invalid-argument',
        );
      }
      await reference.update({
        'rateToBase': rate,
        'effectiveDate': FieldValue.serverTimestamp(),
      });
      return ExchangeRate(
        id: id,
        currencyId: currencyId,
        rateToBase: rate,
        effectiveDate: DateTime.now(),
      );
    }, 'Could not update the exchange rate. Please try again.');
  }
}
