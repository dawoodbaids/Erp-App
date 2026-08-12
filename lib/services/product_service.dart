import '../core/network/api_client.dart';
import '../core/network/api_config.dart';
import '../models/product.dart';

class ProductService {
  Future<List<Product>> getProducts() async {
    final data = await ApiClient.getData(ApiConfig.productsPath);
    return (data as List)
        .map((e) => Product.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<Product> getProductByBarcode(String barcode) async {
    final data = await ApiClient.getData(
      '${ApiConfig.productsPath}/barcode/$barcode',
    );
    return Product.fromJson(data as Map<String, dynamic>);
  }

  Future<Product> createProduct(Product draft) async {
    final data = await ApiClient.postData(
      ApiConfig.productsPath,
      data: draft.toCreateRequest(),
    );
    return Product.fromJson(data as Map<String, dynamic>);
  }

  Future<Product> updateProduct(Product product) async {
    final data = await ApiClient.putData(
      '${ApiConfig.productsPath}/${product.id}',
      data: product.toCreateRequest(),
    );
    return Product.fromJson(data as Map<String, dynamic>);
  }

  Future<String?> uploadImage(String id, String filePath) async {
    final data = await ApiClient.postMultipart(
      '${ApiConfig.productsPath}/$id/image',
      fileField: 'image',
      filePath: filePath,
    );
    if (data is Map && data['imageUrl'] is String) {
      return data['imageUrl'] as String;
    }
    if (data is Map<String, dynamic>) {
      return Product.fromJson(data).image;
    }
    return null;
  }
}
