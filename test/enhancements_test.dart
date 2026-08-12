import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';

import 'package:erp_mobileapp_ui/controllers/create_invoice_controller.dart';
import 'package:erp_mobileapp_ui/controllers/customer_controller.dart';
import 'package:erp_mobileapp_ui/controllers/invoice_controller.dart';
import 'package:erp_mobileapp_ui/controllers/product_controller.dart';
import 'package:erp_mobileapp_ui/controllers/settings_controller.dart';
import 'package:erp_mobileapp_ui/core/network/api_client.dart';
import 'package:erp_mobileapp_ui/core/network/mock_api.dart';
import 'package:erp_mobileapp_ui/models/currency.dart';
import 'package:erp_mobileapp_ui/models/customer.dart';
import 'package:erp_mobileapp_ui/models/invoice.dart';
import 'package:erp_mobileapp_ui/models/product.dart';
import 'package:erp_mobileapp_ui/services/customer_service.dart';
import 'package:erp_mobileapp_ui/services/invoice_service.dart';
import 'package:erp_mobileapp_ui/services/product_service.dart';

void main() {
  setUp(() {
    MockApi.instance.reset();
    Get.reset();
  });

  test('creates a named invoice, hides it, and finds it by number', () async {
    const customer = Customer(id: '1', name: 'ABC Company');
    const currency = Currency(
      id: '1',
      code: 'JOD',
      name: 'Jordanian Dinar',
      symbol: 'JOD',
      isBaseCurrency: true,
    );
    final draft = Invoice(
      id: '',
      invoiceNumber: '',
      invoiceName: 'Warehouse Restock',
      customer: customer,
      currency: currency,
      exchangeRate: 1,
      taxMode: TaxMode.exclusive,
      status: InvoiceStatus.draft,
      items: const [],
      subtotal: 0,
      taxAmount: 0,
      totalAmount: 0,
      createdAt: DateTime.now(),
    );
    final service = InvoiceService();

    final created = await service.createInvoice(draft);
    expect(created.invoiceName, 'Warehouse Restock');

    await service.hide(created.id);
    final visible = await service.getInvoices();
    expect(visible.any((invoice) => invoice.id == created.id), isFalse);

    final found = await service.findByNumber(created.invoiceNumber);
    expect(found.id, created.id);
    expect(found.isHidden, isTrue);
  });

  test('creates a customer through the service contract', () async {
    final created = await CustomerService().createCustomer(
      const Customer(
        id: '',
        name: 'New Retail Partner',
        phone: '+962 79 999 0000',
        email: 'partner@example.com',
        address: 'Amman',
      ),
    );

    expect(created.id, isNotEmpty);
    expect(created.address, 'Amman');
    expect(created.phone, '+962 79 999 0000');
  });

  test('barcode not found can be recovered by creating the product', () async {
    final settings = Get.put(SettingsController(), permanent: true);
    await settings.loadCurrenciesAndRates();
    Get.put(ProductController(), permanent: true);
    Get.put(CustomerController(), permanent: true);
    Get.put(InvoiceController(), permanent: true);
    final invoiceController = Get.put(
      CreateInvoiceController(),
      permanent: true,
    );

    final missing = await invoiceController.addByBarcode('987654321000');
    expect(missing, contains('987654321000'));

    final productResult = await Get.find<ProductController>().createProduct(
      const Product(
        id: '',
        name: 'New Barcode Product',
        barcode: '987654321000',
        price: 12.5,
        taxRate: 16,
        currencyId: '1',
      ),
    );
    expect(productResult.isSuccess, isTrue);

    invoiceController.addProduct(productResult.product!);
    expect(invoiceController.items.single.barcode, '987654321000');
  });

  test('product image upload persists its returned URL', () async {
    final service = ProductService();
    final created = await service.createProduct(
      const Product(
        id: '',
        name: 'Camera Product',
        barcode: '987654321001',
        price: 10,
        taxRate: 0,
        currencyId: '1',
      ),
    );

    final imageUrl = await service.uploadImage(created.id, 'test-image.png');
    expect(imageUrl, '/uploads/products/${created.id}.png');
  });

  test('dashboard endpoints return summary, trend, and status data', () async {
    final summary = await ApiClient.getData('/api/dashboard/summary');
    final trend = await ApiClient.getData('/api/dashboard/sales-trend');
    final status = await ApiClient.getData('/api/dashboard/invoice-status');

    expect(summary['baseCurrencyCode'], 'JOD');
    expect(trend, isA<List>());
    expect(status['approvedCount'], isA<int>());
  });
}
