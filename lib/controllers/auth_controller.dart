import 'dart:async';

import 'package:get/get.dart';

import '../core/network/api_client.dart';
import '../core/routes/app_routes.dart';
import '../core/storage/token_storage.dart';
import '../models/user.dart';
import '../services/auth_service.dart';
import 'customer_controller.dart';
import 'invoice_controller.dart';
import 'product_controller.dart';
import 'settings_controller.dart';

class AuthController extends GetxController {
  final _isAuthenticated = false.obs;
  final _isLoading = false.obs;
  final _currentUser = Rxn<User>();
  final _errorMessage = Rxn<String>();

  final _authService = AuthService();

  bool get isAuthenticated => _isAuthenticated.value;
  bool get isLoading => _isLoading.value;
  User? get currentUser => _currentUser.value;
  String? get errorMessage => _errorMessage.value;

  @override
  void onInit() {
    super.onInit();
    _restoreSession();
  }

  Future<bool> login(String username, String password) async {
    _isLoading.value = true;
    _errorMessage.value = null;
    try {
      final session = await _authService.login(username.trim(), password);
      await TokenStorage.saveSession(session);
      _currentUser.value = session.toUser;
      _isAuthenticated.value = true;
      await _loadMasterData();
      return true;
    } on ApiException catch (e) {
      _errorMessage.value = e.message;
      return false;
    } catch (_) {
      _errorMessage.value = 'Something went wrong. Please try again.';
      return false;
    } finally {
      _isLoading.value = false;
    }
  }

  Future<void> logout() async {
    await TokenStorage.clear();
    _currentUser.value = null;
    _isAuthenticated.value = false;
    Get.offAllNamed(AppRoutes.login);
  }

  Future<void> _restoreSession() async {
    final session = await TokenStorage.readSession();
    if (session == null || session.isExpired) {
      await TokenStorage.clear();
      return;
    }
    _currentUser.value = session.toUser;
    _isAuthenticated.value = true;
    unawaited(_loadMasterData());
  }

  Future<void> _loadMasterData() async {
    await Get.find<SettingsController>().loadCurrenciesAndRates();
    await Future.wait([
      Get.find<CustomerController>().refresh(),
      Get.find<ProductController>().refresh(),
      Get.find<InvoiceController>().refresh(),
    ]);
  }
}
