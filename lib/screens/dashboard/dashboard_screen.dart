import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../controllers/auth_controller.dart';
import '../../controllers/dashboard_controller.dart';
import '../../controllers/invoice_controller.dart';
import '../../controllers/shell_controller.dart';
import '../../core/routes/app_routes.dart';
import '../../core/theme/app_colors.dart';
import '../../core/utils/formatters.dart';
import '../../models/dashboard.dart';
import '../../models/invoice.dart';
import '../../widgets/barcode_scanner_page.dart';
import '../../widgets/ui/app_card.dart';
import '../../widgets/ui/app_loading.dart';
import '../../widgets/ui/app_page_header.dart';
import '../../widgets/ui/app_section_header.dart';
import '../../widgets/ui/app_states.dart';
import '../../widgets/ui/initials_avatar.dart';
import '../../widgets/ui/invoice_card.dart';
import '../../widgets/ui/stat_card.dart';
import '../../widgets/charts/app_charts.dart';

//dashboad code must be more clean
class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && Get.isRegistered<DashboardController>()) {
        Get.find<DashboardController>().refresh();
      }
    });
  }

  Future<void> _refresh() async {
    await Future.wait([
      Get.find<DashboardController>().refresh(),
      Get.find<InvoiceController>().refresh(),
    ]);
  }

  @override
  Widget build(BuildContext context) {
    final auth = Get.find<AuthController>();
    final shell = Get.find<ShellController>();
    final name = auth.currentUser?.displayName ?? 'Admin';

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: GetX<DashboardController>(
        builder: (dashboard) {
          if (dashboard.isLoading && dashboard.summary.value == null) {
            return const AppLoadingState();
          }
          if (dashboard.errorMessage != null &&
              dashboard.summary.value == null) {
            return AppErrorState(
              title: 'dashboard.errorTitle'.tr,
              message: dashboard.errorMessage!,
              onRetry: dashboard.refresh,
            );
          }

          final summary = dashboard.summary.value;
          final status = dashboard.invoiceStatus.value;
          if (summary == null || status == null) {
            return AppErrorState(
              title: 'dashboard.errorTitle'.tr,
              message: 'dashboard.noData'.tr,
              onRetry: dashboard.refresh,
            );
          }

          return RefreshIndicator(
            onRefresh: _refresh,
            child: ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(0, 0, 0, 96),
              children: [
                AppPageHeader(
                  title: 'dashboard.overview'.tr,
                  subtitle: _greetingText(name),
                  actions: [
                    Padding(
                      padding: const EdgeInsets.only(left: 4),
                      child: InitialsAvatar(name: name, size: 40),
                    ),
                  ],
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: _SalesHero(summary: summary),
                ),
                const SizedBox(height: 14),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: _SummaryGrid(summary: summary),
                ),
                const SizedBox(height: 22),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: AppSectionHeader(
                    title: 'dashboard.recentInvoices'.tr,
                    actionLabel: 'dashboard.viewAll'.tr,
                    onAction: shell.goToInvoices,
                  ),
                ),
                const SizedBox(height: 4),
                _RecentInvoices(),
                const SizedBox(height: 22),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: AppSectionHeader(title: 'dashboard.salesTrend'.tr),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                  child: _SalesTrendCard(points: dashboard.salesTrend),
                ),
                const SizedBox(height: 22),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: AppSectionHeader(title: 'dashboard.invoiceStatus'.tr),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                  child: _StatusCard(status: status),
                ),
                const SizedBox(height: 22),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: AppSectionHeader(title: 'dashboard.quickActions'.tr),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: _QuickActions(shell: shell),
                ),
                const SizedBox(height: 22),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: AppSectionHeader(title: 'dashboard.recentActivity'.tr),
                ),
                const SizedBox(height: 4),
                const _RecentActivity(),
              ],
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        heroTag: 'dashboard-create-invoice',
        onPressed: () => Get.toNamed(AppRoutes.invoiceForm),
        icon: const Icon(Icons.add),
        label: Text('dashboard.createInvoice'.tr),
      ),
    );
  }

  String _greetingText(String name) {
    final hour = DateTime.now().hour;
    final greeting = hour < 12
        ? 'dashboard.goodMorning'.tr
        : hour < 17
        ? 'dashboard.goodAfternoon'.tr
        : 'dashboard.goodEvening'.tr;
    return '$greeting, $name';
  }
}

class _SalesHero extends StatelessWidget {
  final DashboardSummary summary;

  const _SalesHero({required this.summary});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppColors.brandStart, AppColors.brandEnd],
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: isDark ? 0.35 : 0.28),
            blurRadius: 26,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: AppColors.onPrimary.withValues(alpha: 0.16),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.insights_rounded,
                  color: AppColors.onPrimary,
                  size: 21,
                ),
              ),
              const SizedBox(width: 12),
              Text(
                'dashboard.totalSales'.tr,
                style: theme.textTheme.labelSmall?.copyWith(
                  color: AppColors.onPrimary.withValues(alpha: 0.9),
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1.2,
                ),
              ),
              const Spacer(),
              Text(
                '${summary.approvedInvoices} ${'dashboard.approved'.tr}',
                style: const TextStyle(
                  color: AppColors.onPrimary,
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Text(
            '${Formatters.amount(summary.totalSales)} ${summary.baseCurrencyCode}',
            style: theme.textTheme.headlineMedium?.copyWith(
              color: AppColors.onPrimary,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'dashboard.subtitle'.tr,
            style: theme.textTheme.bodySmall?.copyWith(
              color: AppColors.onPrimary.withValues(alpha: 0.8),
            ),
          ),
        ],
      ),
    );
  }
}

class _SummaryGrid extends StatelessWidget {
  final DashboardSummary summary;

  const _SummaryGrid({required this.summary});

  @override
  Widget build(BuildContext context) {
    const cards = [
      (
        label: 'dashboard.totalInvoices',
        icon: Icons.receipt_long_rounded,
        color: AppColors.primary,
        background: AppColors.primarySoft,
      ),
      (
        label: 'dashboard.draft',
        icon: Icons.schedule_rounded,
        color: AppColors.draft,
        background: AppColors.draftSoft,
      ),
      (
        label: 'dashboard.approved',
        icon: Icons.check_circle_rounded,
        color: AppColors.approved,
        background: AppColors.approvedSoft,
      ),
      (
        label: 'dashboard.customers',
        icon: Icons.people_rounded,
        color: AppColors.primary,
        background: AppColors.primarySoft,
      ),
      (
        label: 'dashboard.products',
        icon: Icons.inventory_2_rounded,
        color: AppColors.primary,
        background: AppColors.primarySoft,
      ),
      (
        label: 'dashboard.cancelled',
        icon: Icons.cancel_rounded,
        color: AppColors.cancelled,
        background: AppColors.cancelledSoft,
      ),
    ];
    final values = [
      summary.totalInvoices.toString(),
      summary.pendingDrafts.toString(),
      summary.approvedInvoices.toString(),
      summary.totalCustomers.toString(),
      summary.totalProducts.toString(),
      summary.cancelledInvoices.toString(),
    ];

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: cards.length,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        mainAxisSpacing: 10,
        crossAxisSpacing: 10,
        mainAxisExtent: 112,
      ),
      itemBuilder: (_, index) {
        final card = cards[index];
        return StatCard(
          label: card.label.tr,
          value: values[index],
          icon: card.icon,
          color: card.color,
          background: card.background,
        );
      },
    );
  }
}

class _SalesTrendCard extends StatelessWidget {
  final List<SalesPoint> points;

  const _SalesTrendCard({required this.points});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return AppCard(
      padding: const EdgeInsets.fromLTRB(14, 18, 14, 12),
      child: Column(
        children: [
          SalesTrendChart(
            points: points
                .map(
                  (point) => ChartPoint(label: point.label, value: point.total),
                )
                .toList(),
            height: 150,
          ),
          if (points.isNotEmpty) ...[
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: points
                  .map(
                    (point) => Text(
                      point.label,
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  )
                  .toList(),
            ),
          ],
        ],
      ),
    );
  }
}

class _StatusCard extends StatelessWidget {
  final InvoiceStatusStats status;

  const _StatusCard({required this.status});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final entries = [
      DonutEntry(
        label: 'dashboard.draft',
        count: status.draftCount,
        color: AppColors.draft,
      ),
      DonutEntry(
        label: 'dashboard.approved',
        count: status.approvedCount,
        color: AppColors.approved,
      ),
      DonutEntry(
        label: 'dashboard.cancelled',
        count: status.cancelledCount,
        color: AppColors.cancelled,
      ),
    ];
    return AppCard(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          SizedBox(
            width: 132,
            height: 132,
            child: Stack(
              alignment: Alignment.center,
              children: [
                StatusDonutChart(entries: entries, size: 132),
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      '${status.totalCount}',
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    Text(
                      'dashboard.invoices'.tr,
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 18),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: entries
                  .map(
                    (entry) => Padding(
                      padding: const EdgeInsets.symmetric(vertical: 6),
                      child: Row(
                        children: [
                          Container(
                            width: 10,
                            height: 10,
                            decoration: BoxDecoration(
                              color: entry.color,
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(child: Text(entry.label.tr)),
                          Text(
                            '${entry.count}',
                            style: theme.textTheme.bodyMedium?.copyWith(
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ],
                      ),
                    ),
                  )
                  .toList(),
            ),
          ),
        ],
      ),
    );
  }
}

class _QuickActions extends StatelessWidget {
  final ShellController shell;

  const _QuickActions({required this.shell});

  @override
  Widget build(BuildContext context) {
    final actions = <({IconData icon, String label, VoidCallback onTap})>[
      (
        icon: Icons.add_circle_rounded,
        label: 'dashboard.newInvoice'.tr,
        onTap: () => Get.toNamed(AppRoutes.invoiceForm),
      ),
      (
        icon: Icons.manage_search_rounded,
        label: 'dashboard.findInvoice'.tr,
        onTap: () => Get.toNamed(AppRoutes.findInvoice),
      ),
      (
        icon: Icons.qr_code_scanner_rounded,
        label: 'dashboard.scanBarcode'.tr,
        onTap: () => BarcodeScannerPage.show(context),
      ),
      (
        icon: Icons.inventory_2_rounded,
        label: 'dashboard.products'.tr,
        onTap: shell.goToProducts,
      ),
      (
        icon: Icons.people_rounded,
        label: 'dashboard.customers'.tr,
        onTap: shell.goToCustomers,
      ),
    ];

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: actions.length,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        mainAxisSpacing: 10,
        crossAxisSpacing: 10,
        mainAxisExtent: 94,
      ),
      itemBuilder: (_, index) => _QuickActionTile(
        icon: actions[index].icon,
        label: actions[index].label,
        onTap: actions[index].onTap,
      ),
    );
  }
}

class _QuickActionTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _QuickActionTile({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: theme.colorScheme.outlineVariant.withValues(alpha: 0.55),
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: AppColors.primarySoft,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, size: 21, color: AppColors.primary),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                label,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.labelMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _RecentInvoices extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return GetX<InvoiceController>(
      builder: (controller) {
        final recent =
            controller.invoices.where((invoice) => !invoice.isHidden).toList()
              ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
        final visible = recent.take(4).toList();
        if (visible.isEmpty) {
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: AppCard(
              onTap: () => Get.toNamed(AppRoutes.invoiceForm),
              child: Column(
                children: [
                  Icon(
                    Icons.receipt_long_outlined,
                    size: 36,
                    color: Theme.of(context).colorScheme.outline,
                  ),
                  const SizedBox(height: 10),
                  Text('dashboard.noInvoicesYet'.tr),
                  const SizedBox(height: 4),
                  Text(
                    'dashboard.noInvoicesMessage'.tr,
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
          );
        }
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Column(
            children: [
              for (var i = 0; i < visible.length; i++) ...[
                InvoiceCard(invoice: visible[i], dense: true),
                if (i < visible.length - 1) const SizedBox(height: 10),
              ],
            ],
          ),
        );
      },
    );
  }
}

class _RecentActivity extends StatelessWidget {
  const _RecentActivity();

  @override
  Widget build(BuildContext context) {
    return GetX<InvoiceController>(
      builder: (controller) {
        final invoices =
            controller.invoices.where((invoice) => !invoice.isHidden).toList()
              ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
        final activities = invoices.take(4).toList();
        if (activities.isEmpty) {
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: AppCard(
              padding: const EdgeInsets.all(18),
              child: Text(
                'empty.noData'.tr,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
            ),
          );
        }

        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: AppCard(
            padding: EdgeInsets.zero,
            child: Column(
              children: [
                for (var index = 0; index < activities.length; index++) ...[
                  _ActivityRow(invoice: activities[index]),
                  if (index < activities.length - 1) const Divider(height: 1),
                ],
              ],
            ),
          ),
        );
      },
    );
  }
}

class _ActivityRow extends StatelessWidget {
  final Invoice invoice;

  const _ActivityRow({required this.invoice});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final (icon, color) = switch (invoice.status) {
      InvoiceStatus.draft => (Icons.schedule_rounded, AppColors.draft),
      InvoiceStatus.approved => (
        Icons.check_circle_rounded,
        AppColors.approved,
      ),
      InvoiceStatus.cancelled => (Icons.cancel_rounded, AppColors.cancelled),
    };

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
      child: Row(
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, size: 17, color: color),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${invoice.status.translationKey.tr} · ${invoice.invoiceNumber}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  invoice.customer.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Text(
            Formatters.date(invoice.createdAt),
            style: theme.textTheme.labelSmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}
