import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:erp_mobileapp_ui/controllers/auth_controller.dart';
import 'package:erp_mobileapp_ui/controllers/create_invoice_controller.dart';
import 'package:erp_mobileapp_ui/controllers/customer_controller.dart';
import 'package:erp_mobileapp_ui/controllers/dashboard_controller.dart';
import 'package:erp_mobileapp_ui/controllers/invoice_controller.dart';
import 'package:erp_mobileapp_ui/controllers/product_controller.dart';
import 'package:erp_mobileapp_ui/controllers/settings_controller.dart';
import 'package:erp_mobileapp_ui/controllers/shell_controller.dart';
import 'package:erp_mobileapp_ui/core/network/mock_api.dart';
import 'package:erp_mobileapp_ui/main.dart';
import 'package:erp_mobileapp_ui/models/customer.dart';

Future<void> _login(WidgetTester tester) async {
  await tester.pumpWidget(const ErpApp());
  await tester.enterText(find.byKey(const Key('login-username')), 'admin');
  await tester.enterText(find.byKey(const Key('login-password')), 'Admin@123');
  await tester.tap(find.byKey(const Key('login-button')));
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 1400));
  await tester.pumpAndSettle();
}

void _useTallViewport(WidgetTester tester) {
  tester.view.physicalSize = const Size(800, 1800);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.reset);
}

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
    MockApi.instance.reset();
    Get.reset();
    Get.put(SettingsController(), permanent: true);
    Get.put(ProductController(), permanent: true);
    Get.put(InvoiceController(), permanent: true);
    Get.put(CustomerController(), permanent: true);
    Get.put(DashboardController(), permanent: true);
    Get.put(AuthController(), permanent: true);
    Get.put(CreateInvoiceController(), permanent: true);
    Get.put(ShellController(), permanent: true);
  });

  testWidgets('Draft invoice approve flow makes it read-only', (tester) async {
    _useTallViewport(tester);
    await _login(tester);

    await tester.tap(find.text('INV-000001'));
    await tester.pumpAndSettle();

    expect(find.text('Edit Invoice'), findsOneWidget);

    await tester.ensureVisible(find.text('Approve'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Approve'));
    await tester.pumpAndSettle();

    expect(find.text('Approve Invoice?'), findsOneWidget);

    await tester.tap(find.byKey(const Key('confirm-dialog-confirm')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 700));
    await tester.pumpAndSettle();

    expect(find.text('APPROVED — READ ONLY'), findsOneWidget);
    expect(find.text('Edit Invoice'), findsNothing);

    await tester.pump(const Duration(seconds: 4));
    await tester.pumpAndSettle();
  });

  testWidgets('Draft invoice cancel flow keeps invoice and makes it read-only',
      (tester) async {
    _useTallViewport(tester);
    await _login(tester);

    await tester.tap(find.text('INV-000001'));
    await tester.pumpAndSettle();

    await tester.ensureVisible(find.text('Cancel'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();

    expect(find.text('Cancel Invoice?'), findsOneWidget);

    await tester.tap(find.byKey(const Key('confirm-dialog-confirm')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 700));
    await tester.pumpAndSettle();

    expect(find.text('CANCELLED — READ ONLY'), findsOneWidget);
    expect(find.text('Edit Invoice'), findsNothing);

    await tester.pump(const Duration(seconds: 4));
    await tester.pumpAndSettle();

    await tester.pageBack();
    await tester.pumpAndSettle();

    expect(find.text('Invoice Details'), findsNothing);
    expect(find.text('INV-000001'), findsOneWidget);
    expect(find.text('Cancelled'), findsWidgets);
  });

  testWidgets('Create invoice: add product with tax from product, then save',
      (tester) async {
    _useTallViewport(tester);
    await _login(tester);

    await tester.tap(find.text('Create Invoice'));
    await tester.pumpAndSettle();

    expect(find.text('New Sales Invoice'), findsOneWidget);

    await tester.enterText(
      find.byKey(const Key('invoice-name')),
      'Wireless Mouse Sale',
    );

    await tester.tap(find.byType(DropdownButtonFormField<Customer>));
    await tester.pumpAndSettle();
    await tester.tap(find.text('ABC Company').last);
    await tester.pumpAndSettle();

    await tester.tap(find.text('Add Product'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Wireless Mouse'));
    await tester.pumpAndSettle();

    expect(find.text('Barcode: 629100000002'), findsOneWidget);
    expect(find.text('16.000%'), findsOneWidget);

    await tester.ensureVisible(find.text('Save Invoice'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Save Invoice'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 900));
    await tester.pumpAndSettle();

    expect(find.text('INV-000006'), findsOneWidget);

    await tester.pump(const Duration(seconds: 4));
    await tester.pumpAndSettle();
  });
}
