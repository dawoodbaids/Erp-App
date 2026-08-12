import '../../models/currency.dart';
import '../../models/customer.dart';
import '../../models/exchange_rate.dart';
import '../../models/invoice.dart';
import '../../models/invoice_item.dart';
import '../../models/product.dart';
import '../constants/app_assets.dart';
import '../utils/tax_calculator.dart';

class MockData {
  static const List<Customer> customers = [
    Customer(id: 'C1', name: 'ABC Company', phone: '+962 79 111 0001'),
    Customer(id: 'C2', name: 'Tech Solutions', phone: '+962 79 111 0002'),
    Customer(id: 'C3', name: 'Jordan Trading', phone: '+962 79 111 0003'),
    Customer(id: 'C4', name: 'Modern Store', phone: '+962 79 111 0004'),
    Customer(id: 'C5', name: 'Future Solutions', phone: '+962 79 111 0005'),
  ];

  static const List<Currency> currencies = [
    Currency(
      id: 'cur-jod',
      code: 'JOD',
      name: 'Jordanian Dinar',
      symbol: 'JOD',
      isBaseCurrency: true,
    ),
    Currency(id: 'cur-usd', code: 'USD', name: 'US Dollar', symbol: '\$'),
    Currency(id: 'cur-eur', code: 'EUR', name: 'Euro', symbol: '€'),
    Currency(id: 'cur-sar', code: 'SAR', name: 'Saudi Riyal', symbol: 'SAR'),
    Currency(id: 'cur-aed', code: 'AED', name: 'UAE Dirham', symbol: 'AED'),
    Currency(id: 'cur-gbp', code: 'GBP', name: 'British Pound', symbol: 'GBP'),
  ];

  static const List<ExchangeRate> exchangeRates = [
    ExchangeRate(
      id: 'er-jod',
      currencyId: 'cur-jod',
      rateToBase: 1.0,
    ),
    ExchangeRate(
      id: 'er-usd',
      currencyId: 'cur-usd',
      rateToBase: 0.709,
    ),
    ExchangeRate(
      id: 'er-eur',
      currencyId: 'cur-eur',
      rateToBase: 0.825,
    ),
    ExchangeRate(
      id: 'er-sar',
      currencyId: 'cur-sar',
      rateToBase: 0.189,
    ),
    ExchangeRate(
      id: 'er-aed',
      currencyId: 'cur-aed',
      rateToBase: 0.193,
    ),
    ExchangeRate(
      id: 'er-gbp',
      currencyId: 'cur-gbp',
      rateToBase: 0.950,
    ),
  ];

  static const List<Product> products = [
    Product(
      id: 'P1',
      name: 'Laptop',
      barcode: '629100000001',
      image: AppAssets.laptop,
      price: 650.00,
      taxRate: 16,
      currencyId: 'cur-jod',
    ),
    Product(
      id: 'P2',
      name: 'Wireless Mouse',
      barcode: '629100000002',
      image: AppAssets.mouse,
      price: 10.00,
      taxRate: 16,
      currencyId: 'cur-jod',
    ),
    Product(
      id: 'P3',
      name: 'Keyboard',
      barcode: '629100000003',
      image: AppAssets.keyboard,
      price: 15.00,
      taxRate: 16,
      currencyId: 'cur-jod',
    ),
    Product(
      id: 'P4',
      name: 'Monitor',
      barcode: '629100000004',
      image: AppAssets.monitor,
      price: 150.00,
      taxRate: 16,
      currencyId: 'cur-jod',
    ),
    Product(
      id: 'P5',
      name: 'USB-C Cable',
      barcode: '629100000005',
      image: AppAssets.cable,
      price: 5.00,
      taxRate: 8,
      currencyId: 'cur-jod',
    ),
    Product(
      id: 'P6',
      name: 'Headset',
      barcode: '629100000006',
      image: AppAssets.headset,
      price: 25.00,
      taxRate: 16,
      currencyId: 'cur-jod',
    ),
  ];

  static List<InvoiceItem> _items(List<InvoiceItem> items) =>
      List.unmodifiable(items);

  static InvoiceItem _item({
    required String id,
    required Product product,
    required double quantity,
    required double unitPrice,
  }) {
    final originalCurrency = currencies.firstWhere(
      (c) => c.id == product.currencyId,
      orElse: () => currencies.first,
    );
    return InvoiceItem(
      id: id,
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
  }

  static final List<Invoice> invoices = _buildInvoices();

  static List<Invoice> _buildInvoices() {
    final jod = currencies[0];
    final usd = currencies[1];
    final eur = currencies[2];
    final abc = customers[0];
    final tech = customers[1];
    final jordan = customers[2];
    final modern = customers[3];
    final future = customers[4];

    final laptop = products[0];
    final mouse = products[1];
    final keyboard = products[2];
    final monitor = products[3];
    final cable = products[4];
    final headset = products[5];

    final now = DateTime.now();

    final inv1Items = [
      _item(id: 'IT1-1', product: mouse, quantity: 2, unitPrice: mouse.price),
      _item(id: 'IT1-2', product: cable, quantity: 1, unitPrice: cable.price),
    ];
    final inv2Items = [
      _item(id: 'IT2-1', product: laptop, quantity: 1, unitPrice: laptop.price),
      _item(
        id: 'IT2-2',
        product: keyboard,
        quantity: 1,
        unitPrice: keyboard.price,
      ),
    ];
    final inv3Items = [
      _item(
        id: 'IT3-1',
        product: headset,
        quantity: 1,
        unitPrice: headset.price,
      ),
      _item(
        id: 'IT3-2',
        product: monitor,
        quantity: 1,
        unitPrice: monitor.price,
      ),
    ];
    final inv4Items = [
      _item(id: 'IT4-1', product: cable, quantity: 3, unitPrice: cable.price),
      _item(id: 'IT4-2', product: mouse, quantity: 1, unitPrice: mouse.price),
    ];
    final inv5Items = [
      _item(
        id: 'IT5-1',
        product: monitor,
        quantity: 2,
        unitPrice: monitor.price,
      ),
      _item(
        id: 'IT5-2',
        product: keyboard,
        quantity: 1,
        unitPrice: keyboard.price,
      ),
    ];

    Invoice build(
      String id,
      String number,
      Customer customer,
      Currency currency,
      double exchangeRate,
      TaxMode taxMode,
      InvoiceStatus status,
      List<InvoiceItem> items,
      DateTime createdAt,
    ) {
      final computedItems = items
          .map(
            (item) => item.copyWith(
              lineTotal: TaxCalculator.lineTotal(item, taxMode),
            ),
          )
          .toList();
      return Invoice(
        id: id,
        invoiceNumber: number,
        customer: customer,
        currency: currency,
        exchangeRate: exchangeRate,
        taxMode: taxMode,
        status: status,
        items: _items(computedItems),
        subtotal: TaxCalculator.subtotal(computedItems, taxMode),
        taxAmount: TaxCalculator.tax(computedItems, taxMode),
        totalAmount: TaxCalculator.total(computedItems, taxMode),
        createdAt: createdAt,
      );
    }

    return [
      build(
        'INV-1',
        'INV-000001',
        abc,
        jod,
        1.0,
        TaxMode.exclusive,
        InvoiceStatus.draft,
        inv1Items,
        now.subtract(const Duration(days: 5)),
      ),
      build(
        'INV-2',
        'INV-000002',
        tech,
        usd,
        0.709,
        TaxMode.exclusive,
        InvoiceStatus.approved,
        inv2Items,
        now.subtract(const Duration(days: 4)),
      ).copyWith(approvedAt: now.subtract(const Duration(days: 3))),
      build(
        'INV-3',
        'INV-000003',
        jordan,
        eur,
        0.825,
        TaxMode.inclusive,
        InvoiceStatus.cancelled,
        inv3Items,
        now.subtract(const Duration(days: 6)),
      ).copyWith(cancelledAt: now.subtract(const Duration(days: 4))),
      build(
        'INV-4',
        'INV-000004',
        modern,
        jod,
        1.0,
        TaxMode.inclusive,
        InvoiceStatus.draft,
        inv4Items,
        now.subtract(const Duration(days: 2)),
      ),
      build(
        'INV-5',
        'INV-000005',
        future,
        jod,
        1.0,
        TaxMode.exclusive,
        InvoiceStatus.approved,
        inv5Items,
        now.subtract(const Duration(days: 1)),
      ).copyWith(approvedAt: now),
    ];
  }
}
