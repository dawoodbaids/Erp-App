import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../controllers/settings_controller.dart';
import '../../models/currency.dart';
import '../../widgets/ui/app_appbar.dart';
import '../../widgets/ui/app_loading.dart';
import '../../widgets/ui/app_states.dart';
import '../../widgets/ui/app_tile.dart';

class CurrencyScreen extends StatelessWidget {
  const CurrencyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppAppBar(title: 'currency.title'.tr),
      body: GetX<SettingsController>(
        builder: (controller) {
          if (controller.isLoading && controller.currencies.isEmpty) {
            return const AppLoadingState();
          }
          if (controller.errorMessage != null &&
              controller.currencies.isEmpty) {
            return AppErrorState(
              title: 'currency.title'.tr,
              message: controller.errorMessage!,
              onRetry: controller.loadCurrenciesAndRates,
            );
          }

           final baseId = controller.defaultCurrencyId;
           final currencies = controller.currencies;

           if (currencies.isEmpty) {
             return AppEmptyState(
               icon: Icons.currency_exchange_outlined,
               title: 'settings.noCurrenciesTitle'.tr,
               message: 'settings.noCurrenciesMessage'.tr,
             );
           }

           return RefreshIndicator(
            onRefresh: controller.loadCurrenciesAndRates,
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
              children: [
                Text(
                  'currency.subtitle'.tr,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 16),
                AppGroupCard(
                  children: [
                    for (var i = 0; i < currencies.length; i++) ...[
                      if (i > 0) AppDivider(),
                      _CurrencyTile(
                        currency: currencies[i],
                        isDefault: currencies[i].id == baseId,
                        onTap: () async {
                          final error = await controller.setDefaultCurrency(
                            currencies[i].id,
                          );
                          if (error != null) {
                            Get.snackbar(
                              'common.update'.tr,
                              error,
                              snackPosition: SnackPosition.BOTTOM,
                            );
                          }
                        },
                      ),
                    ],
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

class _CurrencyTile extends StatelessWidget {
  final Currency currency;
  final bool isDefault;
  final VoidCallback onTap;

  const _CurrencyTile({
    required this.currency,
    required this.isDefault,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
        child: Row(
          children: [
            Container(
              width: 42,
              height: 42,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: theme.colorScheme.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                currency.symbol,
                style: theme.textTheme.titleMedium?.copyWith(
                  color: theme.colorScheme.primary,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    currency.name,
                    style: theme.textTheme.bodyLarge?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${currency.code} — ${currency.symbol}',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
            if (isDefault)
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 5,
                ),
                decoration: BoxDecoration(
                  color: theme.colorScheme.primary.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  'currency.base'.tr,
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: theme.colorScheme.primary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              )
            else
              Icon(
                Icons.radio_button_unchecked,
                size: 20,
                color: theme.colorScheme.outlineVariant,
              ),
          ],
        ),
      ),
    );
  }
}
