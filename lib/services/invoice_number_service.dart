import 'package:cloud_firestore/cloud_firestore.dart';

import 'firebase_service_exception.dart';

/// Allocates sequential invoice numbers and creates invoices atomically.
class InvoiceNumberService {
  FirebaseFirestore get _db => FirebaseFirestore.instance;

  static const _counterPath = 'settings/invoice_counter';

  static String format(int sequence, {DateTime? date}) =>
      sequence.toString().padLeft(4, '0');

  Future<String> createInvoice(
    Map<String, dynamic> Function(String number) data,
  ) {
    return runFirebase(() async {
      return _db.runTransaction((transaction) async {
        final counterRef = _db.doc(_counterPath);
        final counter = await transaction.get(counterRef);
        var number =
            (counter.data()?['lastInvoiceNumber'] as num?)?.toInt() ?? 0;

        late String selected;
        late DocumentReference<Map<String, dynamic>> invoiceRef;
        do {
          number++;
          selected = number.toString();
          invoiceRef = _db.collection('invoices').doc(selected);
          final existing = await transaction.get(invoiceRef);
          if (existing.exists) continue;
          break;
        } while (true);

        transaction.set(
          counterRef,
          {'lastInvoiceNumber': number},
          SetOptions(merge: true),
        );
        transaction.set(invoiceRef, data(selected));
        return selected;
      });
    }, 'Could not generate the next invoice number. Please try again.');
  }
}
