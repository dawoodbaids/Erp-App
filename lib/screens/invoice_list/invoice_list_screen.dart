import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../controllers/invoice_controller.dart';
import '../../core/routes/app_routes.dart';
import '../../core/theme/app_colors.dart';
import '../../models/invoice.dart';
import '../../widgets/ui/app_appbar.dart';
import '../../widgets/ui/app_loading.dart';
import '../../widgets/ui/app_search_field.dart';
import '../../widgets/ui/app_states.dart';
import '../../widgets/ui/invoice_card.dart';

class InvoiceListScreen extends StatefulWidget {
  const InvoiceListScreen({super.key});

  @override
  State<InvoiceListScreen> createState() => _InvoiceListScreenState();
}

class _InvoiceListScreenState extends State<InvoiceListScreen> {
  final _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppAppBar(
        title: 'invoices.title'.tr,
        subtitle: 'dashboard.subtitle'.tr,
        showBack: false,
        bottom: AppSearchField(
          controller: _searchController,
          hint: 'invoices.searchHint'.tr,
          onChanged: (value) =>
              Get.find<InvoiceController>().setSearchQuery(value),
          onClear: () {
            _searchController.clear();
            Get.find<InvoiceController>().clearSearch();
          },
        ),
      ),
      body: GetX<InvoiceController>(
        builder: (controller) {
          if (controller.errorMessage != null) {
            return AppErrorState(
              title: 'invoices.errorTitle'.tr,
              message: controller.errorMessage!,
              onRetry: controller.refresh,
            );
          }

          if (controller.isLoading && controller.invoices.isEmpty) {
            return const AppListSkeleton();
          }

          final invoices = controller.filteredInvoices;

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _StatusFilter(
                selected: controller.statusFilter,
                onChanged: controller.setStatusFilter,
                totalCount: controller.invoices
                    .where((i) => !i.isHidden)
                    .length,
              ),
              Expanded(
                child: invoices.isEmpty
                    ? AppEmptyState(
                        icon: Icons.receipt_long_outlined,
                        title: 'invoices.emptyTitle'.tr,
                        message: _emptyMessage(controller),
                        actionLabel: 'invoices.create'.tr,
                        onAction: () => Get.toNamed(AppRoutes.invoiceForm),
                      )
                    : RefreshIndicator(
                        onRefresh: controller.refresh,
                        child: ListView.separated(
                          physics: const AlwaysScrollableScrollPhysics(),
                          padding: const EdgeInsets.fromLTRB(16, 6, 16, 96),
                          itemCount: invoices.length,
                          separatorBuilder: (_, _) =>
                              const SizedBox(height: 10),
                          itemBuilder: (context, index) =>
                              InvoiceCard(invoice: invoices[index]),
                        ),
                      ),
              ),
            ],
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        heroTag: 'invoice-list-create-invoice',
        onPressed: () => Get.toNamed(AppRoutes.invoiceForm),
        icon: const Icon(Icons.add),
        label: Text('invoices.create'.tr),
      ),
    );
  }

  String _emptyMessage(InvoiceController controller) {
    final hasQuery = controller.searchQuery.trim().isNotEmpty;
    final hasFilter = controller.statusFilter != null;
    if (hasQuery && hasFilter) {
      return 'invoices.emptyBoth'.trParams({
        'status': controller.statusFilter!.translationKey.tr,
      });
    }
    if (hasQuery) {
      return 'invoices.emptyQuery'.trParams({'query': controller.searchQuery});
    }
    if (hasFilter) {
      return 'invoices.emptyFilter'.trParams({
        'status': controller.statusFilter!.translationKey.tr,
      });
    }
    return 'invoices.emptyNoData'.tr;
  }
}

class _StatusFilter extends StatelessWidget {
  final InvoiceStatus? selected;
  final ValueChanged<InvoiceStatus?> onChanged;
  final int totalCount;

  const _StatusFilter({
    required this.selected,
    required this.onChanged,
    required this.totalCount,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    Widget pill(String label, InvoiceStatus? value, {Color? color}) {
      final isSelected = selected == value;
      final foreground = isSelected
          ? (color ?? theme.colorScheme.primary)
          : theme.colorScheme.onSurfaceVariant;

      return InkWell(
        onTap: () => onChanged(isSelected ? null : value),
        borderRadius: BorderRadius.circular(999),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(
            color: isSelected
                ? (color ?? theme.colorScheme.primary).withValues(
                    alpha: isDark ? 0.22 : 0.12,
                  )
                : Colors.transparent,
            borderRadius: BorderRadius.circular(999),
            border: Border.all(
              color: isSelected
                  ? (color ?? theme.colorScheme.primary).withValues(alpha: 0.6)
                  : theme.colorScheme.outlineVariant.withValues(alpha: 0.6),
            ),
          ),
          child: Text(
            label,
            style: theme.textTheme.labelMedium?.copyWith(
              color: foreground,
              fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
            ),
          ),
        ),
      );
    }

    return SizedBox(
      height: 56,
      child: Padding(
        padding: const EdgeInsetsDirectional.fromSTEB(16, 8, 16, 8),
        child: Row(
          children: [
            Expanded(
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    pill('invoices.all'.tr, null),
                    const SizedBox(width: 8),
                    pill(
                      'invoices.filterDraft'.tr,
                      InvoiceStatus.draft,
                      color: AppColors.draft,
                    ),
                    const SizedBox(width: 8),
                    pill(
                      'invoices.filterApproved'.tr,
                      InvoiceStatus.approved,
                      color: AppColors.approved,
                    ),
                    const SizedBox(width: 8),
                    pill(
                      'invoices.filterCancelled'.tr,
                      InvoiceStatus.cancelled,
                      color: AppColors.cancelled,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 10),
            Text(
              '$totalCount',
              style: theme.textTheme.labelSmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
