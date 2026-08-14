import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../controllers/product_controller.dart';
import '../../core/routes/app_routes.dart';
import '../../models/product.dart';
import '../../widgets/product_form_dialog.dart';
import '../../widgets/ui/app_appbar.dart';
import '../../widgets/ui/app_loading.dart';
import '../../widgets/ui/app_search_field.dart';
import '../../widgets/ui/app_states.dart';
import '../../widgets/ui/collection_summary.dart';
import '../../widgets/ui/product_card.dart';

class ProductsScreen extends StatefulWidget {
  const ProductsScreen({super.key});

  @override
  State<ProductsScreen> createState() => _ProductsScreenState();
}

class _ProductsScreenState extends State<ProductsScreen> {
  final _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _openForm({Product? product}) async {
    await ProductFormDialog.show(context, product: product);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppAppBar(
        title: 'products.title'.tr,
        subtitle: 'products.subtitle'.tr,
        showBack: false,
        bottom: AppSearchField(
          controller: _searchController,
          hint: 'products.searchHint'.tr,
          onChanged: (value) =>
              Get.find<ProductController>().setSearchQuery(value),
          onClear: () {
            _searchController.clear();
            Get.find<ProductController>().clearSearch();
          },
        ),
      ),
      body: GetX<ProductController>(
        builder: (controller) {
          if (controller.errorMessage != null &&
              controller.products.isEmpty) {
            return AppErrorState(
              title: 'products.errorTitle'.tr,
              message: controller.errorMessage!,
              onRetry: controller.refresh,
            );
          }

          if (controller.isLoading && controller.products.isEmpty) {
            return const AppListSkeleton();
          }

          final products = controller.filteredProducts;

          if (products.isEmpty) {
            return AppEmptyState(
              icon: Icons.inventory_2_outlined,
              title: controller.searchQuery.trim().isEmpty
                  ? 'products.emptyTitle'.tr
                  : 'products.emptySearchTitle'.tr,
              message: controller.searchQuery.trim().isEmpty
                  ? 'products.emptyMessage'.tr
                  : 'products.emptySearchMessage'.tr,
              actionLabel: 'products.add'.tr,
              onAction: () => _openForm(),
            );
          }

          return RefreshIndicator(
            onRefresh: controller.refresh,
            child: ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 96),
              children: [
                CollectionSummary(
                  icon: Icons.inventory_2_outlined,
                  label: 'dashboard.products'.tr,
                  count: products.length,
                ),
                const SizedBox(height: 12),
                for (var i = 0; i < products.length; i++) ...[
                  ProductCard(
                    product: products[i],
                    onTap: () => Get.toNamed(
                      AppRoutes.productDetails,
                      arguments: products[i].id,
                    ),
                    onEdit: () => _openForm(product: products[i]),
                  ),
                  if (i < products.length - 1) const SizedBox(height: 10),
                ],
              ],
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        heroTag: 'products-add-product',
        onPressed: () => _openForm(),
        icon: const Icon(Icons.add),
        label: Text('products.add'.tr),
      ),
    );
  }
}
