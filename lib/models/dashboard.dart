import 'json_helpers.dart';

class DashboardSummary {
  final String baseCurrencyCode;
  final double todaySales;
  final double thisMonthSales;
  final double totalSales;
  final int totalInvoices;
  final int approvedInvoices;
  final int pendingDrafts;
  final int cancelledInvoices;
  final int totalCustomers;
  final int totalProducts;

  const DashboardSummary({
    required this.baseCurrencyCode,
    required this.todaySales,
    required this.thisMonthSales,
    required this.totalSales,
    required this.totalInvoices,
    required this.approvedInvoices,
    required this.pendingDrafts,
    required this.cancelledInvoices,
    required this.totalCustomers,
    required this.totalProducts,
  });

  factory DashboardSummary.fromJson(Map<String, dynamic> json) =>
      DashboardSummary(
        baseCurrencyCode: toStr(json['baseCurrencyCode']),
        todaySales: toDouble(json['todaySales']),
        thisMonthSales: toDouble(json['thisMonthSales']),
        totalSales: toDouble(json['totalSales']),
        totalInvoices: toInt(json['totalInvoices']),
        approvedInvoices: toInt(json['approvedInvoices']),
        pendingDrafts: toInt(json['pendingDrafts']),
        cancelledInvoices: toInt(json['cancelledInvoices']),
        totalCustomers: toInt(json['totalCustomers']),
        totalProducts: toInt(json['totalProducts']),
      );
}

class SalesPoint {
  final DateTime date;
  final String label;
  final double total;
  final int invoiceCount;

  const SalesPoint({
    required this.date,
    required this.label,
    required this.total,
    required this.invoiceCount,
  });

  factory SalesPoint.fromJson(Map<String, dynamic> json) => SalesPoint(
    date: toDate(json['date']),
    label: toStr(json['label']),
    total: toDouble(json['total']),
    invoiceCount: toInt(json['invoiceCount']),
  );
}

class InvoiceStatusStats {
  final int draftCount;
  final double draftTotal;
  final int approvedCount;
  final double approvedTotal;
  final int cancelledCount;
  final double cancelledTotal;

  const InvoiceStatusStats({
    required this.draftCount,
    required this.draftTotal,
    required this.approvedCount,
    required this.approvedTotal,
    required this.cancelledCount,
    required this.cancelledTotal,
  });

  factory InvoiceStatusStats.fromJson(Map<String, dynamic> json) =>
      InvoiceStatusStats(
        draftCount: toInt(json['draftCount']),
        draftTotal: toDouble(json['draftTotal']),
        approvedCount: toInt(json['approvedCount']),
        approvedTotal: toDouble(json['approvedTotal']),
        cancelledCount: toInt(json['cancelledCount']),
        cancelledTotal: toDouble(json['cancelledTotal']),
      );

  int get totalCount => draftCount + approvedCount + cancelledCount;

  double get totalValue => draftTotal + approvedTotal + cancelledTotal;
}
