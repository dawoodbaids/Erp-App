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

  /// The selected customer's Firebase document ID. The ID is the stable
  /// dropdown value; the full [Customer] is resolved from the loaded list.
  final selectedCustomerId = Rxn<String>();

  /// Snapshot kept for edit mode when the invoice's customer is no longer in
  /// the loaded list (e.g. deleted from Firebase). Only ever set from an
  /// existing invoice in [loadForEdit].
  Customer? _selectedSnapshot;

  final selectedCurrency = Rxn<Currency>();
  final exchangeRate = 1.0.obs;
  final taxMode = TaxMode.exclusive.obs;
  final discountAmount = 0.0.obs;
  final items = <InvoiceItem>[].obs;
  final invoiceName = ''.obs;

  bool get isEditMode => _isEditMode.value;
  String get editingId => _editingId.value;
  bool get isSaving => _isSaving.value;

  bool get isEditable => true;

  List<Customer> get customers => Get.find<CustomerController>().customers;

  /// The selected customer resolved from the current list by document ID,
  /// falling back to the edit-mode snapshot. Never compares object identity.
  Customer? get selectedCustomer {
    final id = selectedCustomerId.value;
    if (id == null || id.isEmpty) return null;
    final fromList = Get.find<CustomerController>().byId(id);
    if (fromList != null) return fromList;
    if (_selectedSnapshot != null && _selectedSnapshot!.id == id) {
      return _selectedSnapshot;
    }
    return null;
  }

  /// The edit-mode snapshot, exposed so dropdowns can keep a removed
  /// customer's item visible while editing its invoice.
  Customer? get selectedCustomerSnapshot => _selectedSnapshot;

  List<Currency> get currencies => Get.find<SettingsController>().currencies;

  final _invoiceService = InvoiceService();
  final _productService = ProductService();

  InvoiceController get _invoiceController => Get.find<InvoiceController>();
  SettingsController get _settings => Get.find<SettingsController>();

  double get subtotal => TaxCalculator.subtotal(items);

  /// The tax rate applied to the invoice (from Firebase).
  double get taxRate => _settings.defaultTaxRate;

  double get tax => TaxCalculator.taxAmount(
        subtotal,
        discountAmount.value,
        taxRate,
        taxMode.value,
      );

  double get total => TaxCalculator.total(
        subtotal,
        discountAmount.value,
        taxRate,
        taxMode.value,
      );

  /// True when the selected invoice currency needs an exchange rate from
  /// Firebase that is not configured. Saving is blocked in [validate].
  bool get isExchangeRateMissing {
    final currency = selectedCurrency.value;
    if (currency == null) return false;
    final base = _settings.defaultCurrency;
    if (base != null &&
        currency.code.toLowerCase() == base.code.toLowerCase()) {
      return false;
    }
    return _settings.rateForCurrencyAny(currency.id, currency.code) == null;
  }

  @override
  void onInit() {
    super.onInit();
    _reset();
    ever(_settings.currencies, (_) => _selectDefaultCurrencyIfNone());
    ever(
      Get.find<CustomerController>().customers,
      (_) => _syncCustomerSelection(),
    );
    if (_settings.currencies.isEmpty) {
      _settings.ensureCurrenciesLoaded();
    }
  }

  /// Clears a selection that no longer exists in the loaded customers so the
  /// dropdown value is always null or present exactly once.
  void _syncCustomerSelection() {
    final id = selectedCustomerId.value;
    if (id == null || id.isEmpty) return;
    if (Get.find<CustomerController>().byId(id) != null) return;
    if (_selectedSnapshot != null && _selectedSnapshot!.id == id) return;
    selectedCustomerId.value = null;
    _selectedSnapshot = null;
  }

  void _selectDefaultCurrencyIfNone() {
    if (selectedCurrency.value != null) return;
    final defaultCurrency = _settings.defaultCurrency;
    if (defaultCurrency != null) setCurrency(defaultCurrency);
  }

  void _reset() {
    _isEditMode.value = false;
    _editingId.value = '';
    _isSaving.value = false;
    selectedCustomerId.value = null;
    _selectedSnapshot = null;
    selectedCurrency.value = _settings.defaultCurrency;
    exchangeRate.value =
        _settings.rateForCurrency(_settings.defaultCurrencyId) ?? 0;
    taxMode.value = TaxMode.exclusive;
    discountAmount.value = 0;
    items.value = [];
    invoiceName.value = '';
    lastCreated.value = null;
  }

  void loadForCreate() => _reset();

  void loadForEdit(Invoice invoice) {
    _reset();
    _isEditMode.value = true;
    _editingId.value = invoice.id;
    selectedCustomerId.value = invoice.customer.id.isEmpty
        ? null
        : invoice.customer.id;
    _selectedSnapshot = invoice.customer.id.isEmpty ? null : invoice.customer;
    selectedCurrency.value = invoice.currency;
    exchangeRate.value = invoice.exchangeRate;
    taxMode.value = invoice.taxMode;
    discountAmount.value = invoice.discountAmount;
    items.value = List.of(invoice.items);
    invoiceName.value = invoice.invoiceName;
  }

  /// Selects the customer with the given Firebase document ID and applies the
  /// customer's currency when it is configured.
  void selectCustomerById(String? id) {
    if (id == null || id.isEmpty) {
      selectedCustomerId.value = null;
      _selectedSnapshot = null;
      return;
    }
    final customer = Get.find<CustomerController>().byId(id);
    if (customer == null) {
      selectedCustomerId.value = null;
      _selectedSnapshot = null;
      return;
    }
    selectedCustomerId.value = id;
    if (customer.currencyId.isNotEmpty) {
      final currency = _settings.currencyById(customer.currencyId);
      if (currency != null) setCurrency(currency);
    }
  }

  void setCurrency(Currency? currency) {
    selectedCurrency.value = currency;
    if (currency == null) {
      exchangeRate.value = 0;
    } else {
      exchangeRate.value = _settings.rateForCurrency(currency.id) ?? 0;
    }
    _recalculateItems();
  }

  void setTaxMode(TaxMode mode) => taxMode.value = mode;

  void setDiscount(double value) => discountAmount.value = value;

  void setInvoiceName(String value) => invoiceName.value = value;

  /// Converts each item into the selected invoice currency for the UI preview
  /// using exchange rates from Firebase only.
  void _recalculateItems() {
    final invoiceCurrencyId = selectedCurrency.value?.id;
    if (invoiceCurrencyId == null) return;

    items.assignAll(
      items.map(
        (item) => _withLineTotal(
          item.copyWith(
            unitPrice:
                _settings.tryConvert(
                  item.originalUnitPrice,
                  item.originalCurrencyId,
                  invoiceCurrencyId,
                ) ??
                item.originalUnitPrice,
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
        unitPrice:
            _settings.tryConvert(
              product.price,
              product.currencyId,
              invoiceCurrencyId,
            ) ??
            product.price,
        taxRate: _settings.defaultTaxRate,
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
    if (selectedCustomer == null) return 'Please select a customer';
    if (selectedCustomer!.id.isEmpty) {
      return 'The selected customer is invalid';
    }
    if (selectedCurrency.value == null) return 'Please select a currency';
    if (selectedCurrency.value!.id.isEmpty) {
      return 'The selected currency is invalid';
    }
    if (isExchangeRateMissing) {
      final currency = selectedCurrency.value!;
      final base = _settings.defaultCurrency;
      return 'Exchange rate is not available for '
          '${currency.code} → ${base?.code ?? ''}.';
    }
    if (items.isEmpty) return 'Add at least one item to the invoice';
    if (discountAmount.value < 0) {
      return 'Discount cannot be negative';
    }
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
      final itemRateMissing = _itemRateMissing(item);
      if (itemRateMissing != null) return itemRateMissing;
    }
    return null;
  }

  /// Returns an error message when the item's product currency cannot be
  /// converted into the invoice currency with the rates configured in
  /// Firebase. Never invents a rate.
  String? _itemRateMissing(InvoiceItem item) {
    final invoiceCurrency = selectedCurrency.value;
    if (invoiceCurrency == null) return null;
    if (item.originalCurrencyId.isEmpty) return null;
    if (item.originalCurrencyId == invoiceCurrency.id) return null;
    if (item.originalCurrencyCode.isNotEmpty &&
        item.originalCurrencyCode.toLowerCase() ==
            invoiceCurrency.code.toLowerCase()) {
      return null;
    }
    final rate = _settings.getExchangeRateAny(
      item.originalCurrencyId,
      item.originalCurrencyCode,
      invoiceCurrency.id,
      invoiceCurrency.code,
    );
    if (rate == null) {
      final fromCode =
          _settings.currencyById(item.originalCurrencyId)?.code ??
          item.originalCurrencyCode;
      return 'Exchange rate is not available for '
          '$fromCode → ${invoiceCurrency.code}.';
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
          customer: selectedCustomer!,
          currency: selectedCurrency.value!,
          exchangeRate: exchangeRate.value,
          taxRate: existing.taxRate,
          taxMode: taxMode.value,
          status: InvoiceStatus.draft,
          discountAmount: discountAmount.value,
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
        customer: selectedCustomer!,
        currency: selectedCurrency.value!,
        exchangeRate: exchangeRate.value,
        taxRate: _settings.defaultTaxRate,
        taxMode: taxMode.value,
        status: InvoiceStatus.draft,
        discountAmount: discountAmount.value,
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
