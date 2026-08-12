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

  testWidgets('Login screen renders with mock credentials hint', (tester) async {
    await tester.pumpWidget(const ErpApp());

    expect(find.text('RP ERP'), findsOneWidget);
    expect(find.text('Sales Management'), findsOneWidget);
    expect(find.text('Mock credentials: admin / Admin@123'), findsOneWidget);
  });

  testWidgets('Empty login fields show validation messages', (tester) async {
    await tester.pumpWidget(const ErpApp());

    await tester.tap(find.byKey(const Key('login-button')));
    await tester.pumpAndSettle();

    expect(find.text('Username is required'), findsOneWidget);
    expect(find.text('Password is required'), findsOneWidget);
  });

  testWidgets('Successful login navigates to the app shell dashboard',
      (tester) async {
    tester.view.physicalSize = const Size(800, 1800);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(const ErpApp());

    await tester.enterText(find.byKey(const Key('login-username')), 'admin');
    await tester.enterText(find.byKey(const Key('login-password')), 'Admin@123');
    await tester.tap(find.byKey(const Key('login-button')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 1400));
    await tester.pumpAndSettle();

    expect(find.text('Invoices'), findsWidgets);
    expect(find.text('INV-000001'), findsOneWidget);
  });

  testWidgets('Invalid login shows error and stays on login screen',
      (tester) async {
    await tester.pumpWidget(const ErpApp());

    await tester.enterText(find.byKey(const Key('login-username')), 'admin');
    await tester.enterText(find.byKey(const Key('login-password')), 'wrong');
    await tester.tap(find.byKey(const Key('login-button')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 1400));
    await tester.pumpAndSettle();

    expect(find.text('Login failed'), findsOneWidget);
    expect(find.text('Invoices'), findsNothing);

    await tester.pump(const Duration(seconds: 4));
    await tester.pumpAndSettle();
  });
}
