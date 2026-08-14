import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../core/routes/app_routes.dart';
import '../../core/theme/app_radius.dart';
import '../../core/utils/formatters.dart';
import '../../models/invoice.dart';
import 'initials_avatar.dart';
import 'status_chip.dart';

/// Premium invoice list card used on the dashboard and invoices tab.
///
/// Displays invoice number, name, customer, date, total and status in a
/// balanced two-line layout that scales to narrow screens.
class InvoiceCard extends StatelessWidget {
  final Invoice invoice;
  final bool dense;

  const InvoiceCard({super.key, required this.invoice, this.dense = false});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final title =
        invoice.invoiceName.isEmpty ||
            invoice.invoiceName == invoice.displayNumber
        ? 'common.salesInvoice'.tr
        : invoice.invoiceName;

    return Material(
      color: theme.colorScheme.surface,
      borderRadius: AppRadius.card,
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () =>
            Get.toNamed(AppRoutes.invoiceDetails, arguments: invoice.id),
        child: Container(
          padding: EdgeInsets.symmetric(
            horizontal: dense ? 12 : 14,
            vertical: dense ? 11 : 13,
          ),
          decoration: BoxDecoration(
            borderRadius: AppRadius.card,
            border: Border.all(
              color: theme.colorScheme.outlineVariant.withValues(alpha: 0.5),
            ),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              InitialsAvatar(
                name: invoice.customer.name,
                size: dense ? 38 : 44,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      invoice.displayNumber,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      '${invoice.customer.name} · '
                      '${Formatters.date(invoice.createdAt)}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    '${invoice.currency.code} ${Formatters.amount(invoice.totalAmount)}',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w800,
                      color: theme.colorScheme.primary,
                    ),
                  ),
                  const SizedBox(height: 6),
                  StatusChip(status: invoice.status),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
