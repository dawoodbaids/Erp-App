import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../controllers/settings_controller.dart';
import '../../controllers/shell_controller.dart';
import '../customers/customers_screen.dart';
import '../dashboard/dashboard_screen.dart';
import '../invoice_list/invoice_list_screen.dart';
import '../products/products_screen.dart';
import '../settings/settings_screen.dart';

class ShellScreen extends StatefulWidget {
  const ShellScreen({super.key});

  @override
  State<ShellScreen> createState() => _ShellScreenState();
}

class _ShellScreenState extends State<ShellScreen> {
  final _tabs = <Widget?>[null, null, null, null, null];

  Widget _tabFor(int index) {
    final existing = _tabs[index];
    if (existing != null) return existing;

    final tab = switch (index) {
      0 => const DashboardScreen(),
      1 => const InvoiceListScreen(),
      2 => const ProductsScreen(),
      3 => const CustomersScreen(),
      _ => const SettingsScreen(),
    };
    _tabs[index] = tab;
    return tab;
  }

  @override
  Widget build(BuildContext context) {
    return GetX<ShellController>(
      builder: (controller) {
        final selectedIndex = controller.tabIndex.clamp(0, 4).toInt();
        _tabFor(selectedIndex);
        return Scaffold(
          body: IndexedStack(
            index: selectedIndex,
            children: [for (final tab in _tabs) tab ?? const SizedBox.shrink()],
          ),
          bottomNavigationBar: GetX<SettingsController>(
            builder: (settings) => NavigationBar(
              key: ValueKey(settings.locale),
              selectedIndex: selectedIndex,
              onDestinationSelected: controller.setTab,
              destinations: [
                NavigationDestination(
                  icon: Icon(Icons.home_outlined),
                  selectedIcon: Icon(Icons.home_rounded),
                  label: 'nav.home'.tr,
                ),
                NavigationDestination(
                  icon: Icon(Icons.receipt_long_outlined),
                  selectedIcon: Icon(Icons.receipt_long_rounded),
                  label: 'nav.invoices'.tr,
                ),
                NavigationDestination(
                  icon: Icon(Icons.inventory_2_outlined),
                  selectedIcon: Icon(Icons.inventory_2_rounded),
                  label: 'nav.products'.tr,
                ),
                NavigationDestination(
                  icon: Icon(Icons.people_outline),
                  selectedIcon: Icon(Icons.people_rounded),
                  label: 'nav.customers'.tr,
                ),
                NavigationDestination(
                  icon: Icon(Icons.tune_outlined),
                  selectedIcon: Icon(Icons.tune_rounded),
                  label: 'nav.settings'.tr,
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
