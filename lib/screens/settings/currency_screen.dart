import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';

import '../../controllers/settings_controller.dart';
import '../../models/currency.dart';
import '../../widgets/confirmation_dialog.dart';
import '../../widgets/ui/app_appbar.dart';
import '../../widgets/ui/app_loading.dart';
import '../../widgets/ui/app_snackbars.dart';
import '../../widgets/ui/app_states.dart';
import '../../widgets/ui/app_tile.dart';

class CurrencyScreen extends StatelessWidget {
  const CurrencyScreen({super.key});

  Future<void> _addCurrency(
    BuildContext context,
    SettingsController controller,
  ) async {
    final result = await showDialog<Currency>(
      context: context,
      builder: (_) => _CurrencyDialog(),
    );
    if (result == null) return;

    final error = await controller.createCurrency(result);
    if (error != null) {
      AppSnack.error(error, title: 'currency.addFailed'.tr);
    } else {
      AppSnack.success('currency.added'.tr, title: 'common.add'.tr);
    }
  }

  Future<void> _editCurrency(
    BuildContext context,
    SettingsController controller,
    Currency currency,
  ) async {
    final result = await showDialog<Currency>(
      context: context,
      builder: (_) => _CurrencyDialog(currency: currency),
    );
    if (result == null) return;

    final error = await controller.updateCurrency(result);
    if (error != null) {
      AppSnack.error(error, title: 'common.update'.tr);
    } else {
      AppSnack.success('currency.updated'.tr, title: 'common.update'.tr);
    }
  }

  Future<void> _deleteCurrency(
    BuildContext context,
    SettingsController controller,
    Currency currency,
  ) async {
    final confirmed = await ConfirmationDialog.show(
      context,
      title: 'currency.deleteTitle'.tr,
      message: 'currency.deleteMessage'.trParams({'code': currency.code}),
      confirmText: 'common.delete'.tr,
      destructive: true,
      confirmIcon: Icons.delete_outline,
    );
    if (confirmed != true) return;

    final error = await controller.deleteCurrency(currency.id);
    if (error != null) {
      AppSnack.error(error, title: 'currency.deleteFailed'.tr);
    } else {
      AppSnack.success('currency.deleted'.tr, title: 'common.delete'.tr);
    }
  }

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
              title: 'currency.emptyTitle'.tr,
              message: 'currency.emptyMessage'.tr,
              actionLabel: 'currency.add'.tr,
              onAction: () => _addCurrency(context, controller),
            );
          }

          return RefreshIndicator(
            onRefresh: controller.loadCurrenciesAndRates,
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 96),
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
                        onEdit: () =>
                            _editCurrency(context, controller, currencies[i]),
                        onDelete: controller.isBaseCurrency(currencies[i].id)
                            ? null
                            : () => _deleteCurrency(
                                context,
                                controller,
                                currencies[i],
                              ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        heroTag: 'currency-add',
        onPressed: () =>
            _addCurrency(context, Get.find<SettingsController>()),
        icon: const Icon(Icons.add),
        label: Text('currency.add'.tr),
      ),
    );
  }
}

class _CurrencyTile extends StatelessWidget {
  final Currency currency;
  final bool isDefault;
  final VoidCallback onTap;
  final VoidCallback onEdit;
  final VoidCallback? onDelete;

  const _CurrencyTile({
    required this.currency,
    required this.isDefault,
    required this.onTap,
    required this.onEdit,
    this.onDelete,
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
            IconButton(
              tooltip: 'common.edit'.tr,
              onPressed: onEdit,
              icon: const Icon(Icons.edit_outlined, size: 19),
            ),
            if (onDelete != null)
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
        ),
      ),
    );
  }
}

class _CurrencyDialog extends StatefulWidget {
  final Currency? currency;

  const _CurrencyDialog({this.currency});

  @override
  State<_CurrencyDialog> createState() => _CurrencyDialogState();
}

class _CurrencyDialogState extends State<_CurrencyDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _code;
  late final TextEditingController _name;
  late final TextEditingController _symbol;
  late bool _isActive;

  bool get _isEditing => widget.currency != null;

  @override
  void initState() {
    super.initState();
    _code = TextEditingController(text: widget.currency?.code ?? '');
    _name = TextEditingController(text: widget.currency?.name ?? '');
    _symbol = TextEditingController(text: widget.currency?.symbol ?? '');
    _isActive = widget.currency?.isActive ?? true;
  }

  @override
  void dispose() {
    _code.dispose();
    _name.dispose();
    _symbol.dispose();
    super.dispose();
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    final currency = Currency(
      id: widget.currency?.id ?? '',
      code: _code.text.trim().toUpperCase(),
      name: _name.text.trim(),
      symbol: _symbol.text.trim().isEmpty ? _code.text.trim().toUpperCase() : _symbol.text.trim(),
      isBaseCurrency: widget.currency?.isBaseCurrency ?? false,
      isActive: _isActive,
    );
    Navigator.of(context).pop(currency);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return AlertDialog(
      title: Text(
        _isEditing ? 'currency.editTitle'.tr : 'currency.addTitle'.tr,
      ),
      content: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: _code,
                enabled: !_isEditing,
                textCapitalization: TextCapitalization.characters,
                textInputAction: TextInputAction.next,
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp(r'[A-Za-z]')),
                  LengthLimitingTextInputFormatter(3),
                ],
                validator: (value) => value == null || value.trim().isEmpty
                    ? 'currency.codeRequired'.tr
                    : null,
                decoration: InputDecoration(
                  labelText: 'currency.code'.tr,
                  hintText: 'JOD',
                  prefixIcon: const Icon(Icons.tag),
                ),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _name,
                textInputAction: TextInputAction.next,
                validator: (value) => value == null || value.trim().isEmpty
                    ? 'currency.nameRequired'.tr
                    : null,
                decoration: InputDecoration(
                  labelText: 'currency.name'.tr,
                  hintText: 'Jordanian Dinar',
                  prefixIcon: const Icon(Icons.currency_exchange),
                ),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _symbol,
                textInputAction: TextInputAction.done,
                onFieldSubmitted: (_) => _submit(),
                decoration: InputDecoration(
                  labelText: 'currency.symbol'.tr,
                  hintText: 'JOD',
                  prefixIcon: const Icon(Icons.attach_money),
                ),
              ),
              if (!_isEditing) ...[
                const SizedBox(height: 12),
                Row(
                  children: [
                    Switch(
                      value: _isActive,
                      onChanged: (value) => setState(() => _isActive = value),
                    ),
                    const SizedBox(width: 6),
                    Text('productForm.active'.tr, style: theme.textTheme.bodyMedium),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text('common.cancel'.tr),
        ),
        FilledButton.icon(
          onPressed: _submit,
          icon: const Icon(Icons.save_outlined),
          label: Text('common.save'.tr),
        ),
      ],
    );
  }
}
