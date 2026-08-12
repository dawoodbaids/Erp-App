import 'package:flutter_test/flutter_test.dart';

import 'package:erp_mobileapp_ui/core/utils/currency_converter.dart';
import 'package:erp_mobileapp_ui/core/network/mock_api.dart';
import 'package:erp_mobileapp_ui/models/invoice.dart';
import 'package:erp_mobileapp_ui/models/invoice_item.dart';
import 'package:erp_mobileapp_ui/models/customer.dart';
import 'package:erp_mobileapp_ui/models/currency.dart';

/// JOD is the base currency. RateToBase values per the spec:
/// USD = 0.709, EUR = 0.825, SAR = 0.189, AED = 0.193, GBP = 0.950.
class _Rates {
  static double of(String code) {
    switch (code) {
      case 'JOD':
        return 1.0;
      case 'USD':
        return 0.709;
      case 'EUR':
        return 0.825;
      case 'SAR':
        return 0.189;
      case 'AED':
        return 0.193;
      case 'GBP':
        return 0.950;
    }
    return 1.0;
  }
}

double _convert(double amount, String from, String to) {
  return CurrencyConverter.convert(amount, _Rates.of(from), _Rates.of(to));
}

void main() {
  group('Universal conversion test matrix (section 16)', () {
    test('JOD → USD: 180 / 0.709 = 253.88 USD', () {
      expect(_convert(180, 'JOD', 'USD'), 253.88);
    });

    test('JOD → EUR: 180 / 0.825 = 218.18 EUR', () {
      expect(_convert(180, 'JOD', 'EUR'), 218.18);
    });

    test('USD → JOD: 100 * 0.709 = 70.90 JOD', () {
      expect(_convert(100, 'USD', 'JOD'), 70.90);
    });

    test('EUR → JOD: 100 * 0.825 = 82.50 JOD', () {
      expect(_convert(100, 'EUR', 'JOD'), 82.50);
    });

    test('USD → EUR: 100 * 0.709 / 0.825 = 85.94 EUR', () {
      expect(_convert(100, 'USD', 'EUR'), 85.94);
    });

    test('EUR → USD: 100 * 0.825 / 0.709 = 116.36 USD', () {
      expect(_convert(100, 'EUR', 'USD'), 116.36);
    });

    test('SAR → AED: 100 * 0.189 / 0.193 = 97.93 AED', () {
      expect(_convert(100, 'SAR', 'AED'), 97.93);
    });

    test('AED → GBP: 100 * 0.193 / 0.950 = 20.32 GBP', () {
      expect(_convert(100, 'AED', 'GBP'), 20.32);
    });

    test('Same currency: 180 JOD → JOD = 180 JOD (no conversion)', () {
      expect(_convert(180, 'JOD', 'JOD'), 180);
    });

    test('Base currency always converts as rate 1', () {
      expect(_convert(1, 'JOD', 'USD'), 1.41);
      expect(_convert(1, 'USD', 'JOD'), 0.71);
    });
  });

  group('Backend (mock) applies conversion when creating an invoice', () {
    setUp(() {
      MockApi.instance.reset();
    });

    test('multi-currency products are each converted into the invoice currency',
        () {
      // Product A: 100 JOD (id 7 is USD 100; ids 1-6 are JOD in mock).
      // Use invoice currency AED: 1 AED = 0.193 JOD.
      final jodProduct = InvoiceItem(
        id: 'x',
        productId: '2', // Wireless Mouse, 10 JOD
        productName: 'Wireless Mouse',
        barcode: '629100000002',
        originalUnitPrice: 10,
        originalCurrencyId: '1',
        originalCurrencyCode: 'JOD',
        quantity: 1,
        unitPrice: 0,
        taxRate: 16,
        lineTotal: 0,
      );
      final usdProduct = InvoiceItem(
        id: 'y',
        productId: '7', // Gaming Mouse (Import), 100 USD
        productName: 'Gaming Mouse (Import)',
        barcode: '629100000007',
        originalUnitPrice: 100,
        originalCurrencyId: '2',
        originalCurrencyCode: 'USD',
        quantity: 1,
        unitPrice: 0,
        taxRate: 16,
        lineTotal: 0,
      );

      final draft = Invoice(
        id: '',
        invoiceNumber: '',
        customer: const Customer(id: '1', name: 'ABC Company'),
        currency: const Currency(
          id: '5',
          code: 'AED',
          name: 'UAE Dirham',
          symbol: 'AED',
        ),
        exchangeRate: 0.193,
        taxMode: TaxMode.exclusive,
        status: InvoiceStatus.draft,
        items: [jodProduct, usdProduct],
        subtotal: 0,
        taxAmount: 0,
        totalAmount: 0,
        createdAt: DateTime.now(),
      );

      final created = MockApi.instance.handle(
        'POST',
        '/api/invoices',
        data: draft.toCreateRequest(),
      ) as Map<String, dynamic>;

      final items = (created['items'] as List).cast<Map<String, dynamic>>();
      final jod = items.firstWhere(
        (i) => i['productId'] == 2,
      );
      final usd = items.firstWhere(
        (i) => i['productId'] == 7,
      );

      // 10 JOD → AED: 10 * 1 / 0.193 = 51.81 AED
      expect(jod['unitPrice'], 51.81);
      // 100 USD → AED: 100 * 0.709 / 0.193 = 367.36 AED
      expect(usd['unitPrice'], 367.36);
      // Tax rate must be copied from the product (16%), not the client.
      expect(usd['taxRate'], 16);
      expect(usd['originalCurrencyCode'], 'USD');
      expect(usd['originalUnitPrice'], 100);
    });
  });
}
