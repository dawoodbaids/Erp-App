import 'package:get/get.dart';

import '../models/product.dart';
import '../services/firebase_service_exception.dart';
import '../services/product_service.dart';
import 'dashboard_controller.dart';

/// Result of a product create/update. [product] is set on success,
/// [error] carries a user-facing message on failure.
class ProductResult {
  final Product? product;
  final String? error;

  const ProductResult(this.product, [this.error]);

  bool get isSuccess => product != null && error == null;
}

class ProductController extends GetxController {
  final products = <Product>[].obs;
  final _searchQuery = ''.obs;
  final _isLoading = false.obs;
  final _errorMessage = Rxn<String>();

  final _productService = ProductService();

  String get searchQuery => _searchQuery.value;
  bool get isLoading => _isLoading.value;
  String? get errorMessage => _errorMessage.value;

  List<Product> get filteredProducts {
    final query = _searchQuery.value.trim().toLowerCase();
    if (query.isEmpty) return products;
    return products.where((p) {
      return p.name.toLowerCase().contains(query) ||
          p.barcode.toLowerCase().contains(query);
    }).toList();
  }

  void setSearchQuery(String value) => _searchQuery.value = value;

  void clearSearch() => _searchQuery.value = '';

  Product? findByBarcode(String barcode) {
    final normalized = barcode.trim();
    for (final product in products) {
      if (product.barcode == normalized) return product;
    }
    return null;
  }

  Product? byId(String id) {
    for (final product in products) {
      if (product.id == id) return product;
    }
    return null;
  }

  /// Creates a product in Firestore and updates the visible list.
  Future<ProductResult> createProduct(Product draft) async {
    try {
      final created = await _productService.createProduct(draft);
      products.insert(0, created);
      await _refreshDashboard();
      return ProductResult(created);
    } on FirebaseServiceException catch (e) {
      return ProductResult(null, e.message);
    } catch (_) {
      return ProductResult(
        null,
        'Could not create the product. Please try again.',
      );
    }
  }

  /// Updates the Firestore product and the visible list.
  Future<ProductResult> updateProduct(Product product) async {
    try {
      final updated = await _productService.updateProduct(product);
      final index = products.indexWhere((p) => p.id == product.id);
      if (index >= 0) {
        products[index] = updated;
      } else {
        products.insert(0, updated);
      }
      await _refreshDashboard();
      return ProductResult(updated);
    } on FirebaseServiceException catch (e) {
      return ProductResult(null, e.message);
    } catch (_) {
      return ProductResult(
        null,
        'Could not save the product. Please try again.',
      );
    }
  }

  Future<String?> deleteProduct(String id) async {
    try {
      await _productService.deleteProduct(id);
      products.removeWhere((product) => product.id == id);
      await _refreshDashboard();
      return null;
    } on FirebaseServiceException catch (e) {
      return e.message;
    } catch (_) {
      return 'Could not delete the product. Please try again.';
    }
  }

  Future<Product?> loadDetails(String id) async {
    if (isLoading) return byId(id);
    _isLoading.value = true;
    _errorMessage.value = null;
    try {
      final product = await _productService.getProduct(id);
      final index = products.indexWhere((item) => item.id == id);
      if (index >= 0) {
        products[index] = product;
      } else {
        products.insert(0, product);
      }
      return product;
    } on FirebaseServiceException catch (e) {
      _errorMessage.value = e.message;
      return byId(id);
    } catch (_) {
      _errorMessage.value = 'Could not load the product. Please try again.';
      return byId(id);
    } finally {
      _isLoading.value = false;
    }
  }

  Future<void> _refreshDashboard() async {
    if (Get.isRegistered<DashboardController>()) {
      await Get.find<DashboardController>().refresh();
    }
  }

  @override
  Future<void> refresh() async {
    _isLoading.value = true;
    _errorMessage.value = null;
    try {
      products.value = await _productService.getProducts();
    } on FirebaseServiceException catch (e) {
      _errorMessage.value = e.message;
    } catch (_) {
      _errorMessage.value = 'Could not load products. Please try again.';
    } finally {
      _isLoading.value = false;
    }
  }
}
