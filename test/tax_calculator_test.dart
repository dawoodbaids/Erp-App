import 'package:flutter_test/flutter_test.dart';

import 'package:erp_mobileapp_ui/core/utils/tax_calculator.dart';
import 'package:erp_mobileapp_ui/models/currency.dart';
import 'package:erp_mobileapp_ui/models/customer.dart';
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
        id: 'product-1',
        name: 'Test Product',
        barcode: '123456',
        price: 10,
        taxRate: 16,
        currencyId: 'currency-1',
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
      Invoice invoice(InvoiceStatus status) => Invoice(
        id: 'invoice-${status.name}',
        invoiceNumber: 'INV-${status.name}',
        customer: const Customer(id: 'customer-1', name: 'Test Customer'),
        currency: const Currency(
          id: 'currency-1',
          code: 'TST',
          name: 'Test Currency',
          symbol: 'TST',
        ),
        exchangeRate: 1,
        taxMode: TaxMode.exclusive,
        status: status,
        items: const [],
        subtotal: 0,
        taxAmount: 0,
        totalAmount: 0,
        createdAt: DateTime(2025),
      );

      expect(invoice(InvoiceStatus.draft).isEditable, isTrue);
      expect(invoice(InvoiceStatus.approved).isEditable, isFalse);
      expect(invoice(InvoiceStatus.cancelled).isEditable, isFalse);
    });
  });
}
