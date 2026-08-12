import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../controllers/product_controller.dart';
import '../../controllers/settings_controller.dart';
import '../../core/utils/formatters.dart';
import '../../core/utils/product_image.dart';
import '../../models/product.dart';
import '../../widgets/product_form_dialog.dart';
import '../../widgets/ui/app_appbar.dart';
import '../../widgets/ui/app_card.dart';
import '../../widgets/ui/app_info.dart';
import '../../widgets/ui/app_states.dart';

class ProductDetailsScreen extends StatelessWidget {
  const ProductDetailsScreen({super.key});

  String get _productId => Get.arguments as String;

  Future<void> _edit(BuildContext context, Product product) async {
    await ProductFormDialog.show(context, product: product);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppAppBar(
        title: 'products.detailsTitle'.tr,
        actions: [
          GetX<ProductController>(
            builder: (controller) {
              final product = controller.byId(_productId);
              if (product == null) return const SizedBox.shrink();
              return IconButton(
                tooltip: 'common.edit'.tr,
                onPressed: () => _edit(context, product),
                icon: const Icon(Icons.edit_outlined),
              );
            },
          ),
        ],
      ),
      body: GetX<ProductController>(
        builder: (controller) {
          final product = controller.byId(_productId);
          if (product == null) {
            return AppErrorState(
              title: 'products.errorTitle'.tr,
              message: 'products.emptySearchMessage'.tr,
              onRetry: controller.refresh,
            );
          }

          final settings = Get.find<SettingsController>();
          final currency = settings.currencyById(product.currencyId);

          return ListView(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
            children: [
              _HeroCard(product: product),
              const SizedBox(height: 24),
              AppCard(
                child: Column(
                  children: [
                    AppInfoRow(
                      label: 'products.barcodeLabel'.tr,
                      value: product.barcode,
                      icon: Icons.qr_code_rounded,
                    ),
                    AppInfoRow(
                      label: 'products.priceLabel'.tr,
                      value: Formatters.amountWithCurrency(
                        currency,
                        product.price,
                      ),
                      icon: Icons.attach_money_rounded,
                      emphasize: true,
                    ),
                    AppInfoRow(
                      label: 'products.tax'.tr,
                      value: '${Formatters.rate(product.taxRate)}%',
                      icon: Icons.percent_rounded,
                    ),
                    AppInfoRow(
                      label: 'products.currency'.tr,
                      value: currency.code,
                      icon: Icons.currency_exchange_rounded,
                    ),
                    AppInfoRow(
                      label: 'products.status'.tr,
                      value: product.isActive
                          ? 'products.active'.tr
                          : 'products.inactive'.tr,
                      icon: Icons.circle_rounded,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              SizedBox(
                height: 52,
                child: FilledButton.icon(
                  onPressed: () => _edit(context, product),
                  icon: const Icon(Icons.edit_outlined),
                  label: Text('common.edit'.tr),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _HeroCard extends StatelessWidget {
  final Product product;

  const _HeroCard({required this.product});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return AppCard(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          buildProductImage(product.image, size: 120, context: context),
          const SizedBox(height: 16),
          Text(
            product.name,
            textAlign: TextAlign.center,
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            product.barcode,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}
