import 'package:get/get.dart';

import '../core/network/api_client.dart';
import '../models/customer.dart';
import '../services/customer_service.dart';

class CustomerController extends GetxController {
  final customers = <Customer>[].obs;

  final _isLoading = false.obs;
  final _errorMessage = Rxn<String>();

  final _customerService = CustomerService();

  bool get isLoading => _isLoading.value;
  String? get errorMessage => _errorMessage.value;

  Customer? byId(String id) {
    for (final customer in customers) {
      if (customer.id == id) return customer;
    }
    return null;
  }

  /// Creates a customer on the backend and adds it to the in-memory list.
  /// Returns an error message, or null on success.
  Future<String?> createCustomer({
    required String name,
    String? phone,
    String email = '',
    String? address,
  }) async {
    final normalized = name.trim();
    if (normalized.isEmpty) return 'Customer name is required';

    for (final existing in customers) {
      if (existing.name.toLowerCase() == normalized.toLowerCase()) {
        return 'A customer with this name already exists.';
      }
    }

    try {
      final created = await _customerService.createCustomer(
        Customer(
          id: '',
          name: normalized,
          phone: phone?.trim().isEmpty ?? true ? null : phone?.trim(),
          email: email.trim(),
          address: address?.trim().isEmpty ?? true ? null : address?.trim(),
          createdAt: DateTime.now(),
        ),
      );
      customers.add(created);
      return null;
    } on ApiException catch (e) {
      return e.message;
    } catch (_) {
      return 'Could not create the customer. Please try again.';
    }
  }

  @override
  Future<void> refresh() async {
    _isLoading.value = true;
    _errorMessage.value = null;
    try {
      customers.value = await _customerService.getCustomers();
    } on ApiException catch (e) {
      _errorMessage.value = e.message;
    } catch (_) {
      _errorMessage.value = 'Could not load customers. Please try again.';
    } finally {
      _isLoading.value = false;
    }
  }
}
