import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../controllers/create_invoice_controller.dart';
import '../../controllers/invoice_controller.dart';
import '../../controllers/product_controller.dart';
import '../../controllers/settings_controller.dart';
import '../../controllers/shell_controller.dart';
import '../../core/routes/app_routes.dart';
import '../../core/utils/formatters.dart';
import '../../models/invoice.dart';
import '../../widgets/barcode_dialog.dart';
import '../../widgets/currency_selector.dart';
import '../../widgets/customer_selector.dart';
import '../../widgets/invoice_item_card.dart';
import '../../widgets/invoice_summary.dart';
import '../../widgets/product_form_dialog.dart';
import '../../widgets/product_selector.dart';
import '../../widgets/status_badge.dart';
import '../../widgets/ui/app_appbar.dart';
import '../../widgets/ui/app_card.dart';
import '../../widgets/ui/app_loading.dart';
import '../../widgets/ui/app_states.dart';

//clean up and refactor the code to be more readable and maintainable
class InvoiceFormScreen extends StatefulWidget {
  const InvoiceFormScreen({super.key});

  @override
  State<InvoiceFormScreen> createState() => _InvoiceFormScreenState();
}

class _InvoiceFormScreenState extends State<InvoiceFormScreen> {
  final _formKey = GlobalKey<FormState>();
  bool _loadingInvoice = false;
  String? _invoiceLoadError;

  CreateInvoiceController get _controller =>
      Get.find<CreateInvoiceController>();

  @override
  void initState() {
    super.initState();
    final args = Get.arguments;
    final controller = _controller;

    if (args is String) {
      final invoice = Get.find<InvoiceController>().byId(args);
      if (invoice != null) {
        controller.loadForEdit(invoice);
      } else {
        _loadingInvoice = true;
        controller.loadForCreate();
        WidgetsBinding.instance.addPostFrameCallback((_) => _loadInvoice(args));
      }
    } else {
      controller.loadForCreate();
    }
  }

  Future<void> _loadInvoice(String id) async {
    if (mounted) {
      setState(() {
        _loadingInvoice = true;
        _invoiceLoadError = null;
      });
    }
    final invoice = await Get.find<InvoiceController>().loadDetails(id);
    if (!mounted) return;
    if (invoice == null) {
      setState(() {
        _loadingInvoice = false;
        _invoiceLoadError = 'Could not load the invoice. Please try again.';
      });
      return;
    }
    _controller.loadForEdit(invoice);
    setState(() {
      _loadingInvoice = false;
      _invoiceLoadError = null;
    });
  }

  Future<void> _scanBarcode() async {
    final barcode = await BarcodeDialog.show(context);
    if (barcode == null || barcode.isEmpty) return;

    final controller = _controller;
    final error = await controller.addByBarcode(barcode);
    if (error != null) {
      final canCreate = error.contains('No product found with barcode');
      if (!canCreate) {
        Get.snackbar('form.productNotFound'.tr, error);
        return;
      }

      final create = await Get.dialog<bool>(
        AlertDialog(
          title: Text('form.productNotFound'.tr),
          content: Text(
            'form.createProductFromBarcode'.trParams({'barcode': barcode}),
          ),
          actions: [
            TextButton(onPressed: Get.back, child: Text('common.cancel'.tr)),
            FilledButton(
              onPressed: () => Get.back(result: true),
              child: Text('common.add'.tr),
            ),
          ],
        ),
      );
      if (create != true || !mounted) return;

      final saved = await ProductFormDialog.show(
        context,
        initialBarcode: barcode,
      );
      if (saved == true) {
        final product = Get.find<ProductController>().findByBarcode(barcode);
        if (product != null) controller.addProduct(product);
      }
    }
  }

  Future<void> _addProduct() async {
    final product = await ProductSelector.show(context);
    if (product != null) {
      _controller.addProduct(product);
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    final controller = _controller;
    final error = await controller.save();

    if (error != null) {
      Get.snackbar('form.errorTitle'.tr, error);
      return;
    }

    final createdId = controller.isEditMode
        ? controller.editingId
        : controller.lastCreated.value?.id;
    if (createdId != null && createdId.isNotEmpty) {
      final invoice = Get.find<InvoiceController>().byId(createdId);
      await _showSaveSuccess(createdId, invoice);
    } else {
      Get.offNamed(AppRoutes.shell);
      Get.find<ShellController>().goToInvoices();
    }
  }

  Future<void> _showSaveSuccess(String id, Invoice? invoice) async {
    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        final theme = Theme.of(dialogContext);
        return Dialog(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 460),
            child: Padding(
              padding: const EdgeInsets.all(28),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 68,
                    height: 68,
                    decoration: BoxDecoration(
                      color: theme.colorScheme.primary.withValues(alpha: 0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.check_rounded,
                      size: 38,
                      color: theme.colorScheme.primary,
                    ),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    _controller.isEditMode
                        ? 'form.invoiceUpdatedTitle'.tr
                        : 'form.invoiceCreatedTitle'.tr,
                    textAlign: TextAlign.center,
                    style: theme.textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    invoice?.displayNumber ?? id,
                    style: theme.textTheme.titleMedium?.copyWith(
                      color: theme.colorScheme.primary,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  if (invoice != null) ...[
                    const SizedBox(height: 18),
                    _SuccessMeta(
                      label: 'form.customer'.tr,
                      value: invoice.customer.name,
                    ),
                    const SizedBox(height: 8),
                    _SuccessMeta(
                      label: 'form.total'.tr,
                      value:
                          '${invoice.currency.code} ${Formatters.amount(invoice.totalAmount)}',
                    ),
                  ],
                  const SizedBox(height: 24),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () {
                            Navigator.of(dialogContext).pop();
                            Get.offNamed(AppRoutes.shell);
                            Get.find<ShellController>().goToInvoices();
                          },
                          child: Text('form.backToInvoices'.tr),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: FilledButton(
                          onPressed: () {
                            Navigator.of(dialogContext).pop();
                            Get.offNamed(
                              AppRoutes.invoiceDetails,
                              arguments: id,
                            );
                          },
                          child: Text('form.viewInvoice'.tr),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final textTheme = theme.textTheme;

    if (_loadingInvoice) {
      return const Scaffold(body: AppLoadingState());
    }
    if (_invoiceLoadError != null) {
      return Scaffold(
        body: AppErrorState(
          title: 'form.errorTitle'.tr,
          message: _invoiceLoadError!,
          onRetry: () => _loadInvoice(Get.arguments as String),
        ),
      );
    }

    return GetX<CreateInvoiceController>(
      builder: (controller) {
        final editable = controller.isEditable;
        final currency = controller.selectedCurrency.value;
        final currencyCode = currency?.code ?? '';

        return Scaffold(
          appBar: AppAppBar(
            title: controller.isEditMode
                ? 'form.editTitle'.tr
                : 'form.newTitle'.tr,
          ),
          body: Form(
            key: _formKey,
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _headerCard(context, controller),
                  const SizedBox(height: 16),
                  CustomerSelector(enabled: editable),
                  const SizedBox(height: 16),
                  CurrencySelector(enabled: editable),
                  const SizedBox(height: 16),
                  _exchangeRateInfo(context, controller),
                  const SizedBox(height: 16),
                  _taxModeSelector(context, controller),
                  const SizedBox(height: 20),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: editable ? _scanBarcode : null,
                          icon: const Icon(Icons.qr_code_scanner),
                          label: Text('form.scanBarcode'.tr),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: FilledButton.tonalIcon(
                          onPressed: editable ? _addProduct : null,
                          icon: const Icon(Icons.add),
                          label: Text('form.addProduct'.tr),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'form.items'.tr,
                    style: textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 4),
                  if (controller.items.isEmpty)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      child: Center(
                        child: Text(
                          'form.noItems'.tr,
                          style: textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ),
                    )
                  else
                    ...controller.items.map((item) {
                      return InvoiceItemCard(
                        key: ValueKey(item.id),
                        item: item,
                        editable: editable,
                        taxMode: controller.taxMode.value,
                        currencyCode: currencyCode,
                        onQuantityChanged: (value) =>
                            controller.updateQuantity(item.id, value),
                        onRemove: () => controller.removeItem(item.id),
                      );
                    }),
                  const SizedBox(height: 16),
                  InvoiceSummary(
                    subtotal: controller.subtotal,
                    tax: controller.tax,
                    total: controller.total,
                    currencyCode: currencyCode,
                  ),
                ],
              ),
            ),
          ),
          bottomNavigationBar: SafeArea(
            top: false,
            child: Container(
              padding: const EdgeInsets.fromLTRB(16, 10, 16, 10),
              decoration: BoxDecoration(
                color: theme.colorScheme.surface,
                border: Border(
                  top: BorderSide(
                    color: theme.colorScheme.outlineVariant.withValues(
                      alpha: 0.5,
                    ),
                  ),
                ),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'form.total'.tr,
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.5,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '$currencyCode ${Formatters.amount(controller.total)}',
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w800,
                            color: theme.colorScheme.primary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 16),
                  FilledButton.icon(
                    onPressed: controller.isSaving ? null : _save,
                    icon: controller.isSaving
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.save_outlined),
                    label: Text(
                      controller.isEditMode
                          ? 'form.saveChanges'.tr
                          : 'form.save'.tr,
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  /// Read-only display of the invoice currency's rate against the base
  /// currency. The rate comes from Firestore; the user never enters prices.
  Widget _exchangeRateInfo(
    BuildContext context,
    CreateInvoiceController controller,
  ) {
    final theme = Theme.of(context);
    final settings = Get.find<SettingsController>();
    final currency = controller.selectedCurrency.value;
    final baseCode = settings.defaultCurrency?.code ?? '';
    final currencyCode = currency?.code ?? baseCode;
    final missing = controller.isExchangeRateMissing;
    final showRate =
        !missing && currency != null && controller.exchangeRate.value > 0;

    return AppCard(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      child: Row(
        children: [
          Icon(
            missing ? Icons.error_outline : Icons.swap_horiz,
            size: 18,
            color: missing
                ? theme.colorScheme.error
                : theme.colorScheme.onSurfaceVariant,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              missing
                  ? 'form.exchangeRateMissing'.trParams({
                      'from': currencyCode,
                      'to': baseCode,
                    })
                  : 'form.exchangeRate'.tr,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: missing
                    ? theme.colorScheme.error
                    : theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ),
          if (showRate) ...[
            Icon(
              Icons.lock_outline,
              size: 14,
              color: theme.colorScheme.onSurfaceVariant,
            ),
            const SizedBox(width: 6),
            Text(
              '1 $currencyCode = ${Formatters.rate(controller.exchangeRate.value)} $baseCode',
              style: theme.textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _headerCard(BuildContext context, CreateInvoiceController controller) {
    final theme = Theme.of(context);
    final textTheme = theme.textTheme;

    final invoiceNumber = controller.isEditMode
        ? (Get.find<InvoiceController>()
                  .byId(controller.editingId)
                  ?.displayNumber ??
              '')
        : Get.find<InvoiceController>().previewInvoiceNumber().toString();

    return AppCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'form.invoiceNumber'.tr,
                      style: textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      invoiceNumber,
                      style: textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
              ),
              StatusBadge(status: InvoiceStatus.draft),
            ],
          ),
          const SizedBox(height: 16),
          TextFormField(
            key: const Key('invoice-name'),
            initialValue: controller.invoiceName.value,
            onChanged: controller.setInvoiceName,
            textCapitalization: TextCapitalization.sentences,
            validator: (value) => value == null || value.trim().isEmpty
                ? 'form.invoiceNameRequired'.tr
                : null,
            decoration: InputDecoration(
              labelText: 'form.invoiceName'.tr,
              hintText: 'form.invoiceNameHint'.tr,
              prefixIcon: const Icon(Icons.label_outline),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Icon(
                Icons.calendar_today_outlined,
                size: 16,
                color: theme.colorScheme.outline,
              ),
              const SizedBox(width: 8),
              Text(
                Formatters.dateTime(DateTime.now()),
                style: textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _taxModeSelector(
    BuildContext context,
    CreateInvoiceController controller,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'form.taxMode'.tr,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 8),
        SizedBox(
          width: double.infinity,
          child: SegmentedButton<TaxMode>(
            showSelectedIcon: false,
            segments: [
              ButtonSegment(
                value: TaxMode.exclusive,
                label: Text('form.taxExclusive'.tr),
              ),
              ButtonSegment(
                value: TaxMode.inclusive,
                label: Text('form.taxInclusive'.tr),
              ),
            ],
            selected: {controller.taxMode.value},
            onSelectionChanged: (selection) {
              controller.setTaxMode(selection.first);
            },
          ),
        ),
      ],
    );
  }
}

class _SuccessMeta extends StatelessWidget {
  final String label;
  final String value;

  const _SuccessMeta({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: theme.textTheme.bodySmall),
        Flexible(
          child: Text(
            value,
            textAlign: TextAlign.end,
            style: theme.textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
      ],
    );
  }
}
