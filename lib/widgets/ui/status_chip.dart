import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_radius.dart';
import '../../models/invoice.dart';

/// Modern status pill used on invoice cards, badges and summaries.
class StatusChip extends StatelessWidget {
  final InvoiceStatus status;
  final bool showIcon;

  const StatusChip({super.key, required this.status, this.showIcon = true});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    late final Color background;
    late final Color foreground;
    IconData icon;

    switch (status) {
      case InvoiceStatus.draft:
        icon = Icons.schedule_rounded;
        background = isDark ? AppColors.draftSoftDark : AppColors.draftSoft;
        foreground = isDark ? AppColors.draftDark : AppColors.draft;
      case InvoiceStatus.approved:
        icon = Icons.check_circle_rounded;
        background = isDark
            ? AppColors.approvedSoftDark
            : AppColors.approvedSoft;
        foreground = isDark ? AppColors.approvedDark : AppColors.approved;
      case InvoiceStatus.cancelled:
        icon = Icons.cancel_rounded;
        background = isDark
            ? AppColors.cancelledSoftDark
            : AppColors.cancelledSoft;
        foreground = isDark ? AppColors.cancelledDark : AppColors.cancelled;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: background,
        borderRadius: AppRadius.pillRadius,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (showIcon) ...[
            Icon(icon, size: 13, color: foreground),
            const SizedBox(width: 5),
          ],
          Text(
            status.translationKey.tr,
            style: TextStyle(
              color: foreground,
              fontSize: 12,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.1,
            ),
          ),
        ],
      ),
    );
  }
}
