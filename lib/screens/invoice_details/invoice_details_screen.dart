import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../controllers/invoice_controller.dart';
import '../../controllers/product_controller.dart';
import '../../core/routes/app_routes.dart';
import '../../core/utils/formatters.dart';
import '../../core/utils/product_image.dart';
import '../../core/utils/tax_calculator.dart';
import '../../models/invoice.dart';
import '../../models/invoice_item.dart';
import '../../widgets/confirmation_dialog.dart';
import '../../widgets/invoice_summary.dart';
import '../../widgets/status_badge.dart';
import '../../widgets/ui/app_appbar.dart';
import '../../widgets/ui/app_card.dart';
import '../../widgets/ui/app_loading.dart';
import '../../widgets/ui/app_states.dart';

class InvoiceDetailsScreen extends StatefulWidget {
  const InvoiceDetailsScreen({super.key});

  @override
  State<InvoiceDetailsScreen> createState() => _InvoiceDetailsScreenState();
}

class _InvoiceDetailsScreenState extends State<InvoiceDetailsScreen> {
  String get _invoiceId => Get.arguments as String;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Get.find<InvoiceController>().loadDetails(_invoiceId);
    });
  }

  Future<void> _edit() async {
    await Get.toNamed(AppRoutes.invoiceForm, arguments: _invoiceId);
  }

  Future<void> _approve(
    BuildContext context,
    InvoiceController controller,
  ) async {
    final confirmed = await ConfirmationDialog.show(
      context,
      title: 'details.approveConfirmTitle'.tr,
      message: 'details.approveConfirmMessage'.tr,
      confirmText: 'details.approveConfirmAction'.tr,
      confirmIcon: Icons.check_circle_outline,
    );
    if (confirmed != true) return;

    final error = await controller.approve(_invoiceId);
    if (error != null) {
      Get.snackbar('details.approveFailed'.tr, error);
      return;
    }
    Get.snackbar('common.approve'.tr, 'details.approveSuccess'.tr);
  }

  Future<void> _cancel(
    BuildContext context,
    InvoiceController controller,
  ) async {
    final confirmed = await ConfirmationDialog.show(
      context,
      title: 'details.cancelConfirmTitle'.tr,
      message: 'details.cancelConfirmMessage'.tr,
      confirmText: 'details.cancelConfirmAction'.tr,
      cancelText: 'confirm.no'.tr,
      destructive: true,
      confirmIcon: Icons.cancel_outlined,
    );
    if (confirmed != true) return;

    final error = await controller.cancel(_invoiceId);
    if (error != null) {
      Get.snackbar('details.cancelFailed'.tr, error);
      return;
    }
    Get.snackbar('common.cancel'.tr, 'details.cancelSuccess'.tr);
  }

  Future<void> _hide(BuildContext context, InvoiceController controller) async {
    final confirmed = await ConfirmationDialog.show(
      context,
      title: 'details.hideConfirmTitle'.tr,
      message: 'details.hideConfirmMessage'.tr,
      confirmText: 'details.hideConfirmAction'.tr,
      destructive: true,
      confirmIcon: Icons.visibility_off_outlined,
    );
    if (confirmed != true) return;

    final error = await controller.hide(_invoiceId);
    if (error != null) {
      Get.snackbar('details.hideFailed'.tr, error);
      return;
    }
    if (!mounted) return;
    Get.back();
    Get.snackbar('details.hideSuccess'.tr, 'details.hideSuccessMessage'.tr);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppAppBar(
        title: 'details.title'.tr,
        actions: [
          GetX<InvoiceController>(
            builder: (controller) {
              final invoice = controller.byId(_invoiceId);
              if (invoice == null || invoice.isHidden) {
                return const SizedBox.shrink();
              }
              return PopupMenuButton<String>(
                tooltip: 'details.more'.tr,
                onSelected: (value) {
                  if (value == 'hide') _hide(context, controller);
                },
                itemBuilder: (_) => [
                  PopupMenuItem(
                    value: 'hide',
                    child: ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: const Icon(Icons.visibility_off_outlined),
                      title: Text('details.hideAction'.tr),
                    ),
                  ),
                ],
              );
            },
          ),
        ],
      ),
      body: GetX<InvoiceController>(
        builder: (controller) {
          final invoice = controller.byId(_invoiceId);
          if (invoice == null) {
            if (controller.isLoadingDetails) return const AppLoadingState();
            return AppErrorState(
              title: 'details.title'.tr,
              message: 'error.title'.tr,
              onRetry: () async {
                await controller.loadDetails(_invoiceId);
              },
            );
          }

          if (invoice.items.isEmpty && controller.isLoadingDetails) {
            return const AppLoadingState();
          }

          final editable = invoice.isEditable;

          return RefreshIndicator(
            onRefresh: () => controller.loadDetails(_invoiceId),
            child: ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
              children: [
                _headerCard(context, invoice),
                if (!editable) ...[
                  const SizedBox(height: 12),
                  _readOnlyBanner(context, invoice),
                ],
                const SizedBox(height: 20),
                Text(
                  'details.items'.tr,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${invoice.items.length} ${'customers.invoicePlural'.tr}',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 10),
                if (invoice.items.isEmpty)
                  AppEmptyState(
                    icon: Icons.inventory_2_outlined,
                    title: 'details.noItems'.tr,
                    message: 'form.noItems'.tr,
                  )
                else
                  ...invoice.items.map(
                    (item) => Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: _itemTile(context, invoice, item),
                    ),
                  ),
                const SizedBox(height: 8),
                InvoiceSummary(
                  subtotal: invoice.subtotal,
                  tax: invoice.taxAmount,
                  total: invoice.totalAmount,
                  currencyCode: invoice.currency.code,
                ),
                const SizedBox(height: 20),
                if (editable) _draftActions(context, controller),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _headerCard(BuildContext context, Invoice invoice) {
    final theme = Theme.of(context);
    final textTheme = theme.textTheme;

    return AppCard(
      padding: const EdgeInsets.all(18),
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
                      invoice.invoiceName.isEmpty
                          ? invoice.invoiceNumber
                          : invoice.invoiceName,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      invoice.invoiceNumber,
                      style: textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              StatusBadge(status: invoice.status),
            ],
          ),
          const Divider(height: 26),
          _infoRow(
            context,
            Icons.person_outline,
            'details.customer'.tr,
            invoice.customer.name,
          ),
          _infoRow(
            context,
            Icons.event_outlined,
            'details.date'.tr,
            Formatters.dateTime(invoice.createdAt),
          ),
          _infoRow(
            context,
            Icons.currency_exchange,
            'details.currency'.tr,
            invoice.currency.code,
          ),
          _infoRow(
            context,
            Icons.swap_horiz,
            'details.exchangeRate'.tr,
            '${Formatters.rate(invoice.exchangeRate)} '
            '${invoice.baseCurrencyCode}',
          ),
          _infoRow(
            context,
            Icons.receipt_long_outlined,
            'details.taxMode'.tr,
            invoice.taxMode.translationKey.tr,
          ),
          if (invoice.approvedAt != null)
            _infoRow(
              context,
              Icons.verified_outlined,
              'details.approvedAt'.tr,
              Formatters.dateTime(invoice.approvedAt!),
            ),
          if (invoice.cancelledAt != null)
            _infoRow(
              context,
              Icons.cancel_outlined,
              'details.cancelledAt'.tr,
              Formatters.dateTime(invoice.cancelledAt!),
            ),
          if (invoice.isHidden)
            _infoRow(
              context,
              Icons.visibility_off_outlined,
              'details.visibility'.tr,
              'details.hidden'.tr,
            ),
        ],
      ),
    );
  }

  Widget _readOnlyBanner(BuildContext context, Invoice invoice) {
    final theme = Theme.of(context);
    final cancelled = invoice.status == InvoiceStatus.cancelled;
    final color = cancelled
        ? theme.colorScheme.error
        : theme.colorScheme.secondary;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withValues(alpha: 0.35)),
      ),
      child: Row(
        children: [
          Icon(
            cancelled ? Icons.cancel_outlined : Icons.lock_outline,
            color: color,
            size: 20,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              cancelled
                  ? 'details.readOnlyCancelled'.tr
                  : 'details.readOnlyApproved'.tr,
              style: TextStyle(
                color: color,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.3,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _itemTile(BuildContext context, Invoice invoice, InvoiceItem item) {
    final theme = Theme.of(context);
    final textTheme = theme.textTheme;
    final lineTotal = TaxCalculator.lineTotal(item, invoice.taxMode);

    return AppCard(
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              buildProductImage(
                Get.find<ProductController>().byId(item.productId)?.image,
                size: 36,
                context: context,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  item.productName,
                  style: textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              Text(
                Formatters.amountWithCurrency(invoice.currency, lineTotal),
                style: textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w800,
                  color: theme.colorScheme.primary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            '${'details.barcode'.tr}: ${item.barcode}',
            style: textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 16,
            runSpacing: 4,
            children: [
              _meta(
                context,
                'details.qty'.tr,
                Formatters.quantity(item.quantity),
              ),
              _meta(
                context,
                'details.price'.tr,
                Formatters.amountWithCurrency(invoice.currency, item.unitPrice),
              ),
              if (item.originalCurrencyCode.isNotEmpty &&
                  item.originalCurrencyCode != invoice.currency.code)
                _meta(
                  context,
                  'details.originalPrice'.tr,
                  '${item.originalCurrencyCode} '
                  '${Formatters.amount(item.originalUnitPrice)}',
                ),
              _meta(
                context,
                'details.tax'.tr,
                '${Formatters.rate(item.taxRate)}%',
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _meta(BuildContext context, String label, String value) {
    final theme = Theme.of(context);
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          '$label: ',
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
        Text(
          value,
          style: theme.textTheme.bodySmall?.copyWith(
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }

  Widget _infoRow(
    BuildContext context,
    IconData icon,
    String label,
    String value,
  ) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 17, color: theme.colorScheme.onSurfaceVariant),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              label,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ),
          Flexible(
            child: Text(
              value,
              textAlign: TextAlign.end,
              style: theme.textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _draftActions(BuildContext context, InvoiceController controller) {
    return AppCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: _edit,
              icon: const Icon(Icons.edit_outlined),
              label: Text('details.edit'.tr),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: FilledButton.tonalIcon(
                  onPressed: () => _approve(context, controller),
                  icon: const Icon(Icons.check_circle_outline),
                  label: Text('details.approveConfirmAction'.tr),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => _cancel(context, controller),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Theme.of(context).colorScheme.error,
                  ),
                  icon: const Icon(Icons.cancel_outlined),
                  label: Text('common.cancel'.tr),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
