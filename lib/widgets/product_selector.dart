import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../controllers/product_controller.dart';
import '../controllers/settings_controller.dart';
import '../core/utils/formatters.dart';
import '../core/utils/product_image.dart';
import '../models/product.dart';
import 'ui/app_card.dart';
import 'ui/app_states.dart';

class ProductSelector {
  static Future<Product?> show(BuildContext context) {
    return showModalBottomSheet<Product>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      showDragHandle: true,
      builder: (context) => const _ProductSelectorSheet(),
    );
  }
}

class _ProductSelectorSheet extends StatelessWidget {
  const _ProductSelectorSheet();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final settings = Get.find<SettingsController>();
    final height = MediaQuery.sizeOf(context).height;

    return SizedBox(
      height: height * 0.85,
      child: GetX<ProductController>(
        builder: (controller) {
          final products = controller.filteredProducts;

          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                child: Text(
                  'productSelector.title'.tr,
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: TextField(
                  autofocus: false,
                  onChanged: controller.setSearchQuery,
                  decoration: InputDecoration(
                    hintText: 'productSelector.searchHint'.tr,
                    prefixIcon: const Icon(Icons.search),
                    isDense: true,
                    suffixIcon: controller.searchQuery.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear),
                            onPressed: controller.clearSearch,
                          )
                        : null,
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Expanded(
                child: products.isEmpty
                    ? AppEmptyState(
                        icon: Icons.search_off,
                        title: 'productSelector.empty'.tr,
                        message: '',
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
                        itemCount: products.length,
                        itemBuilder: (context, index) {
                          final product = products[index];
                          final currency = settings.currencyById(
                            product.currencyId,
                          );
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 8),
                            child: AppCard(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 10,
                              ),
                              onTap: () => Navigator.of(context).pop(product),
                              child: Row(
                                children: [
                                  buildProductImage(
                                    product.image,
                                    size: 44,
                                    context: context,
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          product.name,
                                          style: theme.textTheme.bodyLarge
                                              ?.copyWith(
                                                fontWeight: FontWeight.w600,
                                              ),
                                        ),
                                        const SizedBox(height: 2),
                                        Text(
                                          '${product.barcode} · '
                                          '${Formatters.amountWithCurrency(currency, product.price)}'
                                          ' · ${Formatters.rate(product.taxRate)}%',
                                          style: theme.textTheme.bodySmall
                                              ?.copyWith(
                                                color: theme
                                                    .colorScheme
                                                    .onSurfaceVariant,
                                              ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  Icon(
                                    Icons.add_circle_outline,
                                    color: theme.colorScheme.primary,
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
              ),
            ],
          );
        },
      ),
    );
  }
}
