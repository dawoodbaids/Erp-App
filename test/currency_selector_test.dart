import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';

import 'package:erp_mobileapp_ui/controllers/create_invoice_controller.dart';
import 'package:erp_mobileapp_ui/controllers/customer_controller.dart';
import 'package:erp_mobileapp_ui/controllers/settings_controller.dart';
import 'package:erp_mobileapp_ui/core/localization/app_translations.dart';
import 'package:erp_mobileapp_ui/models/currency.dart';
import 'package:erp_mobileapp_ui/models/customer.dart';
import 'package:erp_mobileapp_ui/widgets/currency_selector.dart';
import 'package:erp_mobileapp_ui/widgets/customer_selector.dart';

void main() {
  setUp(() {
    Get.reset();
    final settings = Get.put(SettingsController(), permanent: true);
    settings.currencies.add(
      const Currency(
        id: 'usd',
        code: 'USD',
        name: 'US Dollar',
        symbol: r'$',
        isBaseCurrency: true,
      ),
    );
    Get.put(CustomerController(), permanent: true);
    Get.put(CreateInvoiceController(), permanent: true);
  });

  Future<void> pumpSelector(WidgetTester tester) async {
    await tester.pumpWidget(
      GetMaterialApp(
        translations: AppTranslations(),
        locale: const Locale('en'),
        home: const Scaffold(body: CurrencySelector()),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('currency selector renders without GetX misuse', (tester) async {
    await pumpSelector(tester);

    expect(tester.takeException(), isNull);
    expect(find.text('USD'), findsOneWidget);
  });

  testWidgets('currency selector survives a list reload with new instances',
      (tester) async {
    await pumpSelector(tester);

    final settings = Get.find<SettingsController>();
    settings.currencies.value = [
      const Currency(
        id: 'usd',
        code: 'USD',
        name: 'US Dollar',
        symbol: r'$',
        isBaseCurrency: true,
      ),
      const Currency(id: 'eur', code: 'EUR', name: 'Euro', symbol: '€'),
    ];
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(find.text('USD'), findsOneWidget);
  });

  testWidgets(
      'customer currency stored as a code still shows text in the dropdown',
      (tester) async {
    final settings = Get.find<SettingsController>();
    settings.currencies.add(
      const Currency(
        id: 'jod-doc',
        code: 'JOD',
        name: 'Jordanian Dinar',
        symbol: 'JD',
      ),
    );
    Get.find<CustomerController>().customers.add(
      const Customer(id: 'c1', name: 'Amman Co', currencyId: 'JOD'),
    );

    await tester.pumpWidget(
      GetMaterialApp(
        translations: AppTranslations(),
        locale: const Locale('en'),
        home: const Scaffold(
          body: Column(
            children: [
              CustomerSelector(),
              CurrencySelector(),
            ],
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    // Select the customer whose currencyId is stored as the code "JOD".
    await tester.tap(find.byType(DropdownButtonFormField<String>).first);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Amman Co').last);
    await tester.pumpAndSettle();

    final controller = Get.find<CreateInvoiceController>();
    expect(controller.selectedCustomerId.value, 'c1');
    expect(controller.selectedCurrency.value?.id, 'jod-doc');
    expect(controller.selectedCurrency.value?.code, 'JOD');
    expect(tester.takeException(), isNull);
    // The currency dropdown must show the resolved currency text.
    expect(find.text('JOD'), findsOneWidget);
  });

  testWidgets('the user can change the invoice currency at any time',
      (tester) async {
    final settings = Get.find<SettingsController>();
    settings.currencies.addAll([
      const Currency(
        id: 'jod-doc',
        code: 'JOD',
        name: 'Jordanian Dinar',
        symbol: 'JD',
      ),
      const Currency(id: 'eur', code: 'EUR', name: 'Euro', symbol: '€'),
    ]);
    Get.find<CustomerController>().customers.add(
      const Customer(id: 'c1', name: 'Amman Co', currencyId: 'jod-doc'),
    );

    await tester.pumpWidget(
      GetMaterialApp(
        translations: AppTranslations(),
        locale: const Locale('en'),
        home: const Scaffold(
          body: Column(
            children: [
              CustomerSelector(),
              CurrencySelector(),
            ],
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    // The customer auto-applies its own currency (JOD) ...
    await tester.tap(find.byType(DropdownButtonFormField<String>).first);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Amman Co').last);
    await tester.pumpAndSettle();
    final controller = Get.find<CreateInvoiceController>();
    expect(controller.selectedCurrency.value?.code, 'JOD');

    // ... but the user can still switch to EUR afterwards.
    await tester.tap(find.byType(DropdownButtonFormField<String>).last);
    await tester.pumpAndSettle();
    await tester.tap(find.text('EUR').last);
    await tester.pumpAndSettle();

    expect(controller.selectedCurrency.value?.code, 'EUR');
    expect(controller.selectedCurrency.value?.id, 'eur');
    expect(tester.takeException(), isNull);
  });
}
