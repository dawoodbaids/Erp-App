import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;
import 'package:get/get.dart';

import '../core/routes/app_routes.dart';
import '../models/user.dart';
import '../services/auth_service.dart';
import '../services/firebase_service_exception.dart';
import '../services/firestore_initializer.dart';
import 'customer_controller.dart';
import 'dashboard_controller.dart';
import 'invoice_controller.dart';
import 'product_controller.dart';
import 'settings_controller.dart';

class AuthController extends GetxController {
  final _isAuthenticated = false.obs;
  final _isLoading = false.obs;
  final _currentUser = Rxn<User>();
  final _errorMessage = Rxn<String>();

  final _authService = AuthService();
  final _firestoreInitializer = FirestoreInitializer();
  StreamSubscription<firebase_auth.User?>? _authSubscription;
  var _authStateVersion = 0;

  bool get isAuthenticated => _isAuthenticated.value;
  bool get isLoading => _isLoading.value;
  User? get currentUser => _currentUser.value;
  String? get errorMessage => _errorMessage.value;

  @override
  void onInit() {
    super.onInit();
    _listenForAuthChanges();
  }

  Future<bool> login(String email, String password) async {
    _isLoading.value = true;
    _errorMessage.value = null;
    try {
      _currentUser.value = await _authService.login(email.trim(), password);
      _isAuthenticated.value = true;
      await _initializeFirestore();
      await _loadMasterData();
      return true;
    } on FirebaseServiceException catch (error) {
      try {
        await _authService.logout();
      } catch (_) {}
      _clearApplicationData();
      _errorMessage.value = error.message;
      return false;
    } catch (_) {
      try {
        await _authService.logout();
      } catch (_) {}
      _clearApplicationData();
      _errorMessage.value = 'Something went wrong. Please try again.';
      return false;
    } finally {
      _isLoading.value = false;
    }
  }

  Future<void> logout() async {
    _authStateVersion++;
    try {
      await _authService.logout();
      _clearApplicationData();
      Get.offAllNamed(AppRoutes.login);
    } on FirebaseServiceException catch (error) {
      _errorMessage.value = error.message;
    }
  }

  void _listenForAuthChanges() {
    try {
      _authSubscription = _authService.authStateChanges.listen((user) async {
        final version = ++_authStateVersion;
        if (user == null) {
          final wasAuthenticated = _isAuthenticated.value;
          _clearApplicationData();
          if (wasAuthenticated && Get.currentRoute != AppRoutes.login) {
            Get.offAllNamed(AppRoutes.login);
          }
          return;
        }

        try {
          final profile = await _authService.currentUser();
          if (version != _authStateVersion) return;
          _currentUser.value = profile;
          _isAuthenticated.value = _currentUser.value != null;
          if (_isAuthenticated.value) {
            unawaited(_initializeFirestore());
            unawaited(_loadMasterData());
          }
        } on FirebaseServiceException catch (error) {
          _errorMessage.value = error.message;
        }
      });
    } catch (_) {
      _errorMessage.value = 'Firebase is not configured for this Android app.';
    }
  }

  Future<void> _loadMasterData() async {
    await Get.find<SettingsController>().loadCurrenciesAndRates();
    await Future.wait([
      Get.find<CustomerController>().refresh(),
      Get.find<ProductController>().refresh(),
      Get.find<InvoiceController>().refresh(),
    ]);
  }

  Future<void> _initializeFirestore() async {
    try {
      await _firestoreInitializer.ensureSeedData();
    } on FirebaseServiceException catch (error) {
      _errorMessage.value = error.message;
    } catch (_) {
      _errorMessage.value = 'Could not initialize Firestore data.';
    }
  }

  void _clearApplicationData() {
    _currentUser.value = null;
    _isAuthenticated.value = false;
    if (Get.isRegistered<SettingsController>()) {
      final settings = Get.find<SettingsController>();
      settings.currencies.clear();
      settings.exchangeRates.clear();
      settings.taxes.clear();
    }
    if (Get.isRegistered<CustomerController>()) {
      Get.find<CustomerController>().customers.clear();
    }
    if (Get.isRegistered<ProductController>()) {
      Get.find<ProductController>().products.clear();
    }
    if (Get.isRegistered<InvoiceController>()) {
      Get.find<InvoiceController>().invoices.clear();
    }
    if (Get.isRegistered<DashboardController>()) {
      final dashboard = Get.find<DashboardController>();
      dashboard.summary.value = null;
      dashboard.salesTrend.clear();
      dashboard.invoiceStatus.value = null;
    }
  }

  @override
  void onClose() {
    _authSubscription?.cancel();
    super.onClose();
  }
}
