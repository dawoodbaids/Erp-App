import '../core/network/api_client.dart';
import '../core/network/api_config.dart';
import '../models/dashboard.dart';
import '../models/invoice.dart';

class InvoiceService {
  Future<List<Invoice>> getInvoices() async {
    final data = await ApiClient.getData(ApiConfig.invoicesPath);
    return (data as List)
        .map((e) => Invoice.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<Invoice> getInvoice(String id) async {
    final data = await ApiClient.getData('${ApiConfig.invoicesPath}/$id');
    return Invoice.fromJson(data as Map<String, dynamic>);
  }

  Future<Invoice> findByNumber(String number) async {
    final data = await ApiClient.getData(
      '${ApiConfig.invoicesPath}/number/$number',
    );
    return Invoice.fromJson(data as Map<String, dynamic>);
  }

  Future<Invoice> createInvoice(Invoice draft) async {
    final data = await ApiClient.postData(
      ApiConfig.invoicesPath,
      data: draft.toCreateRequest(),
    );
    return Invoice.fromJson(data as Map<String, dynamic>);
  }

  Future<Invoice> approve(String id) async {
    final data = await ApiClient.postData(
      '${ApiConfig.invoicesPath}/$id/approve',
    );
    return Invoice.fromJson(data as Map<String, dynamic>);
  }

  Future<Invoice> cancel(String id) async {
    final data = await ApiClient.postData(
      '${ApiConfig.invoicesPath}/$id/cancel',
    );
    return Invoice.fromJson(data as Map<String, dynamic>);
  }

  Future<Invoice> hide(String id) async {
    final data = await ApiClient.postData(
      '${ApiConfig.invoicesPath}/$id/hide',
    );
    return Invoice.fromJson(data as Map<String, dynamic>);
  }

  Future<DashboardSummary> getSummary() async {
    final data = await ApiClient.getData('${ApiConfig.dashboardPath}/summary');
    return DashboardSummary.fromJson(data as Map<String, dynamic>);
  }

  Future<List<SalesPoint>> getSalesTrend({int months = 6}) async {
    final data = await ApiClient.getData(
      '${ApiConfig.dashboardPath}/sales-trend',
      queryParameters: {'months': months},
    );
    return (data as List)
        .map((e) => SalesPoint.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<InvoiceStatusStats> getInvoiceStatus() async {
    final data = await ApiClient.getData(
      '${ApiConfig.dashboardPath}/invoice-status',
    );
    return InvoiceStatusStats.fromJson(data as Map<String, dynamic>);
  }
}
