import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:get/get.dart';

import 'controllers/auth_controller.dart';
import 'controllers/create_invoice_controller.dart';
import 'controllers/customer_controller.dart';
import 'controllers/dashboard_controller.dart';
import 'controllers/invoice_controller.dart';
import 'controllers/product_controller.dart';
import 'controllers/settings_controller.dart';
import 'controllers/shell_controller.dart';
import 'core/constants/app_constants.dart';
import 'core/localization/app_translations.dart';
import 'core/routes/app_pages.dart';
import 'core/routes/app_routes.dart';
import 'core/theme/app_theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  if (defaultTargetPlatform == TargetPlatform.android) {
    await Firebase.initializeApp();
  }

  Get.put(SettingsController());
  Get.put(ProductController());
  Get.put(InvoiceController());
  Get.put(CustomerController());
  Get.put(DashboardController());
  Get.put(AuthController());
  Get.put(CreateInvoiceController());
  Get.put(ShellController());

  runApp(const ErpApp());
}

class ErpApp extends StatelessWidget {
  const ErpApp({super.key});

  @override
  Widget build(BuildContext context) {
    return GetX<SettingsController>(
      builder: (settings) {
        return GetMaterialApp(
          title: AppConstants.appName,
          debugShowCheckedModeBanner: false,
          initialRoute: AppRoutes.login,
          getPages: AppPages.pages,
          theme: AppTheme.dark,
          darkTheme: AppTheme.dark,
          themeMode: ThemeMode.dark,
          locale: settings.locale,
          fallbackLocale: const Locale('en'),
          supportedLocales: const [Locale('en'), Locale('ar')],
          localizationsDelegates: const [
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          translations: AppTranslations(),
          defaultTransition: Transition.fadeIn,
        );
      },
    );
  }
}
