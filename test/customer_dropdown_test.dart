import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';

import 'package:erp_mobileapp_ui/controllers/create_invoice_controller.dart';
import 'package:erp_mobileapp_ui/controllers/customer_controller.dart';
import 'package:erp_mobileapp_ui/controllers/settings_controller.dart';
import 'package:erp_mobileapp_ui/core/localization/app_translations.dart';
import 'package:erp_mobileapp_ui/models/currency.dart';
import 'package:erp_mobileapp_ui/models/customer.dart';
import 'package:erp_mobileapp_ui/models/invoice.dart';
import 'package:erp_mobileapp_ui/models/invoice_item.dart';
import 'package:erp_mobileapp_ui/widgets/customer_selector.dart';

void main() {
  late SettingsController settings;
  late CustomerController customerController;
  late CreateInvoiceController invoiceController;

  setUp(() {
    Get.reset();
    settings = Get.put(SettingsController(), permanent: true);
    settings.currencies.add(
      const Currency(
        id: 'usd',
        code: 'USD',
        name: 'US Dollar',
        symbol: r'$',
        isBaseCurrency: true,
      ),
    );
    customerController = Get.put(CustomerController(), permanent: true);
    invoiceController = Get.put(CreateInvoiceController(), permanent: true);
  });

  Future<void> pumpSelector(WidgetTester tester) async {
    await tester.pumpWidget(
      GetMaterialApp(
        translations: AppTranslations(),
        locale: const Locale('en'),
        home: const Scaffold(body: CustomerSelector()),
      ),
    );
    await tester.pumpAndSettle();
  }

  Future<void> selectCustomer(WidgetTester tester, String name) async {
    await tester.tap(find.byType(DropdownButtonFormField<String>));
    await tester.pumpAndSettle();
    await tester.tap(find.text(name).last);
    await tester.pumpAndSettle();
  }

  testWidgets(
    'selection survives a customer list reload with new Customer instances',
    (tester) async {
      customerController.customers.add(
        const Customer(id: 'abc', name: 'ABC Company', currencyId: 'usd'),
      );
      await pumpSelector(tester);

      await selectCustomer(tester, 'ABC Company');
      expect(invoiceController.selectedCustomerId.value, 'abc');
      expect(invoiceController.selectedCustomer?.name, 'ABC Company');

      // Simulate a Firebase reload: brand-new Customer object for the same
      // document ID. The old code kept the previous object as the dropdown
      // value and crashed with the "exactly one item" assertion.
      customerController.customers.value = [
        const Customer(id: 'abc', name: 'ABC Company', currencyId: 'usd'),
      ];
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(invoiceController.selectedCustomerId.value, 'abc');
      expect(invoiceController.selectedCustomer?.name, 'ABC Company');
      expect(find.text('ABC Company'), findsOneWidget);
    },
  );

  testWidgets('duplicate Firebase document IDs produce a single item',
      (tester) async {
    customerController.customers.value = [
      const Customer(id: 'abc', name: 'ABC Company'),
      const Customer(id: 'abc', name: 'ABC Company'),
    ];
    await pumpSelector(tester);

    await tester.tap(find.byType(DropdownButtonFormField<String>));
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    // Only the menu's deduplicated item; a second identical item would assert
    // or render twice inside the overlay.
    expect(
      find.descendant(
        of: find.byType(Overlay),
        matching: find.text('ABC Company'),
      ),
      findsOneWidget,
    );
  });

  testWidgets('selection is cleared when the customer no longer exists',
      (tester) async {
    customerController.customers.add(
      const Customer(id: 'abc', name: 'ABC Company', currencyId: 'usd'),
    );
    await pumpSelector(tester);

    await selectCustomer(tester, 'ABC Company');
    expect(invoiceController.selectedCustomerId.value, 'abc');

    customerController.customers.value = [
      const Customer(id: 'other', name: 'Other Co', currencyId: 'usd'),
    ];
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(invoiceController.selectedCustomerId.value, isNull);
    expect(invoiceController.selectedCustomer, isNull);
  });

  testWidgets('selecting a customer applies the customer currency',
      (tester) async {
    settings.currencies.add(
      const Currency(
        id: 'jod',
        code: 'JOD',
        name: 'Jordanian Dinar',
        symbol: 'JD',
      ),
    );
    customerController.customers.add(
      const Customer(id: 'x1', name: 'Amman Co', currencyId: 'jod'),
    );
    await pumpSelector(tester);

    await selectCustomer(tester, 'Amman Co');

    expect(invoiceController.selectedCustomerId.value, 'x1');
    expect(invoiceController.selectedCustomer?.currencyId, 'jod');
    expect(invoiceController.selectedCurrency.value?.id, 'jod');
  });

  testWidgets(
    'edit mode keeps a saved customer visible when it was removed from the list',
    (tester) async {
      invoiceController.loadForEdit(
        Invoice(
          id: 'inv-1',
          invoiceNumber: '7',
          invoiceName: 'Invoice 7',
          customer: const Customer(
            id: 'gone',
            name: 'Gone Co',
            currencyId: 'usd',
          ),
          currency: settings.defaultCurrency!,
          exchangeRate: 1,
          taxMode: TaxMode.exclusive,
          status: InvoiceStatus.draft,
          items: const <InvoiceItem>[],
          subtotal: 0,
          taxAmount: 0,
          totalAmount: 0,
          createdAt: DateTime(2026, 1, 1),
        ),
      );
      await pumpSelector(tester);

      expect(tester.takeException(), isNull);
      expect(invoiceController.selectedCustomerId.value, 'gone');
      expect(invoiceController.selectedCustomer?.name, 'Gone Co');
      expect(find.text('Gone Co'), findsOneWidget);
    },
  );
}
