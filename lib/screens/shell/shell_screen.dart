import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../controllers/auth_controller.dart';
import '../../controllers/settings_controller.dart';
import '../../controllers/shell_controller.dart';
import '../../core/constants/app_constants.dart';
import '../../core/theme/app_colors.dart';
import '../../widgets/ui/app_appbar.dart';
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
        final index = controller.tabIndex.clamp(0, 4).toInt();
        _tabFor(index);
        return GetX<SettingsController>(
          builder: (settings) {
            final wide = MediaQuery.sizeOf(context).width >= 900;
            final content = IndexedStack(
              index: index,
              children: [
                for (final tab in _tabs) tab ?? const SizedBox.shrink(),
              ],
            );
            if (wide) {
              return Scaffold(
                body: Row(
                  children: [
                    _SideBar(index: index, onSelected: controller.setTab),
                    Expanded(child: content),
                  ],
                ),
              );
            }
            return Scaffold(
              body: content,
              bottomNavigationBar: _BottomBar(
                index: index,
                onSelected: controller.setTab,
                locale: settings.locale,
              ),
            );
          },
        );
      },
    );
  }
}

class _SideBar extends StatelessWidget {
  final int index;
  final ValueChanged<int> onSelected;

  const _SideBar({required this.index, required this.onSelected});

  static const _items = [
    (Icons.grid_view_rounded, 'nav.home'),
    (Icons.receipt_long_rounded, 'nav.invoices'),
    (Icons.inventory_2_rounded, 'nav.products'),
    (Icons.people_alt_rounded, 'nav.customers'),
    (Icons.tune_rounded, 'nav.settings'),
  ];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final authName =
        Get.find<AuthController>().currentUser?.displayName ?? 'Admin';
    return Container(
      width: 248,
      color: theme.colorScheme.surface,
      padding: const EdgeInsets.fromLTRB(18, 28, 18, 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [AppColors.brandStart, AppColors.brandEnd],
                  ),
                  borderRadius: BorderRadius.circular(13),
                ),
                child: const Icon(Icons.auto_awesome, color: Colors.white),
              ),
              const SizedBox(width: 12),
              Text(
                AppConstants.appName,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),
          const SizedBox(height: 42),
          Text(
            'WORKSPACE',
            style: theme.textTheme.labelSmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
              letterSpacing: 1.4,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 12),
          for (var i = 0; i < _items.length; i++) ...[
            _NavItem(
              icon: _items[i].$1,
              label: _items[i].$2.tr,
              selected: index == i,
              onTap: () => onSelected(i),
            ),
            const SizedBox(height: 6),
          ],
          const Spacer(),
          AppCardLine(name: authName),
        ],
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _NavItem({
    required this.icon,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = selected
        ? theme.colorScheme.primary
        : theme.colorScheme.onSurfaceVariant;
    return ListTile(
      onTap: onTap,
      dense: true,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(13)),
      tileColor: selected
          ? theme.colorScheme.primary.withValues(alpha: 0.09)
          : null,
      leading: Icon(icon, color: color, size: 21),
      title: Text(
        label,
        style: theme.textTheme.bodyMedium?.copyWith(
          color: color,
          fontWeight: selected ? FontWeight.w800 : FontWeight.w600,
        ),
      ),
    );
  }
}

class AppCardLine extends StatelessWidget {
  final String name;

  const AppCardLine({super.key, required this.name});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const AppAvatar(name: 'ERP', size: 38),
        const SizedBox(width: 10),
        Expanded(
          child: Text(name, maxLines: 1, overflow: TextOverflow.ellipsis),
        ),
      ],
    );
  }
}

class _BottomBar extends StatelessWidget {
  final int index;
  final ValueChanged<int> onSelected;
  final Locale locale;

  const _BottomBar({
    required this.index,
    required this.onSelected,
    required this.locale,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 0, 12, 10),
      child: Material(
        elevation: 10,
        shadowColor: Theme.of(context).shadowColor.withValues(alpha: 0.18),
        borderRadius: BorderRadius.circular(24),
        clipBehavior: Clip.antiAlias,
        child: NavigationBar(
          key: ValueKey(locale),
          selectedIndex: index,
          onDestinationSelected: onSelected,
          destinations: [
        NavigationDestination(
          icon: const Icon(Icons.grid_view_outlined),
          selectedIcon: const Icon(Icons.grid_view_rounded),
          label: 'nav.home'.tr,
        ),
        NavigationDestination(
          icon: const Icon(Icons.receipt_long_outlined),
          selectedIcon: const Icon(Icons.receipt_long_rounded),
          label: 'nav.invoices'.tr,
        ),
        NavigationDestination(
          icon: const Icon(Icons.inventory_2_outlined),
          selectedIcon: const Icon(Icons.inventory_2_rounded),
          label: 'nav.products'.tr,
        ),
        NavigationDestination(
          icon: const Icon(Icons.people_outline),
          selectedIcon: const Icon(Icons.people_rounded),
          label: 'nav.customers'.tr,
        ),
        NavigationDestination(
          icon: const Icon(Icons.tune_outlined),
          selectedIcon: const Icon(Icons.tune_rounded),
          label: 'nav.settings'.tr,
        ),
          ],
        ),
      ),
    );
  }
}
