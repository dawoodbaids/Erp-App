import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/currency.dart';
import 'firebase_service_exception.dart';

/// Loads the currencies that actually exist in the Firebase `currencies`
/// collection. Nothing is hardcoded.
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

  /// Creates a currency in Firestore. The first currency ever created is
  /// automatically marked as the base currency so the app has a valid
  /// conversion anchor.
  Future<Currency> createCurrency(Currency draft) {
    return runFirebase(() async {
      final code = draft.code.trim().toUpperCase();
      if (code.isEmpty) {
        throw const FirebaseServiceException(
          'Currency code is required.',
          code: 'invalid-argument',
        );
      }
      final existing = await _currencies.get();
      for (final doc in existing.docs) {
        final data = doc.data();
        if ((data['code'] ?? '').toString().toUpperCase() == code) {
          throw const FirebaseServiceException(
            'A currency with this code already exists.',
            code: 'already-exists',
          );
        }
      }
      final reference = _currencies.doc();
      final isFirst = existing.docs.isEmpty;
      await reference.set({
        ...draft.toFirestore(),
        'code': code,
        'isBaseCurrency': draft.isBaseCurrency || isFirst,
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });
      return Currency.fromFirestore(reference.id, {
        ...draft.toFirestore(),
        'code': code,
        'isBaseCurrency': draft.isBaseCurrency || isFirst,
      });
    }, 'Could not create the currency. Please try again.');
  }

  Future<Currency> updateCurrency(Currency currency) {
    return runFirebase(() async {
      final reference = _currencies.doc(currency.id);
      final snapshot = await reference.get();
      if (!snapshot.exists || snapshot.data() == null) {
        throw const FirebaseServiceException(
          'The currency was not found.',
          code: 'not-found',
        );
      }
      await reference.update({
        ...currency.toFirestore(),
        'code': currency.code.trim().toUpperCase(),
        'updatedAt': FieldValue.serverTimestamp(),
      });
      return currency;
    }, 'Could not save the currency. Please try again.');
  }

  /// Deletes a currency and any exchange rate documents that reference it.
  /// The base currency cannot be deleted.
  Future<void> deleteCurrency(String id) {
    return runFirebase(() async {
      final reference = _currencies.doc(id);
      final snapshot = await reference.get();
      if (!snapshot.exists || snapshot.data() == null) {
        throw const FirebaseServiceException(
          'The currency was not found.',
          code: 'not-found',
        );
      }
      if (snapshot.data()!['isBaseCurrency'] == true) {
        throw const FirebaseServiceException(
          'The base currency cannot be deleted.',
          code: 'failed-precondition',
        );
      }
      final ratesSnapshot = await _db
          .collection('exchange_rates')
          .where('currencyId', isEqualTo: id)
          .get();
      final batch = _db.batch();
      for (final doc in ratesSnapshot.docs) {
        batch.delete(doc.reference);
      }
      batch.delete(reference);
      await batch.commit();
    }, 'Could not delete the currency. Please try again.');
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
        if (value is num) {
          rates[doc.data()['currencyId']?.toString() ?? ''] = value.toDouble();
        }
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
