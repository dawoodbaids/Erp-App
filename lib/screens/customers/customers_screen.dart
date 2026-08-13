import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../controllers/customer_controller.dart';
import '../../controllers/invoice_controller.dart';
import '../../controllers/settings_controller.dart';
import '../../core/routes/app_routes.dart';
import '../../models/customer.dart';
import '../../models/invoice.dart';
import '../../widgets/customer_form_sheet.dart';
import '../../widgets/ui/app_appbar.dart';
import '../../widgets/ui/app_loading.dart';
import '../../widgets/ui/app_search_field.dart';
import '../../widgets/ui/app_snackbars.dart';
import '../../widgets/ui/app_states.dart';
import '../../widgets/ui/collection_summary.dart';
import '../../widgets/ui/customer_card.dart';

class CustomersScreen extends StatefulWidget {
  const CustomersScreen({super.key});

  @override
  State<CustomersScreen> createState() => _CustomersScreenState();
}

class _CustomersScreenState extends State<CustomersScreen> {
  final _searchController = TextEditingController();
  final _query = ''.obs;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _addCustomer() async {
    final data = await CustomerFormSheet.show(context);
    if (data == null || !mounted) return;

    final error = await Get.find<CustomerController>().createCustomer(
      name: data.name,
      phone: data.phone,
      email: data.email,
      address: data.address,
    );
    if (!mounted) return;
    if (error != null) {
      AppSnack.error(error, title: 'customers.errorTitle'.tr);
    } else {
      AppSnack.success('customers.added'.tr, title: 'common.save'.tr);
    }
  }

  @override
  Widget build(BuildContext context) {
    final invoiceController = Get.find<InvoiceController>();
    return Scaffold(
      appBar: AppAppBar(
        title: 'customers.title'.tr,
        subtitle: 'customers.addSubtitle'.tr,
        showBack: false,
        bottom: AppSearchField(
          controller: _searchController,
          hint: 'customers.searchHint'.tr,
          onChanged: (value) => _query.value = value,
          onClear: () {
            _searchController.clear();
            _query.value = '';
          },
        ),
      ),
      body: GetX<CustomerController>(
        builder: (customerController) {
          if (customerController.errorMessage != null) {
            return AppErrorState(
              title: 'customers.errorTitle'.tr,
              message: customerController.errorMessage!,
              onRetry: customerController.refresh,
            );
          }

          if (customerController.isLoading &&
              customerController.customers.isEmpty) {
            return const AppListSkeleton();
          }

          final customers = customerController.customers;
          final query = _query.value.trim().toLowerCase();
          final filtered = query.isEmpty
              ? customers
              : customers
                    .where((c) => c.name.toLowerCase().contains(query))
                    .toList();

          if (filtered.isEmpty) {
            return AppEmptyState(
              icon: Icons.people_outline,
              title: query.isEmpty
                  ? 'customers.emptyTitle'.tr
                  : 'customers.emptySearchTitle'.tr,
              message: query.isEmpty
                  ? 'customers.emptyMessage'.tr
                  : 'customers.emptySearchMessage'.tr,
            );
          }

          return RefreshIndicator(
            onRefresh: customerController.refresh,
            child: ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
              children: [
                CollectionSummary(
                  icon: Icons.people_alt_outlined,
                  label: 'dashboard.customers'.tr,
                  count: customers.length,
                ),
                const SizedBox(height: 12),
                for (var i = 0; i < filtered.length; i++) ...[
                  CustomerCard(
                    customer: filtered[i],
                    stats: _statsFor(invoiceController, filtered[i]),
                    onTap: () => Get.toNamed(
                      AppRoutes.customerDetails,
                      arguments: filtered[i].id,
                    ),
                  ),
                  if (i < filtered.length - 1) const SizedBox(height: 10),
                ],
              ],
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        heroTag: 'customers-add-customer',
        onPressed: _addCustomer,
        icon: const Icon(Icons.person_add_alt_1),
        label: Text('customers.add'.tr),
      ),
    );
  }

  ({int count, double total}) _statsFor(
    InvoiceController controller,
    Customer customer,
  ) {
    final list = controller.invoices
        .where((i) => !i.isHidden && i.customer.id == customer.id)
        .toList();
    final settings = Get.find<SettingsController>();
    final total = list.fold<double>(
      0,
      (sum, i) => i.status == InvoiceStatus.approved
          ? sum +
                settings.convert(
                  i.totalAmount,
                  i.currency.id,
                  settings.defaultCurrencyId,
                )
          : sum,
    );
    return (count: list.length, total: total);
  }
}
