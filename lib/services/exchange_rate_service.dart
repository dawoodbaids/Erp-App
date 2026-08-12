import '../core/network/api_client.dart';
import '../core/network/api_config.dart';
import '../models/exchange_rate.dart';

class ExchangeRateService {
  Future<List<ExchangeRate>> getExchangeRates() async {
    final data = await ApiClient.getData(ApiConfig.exchangeRatesPath);
    return (data as List)
        .map((e) => ExchangeRate.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<ExchangeRate> updateRate(String id, double rate) async {
    final data = await ApiClient.putData(
      '${ApiConfig.exchangeRatesPath}/$id',
      data: {'rate': rate},
    );
    return ExchangeRate.fromJson(data as Map<String, dynamic>);
  }
}
