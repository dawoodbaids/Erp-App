import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../controllers/settings_controller.dart';
import '../../core/theme/app_radius.dart';
import '../../core/utils/formatters.dart';
import '../../core/utils/product_image.dart';
import '../../models/product.dart';

/// Premium product list card with image, barcode, price and status.
class ProductCard extends StatelessWidget {
  final Product product;
  final VoidCallback onTap;
  final VoidCallback onEdit;

  const ProductCard({
    super.key,
    required this.product,
    required this.onTap,
    required this.onEdit,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final settings = Get.find<SettingsController>();
    final currency = settings.currencyById(product.currencyId);

    return Material(
      color: theme.colorScheme.surface,
      borderRadius: AppRadius.card,
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            borderRadius: AppRadius.card,
            border: Border.all(
              color: theme.colorScheme.outlineVariant.withValues(alpha: 0.5),
            ),
          ),
          child: Row(
            children: [
              buildProductImage(product.image, size: 58, context: context),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      product.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      '${'products.barcodeLabel'.tr}: ${product.barcode}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 4,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        Text(
                           Formatters.amountWithCurrency(currency, product.price),
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.primary,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        _chip(
                          context,
                          label: '${Formatters.rate(product.taxRate)}%',
                          foreground: theme.colorScheme.onSurfaceVariant,
                          background: theme.colorScheme.surfaceContainerHigh
                              .withValues(alpha: 0.7),
                        ),
                        if (!product.isActive)
                          _chip(
                            context,
                            label: 'products.inactive'.tr,
                            foreground: theme.colorScheme.error,
                            background: theme.colorScheme.error.withValues(
                              alpha: 0.1,
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 6),
              IconButton(
                tooltip: 'common.edit'.tr,
                onPressed: onEdit,
                icon: Icon(
                  Icons.edit_outlined,
                  size: 19,
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _chip(
    BuildContext context, {
    required String label,
    required Color foreground,
    required Color background,
  }) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: background,
        borderRadius: AppRadius.pillRadius,
      ),
      child: Text(
        label,
        style: theme.textTheme.labelSmall?.copyWith(
          color: foreground,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
