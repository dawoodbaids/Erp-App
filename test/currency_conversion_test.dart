import 'package:flutter_test/flutter_test.dart';

import 'package:erp_mobileapp_ui/core/utils/currency_converter.dart';

class _Rates {
  static double of(String code) {
    switch (code) {
      case 'BASE':
        return 1;
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
    return 1;
  }
}

double _convert(double amount, String from, String to) {
  return CurrencyConverter.convert(amount, _Rates.of(from), _Rates.of(to));
}

void main() {
  group('Currency conversion', () {
    test('converts from the base currency', () {
      expect(_convert(180, 'BASE', 'USD'), 253.88);
      expect(_convert(180, 'BASE', 'EUR'), 218.18);
    });

    test('converts into the base currency', () {
      expect(_convert(100, 'USD', 'BASE'), 70.90);
      expect(_convert(100, 'EUR', 'BASE'), 82.50);
    });

    test('converts between non-base currencies', () {
      expect(_convert(100, 'USD', 'EUR'), 85.94);
      expect(_convert(100, 'AED', 'GBP'), 20.32);
    });

    test('keeps the amount unchanged for the same currency', () {
      expect(_convert(180, 'BASE', 'BASE'), 180);
    });
  });
}
