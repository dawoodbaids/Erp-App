import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';

import '../../controllers/settings_controller.dart';
import '../../core/utils/formatters.dart';
import '../../models/tax_rate.dart';
import '../../widgets/confirmation_dialog.dart';
import '../../widgets/ui/app_appbar.dart';
import '../../widgets/ui/app_card.dart';
import '../../widgets/ui/app_loading.dart';
import '../../widgets/ui/app_snackbars.dart';
import '../../widgets/ui/app_states.dart';

class TaxScreen extends StatelessWidget {
  const TaxScreen({super.key});

  Future<void> _addTax(
    BuildContext context,
    SettingsController controller,
  ) async {
    final result = await showDialog<TaxRate>(
      context: context,
      builder: (_) => const _TaxDialog(),
    );
    if (result == null) return;

    final error = await controller.createTax(
      name: result.name,
      rate: result.rate,
    );
    if (error != null) {
      AppSnack.error(error, title: 'taxes.addFailed'.tr);
    } else {
      AppSnack.success('taxes.added'.tr, title: 'common.add'.tr);
    }
  }

  Future<void> _editTax(
    BuildContext context,
    SettingsController controller,
    TaxRate tax,
  ) async {
    final result = await showDialog<TaxRate>(
      context: context,
      builder: (_) => _TaxDialog(tax: tax),
    );
    if (result == null) return;

    final error = await controller.updateTax(result);
    if (error != null) {
      AppSnack.error(error, title: 'common.update'.tr);
    } else {
      AppSnack.success('taxes.updated'.tr, title: 'common.update'.tr);
    }
  }

  Future<void> _deleteTax(
    BuildContext context,
    SettingsController controller,
    TaxRate tax,
  ) async {
    final confirmed = await ConfirmationDialog.show(
      context,
      title: 'taxes.deleteTitle'.tr,
      message: 'taxes.deleteMessage'.trParams({'name': tax.name}),
      confirmText: 'common.delete'.tr,
      destructive: true,
      confirmIcon: Icons.delete_outline,
    );
    if (confirmed != true) return;

    final error = await controller.deleteTax(tax.id);
    if (error != null) {
      AppSnack.error(error, title: 'taxes.deleteFailed'.tr);
    } else {
      AppSnack.success('taxes.deleted'.tr, title: 'common.delete'.tr);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppAppBar(title: 'taxes.title'.tr),
      body: GetX<SettingsController>(
        builder: (controller) {
          if (controller.isLoading && controller.taxes.isEmpty) {
            return const AppLoadingState();
          }

          final taxes = controller.taxes;
          if (taxes.isEmpty) {
            return AppEmptyState(
              icon: Icons.percent_outlined,
              title: 'taxes.emptyTitle'.tr,
              message: 'taxes.emptyMessage'.tr,
              actionLabel: 'taxes.add'.tr,
              onAction: () => _addTax(context, controller),
            );
          }

          return RefreshIndicator(
            onRefresh: controller.loadCurrenciesAndRates,
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 96),
              children: [
                Text(
                  'taxes.subtitle'.tr,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 16),
                AppCard(
                  child: Column(
                    children: [
                      for (var i = 0; i < taxes.length; i++) ...[
                        if (i > 0) const Divider(height: 1),
                        _TaxRow(
                          tax: taxes[i],
                          isDefault: i == 0,
                          onEdit: () =>
                              _editTax(context, controller, taxes[i]),
                          onDelete: () =>
                              _deleteTax(context, controller, taxes[i]),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        heroTag: 'tax-add',
        onPressed: () => _addTax(context, Get.find<SettingsController>()),
        icon: const Icon(Icons.add),
        label: Text('taxes.add'.tr),
      ),
    );
  }
}

class _TaxRow extends StatelessWidget {
  final TaxRate tax;
  final bool isDefault;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _TaxRow({
    required this.tax,
    required this.isDefault,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: theme.colorScheme.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(11),
            ),
            child: Text(
              '${tax.rate.round()}%',
              style: theme.textTheme.titleSmall?.copyWith(
                color: theme.colorScheme.primary,
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
                  tax.name,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  isDefault
                      ? 'taxes.defaultHint'.tr
                      : '${Formatters.rate(tax.rate)}%',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: isDefault
                        ? theme.colorScheme.primary
                        : theme.colorScheme.onSurfaceVariant,
                    fontWeight: isDefault ? FontWeight.w700 : null,
                  ),
                ),
              ],
            ),
          ),
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
      ),
    );
  }
}

class _TaxDialog extends StatefulWidget {
  final TaxRate? tax;

  const _TaxDialog({this.tax});

  @override
  State<_TaxDialog> createState() => _TaxDialogState();
}

class _TaxDialogState extends State<_TaxDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _name;
  late final TextEditingController _rate;

  bool get _isEditing => widget.tax != null;

  @override
  void initState() {
    super.initState();
    _name = TextEditingController(text: widget.tax?.name ?? '');
    _rate = TextEditingController(
      text: widget.tax == null ? '' : Formatters.rate(widget.tax!.rate),
    );
  }

  @override
  void dispose() {
    _name.dispose();
    _rate.dispose();
    super.dispose();
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    final rate = double.parse(_rate.text);
    Navigator.of(context).pop(
      TaxRate(
        id: widget.tax?.id ?? '',
        name: _name.text.trim(),
        rate: rate,
        isActive: widget.tax?.isActive ?? true,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(
        _isEditing ? 'taxes.editTitle'.tr : 'taxes.addTitle'.tr,
      ),
      content: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: _name,
                textInputAction: TextInputAction.next,
                validator: (value) => value == null || value.trim().isEmpty
                    ? 'taxes.nameRequired'.tr
                    : null,
                decoration: InputDecoration(
                  labelText: 'taxes.name'.tr,
                  prefixIcon: const Icon(Icons.label_outline),
                ),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _rate,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp(r'[0-9.]')),
                ],
                validator: (value) {
                  final number = double.tryParse(value ?? '');
                  if (number == null) return 'taxes.rateInvalid'.tr;
                  if (number < 0 || number > 100) {
                    return 'taxes.rateRange'.tr;
                  }
                  return null;
                },
                onFieldSubmitted: (_) => _submit(),
                decoration: InputDecoration(
                  labelText: 'taxes.rate'.tr,
                  prefixIcon: const Icon(Icons.percent),
                ),
              ),
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
