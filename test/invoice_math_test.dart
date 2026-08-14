import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';

import 'package:erp_mobileapp_ui/controllers/settings_controller.dart';
import 'package:erp_mobileapp_ui/core/utils/tax_calculator.dart';
import 'package:erp_mobileapp_ui/models/currency.dart';
import 'package:erp_mobileapp_ui/models/exchange_rate.dart';
import 'package:erp_mobileapp_ui/models/invoice.dart';
import 'package:erp_mobileapp_ui/models/invoice_item.dart';

InvoiceItem _item(double unitPrice, double quantity, {double taxRate = 16}) {
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
  group('Test 1: basic tax math', () {
    test('10 USD at 16% gives subtotal 10.00, tax 1.60, total 11.60', () {
      final items = [_item(10, 1)];

      expect(TaxCalculator.subtotal(items), 10.00);
      expect(
        TaxCalculator.taxAmount(10, 0, 16, TaxMode.exclusive),
        1.60,
      );
      expect(
        TaxCalculator.total(10, 0, 16, TaxMode.exclusive),
        11.60,
      );
    });
  });

  group('Test 2: discount reduces the taxable amount', () {
    test('100 USD at 16% with a 10 discount', () {
      final items = [_item(100, 1)];

      expect(TaxCalculator.subtotal(items), 100.00);
      expect(TaxCalculator.taxableAmount(100, 10), 90.00);
      expect(
        TaxCalculator.taxAmount(100, 10, 16, TaxMode.exclusive),
        14.40,
      );
      expect(
        TaxCalculator.total(100, 10, 16, TaxMode.exclusive),
        104.40,
      );
    });
  });

  group('Test 3: conversion happens first, then tax', () {
    test('100 JOD -> 141.04 USD at 0.709, then 16% tax', () {
      Get.reset();
      final settings = Get.put(SettingsController(), permanent: true);
      settings.currencies.value = [
        const Currency(
          id: 'jod-doc',
          code: 'JOD',
          name: 'Jordanian Dinar',
          symbol: 'JD',
          isBaseCurrency: true,
        ),
        const Currency(
          id: 'usd-doc',
          code: 'USD',
          name: 'US Dollar',
          symbol: r'$',
        ),
      ];
      settings.exchangeRates.value = [
        ExchangeRate(
          id: 'rate-usd',
          currencyId: 'usd-doc',
          rateToBase: 0.709,
          effectiveDate: DateTime(2026, 1, 1),
        ),
      ];

      final converted = settings.tryConvert(100, 'jod-doc', 'usd-doc');
      expect(converted, closeTo(141.04, 0.01));

      final items = [_item(converted!, 1)];
      expect(TaxCalculator.subtotal(items), closeTo(141.04, 0.01));
      expect(
        TaxCalculator.taxAmount(141.04, 0, 16, TaxMode.exclusive),
        closeTo(22.57, 0.01),
      );
      expect(
        TaxCalculator.total(141.04, 0, 16, TaxMode.exclusive),
        closeTo(163.61, 0.01),
      );
    });
  });

  group('Multiple products', () {
    test('10 x1 + 20 x2 = 50 subtotal, 8 tax, 58 total at 16%', () {
      final items = [_item(10, 1), _item(20, 2)];

      expect(TaxCalculator.subtotal(items), 50.00);
      expect(
        TaxCalculator.taxAmount(50, 0, 16, TaxMode.exclusive),
        8.00,
      );
      expect(
        TaxCalculator.total(50, 0, 16, TaxMode.exclusive),
        58.00,
      );
    });

    test('line totals are per item and net of tax', () {
      final item = _item(20, 2);
      expect(TaxCalculator.lineTotal(item, TaxMode.exclusive), 40.00);
      expect(TaxCalculator.lineTotal(item, TaxMode.inclusive), 40.00);
    });
  });
}
