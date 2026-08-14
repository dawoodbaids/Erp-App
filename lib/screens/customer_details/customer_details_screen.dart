import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../controllers/customer_controller.dart';
import '../../controllers/invoice_controller.dart';
import '../../controllers/settings_controller.dart';
import '../../core/routes/app_routes.dart';
import '../../core/utils/formatters.dart';
import '../../models/customer.dart';
import '../../models/invoice.dart';
import '../../widgets/customer_form_sheet.dart';
import '../../widgets/confirmation_dialog.dart';
import '../../widgets/ui/app_card.dart';
import '../../widgets/ui/app_appbar.dart';
import '../../widgets/ui/app_loading.dart';
import '../../widgets/ui/app_section_header.dart';
import '../../widgets/ui/app_states.dart';
import '../../widgets/ui/initials_avatar.dart';
import '../../widgets/ui/invoice_card.dart';

class CustomerDetailsScreen extends StatefulWidget {
  const CustomerDetailsScreen({super.key});

  @override
  State<CustomerDetailsScreen> createState() => _CustomerDetailsScreenState();
}

class _CustomerDetailsScreenState extends State<CustomerDetailsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Get.find<CustomerController>().loadDetails(_customerId);
    });
  }

  String get _customerId => Get.arguments as String;

  Future<void> _editCustomer(Customer customer) async {
    final data = await CustomerFormSheet.show(context, customer: customer);
    if (data == null || !mounted) return;

    final updated = Customer(
      id: customer.id,
      name: data.name,
      phone: data.phone,
      email: data.email,
      address: data.address,
      currencyId: data.currencyId.isNotEmpty
          ? data.currencyId
          : customer.currencyId,
      isActive: customer.isActive,
      createdAt: customer.createdAt,
    );
    final error = await Get.find<CustomerController>().updateCustomer(updated);
    if (!mounted) return;
    if (error != null) {
      Get.snackbar('customers.errorTitle'.tr, error);
    } else {
      Get.snackbar('common.update'.tr, 'common.success'.tr);
    }
  }

  Future<void> _deleteCustomer() async {
    final confirmed = await ConfirmationDialog.show(
      context,
      title: 'customers.deleteTitle'.tr,
      message: 'customers.deleteMessage'.tr,
      confirmText: 'common.delete'.tr,
      destructive: true,
      confirmIcon: Icons.delete_outline,
    );
    if (confirmed != true) return;

    final error = await Get.find<CustomerController>().deleteCustomer(
      _customerId,
    );
    if (error != null) {
      Get.snackbar('customers.deleteFailed'.tr, error);
      return;
    }
    if (!mounted) return;
    Get.back();
    Get.snackbar('customers.deleteSuccess'.tr, 'common.success'.tr);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppAppBar(
        title: 'customers.detailsTitle'.tr,
        actions: [
          GetX<CustomerController>(
            builder: (controller) {
              final customer = controller.byId(_customerId);
              if (customer == null) return const SizedBox.shrink();
              return Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    tooltip: 'common.edit'.tr,
                    onPressed: () => _editCustomer(customer),
                    icon: const Icon(Icons.edit_outlined),
                  ),
                  PopupMenuButton<String>(
                    tooltip: 'common.delete'.tr,
                    onSelected: (value) {
                      if (value == 'delete') _deleteCustomer();
                    },
                    itemBuilder: (_) => [
                      PopupMenuItem(
                        value: 'delete',
                        child: ListTile(
                          contentPadding: EdgeInsets.zero,
                          leading: const Icon(Icons.delete_outline),
                          title: Text('common.delete'.tr),
                        ),
                      ),
                    ],
                  ),
                ],
              );
            },
          ),
        ],
      ),
      body: GetX<CustomerController>(
        builder: (controller) {
          final customer = controller.byId(_customerId);
          if (customer == null) {
            if (controller.isLoading) return const AppLoadingState();
            return AppErrorState(
              title: 'customers.errorTitle'.tr,
              message:
                  controller.errorMessage ?? 'customers.emptySearchMessage'.tr,
              onRetry: controller.refresh,
            );
          }

          return Obx(() {
            final invoices =
                Get.find<InvoiceController>().invoices
                    .where((i) => !i.isHidden && i.customer.id == customer.id)
                    .toList()
                  ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
            final approvedTotal = invoices.fold<double>(
              0,
              (sum, i) => i.status == InvoiceStatus.approved
                  ? sum + i.totalAmount * i.exchangeRate
                  : sum,
            );
            final currencyCode =
                Get.find<SettingsController>().defaultCurrency?.code ?? '';

            return ListView(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
            children: [
              _HeaderCard(customer: customer),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: _StatBox(
                      label: 'customers.statInvoices'.tr,
                      value: invoices.length.toString(),
                      icon: Icons.receipt_long_rounded,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _StatBox(
                      label: 'customers.statTotal'.tr,
                      value:
                          '${Formatters.amount(approvedTotal)} $currencyCode',
                      icon: Icons.trending_up_rounded,
                      emphasize: true,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              AppSectionHeader(title: 'customers.invoices'.tr),
              if (invoices.isEmpty)
                AppCard(
                  child: Column(
                    children: [
                      Icon(
                        Icons.receipt_long_outlined,
                        size: 34,
                        color: theme.colorScheme.outline,
                      ),
                      const SizedBox(height: 10),
                      Text(
                        'customers.noInvoices'.tr,
                        textAlign: TextAlign.center,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                )
              else
                Column(
                  children: [
                    for (var i = 0; i < invoices.length; i++) ...[
                      InvoiceCard(invoice: invoices[i], dense: true),
                      if (i < invoices.length - 1) const SizedBox(height: 10),
                    ],
                  ],
                ),
            ],
          );
          });
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        heroTag: 'customer-details-new-invoice',
        onPressed: () => Get.toNamed(AppRoutes.invoiceForm),
        icon: const Icon(Icons.add),
        label: Text('dashboard.newInvoice'.tr),
      ),
    );
  }
}

class _HeaderCard extends StatelessWidget {
  final Customer customer;

  const _HeaderCard({required this.customer});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return AppCard(
      child: Row(
        children: [
          InitialsAvatar(name: customer.name, size: 56),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  customer.name,
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
                if ((customer.phone ?? '').isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    customer.phone!,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
                if (customer.email.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(
                    customer.email,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _StatBox extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final bool emphasize;

  const _StatBox({
    required this.label,
    required this.value,
    required this.icon,
    this.emphasize = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = emphasize
        ? theme.colorScheme.primary
        : theme.colorScheme.onSurface;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: theme.colorScheme.outlineVariant.withValues(alpha: 0.55),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 20, color: color),
          const SizedBox(height: 10),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w800,
              color: color,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: theme.textTheme.labelSmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}
