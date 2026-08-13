import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';

import '../../controllers/settings_controller.dart';
import '../../core/utils/formatters.dart';
import '../../models/exchange_rate.dart';
import '../../widgets/ui/app_appbar.dart';
import '../../widgets/ui/app_card.dart';
import '../../widgets/ui/app_loading.dart';
import '../../widgets/ui/app_snackbars.dart';
import '../../widgets/ui/app_states.dart';
import '../../widgets/ui/app_tile.dart';

class ExchangeRatesScreen extends StatelessWidget {
  const ExchangeRatesScreen({super.key});

  Future<void> _editRate(
    BuildContext context,
    SettingsController controller,
    ExchangeRate rate,
  ) async {
    final result = await showDialog<double>(
      context: context,
      builder: (context) => _ExchangeRateDialog(rate: rate),
    );
    if (result == null) return;

    final error = await controller.updateExchangeRate(rate.id, result);
    if (error != null) {
      AppSnack.error(error, title: 'rates.updateFailed'.tr);
    } else {
      final currency = controller.currencyById(rate.currencyId);
      AppSnack.success(
        'rates.updatedMessage'.trParams({
          'currency': currency?.code ?? rate.currencyId,
          'rate': Formatters.rate(result),
        }),
        title: 'rates.updatedTitle'.tr,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppAppBar(title: 'rates.title'.tr),
      body: GetX<SettingsController>(
        builder: (controller) {
          if (controller.isLoading && controller.exchangeRates.isEmpty) {
            return const AppLoadingState();
          }
          if (controller.errorMessage != null &&
              controller.exchangeRates.isEmpty) {
            return AppErrorState(
              title: 'rates.title'.tr,
              message: controller.errorMessage!,
              onRetry: controller.loadCurrenciesAndRates,
            );
          }

          final base = controller.defaultCurrency;
          if (base == null) {
            return AppEmptyState(
              icon: Icons.currency_exchange_outlined,
              title: 'settings.noCurrenciesTitle'.tr,
              message: 'settings.noCurrenciesMessage'.tr,
            );
          }
          if (controller.exchangeRates.isEmpty) {
            return AppEmptyState(
              icon: Icons.swap_horiz_rounded,
              title: 'rates.emptyTitle'.tr,
              message: 'rates.emptyMessage'.tr,
            );
          }

          return RefreshIndicator(
            onRefresh: controller.loadCurrenciesAndRates,
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
              children: [
                Text(
                  'rates.subtitle'.trParams({'currency': base.code}),
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 16),
                AppCard(
                  child: Column(
                    children: [
                      for (final rate in controller.exchangeRates)
                        _RateRow(
                          rate: rate,
                          isBase: controller.isBaseCurrency(rate.currencyId),
                          baseCode: base.code,
                          onEdit: controller.isBaseCurrency(rate.currencyId)
                              ? null
                              : () => _editRate(context, controller, rate),
                        ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                AppGroupCard(
                  children: [
                    AppTile(
                      icon: Icons.currency_exchange,
                      title: 'settings.currencies'.tr,
                      subtitle: 'settings.currenciesSubtitle'.tr,
                      onTap: () => Get.back(),
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

class _RateRow extends StatelessWidget {
  final ExchangeRate rate;
  final bool isBase;
  final String baseCode;
  final VoidCallback? onEdit;

  const _RateRow({
    required this.rate,
    required this.isBase,
    required this.baseCode,
    this.onEdit,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final settings = Get.find<SettingsController>();
    final currency = settings.currencyById(rate.currencyId);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: theme.colorScheme.surfaceContainerHigh.withValues(
                alpha: 0.7,
              ),
              borderRadius: BorderRadius.circular(11),
            ),
            child: Text(
               currency?.symbol ?? rate.currencyId,
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                   currency?.name ?? rate.currencyId,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  isBase
                      ? 'rates.base'.tr
                      : 'rates.hint'.trParams({
                           'from': currency?.code ?? rate.currencyId,
                          'to': baseCode,
                        }),
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          if (isBase)
            Icon(Icons.lock_outline, size: 18, color: theme.colorScheme.outline)
          else ...[
            Text(
              Formatters.rate(rate.rateToBase),
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(width: 10),
            IconButton(
              tooltip: 'common.edit'.tr,
              onPressed: onEdit,
              icon: const Icon(Icons.edit_outlined, size: 20),
            ),
          ],
        ],
      ),
    );
  }
}

class _ExchangeRateDialog extends StatefulWidget {
  final ExchangeRate rate;

  const _ExchangeRateDialog({required this.rate});

  @override
  State<_ExchangeRateDialog> createState() => _ExchangeRateDialogState();
}

class _ExchangeRateDialogState extends State<_ExchangeRateDialog> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(
      text: Formatters.rate(widget.rate.rateToBase),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final settings = Get.find<SettingsController>();
    final currency = settings.currencyById(widget.rate.currencyId);

    return AlertDialog(
      title: Text('rates.editTitle'.tr),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'rates.hint'.trParams({
               'from': currency?.code ?? widget.rate.currencyId,
               'to': settings.defaultCurrency?.code ?? '',
            }),
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _controller,
            autofocus: true,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            inputFormatters: [
              FilteringTextInputFormatter.allow(RegExp(r'[0-9.]')),
            ],
            decoration: InputDecoration(
              labelText: 'form.exchangeRate'.tr,
              prefixIcon: const Icon(Icons.swap_horiz),
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text('common.cancel'.tr),
        ),
        FilledButton(
          onPressed: () {
            final value = double.tryParse(_controller.text);
            if (value == null || value <= 0) {
              AppSnack.error('rates.invalidRate'.tr);
              return;
            }
            Navigator.of(context).pop(value);
          },
          child: Text('common.save'.tr),
        ),
      ],
    );
  }
}
