import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';

import 'package:erp_mobileapp_ui/controllers/auth_controller.dart';
import 'package:erp_mobileapp_ui/controllers/settings_controller.dart';
import 'package:erp_mobileapp_ui/main.dart';

void main() {
  setUp(() {
    Get.reset();
    Get.put(SettingsController(), permanent: true);
    Get.put(AuthController(), permanent: true);
  });

  testWidgets('login screen renders Firebase sign-in guidance', (tester) async {
    await tester.pumpWidget(const ErpApp());

    expect(find.text('RP ERP'), findsOneWidget);
    expect(find.text('Sales Management'), findsOneWidget);
    expect(
      find.text(
        'Use the email and password configured in Firebase Authentication.',
      ),
      findsOneWidget,
    );
  });

  testWidgets('empty login fields show validation messages', (tester) async {
    await tester.pumpWidget(const ErpApp());

    await tester.tap(find.byKey(const Key('login-button')));
    await tester.pumpAndSettle();

    expect(find.text('Email is required'), findsOneWidget);
    expect(find.text('Password is required'), findsOneWidget);
  });
}
