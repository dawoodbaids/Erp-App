import '../core/network/api_client.dart';
import '../core/network/api_config.dart';
import '../models/currency.dart';

class CurrencyService {
  Future<List<Currency>> getCurrencies() async {
    final data = await ApiClient.getData(ApiConfig.currenciesPath);
    return (data as List)
        .map((e) => Currency.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<Currency> setBaseCurrency(String id) async {
    final data = await ApiClient.putData(
      '${ApiConfig.currenciesPath}/$id/set-base',
    );
    return Currency.fromJson(data as Map<String, dynamic>);
  }
}
