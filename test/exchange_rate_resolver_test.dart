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

  group('rateForCurrencyOrCode', () {
    test('matches by currency document ID', () {
      expect(
        ExchangeRateResolver.rateForCurrencyOrCode(rates, 'eur', 'EUR'),
        1.18,
      );
    });

    test('matches by code when the rate is stored against the code', () {
      expect(
        ExchangeRateResolver.rateForCurrencyOrCode(rates, 'eur-id', 'eur'),
        1.18,
      );
    });

    test('matches a case-insensitive stored code', () {
      expect(
        ExchangeRateResolver.rateForCurrencyOrCode(
          <String, double>{'JOD': 0.709},
          'unknown-id',
          'jod',
        ),
        0.709,
      );
    });

    test('returns null when no positive rate exists', () {
      expect(
        ExchangeRateResolver.rateForCurrencyOrCode(
          <String, double>{'gbp': 0},
          'gbp',
          'GBP',
        ),
        isNull,
      );
      expect(
        ExchangeRateResolver.rateForCurrencyOrCode(rates, 'missing', 'XYZ'),
        isNull,
      );
    });
  });

  group('rateBetweenAny', () {
    test('same currency by code returns 1 without a rate', () {
      expect(
        ExchangeRateResolver.rateBetweenAny(
          rates,
          'eur-a',
          'eur',
          'eur-b',
          'EUR',
          baseCurrencyId,
          'usd',
        ),
        1,
      );
    });

    test('base currency identified by code needs no rate document', () {
      expect(
        ExchangeRateResolver.rateBetweenAny(
          rates,
          'usd-doc',
          'USD',
          'eur-x',
          'EUR',
          baseCurrencyId,
          'usd',
        ),
        closeTo(0.8475, 0.001),
      );
    });

    test('converts when the source rate is stored by code', () {
      final codeRates = <String, double>{'jod': 0.709};
      final rate = ExchangeRateResolver.rateBetweenAny(
        codeRates,
        'usd-id',
        'USD',
        'jod-id',
        'JOD',
        baseCurrencyId,
        'usd',
      );
      expect(rate, isNotNull);
      expect(rate!, closeTo(1.4104, 0.001));
    });

    test('returns null when a required rate is missing', () {
      expect(
        ExchangeRateResolver.rateBetweenAny(
          rates,
          'gbp',
          'GBP',
          'eur',
          'EUR',
          baseCurrencyId,
          'usd',
        ),
        isNull,
      );
    });
  });

  group('resolveCurrencyId', () {
    test('keeps an ID that is already indexed', () {
      expect(
        ExchangeRateResolver.resolveCurrencyId(
          rates,
          'eur',
          const {'eur': 'eur'},
        ),
        'eur',
      );
    });

    test('resolves a code to its canonical ID', () {
      expect(
        ExchangeRateResolver.resolveCurrencyId(
          rates,
          'EUR',
          const {'eur': 'eur-doc-id'},
        ),
        'eur-doc-id',
      );
    });

    test('returns the original value when unresolvable', () {
      expect(
        ExchangeRateResolver.resolveCurrencyId(
          rates,
          'unknown',
          const {'eur': 'eur-doc-id'},
        ),
        'unknown',
      );
    });
  });
}
