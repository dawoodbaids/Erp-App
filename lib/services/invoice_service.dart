import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;

import '../core/utils/currency_converter.dart';
import '../core/utils/firestore_helpers.dart';
import '../core/utils/tax_calculator.dart';
import '../models/currency.dart';
import '../models/customer.dart';
import '../models/invoice.dart';
import '../models/invoice_item.dart';
import '../models/product.dart';
import 'firebase_service_exception.dart';

class InvoiceService {
  FirebaseFirestore get _db => FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> get _invoices =>
      _db.collection('invoices');

  Future<List<Invoice>> getInvoices() {
    return runFirebase(
      () async => _readInvoices().then(
        (invoices) => invoices.where((invoice) => !invoice.isHidden).toList(),
      ),
      'Could not load invoices. Please try again.',
    );
  }

  Future<Invoice> getInvoice(String id) {
    return runFirebase(() async {
      final snapshot = await _invoices.doc(id).get();
      if (!snapshot.exists || snapshot.data() == null) _notFound('Invoice');
      return Invoice.fromFirestore(snapshot.id, snapshot.data()!);
    }, 'Could not load the invoice. Please try again.');
  }

  Future<Invoice> findByNumber(String number) {
    return runFirebase(() async {
      final snapshot = await _invoices
          .where('invoiceNumber', isEqualTo: number)
          .limit(1)
          .get();
      if (snapshot.docs.isEmpty) _notFound('Invoice');
      final doc = snapshot.docs.first;
      return Invoice.fromFirestore(doc.id, doc.data());
    }, 'Could not search for the invoice. Please try again.');
  }

  Future<Invoice> createInvoice(Invoice draft) {
    return _save(
      draft,
      fallback: 'Could not create the invoice. Please try again.',
    );
  }

  Future<Invoice> updateInvoice(Invoice draft) {
    return _save(
      draft,
      existingId: draft.id,
      fallback: 'Could not save the invoice. Please try again.',
    );
  }

  Future<Invoice> approve(String id) =>
      _changeStatus(id, InvoiceStatus.approved);

  Future<Invoice> cancel(String id) =>
      _changeStatus(id, InvoiceStatus.cancelled);

  Future<Invoice> hide(String id) {
    return runFirebase(() async {
      final reference = _invoices.doc(id);
      final snapshot = await reference.get();
      if (!snapshot.exists || snapshot.data() == null) _notFound('Invoice');
      final invoice = Invoice.fromFirestore(snapshot.id, snapshot.data()!);
      await reference.update({
        'isHidden': true,
        'updatedAt': FieldValue.serverTimestamp(),
      });
      return invoice.copyWith(isHidden: true);
    }, 'Could not remove the invoice. Please try again.');
  }

  Future<Invoice> _save(
    Invoice draft, {
    String? existingId,
    required String fallback,
  }) {
    return runFirebase(() async {
      Invoice? existing;
      if (existingId != null) {
        final snapshot = await _invoices.doc(existingId).get();
        if (!snapshot.exists || snapshot.data() == null) _notFound('Invoice');
        existing = Invoice.fromFirestore(snapshot.id, snapshot.data()!);
        if (!existing.isEditable) {
          throw const FirebaseServiceException(
            'Only draft invoices can be edited.',
            code: 'failed-precondition',
          );
        }
      }

      final customer = await _customer(draft.customer.id);
      final currency = await _currency(draft.currency.id);
      final currencies = await _readCurrencies();
      final rates = await _readRates();
      final invoiceItems = await _buildItems(
        draft.items,
        draft.taxMode,
        currency.id,
        currencies,
        rates,
      );
      final baseCurrency = _baseCurrency(currencies);
      final invoice = Invoice(
        id: existing?.id ?? _invoices.doc().id,
        invoiceNumber: existing?.invoiceNumber ?? await _nextInvoiceNumber(),
        invoiceName: draft.invoiceName.trim(),
        customer: customer,
        currency: currency,
        baseCurrencyCode: baseCurrency.code,
        exchangeRate: _rateFor(currency.id, currencies, rates),
        taxMode: draft.taxMode,
        status: InvoiceStatus.draft,
        items: List.unmodifiable(invoiceItems),
        subtotal: TaxCalculator.subtotal(invoiceItems, draft.taxMode),
        taxAmount: TaxCalculator.tax(invoiceItems, draft.taxMode),
        totalAmount: TaxCalculator.total(invoiceItems, draft.taxMode),
        createdAt: existing?.createdAt ?? DateTime.now(),
      );

      final reference = _invoices.doc(invoice.id);
      final data = invoice.toFirestore();
      data['createdAt'] = existing == null
          ? FieldValue.serverTimestamp()
          : Timestamp.fromDate(invoice.createdAt);
      data['updatedAt'] = FieldValue.serverTimestamp();
      final userId = firebase_auth.FirebaseAuth.instance.currentUser?.uid;
      if (userId != null) data['createdBy'] = userId;
      await reference.set(data);
      return invoice;
    }, fallback);
  }

  Future<Invoice> _changeStatus(String id, InvoiceStatus status) {
    final action = status == InvoiceStatus.approved ? 'approve' : 'cancel';
    return runFirebase(() async {
      final reference = _invoices.doc(id);
      final snapshot = await reference.get();
      if (!snapshot.exists || snapshot.data() == null) _notFound('Invoice');
      final invoice = Invoice.fromFirestore(snapshot.id, snapshot.data()!);
      if (!invoice.isEditable) {
        final statusLabel = status == InvoiceStatus.approved
            ? 'approved'
            : 'cancelled';
        throw FirebaseServiceException(
          'Only draft invoices can be $statusLabel.',
          code: 'failed-precondition',
        );
      }
      final timestamp = DateTime.now();
      await reference.update({
        'status': status.label,
        if (status == InvoiceStatus.approved)
          'approvedAt': FieldValue.serverTimestamp(),
        if (status == InvoiceStatus.cancelled)
          'cancelledAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });
      return invoice.copyWith(
        status: status,
        approvedAt: status == InvoiceStatus.approved ? timestamp : null,
        cancelledAt: status == InvoiceStatus.cancelled ? timestamp : null,
      );
    }, 'Could not $action the invoice. Please try again.');
  }

  Future<List<Invoice>> _readInvoices() async {
    final snapshot = await _invoices.get();
    final invoices = snapshot.docs
        .map((doc) => Invoice.fromFirestore(doc.id, doc.data()))
        .toList();
    invoices.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return invoices;
  }

  Future<List<Currency>> _readCurrencies() async {
    final snapshot = await _db.collection('currencies').get();
    return snapshot.docs
        .map((doc) => Currency.fromFirestore(doc.id, doc.data()))
        .where((currency) => currency.isActive)
        .toList();
  }

  Future<Map<String, double>> _readRates() async {
    final snapshot = await _db.collection('exchange_rates').get();
    final rates = <String, double>{};
    for (final doc in snapshot.docs) {
      rates[firestoreString(doc.data()['currencyId'])] = firestoreDouble(
        doc.data()['rateToBase'],
      );
    }
    return rates;
  }

  Future<Customer> _customer(String id) async {
    final snapshot = await _db.collection('customers').doc(id).get();
    if (!snapshot.exists || snapshot.data() == null) _notFound('Customer');
    return Customer.fromFirestore(snapshot.id, snapshot.data()!);
  }

  Future<Currency> _currency(String id) async {
    final snapshot = await _db.collection('currencies').doc(id).get();
    if (!snapshot.exists || snapshot.data() == null) _notFound('Currency');
    return Currency.fromFirestore(snapshot.id, snapshot.data()!);
  }

  Future<List<InvoiceItem>> _buildItems(
    List<InvoiceItem> drafts,
    TaxMode taxMode,
    String invoiceCurrencyId,
    List<Currency> currencies,
    Map<String, double> rates,
  ) async {
    final items = <InvoiceItem>[];
    for (var index = 0; index < drafts.length; index++) {
      final draft = drafts[index];
      final snapshot = await _db
          .collection('products')
          .doc(draft.productId)
          .get();
      if (!snapshot.exists || snapshot.data() == null) _notFound('Product');
      final product = Product.fromFirestore(snapshot.id, snapshot.data()!);
      final originalCurrency = _currencyForId(currencies, product.currencyId);
      final item = InvoiceItem(
        id: '${draft.productId}-$index',
        productId: product.id,
        productName: product.name,
        barcode: product.barcode,
        originalUnitPrice: product.price,
        originalCurrencyId: product.currencyId,
        originalCurrencyCode: originalCurrency.code,
        quantity: draft.quantity,
        unitPrice: _convert(
          product.price,
          product.currencyId,
          invoiceCurrencyId,
          currencies,
          rates,
        ),
        taxRate: product.taxRate,
        lineTotal: 0,
      );
      items.add(
        item.copyWith(lineTotal: TaxCalculator.lineTotal(item, taxMode)),
      );
    }
    return items;
  }

  double _convert(
    double amount,
    String from,
    String to,
    List<Currency> currencies,
    Map<String, double> rates,
  ) {
    final result = CurrencyConverter.convert(
      amount,
      _rateFor(from, currencies, rates),
      _rateFor(to, currencies, rates),
    );
    return (result * 100).round() / 100;
  }

  double _rateFor(
    String currencyId,
    List<Currency> currencies,
    Map<String, double> rates,
  ) {
    if (currencies.isEmpty) {
      throw const FirebaseServiceException(
        'No active currencies are configured.',
        code: 'failed-precondition',
      );
    }
    final base = currencies.firstWhere(
      (currency) => currency.isBaseCurrency,
      orElse: () => currencies.first,
    );
    if (currencyId == base.id) return 1;
    final rate = rates[currencyId] ?? 0;
    if (rate <= 0) {
      throw const FirebaseServiceException(
        'An exchange rate is missing for one of the selected currencies.',
        code: 'failed-precondition',
      );
    }
    return rate;
  }

  Currency _currencyForId(List<Currency> currencies, String id) {
    for (final currency in currencies) {
      if (currency.id == id) return currency;
    }
    throw const FirebaseServiceException(
      'A required currency was not found.',
      code: 'not-found',
    );
  }

  Currency _baseCurrency(List<Currency> currencies) {
    for (final currency in currencies) {
      if (currency.isBaseCurrency) return currency;
    }
    throw const FirebaseServiceException(
      'A base currency is not configured.',
      code: 'failed-precondition',
    );
  }

  Future<String> _nextInvoiceNumber() async {
    final invoices = await _readInvoices();
    var maxNumber = 0;
    for (final invoice in invoices) {
      final match = RegExp(r'INV-(\d+)').firstMatch(invoice.invoiceNumber);
      final value = int.tryParse(match?.group(1) ?? '') ?? 0;
      if (value > maxNumber) maxNumber = value;
    }
    return 'INV-${(maxNumber + 1).toString().padLeft(6, '0')}';
  }

  Never _notFound(String type) =>
      throw FirebaseServiceException('$type was not found.', code: 'not-found');
}
