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

  int get totalCount => draftCount + approvedCount + cancelledCount;

  double get totalValue => draftTotal + approvedTotal + cancelledTotal;
}
