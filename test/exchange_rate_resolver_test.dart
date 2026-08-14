import 'package:flutter_test/flutter_test.dart';

import 'package:erp_mobileapp_ui/core/utils/exchange_rate_resolver.dart';

void main() {
  const baseCurrencyId = 'usd';
  final rates = <String, double>{
    'eur': 1.18,
    'jpy': 0.0071,
  };

  group('rateToBase', () {
    test('base currency is always 1', () {
      expect(
        ExchangeRateResolver.rateToBase(rates, baseCurrencyId, baseCurrencyId),
        1,
      );
    });

    test('returns configured rate for other currencies', () {
      expect(
        ExchangeRateResolver.rateToBase(rates, 'eur', baseCurrencyId),
        1.18,
      );
    });

    test('returns null when the rate is missing', () {
      expect(
        ExchangeRateResolver.rateToBase(rates, 'gbp', baseCurrencyId),
        isNull,
      );
    });

    test('returns null for a zero or negative rate', () {
      final invalid = <String, double>{'gbp': 0, 'x': -1};
      expect(
        ExchangeRateResolver.rateToBase(invalid, 'gbp', baseCurrencyId),
        isNull,
      );
      expect(
        ExchangeRateResolver.rateToBase(invalid, 'x', baseCurrencyId),
        isNull,
      );
    });
  });

  group('rateBetween', () {
    test('same currency returns 1', () {
      expect(
        ExchangeRateResolver.rateBetween(rates, 'eur', 'eur', baseCurrencyId),
        1,
      );
    });

    test('base to foreign is the stored rateToBase', () {
      expect(
        ExchangeRateResolver.rateBetween(
          rates,
          baseCurrencyId,
          'eur',
          baseCurrencyId,
        ),
        closeTo(0.8475, 0.001),
      );
    });

    test('foreign to base is the inverse', () {
      expect(
        ExchangeRateResolver.rateBetween(
          rates,
          'eur',
          baseCurrencyId,
          baseCurrencyId,
        ),
        closeTo(1.18, 0.001),
      );
    });

    test('foreign to foreign divides the rates', () {
      expect(
        ExchangeRateResolver.rateBetween(
          rates,
          'eur',
          'jpy',
          baseCurrencyId,
        ),
        closeTo(166.197, 0.001),
      );
    });

    test('returns null when either rate is missing', () {
      expect(
        ExchangeRateResolver.rateBetween(
          rates,
          'eur',
          'gbp',
          baseCurrencyId,
        ),
        isNull,
      );
      expect(
        ExchangeRateResolver.rateBetween(
          rates,
          'gbp',
          'usd',
          baseCurrencyId,
        ),
        isNull,
      );
    });
  });

  group('convertAmount', () {
    test('converts between currencies', () {
      expect(
        ExchangeRateResolver.convertAmount(
          100,
          rates,
          'eur',
          'jpy',
          baseCurrencyId,
        ),
        closeTo(16619.72, 0.01),
      );
    });

    test('returns null when a rate is missing', () {
      expect(
        ExchangeRateResolver.convertAmount(
          100,
          rates,
          'eur',
          'gbp',
          baseCurrencyId,
        ),
        isNull,
      );
    });
  });
}
