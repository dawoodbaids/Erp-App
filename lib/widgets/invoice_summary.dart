import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../core/utils/formatters.dart';
import 'ui/app_card.dart';

class InvoiceSummary extends StatelessWidget {
  final double subtotal;
  final double discount;
  final double tax;
  final double taxRate;
  final double total;
  final String currencyCode;

  const InvoiceSummary({
    super.key,
    required this.subtotal,
    this.discount = 0,
    required this.tax,
    this.taxRate = 0,
    required this.total,
    required this.currencyCode,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final textTheme = theme.textTheme;

    return AppCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          _SummaryRow(
            label: 'details.subtotal'.tr,
            value: '$currencyCode ${Formatters.amount(subtotal)}',
          ),
          if (discount > 0) ...[
            const SizedBox(height: 8),
            _SummaryRow(
              label: 'details.discount'.tr,
              value: '-$currencyCode ${Formatters.amount(discount)}',
            ),
          ],
          const SizedBox(height: 8),
          _SummaryRow(
            label: taxRate > 0
                ? '${'details.tax'.tr} (${Formatters.rate(taxRate)}%)'
                : 'details.tax'.tr,
            value: '$currencyCode ${Formatters.amount(tax)}',
          ),
          const Divider(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'details.total'.tr,
                style: textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
              ),
              Text(
                '$currencyCode ${Formatters.amount(total)}',
                style: textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w900,
                  color: theme.colorScheme.primary,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _SummaryRow extends StatelessWidget {
  final String label;
  final String value;

  const _SummaryRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: theme.textTheme.bodyMedium?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
        Text(
          value,
          style: theme.textTheme.bodyMedium?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}
