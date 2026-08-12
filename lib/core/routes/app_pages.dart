import 'package:get/get.dart';

import '../../screens/customer_details/customer_details_screen.dart';
import '../../screens/invoice_details/invoice_details_screen.dart';
import '../../screens/invoice_form/invoice_form_screen.dart';
import '../../screens/invoice_list/invoice_list_screen.dart';
import '../../screens/find_invoice/find_invoice_screen.dart';
import '../../screens/login/login_screen.dart';
import '../../screens/product_details/product_details_screen.dart';
import '../../screens/settings/currency_screen.dart';
import '../../screens/settings/exchange_rates_screen.dart';
import '../../screens/settings/language_screen.dart';
import '../../screens/settings/settings_screen.dart';
import '../../screens/shell/shell_screen.dart';
import 'app_routes.dart';

class AppPages {
  static final List<GetPage> pages = [
    GetPage(name: AppRoutes.login, page: () => const LoginScreen()),
    GetPage(name: AppRoutes.shell, page: () => const ShellScreen()),
    GetPage(name: AppRoutes.invoiceList, page: () => const InvoiceListScreen()),
    GetPage(name: AppRoutes.invoiceForm, page: () => const InvoiceFormScreen()),
    GetPage(
      name: AppRoutes.invoiceDetails,
      page: () => const InvoiceDetailsScreen(),
    ),
    GetPage(
      name: AppRoutes.findInvoice,
      page: () => const FindInvoiceScreen(),
    ),
    GetPage(name: AppRoutes.settings, page: () => const SettingsScreen()),
    GetPage(
      name: AppRoutes.customerDetails,
      page: () => const CustomerDetailsScreen(),
    ),
    GetPage(
      name: AppRoutes.productDetails,
      page: () => const ProductDetailsScreen(),
    ),
    GetPage(name: AppRoutes.currencies, page: () => const CurrencyScreen()),
    GetPage(
      name: AppRoutes.exchangeRates,
      page: () => const ExchangeRatesScreen(),
    ),
    GetPage(name: AppRoutes.language, page: () => const LanguageScreen()),
  ];
}
