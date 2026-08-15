import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../controllers/auth_controller.dart';
import '../../controllers/settings_controller.dart';
import '../../controllers/shell_controller.dart';
import '../../core/routes/app_routes.dart';
import '../../widgets/confirmation_dialog.dart';
import '../../widgets/ui/app_appbar.dart';
import '../../widgets/ui/app_card.dart';
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

  @override
  Widget build(BuildContext context) {
    final auth = Get.find<AuthController>();
    final shell = Get.find<ShellController>();

    return Scaffold(
      appBar: AppAppBar(title: 'settings.title'.tr, showBack: false),
      body: GetX<SettingsController>(
        builder: (controller) {
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
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 12, 16, 14),
                      child: Row(
                        children: [
                          Icon(
                            Icons.brightness_6_outlined,
                            color: Theme.of(context).colorScheme.primary,
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Theme',
                                  style: Theme.of(context).textTheme.bodyLarge
                                      ?.copyWith(fontWeight: FontWeight.w700),
                                ),
                                Text(
                                  'Choose how ERP looks on this device',
                                  style: Theme.of(context).textTheme.bodySmall,
                                ),
                              ],
                            ),
                          ),
                          PopupMenuButton<ThemeMode>(
                            initialValue: controller.themeMode,
                            onSelected: controller.setThemeMode,
                            child: Chip(
                              label: Text(_themeLabel(controller.themeMode)),
                              avatar: const Icon(Icons.expand_more, size: 18),
                            ),
                            itemBuilder: (_) => const [
                              PopupMenuItem(
                                value: ThemeMode.system,
                                child: Text('System'),
                              ),
                              PopupMenuItem(
                                value: ThemeMode.light,
                                child: Text('Light'),
                              ),
                              PopupMenuItem(
                                value: ThemeMode.dark,
                                child: Text('Dark'),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const AppDivider(),
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
                      icon: Icons.swap_horiz_rounded,
                      title: 'settings.exchangeRates'.tr,
                      subtitle: 'settings.exchangeRatesSubtitle'.trParams({
                        'currency': controller.defaultCurrency?.code ?? '',
                      }),
                      onTap: () => Get.toNamed(AppRoutes.exchangeRates),
                    ),
                    const AppDivider(),
                    AppTile(
                      icon: Icons.percent_outlined,
                      title: 'settings.taxes'.tr,
                      subtitle: 'settings.taxesSubtitle'.tr,
                      onTap: () => Get.toNamed(AppRoutes.taxes),
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

  String _themeLabel(ThemeMode mode) => switch (mode) {
    ThemeMode.light => 'Light',
    ThemeMode.dark => 'Dark',
    ThemeMode.system => 'System',
  };
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
