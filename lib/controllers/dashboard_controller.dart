import 'package:get/get.dart';

import '../models/dashboard.dart';
import '../services/dashboard_service.dart';
import '../services/firebase_service_exception.dart';

/// Loads the aggregated numbers, sales trend and invoice status breakdown
/// from the dashboard endpoints.
class DashboardController extends GetxController {
  final summary = Rxn<DashboardSummary>();
  final salesTrend = <SalesPoint>[].obs;
  final invoiceStatus = Rxn<InvoiceStatusStats>();

  final _isLoading = false.obs;
  final _errorMessage = Rxn<String>();

  final _dashboardService = DashboardService();

  bool get isLoading => _isLoading.value;
  String? get errorMessage => _errorMessage.value;

  @override
  Future<void> refresh() async {
    _isLoading.value = true;
    _errorMessage.value = null;
    try {
      final results = await Future.wait([
        _dashboardService.getSummary(),
        _dashboardService.getSalesTrend(),
        _dashboardService.getInvoiceStatus(),
      ]);
      summary.value = results[0] as DashboardSummary;
      salesTrend.value = results[1] as List<SalesPoint>;
      invoiceStatus.value = results[2] as InvoiceStatusStats;
    } on FirebaseServiceException catch (e) {
      _errorMessage.value = e.message;
    } catch (_) {
      _errorMessage.value = 'Could not load the dashboard. Please try again.';
    } finally {
      _isLoading.value = false;
    }
  }
}
