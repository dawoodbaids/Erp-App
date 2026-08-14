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

  Future<TaxRate> createTax({
    required String name,
    required double rate,
  }) {
    return runFirebase(() async {
      final trimmed = name.trim();
      if (trimmed.isEmpty) {
        throw const FirebaseServiceException(
          'Tax name is required.',
          code: 'invalid-argument',
        );
      }
      if (rate < 0 || rate > 100) {
        throw const FirebaseServiceException(
          'Tax rate must be between 0 and 100.',
          code: 'invalid-argument',
        );
      }
      final reference = _db.collection('taxes').doc();
      await reference.set({
        'name': trimmed,
        'rate': rate,
        'isActive': true,
        'createdAt': FieldValue.serverTimestamp(),
      });
      return TaxRate.fromFirestore(reference.id, {
        'name': trimmed,
        'rate': rate,
        'isActive': true,
      });
    }, 'Could not create the tax. Please try again.');
  }

  Future<TaxRate> updateTax(TaxRate tax) {
    return runFirebase(() async {
      final trimmed = tax.name.trim();
      if (trimmed.isEmpty) {
        throw const FirebaseServiceException(
          'Tax name is required.',
          code: 'invalid-argument',
        );
      }
      if (tax.rate < 0 || tax.rate > 100) {
        throw const FirebaseServiceException(
          'Tax rate must be between 0 and 100.',
          code: 'invalid-argument',
        );
      }
      final reference = _db.collection('taxes').doc(tax.id);
      final snapshot = await reference.get();
      if (!snapshot.exists || snapshot.data() == null) {
        throw const FirebaseServiceException(
          'The tax was not found.',
          code: 'not-found',
        );
      }
      await reference.update({
        'name': trimmed,
        'rate': tax.rate,
        'isActive': tax.isActive,
        'updatedAt': FieldValue.serverTimestamp(),
      });
      return TaxRate(
        id: tax.id,
        name: trimmed,
        rate: tax.rate,
        isActive: tax.isActive,
      );
    }, 'Could not save the tax. Please try again.');
  }

  Future<void> deleteTax(String id) {
    return runFirebase(() async {
      final reference = _db.collection('taxes').doc(id);
      final snapshot = await reference.get();
      if (!snapshot.exists || snapshot.data() == null) {
        throw const FirebaseServiceException(
          'The tax was not found.',
          code: 'not-found',
        );
      }
      await reference.delete();
    }, 'Could not delete the tax. Please try again.');
  }
}
