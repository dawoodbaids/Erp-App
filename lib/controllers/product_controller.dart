import 'package:get/get.dart';

import '../core/network/api_client.dart';
import '../models/product.dart';
import '../services/product_service.dart';

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

  /// Persists a new product on the backend and prepends it to the list.
  /// Returns an error message, or null on success. On success the returned
  /// value is the freshly created product (including its backend id).
  Future<ProductResult> createProduct(Product draft) async {
    try {
      final created = await _productService.createProduct(draft);
      products.insert(0, created);
      return ProductResult(created);
    } on ApiException catch (e) {
      return ProductResult(null, e.message);
    } catch (_) {
      return ProductResult(null, 'Could not create the product. Please try again.');
    }
  }

  /// Persists product edits on the backend and updates the list.
  Future<ProductResult> updateProduct(Product product) async {
    try {
      final updated = await _productService.updateProduct(product);
      final index = products.indexWhere((p) => p.id == product.id);
      if (index >= 0) {
        products[index] = updated;
      } else {
        products.insert(0, updated);
      }
      return ProductResult(updated);
    } on ApiException catch (e) {
      return ProductResult(null, e.message);
    } catch (_) {
      return ProductResult(null, 'Could not save the product. Please try again.');
    }
  }

  /// Uploads a local image for the product and updates its [Product.image].
  /// Returns an error message, or null on success.
  Future<String?> uploadImage(String id, String filePath) async {
    try {
      final imageUrl = await _productService.uploadImage(id, filePath);
      if (imageUrl == null) return null;
      final index = products.indexWhere((p) => p.id == id);
      if (index >= 0) {
        products[index] = products[index].copyWith(image: imageUrl);
      }
      return null;
    } on ApiException catch (e) {
      return e.message;
    } catch (_) {
      return 'Could not upload the image. Please try again.';
    }
  }

  @override
  Future<void> refresh() async {
    _isLoading.value = true;
    _errorMessage.value = null;
    try {
      products.value = await _productService.getProducts();
    } on ApiException catch (e) {
      _errorMessage.value = e.message;
    } catch (_) {
      _errorMessage.value = 'Could not load products. Please try again.';
    } finally {
      _isLoading.value = false;
    }
  }
}
