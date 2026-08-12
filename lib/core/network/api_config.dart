/// Central configuration for the ERP backend API.
class ApiConfig {
  ApiConfig._();

  /// Development backend. The backend (see `backend/Properties/launchSettings.json`)
  /// listens on http://localhost:5027. The Android emulator reaches the host
  /// machine through the special alias 10.0.2.2.
  static const String baseUrl = 'http://10.0.2.2:5027';

  static const String loginPath = '/api/auth/login';

  static const String customersPath = '/api/customers';
  static const String productsPath = '/api/products';
  static const String currenciesPath = '/api/currencies';
  static const String exchangeRatesPath = '/api/exchange-rates';
  static const String invoicesPath = '/api/invoices';
  static const String dashboardPath = '/api/dashboard';
}
