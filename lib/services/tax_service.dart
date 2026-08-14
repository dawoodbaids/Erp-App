import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/tax_rate.dart';
import 'firebase_service_exception.dart';

/// Loads the applicable tax configuration from the Firebase `taxes`
/// collection. The rate is never hardcoded in the app.
class TaxService {
  FirebaseFirestore get _db => FirebaseFirestore.instance;

  Future<List<TaxRate>> getTaxes() {
    return runFirebase(() async {
      final snapshot = await _db.collection('taxes').get();
      final taxes = snapshot.docs
          .map((doc) => TaxRate.fromFirestore(doc.id, doc.data()))
          .where((tax) => tax.isActive)
          .toList();
      taxes.sort((a, b) => a.name.compareTo(b.name));
      return taxes;
    }, 'Could not load the tax configuration. Please try again.');
  }

  /// The tax rate applied to new invoices. Returns 0 when no active tax
  /// configuration exists in Firebase (no tax applies).
  Future<double> getDefaultTaxRate() async {
    final taxes = await getTaxes();
    if (taxes.isEmpty) return 0;
    return taxes.first.rate;
  }
}
