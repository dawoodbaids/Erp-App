import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';

import 'package:erp_mobileapp_ui/controllers/settings_controller.dart';
import 'package:erp_mobileapp_ui/models/currency.dart';
import 'package:erp_mobileapp_ui/models/exchange_rate.dart';

void main() {
  late SettingsController settings;

  setUp(() {
    Get.reset();
    settings = Get.put(SettingsController(), permanent: true);
    settings.currencies.value = [
      const Currency(
        id: 'usd-doc',
        code: 'USD',
        name: 'US Dollar',
        symbol: r'$',
        isBaseCurrency: true,
      ),
      const Currency(
        id: 'jod-doc',
        code: 'JOD',
        name: 'Jordanian Dinar',
        symbol: 'JD',
      ),
    ];
  });

  group('currencyById resolves document IDs and codes', () {
    test('resolves a document ID', () {
      expect(settings.currencyById('jod-doc')?.code, 'JOD');
    });

    test('resolves a currency code stored in place of an ID', () {
      expect(settings.currencyById('JOD')?.id, 'jod-doc');
      expect(settings.currencyById('jod')?.id, 'jod-doc');
    });

    test('returns null for unknown values', () {
      expect(settings.currencyById('XYZ'), isNull);
      expect(settings.currencyById(''), isNull);
    });
  });

  group('rateForCurrency tolerates rates stored by code', () {
    test('finds the rate when the rate document stores the currency code', () {
      settings.exchangeRates.value = [
        ExchangeRate(
          id: 'rate-1',
          currencyId: 'JOD',
          rateToBase: 0.709,
          effectiveDate: DateTime(2026, 1, 1),
        ),
      ];

      // Looking up by the document ID must still find the code-stored rate,
      // otherwise the invoice form shows a missing rate / no rate text.
      expect(settings.rateForCurrency('jod-doc'), closeTo(0.709, 0.001));
      expect(settings.rateForCurrency('JOD'), closeTo(0.709, 0.001));
    });

    test('base currency always returns 1', () {
      expect(settings.rateForCurrency('usd-doc'), 1);
      expect(settings.rateForCurrency('USD'), 1);
    });

    test('returns null when no rate exists', () {
      expect(settings.rateForCurrency('jod-doc'), isNull);
    });
  });

  group('tryConvert uses id-or-code rates', () {
    test('converts using a code-stored rate', () {
      settings.exchangeRates.value = [
        ExchangeRate(
          id: 'rate-1',
          currencyId: 'JOD',
          rateToBase: 0.709,
          effectiveDate: DateTime(2026, 1, 1),
        ),
      ];

      // 100 JOD = 70.90 USD
      expect(
        settings.tryConvert(100, 'jod-doc', 'usd-doc'),
        closeTo(70.9, 0.01),
      );
    });

    test('returns null when a required rate is missing', () {
      expect(settings.tryConvert(100, 'jod-doc', 'usd-doc'), isNull);
    });
  });
}
