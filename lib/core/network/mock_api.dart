import '../../models/currency.dart';
import '../../models/customer.dart';
import '../../models/exchange_rate.dart';
import '../../models/invoice.dart';
import '../../models/invoice_item.dart';
import '../../models/product.dart';
import '../utils/currency_converter.dart';
import '../utils/tax_calculator.dart';

/// Exception thrown by the in-memory backend when a request cannot be served.
class MockApiException implements Exception {
  final int statusCode;
  final String message;

  const MockApiException(this.statusCode, this.message);

  @override
  String toString() => message;
}

/// Lightweight in-memory backend used when the real API is unreachable.
///
/// It mirrors the JSON contract of the .NET backend so the services,
/// controllers and models work unchanged. It is used automatically in
/// widget tests and as an offline fallback for the demo.
class MockApi {
  MockApi._() {
    _reset();
  }

  static final MockApi instance = MockApi._();

  static const _mockUsername = 'admin';
  static const _mockPassword = 'Admin@123';

  final List<Customer> _customers = [];
  final List<Product> _products = [];
  final List<Currency> _currencies = [];
  final List<ExchangeRate> _exchangeRates = [];
  final List<Invoice> _invoices = [];

  int _nextInvoiceId = 0;
  int _nextRateId = 0;
  int _nextCustomerId = 0;
  int _nextProductId = 0;

  /// Re-seeds the in-memory store. Tests call this between cases so every
  /// scenario starts from a known state.
  void reset() => _reset();

  /// Restores the initial seed data. Called automatically on first use.
  void _reset() {
    _customers
      ..clear()
      ..addAll(_seedCustomers());
    _products
      ..clear()
      ..addAll(_seedProducts());
    _currencies
      ..clear()
      ..addAll(_seedCurrencies());
    _exchangeRates
      ..clear()
      ..addAll(_seedExchangeRates());
    _invoices
      ..clear()
      ..addAll(_seedInvoices());
    _nextInvoiceId = 6;
    _nextRateId = 7;
    _nextCustomerId = 6;
    _nextProductId = 10;
  }

  /// Dispatches a request to the in-memory backend.
  ///
  /// [method] is one of `GET`, `POST` or `PUT`. [path] is the API path such
  /// as `/api/invoices`. [data] carries the request body for POST/PUT.
  dynamic handle(
    String method,
    String path, {
    Map<String, dynamic>? data,
  }) {
    if (method == 'POST' && path == '/api/auth/login') {
      return _login(data);
    }
    if (method == 'GET' && path == '/api/customers') {
      return _customers.map((c) => c.toJson()).toList();
    }
    if (method == 'POST' && path == '/api/customers') {
      return _createCustomer(data).toJson();
    }
    if (method == 'GET' && path == '/api/products') {
      return _products.map((p) => p.toJson()).toList();
    }
    if (method == 'POST' && path == '/api/products') {
      return _createProduct(data).toJson();
    }
    if (method == 'PUT' && path.startsWith('/api/products/')) {
      final id = path.substring('/api/products/'.length);
      return _updateProduct(id, data).toJson();
    }
    if (method == 'POST' &&
        RegExp(r'^/api/products/\d+/image$').hasMatch(path)) {
      final id = path.substring('/api/products/'.length, path.length - 6);
      return _setProductImage(id);
    }
    if (method == 'GET' &&
        path.startsWith('/api/products/barcode/') &&
        path.contains('/price/')) {
      final rest = path.substring('/api/products/barcode/'.length);
      final parts = rest.split('/price/');
      return _pricePreview(_productByBarcode(parts.first), parts.last);
    }
    if (method == 'GET' && path.startsWith('/api/products/barcode/')) {
      final barcode = path.substring('/api/products/barcode/'.length);
      return _productByBarcode(barcode).toJson();
    }
    if (method == 'GET' &&
        RegExp(r'^/api/products/\d+/price/\d+$').hasMatch(path)) {
      final parts = path.substring('/api/products/'.length).split('/price/');
      return _pricePreview(_productById(parts.first), parts.last);
    }
    if (method == 'GET' && path == '/api/currencies') {
      return _currencies.map((c) => c.toJson()).toList();
    }
    if (method == 'PUT' && path.endsWith('/set-base')) {
      final id = path
          .replaceFirst('/api/currencies/', '')
          .replaceFirst('/set-base', '');
      return _setBaseCurrency(id).toJson();
    }
    if (method == 'GET' && path == '/api/exchange-rates') {
      return _exchangeRates.map((r) => r.toJson()).toList();
    }
    if (method == 'PUT' && path.startsWith('/api/exchange-rates/')) {
      final id = path.substring('/api/exchange-rates/'.length);
      return _updateRate(id, data).toJson();
    }
    if (method == 'GET' && path == '/api/invoices') {
      return _invoices
          .where((i) => !i.isHidden)
          .map((i) => i.toJson())
          .toList();
    }
    if (method == 'GET' && path.startsWith('/api/invoices/number/')) {
      final number = path.substring('/api/invoices/number/'.length);
      return _invoiceByNumber(number).toJson();
    }
    if (method == 'GET' && path.startsWith('/api/invoices/')) {
      final id = path.substring('/api/invoices/'.length);
      return _invoiceById(id).toJson();
    }
    if (method == 'POST' && path == '/api/invoices') {
      return _createInvoice(data).toJson();
    }
    if (method == 'POST' && path.endsWith('/hide')) {
      final id = path
          .replaceFirst('/api/invoices/', '')
          .replaceFirst('/hide', '');
      return _hide(id).toJson();
    }
    if (method == 'POST' && path.endsWith('/approve')) {
      final id = path
          .replaceFirst('/api/invoices/', '')
          .replaceFirst('/approve', '');
      return _approve(id).toJson();
    }
    if (method == 'POST' && path.endsWith('/cancel')) {
      final id = path
          .replaceFirst('/api/invoices/', '')
          .replaceFirst('/cancel', '');
      return _cancel(id).toJson();
    }
    if (method == 'GET' && path == '/api/dashboard/summary') {
      return _dashboardSummary();
    }
    if (method == 'GET' && path == '/api/dashboard/sales-trend') {
      return _salesTrend();
    }
    if (method == 'GET' && path == '/api/dashboard/invoice-status') {
      return _invoiceStatus();
    }

    throw const MockApiException(404, 'The requested resource was not found.');
  }

  Map<String, dynamic> _login(Map<String, dynamic>? data) {
    final username = data?['username']?.toString() ?? '';
    final password = data?['password']?.toString() ?? '';
    if (username == _mockUsername && password == _mockPassword) {
      return {
        'token': 'mock-jwt-token',
        'expiresAt': DateTime.now()
            .add(const Duration(hours: 8))
            .toIso8601String(),
        'username': _mockUsername,
        'fullName': 'Administrator',
      };
    }
    throw const MockApiException(401, 'Invalid username or password');
  }

  Product _productByBarcode(String barcode) {
    for (final product in _products) {
      if (product.barcode == barcode) return product;
    }
    throw MockApiException(404, 'No product found with barcode $barcode.');
  }

  Product _productById(String id) {
    for (final product in _products) {
      if (product.id == id) return product;
    }
    throw MockApiException(404, 'Product not found.');
  }

  Customer _customerById(String id) {
    for (final customer in _customers) {
      if (customer.id == id) return customer;
    }
    throw MockApiException(404, 'Customer not found.');
  }

  Currency _currencyById(String id) {
    for (final currency in _currencies) {
      if (currency.id == id) return currency;
    }
    throw MockApiException(404, 'Currency not found.');
  }

  Invoice _invoiceById(String id) {
    for (final invoice in _invoices) {
      if (invoice.id == id) return invoice;
    }
    throw MockApiException(404, 'Invoice not found.');
  }

  Invoice _invoiceByNumber(String number) {
    for (final invoice in _invoices) {
      if (invoice.invoiceNumber == number) return invoice;
    }
    throw MockApiException(404, 'Invoice not found.');
  }

  Customer _createCustomer(Map<String, dynamic>? data) {
    if (data == null) {
      throw const MockApiException(400, 'Invalid customer payload');
    }
    final name = data['name']?.toString().trim() ?? '';
    if (name.isEmpty) {
      throw const MockApiException(400, 'Customer name is required');
    }
    for (final existing in _customers) {
      if (existing.name.toLowerCase() == name.toLowerCase()) {
        throw const MockApiException(
          409,
          'A customer with this name already exists.',
        );
      }
    }
    final customer = Customer(
      id: '$_nextCustomerId',
      name: name,
      phone: data['phone']?.toString().trim().isEmpty ?? true
          ? null
          : data['phone']?.toString().trim(),
      email: data['email']?.toString().trim() ?? '',
      address: data['address']?.toString().trim().isEmpty ?? true
          ? null
          : data['address']?.toString().trim(),
      createdAt: DateTime.now(),
    );
    _nextCustomerId += 1;
    _customers.add(customer);
    return customer;
  }

  Product _createProduct(Map<String, dynamic>? data) {
    if (data == null) {
      throw const MockApiException(400, 'Invalid product payload');
    }
    final name = data['name']?.toString().trim() ?? '';
    final barcode = data['barcode']?.toString().trim() ?? '';
    if (name.isEmpty) {
      throw const MockApiException(400, 'Product name is required');
    }
    if (barcode.isEmpty) {
      throw const MockApiException(400, 'Barcode is required');
    }
    for (final existing in _products) {
      if (existing.barcode == barcode) {
        throw const MockApiException(
          409,
          'A product with this barcode already exists.',
        );
      }
    }
    final product = Product(
      id: '$_nextProductId',
      name: name,
      barcode: barcode,
      price: _numValue(data['price'], 0),
      taxRate: _numValue(data['taxRate'], 0),
      currencyId: _idValue(data['currencyId']),
      isActive: data['isActive'] != false,
    );
    _nextProductId += 1;
    _products.insert(0, product);
    return product;
  }

  Product _updateProduct(String id, Map<String, dynamic>? data) {
    final product = _productById(id);
    final name = data?['name']?.toString().trim() ?? product.name;
    final barcode = data?['barcode']?.toString().trim() ?? product.barcode;
    for (final existing in _products) {
      if (existing.id != id && existing.barcode == barcode) {
        throw const MockApiException(
          409,
          'A product with this barcode already exists.',
        );
      }
    }
    final updated = product.copyWith(
      name: name,
      barcode: barcode,
      price: data?['price'] is num
          ? (data!['price'] as num).toDouble()
          : product.price,
      taxRate: data?['taxRate'] is num
          ? (data!['taxRate'] as num).toDouble()
          : product.taxRate,
      currencyId: data?['currencyId'] != null
          ? _idValue(data!['currencyId'])
          : product.currencyId,
      isActive: data?['isActive'] is bool
          ? data!['isActive'] as bool
          : product.isActive,
    );
    _replaceProduct(updated);
    return updated;
  }

  Map<String, dynamic> _setProductImage(String id) {
    final product = _productById(id);
    final updated = product.copyWith(image: '/uploads/products/$id.png');
    _replaceProduct(updated);
    return updated.toJson();
  }

  void _replaceProduct(Product product) {
    final index = _products.indexWhere((p) => p.id == product.id);
    if (index >= 0) {
      _products[index] = product;
    } else {
      _products.insert(0, product);
    }
  }

  Invoice _hide(String id) {
    final invoice = _invoiceById(id);
    if (invoice.isHidden) {
      throw const MockApiException(409, 'Invoice is already hidden.');
    }
    final updated = invoice.copyWith(isHidden: true);
    _replaceInvoice(updated);
    return updated;
  }

  Map<String, dynamic> _dashboardSummary() {
    final visible = _invoices.where((invoice) => !invoice.isHidden).toList();
    final approved = visible
        .where((i) => i.status == InvoiceStatus.approved)
        .toList();
    final now = DateTime.now();
    final today = approved
        .where(
          (i) =>
              i.createdAt.year == now.year &&
              i.createdAt.month == now.month &&
              i.createdAt.day == now.day,
        )
        .fold<double>(0, (sum, i) => sum + i.totalAmount);
    final thisMonth = approved
        .where(
          (i) =>
              i.createdAt.year == now.year && i.createdAt.month == now.month,
        )
        .fold<double>(0, (sum, i) => sum + i.totalAmount);
    final totalSales = approved.fold<double>(0, (sum, i) => sum + i.totalAmount);
    return {
      'baseCurrencyCode': _currencyById(_baseCurrencyId()).code,
      'todaySales': _round2(today),
      'thisMonthSales': _round2(thisMonth),
      'totalSales': _round2(totalSales),
      'totalInvoices': visible.length,
      'approvedInvoices': approved.length,
      'pendingDrafts': visible
          .where((i) => i.status == InvoiceStatus.draft)
          .length,
      'cancelledInvoices': visible
          .where((i) => i.status == InvoiceStatus.cancelled)
          .length,
      'totalCustomers': _customers.length,
      'totalProducts': _products.length,
    };
  }

  List<Map<String, dynamic>> _salesTrend() {
    final now = DateTime.now();
    final visible = _invoices.where((invoice) => !invoice.isHidden).toList();
    final points = <Map<String, dynamic>>[];
    for (var offset = 5; offset >= 0; offset--) {
      final day = DateTime(now.year, now.month, now.day).subtract(
        Duration(days: offset),
      );
      final dayInvoices = visible.where((i) {
        return i.status == InvoiceStatus.approved &&
            i.createdAt.year == day.year &&
            i.createdAt.month == day.month &&
            i.createdAt.day == day.day;
      }).toList();
      points.add({
        'date': day.toIso8601String(),
        'label': day.weekday < 7
            ? const [
                'Mon',
                'Tue',
                'Wed',
                'Thu',
                'Fri',
                'Sat',
                'Sun',
              ][day.weekday - 1]
            : '?',
        'total': _round2(
          dayInvoices.fold<double>(0, (sum, i) => sum + i.totalAmount),
        ),
        'invoiceCount': dayInvoices.length,
      });
    }
    return points;
  }

  Map<String, dynamic> _invoiceStatus() {
    final visible = _invoices.where((invoice) => !invoice.isHidden).toList();
    double total(Iterable<Invoice> list) =>
        _round2(list.fold<double>(0, (sum, i) => sum + i.totalAmount));
    return {
      'draftCount': visible
          .where((i) => i.status == InvoiceStatus.draft)
          .length,
      'draftTotal': total(
        visible.where((i) => i.status == InvoiceStatus.draft),
      ),
      'approvedCount': visible
          .where((i) => i.status == InvoiceStatus.approved)
          .length,
      'approvedTotal': total(
        visible.where((i) => i.status == InvoiceStatus.approved),
      ),
      'cancelledCount': visible
          .where((i) => i.status == InvoiceStatus.cancelled)
          .length,
      'cancelledTotal': total(
        visible.where((i) => i.status == InvoiceStatus.cancelled),
      ),
    };
  }

  double _rateToBase(String currencyId) {
    if (currencyId == _baseCurrencyId()) return 1.0;
    for (final rate in _exchangeRates) {
      if (rate.currencyId == currencyId) return rate.rateToBase;
    }
    return 1.0;
  }

  String _baseCurrencyId() {
    for (final currency in _currencies) {
      if (currency.isBaseCurrency) return currency.id;
    }
    return _currencies.isEmpty ? '1' : _currencies.first.id;
  }

  double _round2(double value) => (value * 100).round() / 100;

  /// Universal conversion: amount * sourceRateToBase / targetRateToBase.
  double _convert(double amount, String fromCurrencyId, String toCurrencyId) {
    return CurrencyConverter.convert(
      amount,
      _rateToBase(fromCurrencyId),
      _rateToBase(toCurrencyId),
    );
  }

  Map<String, dynamic> _pricePreview(Product product, String currencyId) {
    final currency = _currencyById(currencyId);
    final original = _currencyById(product.currencyId);
    return {
      'productId': int.tryParse(product.id) ?? product.id,
      'name': product.name,
      'originalPrice': product.price,
      'originalCurrencyId': int.tryParse(product.currencyId) ?? product.currencyId,
      'originalCurrency': original.code,
      'invoiceCurrencyId': int.tryParse(currencyId) ?? currencyId,
      'invoiceCurrency': currency.code,
      'convertedUnitPrice': _convert(
        product.price,
        product.currencyId,
        currencyId,
      ),
      'taxRate': product.taxRate,
    };
  }

  Currency _setBaseCurrency(String id) {
    final currency = _currencyById(id);
    final updated = _currencies.map((c) {
      return c.id == id ? c : c.copyWith(isBaseCurrency: false);
    }).toList();
    final index = updated.indexWhere((c) => c.id == id);
    updated[index] = updated[index].copyWith(isBaseCurrency: true);
    _currencies
      ..clear()
      ..addAll(updated);

    final now = DateTime.now();
    final newBaseRate = _rateToBase(id);
    for (final c in _currencies) {
      final current = _rateToBase(c.id);
      final newRate = c.id == id ? 1.0 : _round2(current / newBaseRate);
      _exchangeRates.add(
        ExchangeRate(
          id: '${_nextRateId++}',
          currencyId: c.id,
          rateToBase: newRate,
          effectiveDate: now,
        ),
      );
    }
    return currency;
  }

  ExchangeRate _updateRate(String id, Map<String, dynamic>? data) {
    final rateValue = data?['rate'];
    final rate = rateValue is num
        ? rateValue.toDouble()
        : double.tryParse(rateValue?.toString() ?? '');
    if (rate == null || rate <= 0) {
      throw const MockApiException(400, 'Rate must be greater than zero');
    }
    for (final existing in _exchangeRates) {
      if (existing.id == id) {
        final currency = _currencyById(existing.currencyId);
        if (currency.isBaseCurrency) {
          throw const MockApiException(
            400,
            'The base currency rate cannot be changed',
          );
        }
        final created = ExchangeRate(
          id: '${_nextRateId++}',
          currencyId: existing.currencyId,
          rateToBase: rate,
          effectiveDate: DateTime.now(),
        );
        _exchangeRates.add(created);
        return created;
      }
    }
    throw MockApiException(404, 'Exchange rate not found.');
  }

  Invoice _createInvoice(Map<String, dynamic>? data) {
    if (data == null) {
      throw const MockApiException(400, 'Invalid invoice payload');
    }

    final customerId = _idValue(data['customerId']);
    final currencyId = _idValue(data['currencyId']);
    final taxMode =
        (data['taxMode']?.toString() ?? '').toLowerCase() == 'inclusive'
        ? TaxMode.inclusive
        : TaxMode.exclusive;
    final invoiceNumber = _nextInvoiceNumber();
    final invoiceName = (data['invoiceName']?.toString().trim() ?? '')
            .isEmpty
        ? invoiceNumber
        : data['invoiceName']!.toString().trim();

    final rawItems = (data['items'] as List?) ?? const [];
    final items = <InvoiceItem>[];
    var seq = 1;
    for (final raw in rawItems) {
      final map = raw as Map<String, dynamic>;
      final product = _productById(_idValue(map['productId']));
      final quantity = _numValue(map['quantity'], 1);
      final originalCurrency = _currencyById(product.currencyId);

      // The backend converts the product's ORIGINAL price into the invoice
      // currency and copies the product tax rate (never the client's).
      final unitPrice = _convert(
        product.price,
        product.currencyId,
        currencyId,
      );
      final item = InvoiceItem(
        id: 'IT-$_nextInvoiceId-$seq',
        productId: product.id,
        productName: product.name,
        barcode: product.barcode,
        originalUnitPrice: product.price,
        originalCurrencyId: product.currencyId,
        originalCurrencyCode: originalCurrency.code,
        quantity: quantity,
        unitPrice: unitPrice,
        taxRate: product.taxRate,
        lineTotal: 0,
      );
      items.add(
        item.copyWith(lineTotal: TaxCalculator.lineTotal(item, taxMode)),
      );
      seq++;
    }

    final computedItems = items
        .map(
          (item) => item.copyWith(
            lineTotal: TaxCalculator.lineTotal(item, taxMode),
          ),
        )
        .toList();

    final invoice = Invoice(
      id: '$_nextInvoiceId',
      invoiceNumber: invoiceNumber,
      invoiceName: invoiceName,
      customer: _customerById(customerId),
      currency: _currencyById(currencyId),
      exchangeRate: _rateToBase(currencyId),
      taxMode: taxMode,
      status: InvoiceStatus.draft,
      items: List.unmodifiable(computedItems),
      subtotal: TaxCalculator.subtotal(computedItems, taxMode),
      taxAmount: TaxCalculator.tax(computedItems, taxMode),
      totalAmount: TaxCalculator.total(computedItems, taxMode),
      createdAt: DateTime.now(),
    );

    _nextInvoiceId += 1;
    _invoices.insert(0, invoice);
    return invoice;
  }

  Invoice _approve(String id) {
    final invoice = _invoiceById(id);
    if (invoice.status != InvoiceStatus.draft) {
      throw const MockApiException(409, 'Only draft invoices can be approved');
    }
    final updated = invoice.copyWith(
      status: InvoiceStatus.approved,
      approvedAt: DateTime.now(),
    );
    _replaceInvoice(updated);
    return updated;
  }

  Invoice _cancel(String id) {
    final invoice = _invoiceById(id);
    if (invoice.status != InvoiceStatus.draft) {
      throw const MockApiException(409, 'Only draft invoices can be cancelled');
    }
    final updated = invoice.copyWith(
      status: InvoiceStatus.cancelled,
      cancelledAt: DateTime.now(),
    );
    _replaceInvoice(updated);
    return updated;
  }

  void _replaceInvoice(Invoice invoice) {
    final index = _invoices.indexWhere((i) => i.id == invoice.id);
    if (index >= 0) {
      _invoices[index] = invoice;
    } else {
      _invoices.insert(0, invoice);
    }
  }

  String _nextInvoiceNumber() {
    var maxNumber = 0;
    for (final invoice in _invoices) {
      final match = RegExp(r'INV-(\d+)').firstMatch(invoice.invoiceNumber);
      if (match != null) {
        final n = int.tryParse(match.group(1)!) ?? 0;
        if (n > maxNumber) maxNumber = n;
      }
    }
    return 'INV-${(maxNumber + 1).toString().padLeft(6, '0')}';
  }

  static String _idValue(Object? value) =>
      value == null ? '' : value.toString();

  static double _numValue(Object? value, double fallback) {
    if (value is num) return value.toDouble();
    return double.tryParse(value?.toString() ?? '') ?? fallback;
  }

  static List<Currency> _seedCurrencies() => [
    const Currency(
      id: '1',
      code: 'JOD',
      name: 'Jordanian Dinar',
      symbol: 'JOD',
      isBaseCurrency: true,
    ),
    const Currency(id: '2', code: 'USD', name: 'US Dollar', symbol: r'$'),
    const Currency(id: '3', code: 'EUR', name: 'Euro', symbol: '€'),
    const Currency(id: '4', code: 'SAR', name: 'Saudi Riyal', symbol: 'SAR'),
    const Currency(id: '5', code: 'AED', name: 'UAE Dirham', symbol: 'AED'),
    const Currency(id: '6', code: 'GBP', name: 'British Pound', symbol: 'GBP'),
  ];

  static List<ExchangeRate> _seedExchangeRates() => [
    ExchangeRate(id: '1', currencyId: '1', rateToBase: 1.0),
    ExchangeRate(id: '2', currencyId: '2', rateToBase: 0.709),
    ExchangeRate(id: '3', currencyId: '3', rateToBase: 0.825),
    ExchangeRate(id: '4', currencyId: '4', rateToBase: 0.189),
    ExchangeRate(id: '5', currencyId: '5', rateToBase: 0.193),
    ExchangeRate(id: '6', currencyId: '6', rateToBase: 0.950),
  ];

  static List<Customer> _seedCustomers() => [
    Customer(
      id: '1',
      name: 'ABC Company',
      phone: '+962 79 111 0001',
      email: 'info@abccompany.com',
      createdAt: DateTime.now().subtract(const Duration(days: 200)),
    ),
    Customer(
      id: '2',
      name: 'Tech Solutions',
      phone: '+962 79 111 0002',
      email: 'contact@techsolutions.com',
      createdAt: DateTime.now().subtract(const Duration(days: 180)),
    ),
    Customer(
      id: '3',
      name: 'Jordan Trading',
      phone: '+962 79 111 0003',
      email: 'sales@jordantrading.com',
      createdAt: DateTime.now().subtract(const Duration(days: 150)),
    ),
    Customer(
      id: '4',
      name: 'Modern Store',
      phone: '+962 79 111 0004',
      email: 'hello@modernstore.com',
      createdAt: DateTime.now().subtract(const Duration(days: 90)),
    ),
    Customer(
      id: '5',
      name: 'Future Solutions',
      phone: '+962 79 111 0005',
      email: 'support@futuresolutions.com',
      createdAt: DateTime.now().subtract(const Duration(days: 60)),
    ),
  ];

  static List<Product> _seedProducts() => [
    Product(
      id: '1',
      name: 'Laptop',
      barcode: '629100000001',
      image: 'assets/images/product_laptop.png',
      price: 650.00,
      taxRate: 16,
      currencyId: '1',
    ),
    Product(
      id: '2',
      name: 'Wireless Mouse',
      barcode: '629100000002',
      image: 'assets/images/product_mouse.png',
      price: 10.00,
      taxRate: 16,
      currencyId: '1',
    ),
    Product(
      id: '3',
      name: 'Keyboard',
      barcode: '629100000003',
      image: 'assets/images/product_keyboard.png',
      price: 15.00,
      taxRate: 16,
      currencyId: '1',
    ),
    Product(
      id: '4',
      name: 'Monitor',
      barcode: '629100000004',
      image: 'assets/images/product_monitor.png',
      price: 150.00,
      taxRate: 16,
      currencyId: '1',
    ),
    Product(
      id: '5',
      name: 'USB-C Cable',
      barcode: '629100000005',
      image: 'assets/images/product_cable.png',
      price: 5.00,
      taxRate: 8,
      currencyId: '1',
    ),
    Product(
      id: '6',
      name: 'Headset',
      barcode: '629100000006',
      image: 'assets/images/product_headset.png',
      price: 25.00,
      taxRate: 16,
      currencyId: '1',
    ),
    Product(
      id: '7',
      name: 'Gaming Mouse (Import)',
      barcode: '629100000007',
      image: 'assets/images/product_mouse.png',
      price: 100.00,
      taxRate: 16,
      currencyId: '2',
    ),
    Product(
      id: '8',
      name: 'Bluetooth Headset (Import)',
      barcode: '629100000008',
      image: 'assets/images/product_headset.png',
      price: 80.00,
      taxRate: 16,
      currencyId: '3',
    ),
    Product(
      id: '9',
      name: 'LED Desk Lamp (Import)',
      barcode: '629100000009',
      image: 'assets/images/product_cable.png',
      price: 150.00,
      taxRate: 16,
      currencyId: '4',
    ),
  ];

  static List<Invoice> _seedInvoices() {
    final jod = _seedCurrencies()[0];
    final usd = _seedCurrencies()[1];
    final eur = _seedCurrencies()[2];
    final customers = _seedCustomers();
    final products = _seedProducts();

    final now = DateTime.now();

    Invoice build(
      String id,
      String number,
      int customerIndex,
      Currency currency,
      double exchangeRate,
      TaxMode taxMode,
      InvoiceStatus status,
      List<(int productIndex, double quantity)> lines,
      Duration age,
    ) {
      final items = lines.map((line) {
        final product = products[line.$1];
        final original = _seedCurrencies()[0];
        final converted = _convertForSeed(
          product.price,
          product.currencyId,
          currency.id,
        );
        return InvoiceItem(
          id: '$id-IT-${line.$1}',
          productId: product.id,
          productName: product.name,
          barcode: product.barcode,
          originalUnitPrice: product.price,
          originalCurrencyId: product.currencyId,
          originalCurrencyCode: original.code,
          quantity: line.$2,
          unitPrice: converted,
          taxRate: product.taxRate,
          lineTotal: 0,
        );
      }).toList();
      final computed = items
          .map(
            (item) => item.copyWith(
              lineTotal: TaxCalculator.lineTotal(item, taxMode),
            ),
          )
          .toList();
      return Invoice(
        id: id,
        invoiceNumber: number,
        invoiceName: number,
        customer: customers[customerIndex],
        currency: currency,
        exchangeRate: exchangeRate,
        taxMode: taxMode,
        status: status,
        items: List.unmodifiable(computed),
        subtotal: TaxCalculator.subtotal(computed, taxMode),
        taxAmount: TaxCalculator.tax(computed, taxMode),
        totalAmount: TaxCalculator.total(computed, taxMode),
        createdAt: now.subtract(age),
      );
    }

    final inv1 = build(
      '1',
      'INV-000001',
      0,
      jod,
      1.0,
      TaxMode.exclusive,
      InvoiceStatus.draft,
      const [(1, 2), (4, 1)],
      const Duration(days: 5),
    );
    final inv2 = build(
      '2',
      'INV-000002',
      1,
      usd,
      0.709,
      TaxMode.exclusive,
      InvoiceStatus.approved,
      const [(0, 1), (2, 1)],
      const Duration(days: 4),
    ).copyWith(approvedAt: now.subtract(const Duration(days: 3)));
    final inv3 = build(
      '3',
      'INV-000003',
      2,
      eur,
      0.825,
      TaxMode.inclusive,
      InvoiceStatus.cancelled,
      const [(5, 1), (3, 1)],
      const Duration(days: 6),
    ).copyWith(cancelledAt: now.subtract(const Duration(days: 4)));
    final inv4 = build(
      '4',
      'INV-000004',
      3,
      jod,
      1.0,
      TaxMode.inclusive,
      InvoiceStatus.draft,
      const [(4, 3), (1, 1)],
      const Duration(days: 2),
    );
    final inv5 = build(
      '5',
      'INV-000005',
      4,
      jod,
      1.0,
      TaxMode.exclusive,
      InvoiceStatus.approved,
      const [(3, 2), (2, 1)],
      const Duration(days: 1),
    ).copyWith(approvedAt: now);

    return [inv1, inv2, inv3, inv4, inv5];
  }

  /// Seed-time conversion using the seeded rates so the mock invoices match
  /// what the real backend would have produced.
  static double _convertForSeed(
    double amount,
    String fromCurrencyId,
    String toCurrencyId,
  ) {
    final rates = _seedExchangeRates();
    double rate(String currencyId) {
      if (currencyId == '1') return 1.0;
      for (final r in rates) {
        if (r.currencyId == currencyId) return r.rateToBase;
      }
      return 1.0;
    }

    final source = rate(fromCurrencyId);
    final target = rate(toCurrencyId);
    if (target == 0) return amount;
    final converted = amount * source / target;
    return (converted * 100).round() / 100;
  }
}
