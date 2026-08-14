import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';

import 'package:erp_mobileapp_ui/controllers/invoice_controller.dart';
import 'package:erp_mobileapp_ui/core/utils/firestore_helpers.dart';
import 'package:erp_mobileapp_ui/models/currency.dart';
import 'package:erp_mobileapp_ui/models/customer.dart';
import 'package:erp_mobileapp_ui/models/invoice.dart';
import 'package:erp_mobileapp_ui/services/invoice_number_service.dart';

Invoice _invoice(String id, String number) => Invoice(
  id: id,
  invoiceNumber: number,
  customer: const Customer(id: 'customer-1', name: 'Test Customer'),
  currency: const Currency(
    id: 'currency-1',
    code: 'JOD',
    name: 'Jordanian Dinar',
    symbol: 'JD',
  ),
  exchangeRate: 1,
  taxMode: TaxMode.exclusive,
  status: InvoiceStatus.draft,
  items: const [],
  subtotal: 0,
  taxAmount: 0,
  totalAmount: 0,
  createdAt: DateTime(2026, 8, 14),
);

void main() {
  group('InvoiceNumberService.format', () {
    test('produces sequential, unique INV-YYYY-NNNN numbers', () {
      final numbers = [1, 2, 3]
          .map((seq) => InvoiceNumberService.format(seq, date: DateTime(2026)))
          .toList();

      expect(numbers, ['INV-2026-0001', 'INV-2026-0002', 'INV-2026-0003']);
      expect(numbers.toSet().length, numbers.length);
    });
  });

  group('firestoreInvoiceNumber parsing', () {
    test('extracts the trailing sequence from new readable numbers', () {
      expect(firestoreInvoiceNumber('INV-2026-0003'), 3);
      expect(firestoreInvoiceNumber('INV-000007'), 7);
    });

    test('keeps legacy numeric values intact', () {
      expect(firestoreInvoiceNumber(42), 42);
      expect(firestoreInvoiceNumber('42'), 42);
    });

    test('returns 0 for garbage so old documents never crash', () {
      expect(firestoreInvoiceNumber(null), 0);
      expect(firestoreInvoiceNumber(''), 0);
    });

    test('labels legacy numbers as strings', () {
      expect(firestoreInvoiceNumberLabel(42), '42');
      expect(firestoreInvoiceNumberLabel('INV-2026-0003'), 'INV-2026-0003');
    });
  });

  group('previewInvoiceNumber', () {
    test('is the next number after the loaded invoices', () {
      Get.reset();
      final controller = Get.put(InvoiceController(), permanent: true);
      controller.invoices.addAll([
        _invoice('a', 'INV-2026-0001'),
        _invoice('b', 'INV-2026-0002'),
        _invoice('c', 'INV-2026-0003'),
      ]);

      expect(controller.previewInvoiceNumber(), 'INV-2026-0004');
    });

    test('handles legacy numeric invoices', () {
      Get.reset();
      final controller = Get.put(InvoiceController(), permanent: true);
      controller.invoices.addAll([
        _invoice('a', '1'),
        _invoice('b', '2'),
      ]);

      expect(controller.previewInvoiceNumber(), 'INV-2026-0003');
    });
  });

  group('displayNumber', () {
    test('new numbers show as-is, legacy numbers keep the # style', () {
      expect(_invoice('a', 'INV-2026-0001').displayNumber, 'INV-2026-0001');
      expect(_invoice('b', '1').displayNumber, '#1');
    });
  });
}