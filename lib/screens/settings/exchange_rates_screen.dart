import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';

import '../../controllers/settings_controller.dart';
import '../../core/routes/app_routes.dart';
import '../../core/utils/formatters.dart';
import '../../models/currency.dart';
import '../../models/exchange_rate.dart';
import '../../widgets/confirmation_dialog.dart';
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

  Future<void> _addRate(
    BuildContext context,
    SettingsController controller,
    Currency currency,
  ) async {
    final result = await showDialog<double>(
      context: context,
      builder: (context) => _ExchangeRateDialog(currency: currency),
    );
    if (result == null) return;

    final error = await controller.createExchangeRate(currency.id, result);
    if (error != null) {
      AppSnack.error(error, title: 'rates.addFailed'.tr);
    } else {
      AppSnack.success(
        'rates.updatedMessage'.trParams({
          'currency': currency.code,
          'rate': Formatters.rate(result),
        }),
        title: 'rates.addedTitle'.tr,
      );
    }
  }

  Future<void> _deleteRate(
    BuildContext context,
    SettingsController controller,
    ExchangeRate rate,
  ) async {
    final currency = controller.currencyById(rate.currencyId);
    final confirmed = await ConfirmationDialog.show(
      context,
      title: 'rates.deleteTitle'.tr,
      message: 'rates.deleteMessage'.trParams({
        'currency': currency?.code ?? rate.currencyId,
      }),
      confirmText: 'common.delete'.tr,
      destructive: true,
      confirmIcon: Icons.delete_outline,
    );
    if (confirmed != true) return;

    final error = await controller.deleteExchangeRate(rate.id);
    if (error != null) {
      AppSnack.error(error, title: 'rates.deleteFailed'.tr);
    } else {
      AppSnack.success('rates.deleted'.tr, title: 'common.delete'.tr);
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
              actionLabel: 'currency.add'.tr,
              onAction: () => Get.toNamed(AppRoutes.currencies),
            );
          }

          final missing = _currenciesMissingRate(controller, base);
          final hasRates = controller.exchangeRates.isNotEmpty;

          if (!hasRates && missing.isEmpty) {
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
                if (missing.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  Text(
                    'rates.missingTitle'.tr,
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 8),
                  AppCard(
                    child: Column(
                      children: [
                        for (var i = 0; i < missing.length; i++) ...[
                          if (i > 0) const Divider(height: 1),
                          _MissingRateRow(
                            currency: missing[i],
                            baseCode: base.code,
                            onAdd: () =>
                                _addRate(context, controller, missing[i]),
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
                if (hasRates) ...[
                  const SizedBox(height: 16),
                  Text(
                    'rates.configuredTitle'.tr,
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 8),
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
                            onDelete: controller.isBaseCurrency(rate.currencyId)
                                ? null
                                : () => _deleteRate(context, controller, rate),
                          ),
                      ],
                    ),
                  ),
                ],
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

  /// Active non-base currencies that have no exchange rate configured yet.
  /// Canonical rate documents and pair documents (e.g. `JOD_USD`) both
  /// count as a configured rate.
  List<Currency> _currenciesMissingRate(
    SettingsController controller,
    Currency base,
  ) {
    return controller.currencies.where((currency) {
      if (currency.id == base.id) return false;
      if (currency.code.toLowerCase() == base.code.toLowerCase()) {
        return false;
      }
      if (!currency.isActive) return false;
      return !controller.hasRateFor(currency);
    }).toList();
  }
}

class _MissingRateRow extends StatelessWidget {
  final Currency currency;
  final String baseCode;
  final VoidCallback onAdd;

  const _MissingRateRow({
    required this.currency,
    required this.baseCode,
    required this.onAdd,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
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
              currency.symbol.isNotEmpty ? currency.symbol : currency.displayLabel,
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
                  currency.displayLabel,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'rates.hint'.trParams({
                    'from': currency.displayLabel,
                    'to': baseCode,
                  }),
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          TextButton.icon(
            onPressed: onAdd,
            icon: const Icon(Icons.add, size: 18),
            label: Text('rates.add'.tr),
          ),
        ],
      ),
    );
  }
}

class _RateRow extends StatelessWidget {
  final ExchangeRate rate;
  final bool isBase;
  final String baseCode;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;

  const _RateRow({
    required this.rate,
    required this.isBase,
    required this.baseCode,
    this.onEdit,
    this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final settings = Get.find<SettingsController>();
    final currency = settings.currencyById(rate.currencyId);

    if (rate.isPair) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
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
              child: Icon(
                Icons.swap_horiz,
                size: 19,
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'rates.pairTitle'.tr,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'rates.pairSubtitle'.trParams({
                      'from': rate.fromCurrency ?? '',
                      'to': rate.toCurrency ?? '',
                    }),
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
            Text(
              '1 ${rate.fromCurrency ?? ''} = '
              '${Formatters.rate(rate.pairRate ?? 0)} ${rate.toCurrency ?? ''}',
              style: theme.textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
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
              currency?.symbol.isNotEmpty ?? false
                  ? currency!.symbol
                  : currency?.displayLabel ?? rate.currencyId,
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
                  currency?.displayLabel ?? rate.currencyId,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  isBase
                      ? 'rates.base'.tr
                      : 'rates.hint'.trParams({
                          'from': currency?.displayLabel ?? rate.currencyId,
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
            const SizedBox(width: 4),
            IconButton(
              tooltip: 'common.edit'.tr,
              onPressed: onEdit,
              icon: const Icon(Icons.edit_outlined, size: 19),
            ),
            IconButton(
              tooltip: 'common.delete'.tr,
              onPressed: onDelete,
              icon: Icon(
                Icons.delete_outline,
                size: 19,
                color: theme.colorScheme.error,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _ExchangeRateDialog extends StatefulWidget {
  final ExchangeRate? rate;
  final Currency? currency;

  const _ExchangeRateDialog({this.rate, this.currency});

  @override
  State<_ExchangeRateDialog> createState() => _ExchangeRateDialogState();
}

class _ExchangeRateDialogState extends State<_ExchangeRateDialog> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(
      text: widget.rate == null ? '' : Formatters.rate(widget.rate!.rateToBase),
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
    final currency = widget.currency ??
        (widget.rate != null
            ? settings.currencyById(widget.rate!.currencyId)
            : null);
    final base = settings.defaultCurrency;

    return AlertDialog(
      title: Text(
        widget.rate == null ? 'rates.addTitle'.tr : 'rates.editTitle'.tr,
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'rates.hint'.trParams({
              'from': currency?.displayLabel ?? '',
              'to': base?.displayLabel ?? '',
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