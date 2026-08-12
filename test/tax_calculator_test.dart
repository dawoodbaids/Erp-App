import 'package:flutter_test/flutter_test.dart';

import 'package:erp_mobileapp_ui/core/constants/mock_data.dart';
import 'package:erp_mobileapp_ui/core/utils/tax_calculator.dart';
import 'package:erp_mobileapp_ui/models/invoice.dart';
import 'package:erp_mobileapp_ui/models/invoice_item.dart';
import 'package:erp_mobileapp_ui/models/product.dart';

InvoiceItem _item({double quantity = 1, double unitPrice = 0, double taxRate = 0}) {
  return InvoiceItem(
    id: 'it',
    productId: 'p',
    productName: 'Test',
    barcode: '123',
    quantity: quantity,
    unitPrice: unitPrice,
    taxRate: taxRate,
    lineTotal: 0,
  );
}

void main() {
  group('Tax exclusive', () {
    test('calculates subtotal, tax and total', () {
      final items = [
        _item(quantity: 2, unitPrice: 100, taxRate: 16),
      ];

      expect(TaxCalculator.subtotal(items, TaxMode.exclusive), 200);
      expect(TaxCalculator.tax(items, TaxMode.exclusive), 32);
      expect(TaxCalculator.total(items, TaxMode.exclusive), 232);
      expect(TaxCalculator.lineTotal(items.first, TaxMode.exclusive), 232);
    });

    test('product tax rate feeds the invoice item', () {
      const product = Product(
        id: 'P1',
        name: 'Wireless Mouse',
        barcode: '629100000002',
        price: 10,
        taxRate: 16,
        currencyId: 'cur-jod',
      );
      final item = InvoiceItem(
        id: 'i1',
        productId: product.id,
        productName: product.name,
        barcode: product.barcode,
        quantity: 2,
        unitPrice: product.price,
        taxRate: product.taxRate,
        lineTotal: 0,
      );

      expect(item.taxRate, 16);
      expect(TaxCalculator.total([item], TaxMode.exclusive), 23.20);
    });
  });

  group('Tax inclusive', () {
    test('derives net and tax from a gross of 116 at 16%', () {
      final items = [
        _item(quantity: 1, unitPrice: 116, taxRate: 16),
      ];

      expect(TaxCalculator.subtotal(items, TaxMode.inclusive), 100);
      expect(TaxCalculator.tax(items, TaxMode.inclusive), 16);
      expect(TaxCalculator.total(items, TaxMode.inclusive), 116);
    });
  });

  group('Editability rule', () {
    test('only drafts are editable', () {
      final draft = MockData.invoices.firstWhere(
        (i) => i.status == InvoiceStatus.draft,
      );
      final approved = MockData.invoices.firstWhere(
        (i) => i.status == InvoiceStatus.approved,
      );
      final cancelled = MockData.invoices.firstWhere(
        (i) => i.status == InvoiceStatus.cancelled,
      );

      expect(draft.isEditable, isTrue);
      expect(approved.isEditable, isFalse);
      expect(cancelled.isEditable, isFalse);
    });
  });

  group('Mock data', () {
    test('contains the five required invoice statuses', () {
      final statuses = MockData.invoices.map((i) => i.status).toSet();

      expect(statuses, contains(InvoiceStatus.draft));
      expect(statuses, contains(InvoiceStatus.approved));
      expect(statuses, contains(InvoiceStatus.cancelled));
      expect(MockData.invoices.length, greaterThanOrEqualTo(5));
    });

    test('every product carries its own tax rate', () {
      for (final product in MockData.products) {
        expect(product.taxRate, greaterThan(0));
      }
    });
  });
}
