import 'package:cloud_firestore/cloud_firestore.dart';

import '../core/utils/firestore_helpers.dart';
import 'firebase_service_exception.dart';

/// Generates sequential, numeric-only invoice numbers using a Firestore
/// transaction so concurrent creations never produce duplicates.
///
/// The counter lives in `settings/invoice_counter` under `lastInvoiceNumber`.
/// On first use the counter is initialised above the highest existing invoice
/// number so legacy invoices are never overwritten or duplicated.
class InvoiceNumberService {
  FirebaseFirestore get _db => FirebaseFirestore.instance;

  static const _counterPath = 'settings/invoice_counter';

  Future<int> next() {
    return runFirebase(() async {
      final counterRef = _db.doc(_counterPath);

      final existing = await _db.collection('invoices').get();
      var maxExisting = 0;
      for (final doc in existing.docs) {
        final number = firestoreInvoiceNumber(doc.data()['invoiceNumber']);
        if (number > maxExisting) maxExisting = number;
      }

      return _db.runTransaction((transaction) async {
        final snapshot = await transaction.get(counterRef);
        var last =
            (snapshot.data()?['lastInvoiceNumber'] as num?)?.toInt() ?? 0;
        if (last < maxExisting) last = maxExisting;
        final next = last + 1;
        transaction.set(
          counterRef,
          {'lastInvoiceNumber': next},
          SetOptions(merge: true),
        );
        return next;
      });
    }, 'Could not generate the next invoice number. Please try again.');
  }
}
