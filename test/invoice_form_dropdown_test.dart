import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';

import 'package:erp_mobileapp_ui/controllers/create_invoice_controller.dart';
import 'package:erp_mobileapp_ui/controllers/customer_controller.dart';
import 'package:erp_mobileapp_ui/controllers/invoice_controller.dart';
import 'package:erp_mobileapp_ui/controllers/product_controller.dart';
import 'package:erp_mobileapp_ui/controllers/settings_controller.dart';
import 'package:erp_mobileapp_ui/controllers/shell_controller.dart';
import 'package:erp_mobileapp_ui/core/localization/app_translations.dart';
import 'package:erp_mobileapp_ui/core/theme/app_theme.dart';
import 'package:erp_mobileapp_ui/models/currency.dart';
import 'package:erp_mobileapp_ui/models/customer.dart';
import 'package:erp_mobileapp_ui/screens/invoice_form/invoice_form_screen.dart';

void main() {
  late SettingsController settings;

  setUp(() {
    Get.reset();
    settings = Get.put(SettingsController(), permanent: true);
    Get.put(ProductController(), permanent: true);
    Get.put(InvoiceController(), permanent: true);
    Get.put(CustomerController(), permanent: true);
    Get.put(ShellController(), permanent: true);
  });

  Future<void> pumpInvoiceForm(WidgetTester tester) async {
    // CreateInvoiceController is registered AFTER currencies are loaded so
    // its onInit never touches Firestore in the test.
    Get.put(CreateInvoiceController(), permanent: true);
    await tester.pumpWidget(
      GetMaterialApp(
        theme: AppTheme.dark,
        translations: AppTranslations(),
        locale: const Locale('en'),
        home: const InvoiceFormScreen(),
      ),
    );
    await tester.pumpAndSettle();
  }

  Future<void> selectCustomer(WidgetTester tester, String name) async {
    await tester.tap(find.byType(DropdownButtonFormField<String>).first);
    await tester.pumpAndSettle();
    await tester.tap(find.text(name).last);
    await tester.pumpAndSettle();
  }

  testWidgets(
      'currency dropdown shows a label even when the Firebase document has '
      'no code field', (tester) async {
    // Simulates hand-created documents: the currency doc stores only a name
    // (and uses the document ID as the code, e.g. `currencies/usd`).
    settings.currencies.value = [
      Currency.fromFirestore('usd', {
        'name': 'US Dollar',
        'isBaseCurrency': true,
      }),
      Currency.fromFirestore('jod', {
        'name': 'Jordanian Dinar',
      }),
    ];
    await pumpInvoiceForm(tester);

    expect(tester.takeException(), isNull);
    // The dropdown must show a non-empty label (falls back to the name).
    expect(find.text('US Dollar'), findsOneWidget);
  });

  testWidgets(
      'currency dropdown shows the code for well-formed documents',
      (tester) async {
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
    await pumpInvoiceForm(tester);

    expect(tester.takeException(), isNull);
    expect(find.text('USD'), findsOneWidget);
  });

  testWidgets(
      'selecting a customer with a code-based currency shows the currency '
      'in the dropdown', (tester) async {
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
    Get.find<CustomerController>().customers.add(
      const Customer(id: 'c1', name: 'Amman Co', currencyId: 'JOD'),
    );
    await pumpInvoiceForm(tester);

    await selectCustomer(tester, 'Amman Co');

    final controller = Get.find<CreateInvoiceController>();
    expect(controller.selectedCustomerId.value, 'c1');
    expect(controller.selectedCurrency.value?.id, 'jod-doc');
    expect(tester.takeException(), isNull);
    // The currency dropdown button now shows the customer's currency.
    expect(find.text('JOD'), findsOneWidget);
  });
}
