import 'package:get/get.dart';

import '../models/customer.dart';
import '../services/firebase_service_exception.dart';
import '../services/customer_service.dart';
import 'dashboard_controller.dart';

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

  /// Creates a customer in Firestore and adds it to the visible list.
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
      await _refreshDashboard();
      return null;
    } on FirebaseServiceException catch (e) {
      return e.message;
    } catch (_) {
      return 'Could not create the customer. Please try again.';
    }
  }

  Future<Customer?> loadDetails(String id) async {
    if (isLoading) return byId(id);
    _isLoading.value = true;
    _errorMessage.value = null;
    try {
      final customer = await _customerService.getCustomer(id);
      final index = customers.indexWhere((item) => item.id == id);
      if (index >= 0) {
        customers[index] = customer;
      } else {
        customers.insert(0, customer);
      }
      return customer;
    } on FirebaseServiceException catch (e) {
      _errorMessage.value = e.message;
      return byId(id);
    } catch (_) {
      _errorMessage.value = 'Could not load the customer. Please try again.';
      return byId(id);
    } finally {
      _isLoading.value = false;
    }
  }

  Future<String?> updateCustomer(Customer customer) async {
    final normalized = customer.name.trim();
    if (normalized.isEmpty) return 'Customer name is required';

    try {
      final updated = await _customerService.updateCustomer(
        Customer(
          id: customer.id,
          name: normalized,
          phone: customer.phone,
          email: customer.email.trim(),
          address: customer.address,
          isActive: customer.isActive,
          createdAt: customer.createdAt,
        ),
      );
      final index = customers.indexWhere((item) => item.id == updated.id);
      if (index >= 0) {
        customers[index] = updated;
      } else {
        customers.insert(0, updated);
      }
      await _refreshDashboard();
      return null;
    } on FirebaseServiceException catch (e) {
      return e.message;
    } catch (_) {
      return 'Could not save the customer. Please try again.';
    }
  }

  Future<String?> deleteCustomer(String id) async {
    try {
      await _customerService.deleteCustomer(id);
      customers.removeWhere((customer) => customer.id == id);
      await _refreshDashboard();
      return null;
    } on FirebaseServiceException catch (e) {
      return e.message;
    } catch (_) {
      return 'Could not delete the customer. Please try again.';
    }
  }

  Future<void> _refreshDashboard() async {
    if (Get.isRegistered<DashboardController>()) {
      await Get.find<DashboardController>().refresh();
    }
  }

  @override
  Future<void> refresh() async {
    _isLoading.value = true;
    _errorMessage.value = null;
    try {
      customers.value = await _customerService.getCustomers();
    } on FirebaseServiceException catch (e) {
      _errorMessage.value = e.message;
    } catch (_) {
      _errorMessage.value = 'Could not load customers. Please try again.';
    } finally {
      _isLoading.value = false;
    }
  }
}
