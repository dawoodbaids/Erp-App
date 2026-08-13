import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/product.dart';
import 'firebase_service_exception.dart';

class ProductService {
  FirebaseFirestore get _db => FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> get _products =>
      _db.collection('products');

  Future<List<Product>> getProducts() {
    return runFirebase(() async {
      final snapshot = await _products.get();
      final products = snapshot.docs
          .map((doc) => Product.fromFirestore(doc.id, doc.data()))
          .toList();
      return products;
    }, 'Could not load products. Please try again.');
  }

  Future<Product> getProduct(String id) {
    return runFirebase(() async {
      final snapshot = await _products.doc(id).get();
      if (!snapshot.exists || snapshot.data() == null) {
        throw const FirebaseServiceException(
          'The product was not found.',
          code: 'not-found',
        );
      }
      return Product.fromFirestore(snapshot.id, snapshot.data()!);
    }, 'Could not load the product. Please try again.');
  }

  Future<Product> getProductByBarcode(String barcode) {
    return runFirebase(() async {
      final snapshot = await _products
          .where('barcode', isEqualTo: barcode)
          .limit(1)
          .get();
      if (snapshot.docs.isEmpty) {
        throw const FirebaseServiceException(
          'No product found with that barcode.',
          code: 'not-found',
        );
      }
      final doc = snapshot.docs.first;
      return Product.fromFirestore(doc.id, doc.data());
    }, 'Could not look up the barcode. Please try again.');
  }

  Future<Product> createProduct(Product draft) {
    return runFirebase(() async {
      await _ensureBarcodeAvailable(draft.barcode);
      final reference = _products.doc();
      await reference.set({
        ...draft.toFirestore(),
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });
      return Product.fromFirestore(reference.id, {
        ...draft.toFirestore(),
        'isActive': draft.isActive,
      });
    }, 'Could not create the product. Please try again.');
  }

  Future<Product> updateProduct(Product product) {
    return runFirebase(() async {
      await _ensureBarcodeAvailable(product.barcode, excludingId: product.id);
      final reference = _products.doc(product.id);
      final snapshot = await reference.get();
      if (!snapshot.exists || snapshot.data() == null) {
        throw const FirebaseServiceException(
          'The product was not found.',
          code: 'not-found',
        );
      }
      await reference.update({
        ...product.toFirestore(),
        'updatedAt': FieldValue.serverTimestamp(),
      });
      return product;
    }, 'Could not save the product. Please try again.');
  }

  Future<void> deleteProduct(String id) {
    return runFirebase(() async {
      final reference = _products.doc(id);
      final snapshot = await reference.get();
      if (!snapshot.exists || snapshot.data() == null) {
        throw const FirebaseServiceException(
          'The product was not found.',
          code: 'not-found',
        );
      }
      await reference.delete();
    }, 'Could not delete the product. Please try again.');
  }

  Future<void> _ensureBarcodeAvailable(
    String barcode, {
    String? excludingId,
  }) async {
    final snapshot = await _products
        .where('barcode', isEqualTo: barcode)
        .limit(1)
        .get();
    if (snapshot.docs.isNotEmpty && snapshot.docs.first.id != excludingId) {
      throw const FirebaseServiceException(
        'A product with this barcode already exists.',
        code: 'already-exists',
      );
    }
  }
}
