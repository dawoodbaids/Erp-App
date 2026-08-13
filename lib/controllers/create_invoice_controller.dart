import 'package:get/get.dart';

import '../core/utils/tax_calculator.dart';
import '../models/currency.dart';
import '../models/customer.dart';
import '../models/invoice.dart';
import '../models/invoice_item.dart';
import '../models/product.dart';
import '../services/firebase_service_exception.dart';
import '../services/invoice_service.dart';
import '../services/product_service.dart';
import 'customer_controller.dart';
import 'dashboard_controller.dart';
import 'invoice_controller.dart';
import 'settings_controller.dart';

class CreateInvoiceController extends GetxController {
  final _isEditMode = false.obs;
  final _editingId = ''.obs;
  final _isSaving = false.obs;

  final selectedCustomer = Rxn<Customer>();
  final selectedCurrency = Rxn<Currency>();
  final exchangeRate = 1.0.obs;
  final taxMode = TaxMode.exclusive.obs;
  final items = <InvoiceItem>[].obs;
  final invoiceName = ''.obs;

  bool get isEditMode => _isEditMode.value;
  String get editingId => _editingId.value;
  bool get isSaving => _isSaving.value;

  bool get isEditable => true;

  List<Customer> get customers => Get.find<CustomerController>().customers;

  List<Currency> get currencies => Get.find<SettingsController>().currencies;

  final _invoiceService = InvoiceService();
  final _productService = ProductService();

  InvoiceController get _invoiceController => Get.find<InvoiceController>();
  SettingsController get _settings => Get.find<SettingsController>();

  double get subtotal => TaxCalculator.subtotal(items, taxMode.value);
  double get tax => TaxCalculator.tax(items, taxMode.value);
  double get total => TaxCalculator.total(items, taxMode.value);

  @override
  void onInit() {
    super.onInit();
    _reset();
  }

  void _reset() {
    _isEditMode.value = false;
    _editingId.value = '';
    _isSaving.value = false;
    selectedCustomer.value = null;
    selectedCurrency.value = _settings.defaultCurrency;
    exchangeRate.value = _settings.rateFor(_settings.defaultCurrencyId);
    taxMode.value = TaxMode.exclusive;
    items.value = [];
    invoiceName.value = '';
    lastCreated.value = null;
  }

  void loadForCreate() => _reset();

  void loadForEdit(Invoice invoice) {
    _reset();
    _isEditMode.value = true;
    _editingId.value = invoice.id;
    selectedCustomer.value = invoice.customer;
    selectedCurrency.value = invoice.currency;
    exchangeRate.value = invoice.exchangeRate;
    taxMode.value = invoice.taxMode;
    items.value = List.of(invoice.items);
    invoiceName.value = invoice.invoiceName;
  }

  void setCustomer(Customer? customer) => selectedCustomer.value = customer;

  void setCurrency(Currency? currency) {
    selectedCurrency.value = currency;
    if (currency != null) {
      exchangeRate.value = _settings.rateFor(currency.id);
    }
    _recalculateItems();
  }

  void setTaxMode(TaxMode mode) => taxMode.value = mode;

  void setInvoiceName(String value) => invoiceName.value = value;

  /// Converts each item into the selected invoice currency for the UI preview.
  void _recalculateItems() {
    final invoiceCurrencyId = selectedCurrency.value?.id;
    if (invoiceCurrencyId == null) return;

    items.assignAll(
      items.map(
        (item) => _withLineTotal(
          item.copyWith(
            unitPrice: _settings.convert(
              item.originalUnitPrice,
              item.originalCurrencyId,
              invoiceCurrencyId,
            ),
          ),
        ),
      ),
    );
  }

  InvoiceItem _withLineTotal(InvoiceItem item) {
    return item.copyWith(
      lineTotal: TaxCalculator.lineTotal(item, taxMode.value),
    );
  }

  void addProduct(Product product) {
    final invoiceCurrencyId =
        selectedCurrency.value?.id ?? _settings.defaultCurrencyId;

    final existingIndex = items.indexWhere((i) => i.productId == product.id);
    if (existingIndex >= 0) {
      final current = items[existingIndex];
      items[existingIndex] = _withLineTotal(
        current.copyWith(quantity: current.quantity + 1),
      );
    } else {
      final originalCurrency = _settings.currencyById(product.currencyId);
      final item = InvoiceItem(
        id: 'IT-${DateTime.now().microsecondsSinceEpoch}',
        productId: product.id,
        productName: product.name,
        barcode: product.barcode,
        originalUnitPrice: product.price,
        originalCurrencyId: product.currencyId,
        originalCurrencyCode: originalCurrency?.code ?? '',
        quantity: 1,
        unitPrice: _settings.convert(
          product.price,
          product.currencyId,
          invoiceCurrencyId,
        ),
        taxRate: product.taxRate,
        lineTotal: 0,
      );
      items.add(_withLineTotal(item));
    }
  }

  bool _isBarcodeLookupInProgress = false;

  Future<String?> addByBarcode(String barcode) async {
    final normalized = barcode.trim();
    if (normalized.isEmpty) return 'Enter a barcode first.';

    final existingIndex = items.indexWhere((i) => i.barcode == normalized);
    if (existingIndex >= 0) {
      final current = items[existingIndex];
      items[existingIndex] = _withLineTotal(
        current.copyWith(quantity: current.quantity + 1),
      );
      return null;
    }

    if (_isBarcodeLookupInProgress) {
      return null;
    }
    _isBarcodeLookupInProgress = true;
    try {
      final product = await _productService.getProductByBarcode(normalized);
      addProduct(product);
      return null;
    } on FirebaseServiceException catch (e) {
      if (e.code == 'not-found') {
        return 'No product found with barcode $normalized.';
      }
      return e.message;
    } catch (_) {
      return 'Could not look up the barcode. Please try again.';
    } finally {
      _isBarcodeLookupInProgress = false;
    }
  }

  void removeItem(String itemId) {
    items.removeWhere((i) => i.id == itemId);
  }

  void updateQuantity(String itemId, double quantity) {
    final index = items.indexWhere((i) => i.id == itemId);
    if (index < 0) return;
    items[index] = _withLineTotal(items[index].copyWith(quantity: quantity));
  }

  final lastCreated = Rxn<Invoice>();

  String? validate() {
    if (invoiceName.value.trim().isEmpty) {
      return 'Invoice name is required';
    }
    if (selectedCustomer.value == null) return 'Please select a customer';
    if (selectedCustomer.value!.id.isEmpty) {
      return 'The selected customer is invalid';
    }
    if (selectedCurrency.value == null) return 'Please select a currency';
    if (selectedCurrency.value!.id.isEmpty) {
      return 'The selected currency is invalid';
    }
    if (items.isEmpty) return 'Add at least one item to the invoice';
    for (final item in items) {
      if (item.productId.isEmpty) {
        return 'A product on this invoice is invalid';
      }
      if (item.quantity <= 0) {
        return 'Quantity must be greater than zero';
      }
      if (item.unitPrice < 0) {
        return 'Unit price cannot be negative';
      }
    }
    return null;
  }

  Future<String?> save() async {
    final error = validate();
    if (error != null) return error;

    _isSaving.value = true;
    try {
      if (isEditMode) {
        final existing = _invoiceController.byId(_editingId.value);
        if (existing == null) return 'The invoice could not be found.';
        final invoice = Invoice(
          id: _editingId.value,
          invoiceNumber: existing.invoiceNumber,
          invoiceName: invoiceName.value.trim(),
          isHidden: existing.isHidden,
          customer: selectedCustomer.value!,
          currency: selectedCurrency.value!,
          exchangeRate: exchangeRate.value,
          taxMode: taxMode.value,
          status: InvoiceStatus.draft,
          items: List.unmodifiable(items),
          subtotal: subtotal,
          taxAmount: tax,
          totalAmount: total,
          createdAt: existing.createdAt,
        );
        await _invoiceService.updateInvoice(invoice);
        await _invoiceController.refresh();
        await _refreshDashboard();
        return null;
      }

      final invoice = Invoice(
        id: '',
        invoiceNumber: '',
        invoiceName: invoiceName.value.trim(),
        customer: selectedCustomer.value!,
        currency: selectedCurrency.value!,
        exchangeRate: exchangeRate.value,
        taxMode: taxMode.value,
        status: InvoiceStatus.draft,
        items: List.unmodifiable(items),
        subtotal: subtotal,
        taxAmount: tax,
        totalAmount: total,
        createdAt: DateTime.now(),
      );

      lastCreated.value = await _invoiceService.createInvoice(invoice);
      await _invoiceController.refresh();
      await _refreshDashboard();
      return null;
    } on FirebaseServiceException catch (e) {
      return e.message;
    } catch (_) {
      return 'Could not create the invoice. Please try again.';
    } finally {
      _isSaving.value = false;
    }
  }

  Future<void> _refreshDashboard() async {
    if (Get.isRegistered<DashboardController>()) {
      await Get.find<DashboardController>().refresh();
    }
  }
}
