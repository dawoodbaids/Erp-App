import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../controllers/auth_controller.dart';
import '../../controllers/dashboard_controller.dart';
import '../../controllers/invoice_controller.dart';
import '../../controllers/product_controller.dart';
import '../../controllers/settings_controller.dart';
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
import '../../widgets/ui/wave_decoration.dart';
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
      body: Stack(
        children: [
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: IgnorePointer(
              child: WaveAccent(
                height: 250,
                color: Theme.of(context).colorScheme.primary.withValues(
                  alpha: Theme.of(context).brightness == Brightness.dark
                      ? 0.07
                      : 0.1,
                ),
              ),
            ),
          ),
          GetX<DashboardController>(
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
                    SafeArea(
                      bottom: false,
                      child: AppPageHeader(
                        title: 'dashboard.overview'.tr,
                        subtitle: _greetingText(name),
                        subtitleStyle: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(
                              fontWeight: FontWeight.w700,
                              color: Theme.of(
                                context,
                              ).colorScheme.onSurfaceVariant,
                            ),
                        padding: const EdgeInsets.fromLTRB(20, 12, 20, 12),
                        actions: [
                          Padding(
                            padding: const EdgeInsets.only(left: 4),
                            child: InitialsAvatar(name: name, size: 40),
                          ),
                        ],
                      ),
                    ),
                    _SalesHero(summary: summary),
                    const SizedBox(height: 14),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: _SummaryGrid(summary: summary),
                    ),
                    const SizedBox(height: 22),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: AppSectionHeader(
                        title: 'dashboard.topProducts'.tr,
                        actionLabel: 'dashboard.viewAll'.tr,
                        onAction: shell.goToProducts,
                      ),
                    ),
                    const SizedBox(height: 4),
                    const _TopProducts(),
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
                      child: AppSectionHeader(
                        title: 'dashboard.invoiceStatus'.tr,
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                      child: _StatusCard(status: status),
                    ),
                    const SizedBox(height: 22),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: AppSectionHeader(
                        title: 'dashboard.quickActions'.tr,
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: _QuickActions(shell: shell),
                    ),
                    const SizedBox(height: 22),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: AppSectionHeader(
                        title: 'dashboard.recentActivity'.tr,
                      ),
                    ),
                    const SizedBox(height: 4),
                    const _RecentActivity(),
                  ],
                ),
              );
            },
          ),
        ],
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

    return ClipPath(
      clipper: WaveClipper(),
      child: Container(
        padding: const EdgeInsets.fromLTRB(20, 24, 20, 48),
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
        child: Stack(
          children: [
            Positioned(
              right: -34,
              top: -38,
              child: _GlowCircle(
                size: 150,
                color: Colors.white.withValues(alpha: isDark ? 0.05 : 0.09),
              ),
            ),
            Positioned(
              right: 26,
              bottom: -42,
              child: _GlowCircle(
                size: 110,
                color: AppColors.cyan.withValues(alpha: isDark ? 0.16 : 0.2),
              ),
            ),
            Column(
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
                        border: Border.all(
                          color: AppColors.onPrimary.withValues(alpha: 0.25),
                        ),
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
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 5,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.onPrimary.withValues(alpha: 0.14),
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Text(
                        '${summary.approvedInvoices} ${'dashboard.approved'.tr}',
                        style: const TextStyle(
                          color: AppColors.onPrimary,
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                Obx(() {
                  final code =
                      Get.find<SettingsController>().defaultCurrency?.code ??
                      '';
                  return Text(
                    '${Formatters.amount(summary.totalSales)} $code',
                    style: theme.textTheme.headlineMedium?.copyWith(
                      color: AppColors.onPrimary,
                      fontWeight: FontWeight.w900,
                      letterSpacing: -0.5,
                    ),
                  );
                }),
                const SizedBox(height: 8),
                Text(
                  'dashboard.subtitle'.tr,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: AppColors.onPrimary.withValues(alpha: 0.8),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _GlowCircle extends StatelessWidget {
  final double size;
  final Color color;

  const _GlowCircle({required this.size, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: color,
        border: Border.all(color: color.withValues(alpha: 0.4)),
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
        feature: _FeatureKind.invoices,
        color: AppColors.primary,
        background: AppColors.primarySoft,
      ),
      (
        label: 'dashboard.customers',
        icon: Icons.people_rounded,
        feature: _FeatureKind.customers,
        color: AppColors.primary,
        background: AppColors.primarySoft,
      ),
      (
        label: 'dashboard.products',
        icon: Icons.inventory_2_rounded,
        feature: _FeatureKind.products,
        color: AppColors.primary,
        background: AppColors.primarySoft,
      ),
      (
        label: 'dashboard.draft',
        icon: Icons.schedule_rounded,
        feature: _FeatureKind.draft,
        color: AppColors.draft,
        background: AppColors.draftSoft,
      ),
      (
        label: 'dashboard.approved',
        icon: Icons.check_circle_rounded,
        feature: _FeatureKind.approved,
        color: AppColors.approved,
        background: AppColors.approvedSoft,
      ),
      (
        label: 'dashboard.cancelled',
        icon: Icons.cancel_rounded,
        feature: _FeatureKind.cancelled,
        color: AppColors.cancelled,
        background: AppColors.cancelledSoft,
      ),
    ];
    final values = [
      summary.totalInvoices.toString(),
      summary.totalCustomers.toString(),
      summary.totalProducts.toString(),
      summary.pendingDrafts.toString(),
      summary.approvedInvoices.toString(),
      summary.cancelledInvoices.toString(),
    ];

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: cards.length,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        mainAxisSpacing: 10,
        crossAxisSpacing: 10,
        mainAxisExtent: 132,
      ),
      itemBuilder: (_, index) {
        final card = cards[index];
        return StatCard(
          label: card.label.tr,
          value: values[index],
          icon: card.icon,
          color: card.color,
          background: card.background,
          feature: _FeatureArt(kind: card.feature, color: card.color),
        );
      },
    );
  }
}

/// Distinct icon-free motif that visualises what each stat card represents.
enum _FeatureKind { invoices, customers, products, draft, approved, cancelled }

class _FeatureArt extends StatelessWidget {
  final _FeatureKind kind;
  final Color color;

  const _FeatureArt({required this.kind, required this.color});

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: const Size(28, 28),
      painter: _FeaturePainter(kind: kind, color: color),
    );
  }
}

class _FeaturePainter extends CustomPainter {
  final _FeatureKind kind;
  final Color color;

  _FeaturePainter({required this.kind, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    switch (kind) {
      case _FeatureKind.invoices:
        _paintInvoices(canvas, size);
      case _FeatureKind.customers:
        _paintCustomers(canvas, size);
      case _FeatureKind.products:
        _paintProducts(canvas, size);
      case _FeatureKind.draft:
        _paintDraft(canvas, size);
      case _FeatureKind.approved:
        _paintApproved(canvas, size);
      case _FeatureKind.cancelled:
        _paintCancelled(canvas, size);
    }
  }

  void _paintInvoices(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    RRect sheet(double dx, double dy) {
      final rect = Rect.fromCenter(
        center: center.translate(dx, dy),
        width: 15,
        height: 19,
      );
      return RRect.fromRectAndCorners(
        rect,
        topLeft: const Radius.circular(2.5),
        topRight: const Radius.circular(2.5),
        bottomLeft: const Radius.circular(2.5),
        bottomRight: const Radius.circular(2.5),
      );
    }

    canvas.drawRRect(
      sheet(-3.5, -3.5),
      Paint()..color = color.withValues(alpha: 0.25),
    );
    canvas.drawRRect(
      sheet(-1.5, -1.5),
      Paint()..color = color.withValues(alpha: 0.5),
    );
    canvas.drawRRect(sheet(0.5, 0.5), Paint()..color = color);
  }

  void _paintCustomers(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final outline = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.4
      ..color = color;
    canvas.drawCircle(
      center.translate(-7, 3.5),
      6.5,
      outline..color = color.withValues(alpha: 0.3),
    );
    canvas.drawCircle(
      center.translate(7, 3.5),
      6.5,
      outline..color = color.withValues(alpha: 0.55),
    );
    canvas.drawCircle(center.translate(0, -2), 7, Paint()..color = color);
  }

  void _paintProducts(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(
          center: center.translate(0, 2.5),
          width: 17,
          height: 12,
        ),
        const Radius.circular(3),
      ),
      Paint()..color = color,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(
          center: center.translate(0, -4.5),
          width: 12,
          height: 6,
        ),
        const Radius.circular(2),
      ),
      Paint()..color = color.withValues(alpha: 0.45),
    );
  }

  void _paintDraft(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round
      ..color = color;
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: 10.5),
      -math.pi / 2,
      math.pi * 1.5,
      false,
      paint,
    );
    final hand = Paint()
      ..color = color
      ..strokeWidth = 2.5
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(center, Offset(center.dx, center.dy - 7.5), hand);
    canvas.drawLine(center, Offset(center.dx + 5.5, center.dy + 2.5), hand);
    canvas.drawCircle(center, 1.7, Paint()..color = color);
  }

  void _paintApproved(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    canvas.drawCircle(
      center,
      11,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3
        ..color = color,
    );
    final check = Path()
      ..moveTo(center.dx - 5, center.dy - 0.5)
      ..lineTo(center.dx - 1.5, center.dy + 3.5)
      ..lineTo(center.dx + 5.5, center.dy - 4);
    canvas.drawPath(
      check,
      Paint()
        ..color = color
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round,
    );
  }

  void _paintCancelled(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    canvas.drawCircle(
      center,
      11,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3
        ..color = color,
    );
    canvas.drawLine(
      center.translate(-6.5, -6.5),
      center.translate(6.5, 6.5),
      Paint()
        ..color = color
        ..strokeWidth = 3
        ..strokeCap = StrokeCap.round,
    );
  }

  @override
  bool shouldRepaint(covariant _FeaturePainter oldDelegate) =>
      oldDelegate.kind != kind || oldDelegate.color != color;
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
      borderRadius: BorderRadius.circular(18),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              theme.colorScheme.surface,
              theme.colorScheme.primary.withValues(alpha: 0.035),
            ],
          ),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: theme.colorScheme.outlineVariant.withValues(alpha: 0.5),
          ),
          boxShadow: [
            BoxShadow(
              color: theme.shadowColor.withValues(alpha: 0.07),
              blurRadius: 10,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [Color(0xFF00BCD4), Color(0xFF1565C0)],
                ),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, size: 21, color: Colors.white),
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

class _TopProducts extends StatelessWidget {
  const _TopProducts();

  @override
  Widget build(BuildContext context) {
    return GetX<InvoiceController>(
      builder: (invoiceController) {
        final productController = Get.find<ProductController>();
        final totals = <String, double>{};
        final names = <String, String>{};
        for (final invoice in invoiceController.invoices) {
          if (invoice.isHidden || invoice.status != InvoiceStatus.approved) {
            continue;
          }
          for (final item in invoice.items) {
            final product = productController.byId(item.productId);
            final key = item.productId.isNotEmpty
                ? item.productId
                : item.productName;
            if (key.isEmpty) continue;
            totals[key] = (totals[key] ?? 0) + item.quantity;
            names[key] = product?.name ?? item.productName;
          }
        }
        final ranked = totals.entries.toList()
          ..sort((a, b) => b.value.compareTo(a.value));
        final top = ranked.take(3).toList();
        if (top.isEmpty) {
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: AppCard(
              child: Text(
                'dashboard.noProductSales'.tr,
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
                for (var i = 0; i < top.length; i++) ...[
                  _ProductRankRow(
                    rank: i + 1,
                    name: names[top[i].key] ?? 'Unknown product',
                    quantity: top[i].value,
                    maxQuantity: top.first.value,
                  ),
                  if (i < top.length - 1) const Divider(height: 1, indent: 72),
                ],
              ],
            ),
          ),
        );
      },
    );
  }
}

class _ProductRankRow extends StatelessWidget {
  final int rank;
  final String name;
  final double quantity;
  final double maxQuantity;

  const _ProductRankRow({
    required this.rank,
    required this.name,
    required this.quantity,
    required this.maxQuantity,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final progress = maxQuantity <= 0
        ? 0.0
        : (quantity / maxQuantity).clamp(0.0, 1.0);

    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
      child: Row(
        children: [
          Container(
            width: 34,
            height: 34,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: rank == 1
                  ? null
                  : theme.colorScheme.primary.withValues(alpha: 0.1),
              gradient: rank == 1
                  ? const LinearGradient(
                      colors: [Color(0xFF00BCD4), Color(0xFF1565C0)],
                    )
                  : null,
              borderRadius: BorderRadius.circular(11),
            ),
            child: Text(
              '$rank',
              style: TextStyle(
                color: rank == 1 ? Colors.white : theme.colorScheme.primary,
                fontWeight: FontWeight.w900,
                fontSize: 14,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      Formatters.quantity(quantity),
                      style: theme.textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w900,
                        color: theme.colorScheme.primary,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                ClipRRect(
                  borderRadius: BorderRadius.circular(999),
                  child: SizedBox(
                    height: 5,
                    child: Stack(
                      children: [
                        Container(
                          width: double.infinity,
                          color: theme.colorScheme.primary.withValues(
                            alpha: 0.12,
                          ),
                        ),
                        FractionallySizedBox(
                          widthFactor: progress,
                          child: Container(
                            decoration: const BoxDecoration(
                              gradient: LinearGradient(
                                colors: [Color(0xFF00BCD4), Color(0xFF1565C0)],
                              ),
                              borderRadius: BorderRadius.all(
                                Radius.circular(999),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
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
                  '${invoice.status.translationKey.tr} ┬╖ ${invoice.displayNumber}',
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
