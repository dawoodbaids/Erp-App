import 'package:cloud_firestore/cloud_firestore.dart';

import '../core/utils/firestore_helpers.dart';
import 'firebase_service_exception.dart';

/// Generates sequential, unique invoice numbers using a Firestore
/// transaction so concurrent creations never produce duplicates.
///
/// The counter lives in `settings/invoice_counter` under `lastInvoiceNumber`.
/// On first use the counter is initialised above the highest existing invoice
/// number so legacy invoices are never overwritten or duplicated.
///
/// Numbers are formatted as `INV-YYYY-NNNN` (e.g. `INV-2026-0001`) where the
/// sequence is the counter value. The readable number is separate from the
/// Firestore document ID.
class InvoiceNumberService {
  FirebaseFirestore get _db => FirebaseFirestore.instance;

  static const _counterPath = 'settings/invoice_counter';

  /// Formats a sequence number as a readable invoice number, e.g.
  /// `INV-2026-0001`.
  static String format(int sequence, {DateTime? date}) {
    final year = (date ?? DateTime.now()).year;
    return 'INV-$year-${sequence.toString().padLeft(4, '0')}';
  }

  /// Returns the next unique invoice number, e.g. `INV-2026-0001`.
  Future<String> next() {
    return runFirebase(() async {
      final sequence = await _nextSequence();
      return format(sequence);
    }, 'Could not generate the next invoice number. Please try again.');
  }

  Future<int> _nextSequence() {
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