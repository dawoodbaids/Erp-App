import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../controllers/auth_controller.dart';
import '../../controllers/settings_controller.dart';
import '../../controllers/shell_controller.dart';
import '../../core/routes/app_routes.dart';
import '../../models/currency.dart';
import '../../widgets/confirmation_dialog.dart';
import '../../widgets/ui/app_appbar.dart';
import '../../widgets/ui/app_card.dart';
import '../../widgets/ui/app_loading.dart';
import '../../widgets/ui/app_states.dart';
import '../../widgets/ui/app_tile.dart';
import '../../widgets/ui/initials_avatar.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  Future<void> _logout(BuildContext context) async {
    final confirmed = await ConfirmationDialog.show(
      context,
      title: 'settings.logoutConfirmTitle'.tr,
      message: 'settings.logoutConfirmMessage'.tr,
      confirmText: 'settings.logoutAction'.tr,
      destructive: true,
      confirmIcon: Icons.logout,
    );
    if (confirmed == true) Get.find<AuthController>().logout();
  }

  Future<void> _chooseCurrency(
    BuildContext context,
    SettingsController controller,
  ) async {
    final selected = await showModalBottomSheet<Currency>(
      context: context,
      showDragHandle: true,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 4, 20, 8),
              child: Align(
                alignment: AlignmentDirectional.centerStart,
                child: Text(
                  'settings.defaultCurrency'.tr,
                  style: Theme.of(
                    context,
                  ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
                ),
              ),
            ),
            ...controller.currencies.map(
              (currency) => _ChoiceTile(
                icon: Icons.currency_exchange_outlined,
                title: '${currency.code} · ${currency.name}',
                selected: currency.id == controller.defaultCurrencyId,
                onTap: () => Navigator.of(context).pop(currency),
              ),
            ),
            const SizedBox(height: 12),
          ],
        ),
      ),
    );
    if (selected == null) return;

    final error = await controller.setDefaultCurrency(selected.id);
    if (error != null) Get.snackbar('settings.defaultCurrency'.tr, error);
  }

  @override
  Widget build(BuildContext context) {
    final auth = Get.find<AuthController>();
    final shell = Get.find<ShellController>();

    return Scaffold(
      appBar: AppAppBar(title: 'settings.title'.tr, showBack: false),
      body: GetX<SettingsController>(
        builder: (controller) {
          if (controller.isLoading && controller.currencies.isEmpty) {
            return const AppLoadingState();
          }
          if (controller.errorMessage != null &&
              controller.currencies.isEmpty) {
            return AppErrorState(
              title: 'settings.title'.tr,
              message: controller.errorMessage!,
              onRetry: controller.loadCurrenciesAndRates,
            );
          }
          final defaultCurrency = controller.defaultCurrency;
          if (defaultCurrency == null) {
            return AppEmptyState(
              icon: Icons.currency_exchange_outlined,
              title: 'settings.noCurrenciesTitle'.tr,
              message: 'settings.noCurrenciesMessage'.tr,
            );
          }

          final name = auth.currentUser?.displayName ?? 'Administrator';
          final username = auth.currentUser?.username ?? 'admin';
          final language = controller.locale.languageCode == 'ar'
              ? 'language.arabic'.tr
              : 'language.english'.tr;

          return RefreshIndicator(
            onRefresh: controller.loadCurrenciesAndRates,
            child: ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
              children: [
                AppCard(
                  padding: const EdgeInsets.all(18),
                  child: Row(
                    children: [
                      InitialsAvatar(name: name, size: 54),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              name,
                              style: Theme.of(context).textTheme.titleMedium
                                  ?.copyWith(fontWeight: FontWeight.w800),
                            ),
                            const SizedBox(height: 3),
                            Text(
                              '@$username',
                              style: Theme.of(context).textTheme.bodySmall
                                  ?.copyWith(
                                    color: Theme.of(
                                      context,
                                    ).colorScheme.onSurfaceVariant,
                                  ),
                            ),
                          ],
                        ),
                      ),
                      Icon(
                        Icons.verified_rounded,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                _SectionLabel('settings.account'.tr),
                AppGroupCard(
                  children: [
                    AppTile(
                      icon: Icons.lock_outline,
                      title: 'settings.security'.tr,
                      subtitle: 'settings.securitySubtitle'.tr,
                      onTap: () => Get.snackbar(
                        'settings.security'.tr,
                        'settings.securityNote'.tr,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                _SectionLabel('settings.application'.tr),
                AppGroupCard(
                  children: [
                    AppTile(
                      icon: Icons.language_outlined,
                      title: 'settings.language'.tr,
                      subtitle: language,
                      onTap: () => Get.toNamed(AppRoutes.language),
                    ),
                    const AppDivider(),
                  ],
                ),
                const SizedBox(height: 24),
                _SectionLabel('settings.preferences'.tr),
                AppGroupCard(
                  children: [
                    AppTile(
                      icon: Icons.currency_exchange_outlined,
                      title: 'settings.defaultCurrency'.tr,
                      subtitle: 'settings.defaultCurrencySubtitle'.tr,
                      trailing: _ValuePill(value: defaultCurrency.code),
                      onTap: () => _chooseCurrency(context, controller),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                _SectionLabel('settings.invoiceTools'.tr),
                AppGroupCard(
                  children: [
                    AppTile(
                      icon: Icons.inventory_2_outlined,
                      title: 'settings.productManagement'.tr,
                      subtitle: 'settings.productManagementSubtitle'.tr,
                      onTap: shell.goToProducts,
                    ),
                    const AppDivider(),
                    AppTile(
                      icon: Icons.manage_search_outlined,
                      title: 'settings.findInvoice'.tr,
                      subtitle: 'settings.findInvoiceSubtitle'.tr,
                      onTap: () => Get.toNamed(AppRoutes.findInvoice),
                    ),
                    const AppDivider(),
                    AppTile(
                      icon: Icons.payments_outlined,
                      title: 'settings.currencies'.tr,
                      subtitle: 'settings.currenciesSubtitle'.tr,
                      onTap: () => Get.toNamed(AppRoutes.currencies),
                    ),
                    const AppDivider(),
                    AppTile(
                      icon: Icons.swap_horiz_rounded,
                      title: 'settings.exchangeRates'.tr,
                      subtitle: 'settings.exchangeRatesSubtitle'.trParams({
                        'currency': defaultCurrency.code,
                      }),
                      onTap: () => Get.toNamed(AppRoutes.exchangeRates),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                _SectionLabel('settings.about'.tr),
                AppGroupCard(
                  children: [
                    AppTile(
                      icon: Icons.info_outline,
                      title: 'settings.version'.tr,
                      subtitle: '1.0.0',
                    ),
                    const AppDivider(),
                    AppTile(
                      icon: Icons.logout_rounded,
                      title: 'settings.logout'.tr,
                      subtitle: 'settings.logoutSubtitle'.tr,
                      destructive: true,
                      onTap: () => _logout(context),
                    ),
                  ],
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  final String text;

  const _SectionLabel(this.text);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsetsDirectional.only(start: 4, bottom: 10),
      child: Text(
        text.toUpperCase(),
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
          color: Theme.of(context).colorScheme.onSurfaceVariant,
          fontWeight: FontWeight.w800,
          letterSpacing: 1,
        ),
      ),
    );
  }
}

class _ValuePill extends StatelessWidget {
  final String value;

  const _ValuePill({required this.value});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: theme.colorScheme.primaryContainer,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        value,
        style: theme.textTheme.labelMedium?.copyWith(
          color: theme.colorScheme.primary,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}

class _ChoiceTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final bool selected;
  final VoidCallback onTap;

  const _ChoiceTile({
    required this.icon,
    required this.title,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return ListTile(
      onTap: onTap,
      leading: Icon(icon, color: theme.colorScheme.primary),
      title: Text(title),
      trailing: selected
          ? Icon(Icons.check_circle_rounded, color: theme.colorScheme.primary)
          : const Icon(Icons.radio_button_unchecked),
    );
  }
}
