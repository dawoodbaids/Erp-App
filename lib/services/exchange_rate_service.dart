import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/exchange_rate.dart';
import 'firebase_service_exception.dart';

class ExchangeRateService {
  FirebaseFirestore get _db => FirebaseFirestore.instance;

  Future<List<ExchangeRate>> getExchangeRates() {
    return runFirebase(() async {
      final snapshot = await _db.collection('exchange_rates').get();
      final rates = snapshot.docs
          .map((doc) => ExchangeRate.fromFirestore(doc.id, doc.data()))
          .toList();
      rates.sort((a, b) => a.currencyId.compareTo(b.currencyId));
      return rates;
    }, 'Could not load exchange rates. Please try again.');
  }

  Future<ExchangeRate> updateRate(String id, double rate) {
    return runFirebase(() async {
      if (rate <= 0) {
        throw const FirebaseServiceException(
          'Rate must be greater than zero.',
          code: 'invalid-argument',
        );
      }
      final reference = _db.collection('exchange_rates').doc(id);
      final snapshot = await reference.get();
      if (!snapshot.exists || snapshot.data() == null) {
        throw const FirebaseServiceException(
          'The exchange rate was not found.',
          code: 'not-found',
        );
      }
      final currencyId = snapshot.data()!['currencyId']?.toString() ?? '';
      final currency = await _db.collection('currencies').doc(currencyId).get();
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
