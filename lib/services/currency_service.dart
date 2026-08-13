import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/currency.dart';
import 'firebase_service_exception.dart';

class CurrencyService {
  FirebaseFirestore get _db => FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> get _currencies =>
      _db.collection('currencies');

  Future<List<Currency>> getCurrencies() {
    return runFirebase(() async {
      final snapshot = await _currencies.get();
      final currencies = snapshot.docs
          .map((doc) => Currency.fromFirestore(doc.id, doc.data()))
          .where((currency) => currency.isActive)
          .toList();
      currencies.sort((a, b) => a.code.compareTo(b.code));
      return currencies;
    }, 'Could not load currencies. Please try again.');
  }

  Future<Currency> setBaseCurrency(String id) {
    return runFirebase(() async {
      final snapshot = await _currencies.get();
      QueryDocumentSnapshot<Map<String, dynamic>>? selected;
      for (final doc in snapshot.docs) {
        if (doc.id == id) {
          selected = doc;
          break;
        }
      }
      if (selected == null) {
        throw const FirebaseServiceException(
          'The selected currency was not found.',
          code: 'not-found',
        );
      }

      final ratesSnapshot = await _db.collection('exchange_rates').get();
      final rates = <String, double>{};
      for (final doc in ratesSnapshot.docs) {
        final value = doc.data()['rateToBase'];
        if (value is num) rates[doc.data()['currencyId']?.toString() ?? ''] = value.toDouble();
      }
      final newBaseRate = rates[id] ?? 1.0;
      if (newBaseRate <= 0) {
        throw const FirebaseServiceException(
          'The selected currency has no valid exchange rate.',
        );
      }

      final batch = _db.batch();
      for (final doc in snapshot.docs) {
        batch.update(doc.reference, {
          'isBaseCurrency': doc.id == id,
          'updatedAt': FieldValue.serverTimestamp(),
        });
      }
      for (final doc in ratesSnapshot.docs) {
        final currencyId = doc.data()['currencyId']?.toString() ?? '';
        final currentRate = rates[currencyId] ?? 1.0;
        final rate = currencyId == id ? 1.0 : currentRate / newBaseRate;
        batch.update(doc.reference, {
          'rateToBase': _round(rate),
          'effectiveDate': FieldValue.serverTimestamp(),
        });
      }
      await batch.commit();
      return Currency.fromFirestore(selected.id, {
        ...selected.data(),
        'isBaseCurrency': true,
      });
    }, 'Could not change the base currency. Please try again.');
  }

  double _round(double value) => (value * 1000).round() / 1000;
}
