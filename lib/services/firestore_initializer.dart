import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;

import '../models/currency.dart';
import '../models/customer.dart';
import '../models/exchange_rate.dart';
import '../models/invoice.dart';
import '../models/invoice_item.dart';
import '../models/product.dart';

/// Creates one small, valid document per required collection.
/// Remove the call from AuthController after the database is confirmed.
class FirestoreInitializer {
  static const bool enabled = true;

  FirebaseFirestore get _db => FirebaseFirestore.instance;

  Future<void>? _pending;

  Future<void> ensureSeedData() {
    return _pending ??= _initialize().whenComplete(() => _pending = null);
  }

  Future<void> _initialize() async {
    if (!enabled) return;
    final user = firebase_auth.FirebaseAuth.instance.currentUser;
    if (user == null) return;

    const currencyId = 'seed-currency';
    const customerId = 'seed-customer';
    const productId = 'seed-product';
    await _createIfMissing(_db.collection('users').doc(user.uid), {
      'email': user.email ?? '',
      'displayName': user.displayName ?? user.email ?? '',
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    });

    final currency = const Currency(
      id: currencyId,
      code: 'USD',
      name: 'US Dollar',
      symbol: r'$',
      isBaseCurrency: true,
    );
    await _createIfMissing(
      _db.collection('currencies').doc(currencyId),
      currency.toFirestore(),
    );

    final rate = ExchangeRate(
      id: 'seed-rate',
      currencyId: currencyId,
      rateToBase: 1,
      effectiveDate: DateTime.now(),
    );
    await _createIfMissing(
      _db.collection('exchange_rates').doc(rate.id),
      rate.toFirestore(),
    );

    final customer = const Customer(
      id: customerId,
      name: 'Seed Customer',
      email: 'customer@example.com',
    );
    await _createIfMissing(_db.collection('customers').doc(customerId), {
      ...customer.toFirestore(),
      'nameLower': customer.name.toLowerCase(),
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    });

    final product = const Product(
      id: productId,
      name: 'Seed Product',
      barcode: 'SEED-0001',
      price: 100,
      taxRate: 0,
      currencyId: currencyId,
    );
    await _createIfMissing(_db.collection('products').doc(productId), {
      ...product.toFirestore(),
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    });

    final item = const InvoiceItem(
      id: 'seed-item-0',
      productId: productId,
      productName: 'Seed Product',
      barcode: 'SEED-0001',
      originalUnitPrice: 100,
      originalCurrencyId: currencyId,
      originalCurrencyCode: 'USD',
      quantity: 1,
      unitPrice: 100,
      taxRate: 0,
      lineTotal: 100,
    );
    final invoice = Invoice(
      id: 'seed-invoice',
      invoiceNumber: 'INV-000001',
      invoiceName: 'Seed Invoice',
      customer: customer,
      currency: currency,
      baseCurrencyCode: 'USD',
      exchangeRate: 1,
      taxMode: TaxMode.exclusive,
      status: InvoiceStatus.draft,
      items: [item],
      subtotal: 100,
      taxAmount: 0,
      totalAmount: 100,
      createdAt: DateTime.now(),
    );
    final invoiceData = invoice.toFirestore()
      ..['createdAt'] = FieldValue.serverTimestamp()
      ..['updatedAt'] = FieldValue.serverTimestamp()
      ..['createdBy'] = user.uid;
    await _createIfMissing(
      _db.collection('invoices').doc(invoice.id),
      invoiceData,
    );
  }

  Future<void> _createIfMissing(
    DocumentReference<Map<String, dynamic>> reference,
    Map<String, dynamic> data,
  ) async {
    await _db.runTransaction((transaction) async {
      final snapshot = await transaction.get(reference);
      if (!snapshot.exists) transaction.set(reference, data);
    });
  }
}
