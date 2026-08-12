import 'package:get/get.dart';

import '../core/network/api_client.dart';
import '../models/invoice.dart';
import '../models/product.dart';
import '../services/invoice_service.dart';
import 'product_controller.dart';

class InvoiceController extends GetxController {
  final invoices = <Invoice>[].obs;
  final _searchQuery = ''.obs;
  final _statusFilter = Rxn<InvoiceStatus>();
  final _isLoading = false.obs;
  final _errorMessage = Rxn<String>();
  final _isLoadingDetails = false.obs;

  final _invoiceService = InvoiceService();

  String get searchQuery => _searchQuery.value;
  InvoiceStatus? get statusFilter => _statusFilter.value;
  bool get isLoading => _isLoading.value;
  String? get errorMessage => _errorMessage.value;
  bool get isLoadingDetails => _isLoadingDetails.value;

  List<Invoice> get filteredInvoices {
    final query = _searchQuery.value.trim().toLowerCase();
    return invoices.where((invoice) {
      if (invoice.isHidden) return false;
      final matchesStatus =
          _statusFilter.value == null || invoice.status == _statusFilter.value;
      if (!matchesStatus) return false;
      if (query.isEmpty) return true;
      return invoice.invoiceNumber.toLowerCase().contains(query) ||
          invoice.invoiceName.toLowerCase().contains(query) ||
          invoice.customer.name.toLowerCase().contains(query);
    }).toList();
  }

  void setSearchQuery(String value) => _searchQuery.value = value;

  void setStatusFilter(InvoiceStatus? status) => _statusFilter.value = status;

  void clearSearch() => _searchQuery.value = '';

  Invoice? byId(String id) {
    for (final invoice in invoices) {
      if (invoice.id == id) return invoice;
    }
    return null;
  }

  String nextInvoiceNumber() {
    var maxNumber = 0;
    for (final invoice in invoices) {
      final match = RegExp(r'INV-(\d+)').firstMatch(invoice.invoiceNumber);
      if (match != null) {
        final n = int.tryParse(match.group(1)!) ?? 0;
        if (n > maxNumber) maxNumber = n;
      }
    }
    return 'INV-${(maxNumber + 1).toString().padLeft(6, '0')}';
  }

  void addInvoice(Invoice invoice) {
    invoices.insert(0, invoice);
  }

  void updateInvoice(Invoice invoice) {
    final index = invoices.indexWhere((i) => i.id == invoice.id);
    if (index < 0) return;
    invoices[index] = invoice;
  }

  Future<String?> approve(String id) async {
    try {
      final updated = await _invoiceService.approve(id);
      _replaceInvoice(updated);
      await refresh();
      return null;
    } on ApiException catch (e) {
      return e.message;
    } catch (_) {
      return 'Could not approve the invoice. Please try again.';
    }
  }

  Future<String?> cancel(String id) async {
    try {
      final updated = await _invoiceService.cancel(id);
      _replaceInvoice(updated);
      await refresh();
      return null;
    } on ApiException catch (e) {
      return e.message;
    } catch (_) {
      return 'Could not cancel the invoice. Please try again.';
    }
  }

  /// Hides the invoice from the default list (soft remove). Returns an error
  /// message, or null on success.
  Future<String?> hide(String id) async {
    try {
      final updated = await _invoiceService.hide(id);
      _replaceInvoice(updated);
      await refresh();
      return null;
    } on ApiException catch (e) {
      return e.message;
    } catch (_) {
      return 'Could not remove the invoice. Please try again.';
    }
  }

  /// Looks up an invoice by its exact number (e.g. INV-000007). Returns the
  /// invoice, or null with an error message when not found.
  Future<(Invoice?, String?)> findByNumber(String number) async {
    try {
      final invoice = await _invoiceService.findByNumber(number);
      _replaceInvoice(invoice);
      return (invoice, null);
    } on ApiException catch (e) {
      return (null, e.message);
    } catch (_) {
      return (null, 'Could not search for the invoice. Please try again.');
    }
  }

  void _replaceInvoice(Invoice invoice) {
    final index = invoices.indexWhere((i) => i.id == invoice.id);
    if (index >= 0) {
      invoices[index] = invoice;
    } else {
      invoices.insert(0, invoice);
    }
  }

  @override
  Future<void> refresh() async {
    _isLoading.value = true;
    _errorMessage.value = null;
    try {
      invoices.value = await _invoiceService.getInvoices();
    } on ApiException catch (e) {
      _errorMessage.value = e.message;
    } catch (_) {
      _errorMessage.value = 'Could not load invoices. Please try again.';
    } finally {
      _isLoading.value = false;
    }
  }

  Future<Invoice?> loadDetails(String id) async {
    if (_isLoadingDetails.value) return byId(id);
    _isLoadingDetails.value = true;
    try {
      final full = _withBarcodes(await _invoiceService.getInvoice(id));
      final index = invoices.indexWhere((i) => i.id == id);
      if (index >= 0) {
        invoices[index] = full;
      } else {
        invoices.insert(0, full);
      }
      return full;
    } on ApiException {
      return byId(id);
    } catch (_) {
      return byId(id);
    } finally {
      _isLoadingDetails.value = false;
    }
  }

  Invoice _withBarcodes(Invoice invoice) {
    final products = Get.find<ProductController>().products;
    final items = invoice.items.map((item) {
      final product = _productById(products, item.productId);
      if (product == null || product.barcode == item.barcode) return item;
      return item.copyWith(barcode: product.barcode);
    }).toList();
    return invoice.copyWith(items: items);
  }

  Product? _productById(List<Product> products, String id) {
    for (final product in products) {
      if (product.id == id) return product;
    }
    return null;
  }
}
