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

  testWidgets('redesigned shell supports navigation, dark mode and RTL', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(800, 1800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(const ErpApp());
    await tester.enterText(find.byKey(const Key('login-username')), 'admin');
    await tester.enterText(
      find.byKey(const Key('login-password')),
      'Admin@123',
    );
    await tester.tap(find.byKey(const Key('login-button')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 1400));
    await tester.pumpAndSettle();

    final shell = Get.find<ShellController>();
    final settings = Get.find<SettingsController>();

    expect(find.byType(NavigationBar), findsOneWidget);
    expect(
      Theme.of(tester.element(find.byType(NavigationBar))).brightness,
      Brightness.light,
    );

    for (final index in [1, 2, 3, 4, 0]) {
      shell.setTab(index);
      await tester.pumpAndSettle();
    }

    settings.setThemeMode(ThemeMode.dark);
    await tester.pumpAndSettle();
    expect(
      Theme.of(tester.element(find.byType(NavigationBar))).brightness,
      Brightness.dark,
    );

    settings.setLocale(const Locale('ar'));
    await tester.pumpAndSettle();
    expect(
      Directionality.of(tester.element(find.byType(NavigationBar))),
      TextDirection.rtl,
    );
    expect(find.text('الفواتير'), findsWidgets);

    settings.setLocale(const Locale('en'));
    settings.setThemeMode(ThemeMode.light);
    await tester.pumpAndSettle();
    expect(
      Directionality.of(tester.element(find.byType(NavigationBar))),
      TextDirection.ltr,
    );
    expect(find.text('Invoices'), findsWidgets);
  });
}
