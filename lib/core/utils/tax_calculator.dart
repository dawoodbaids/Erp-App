import '../../models/invoice.dart';
import '../../models/invoice_item.dart';

class TaxCalculator {
  static double _round(double value) => (value * 100).round() / 100;

  static double netAmount(InvoiceItem item, TaxMode mode) {
    final net = _round(item.quantity * item.unitPrice);
    if (mode == TaxMode.exclusive) {
      return net;
    }
    return _round(net / (1 + item.taxRate / 100));
  }

  static double taxAmount(InvoiceItem item, TaxMode mode) {
    final net = _round(item.quantity * item.unitPrice);
    if (mode == TaxMode.exclusive) {
      return _round(net * item.taxRate / 100);
    }
    return _round(net - _round(net / (1 + item.taxRate / 100)));
  }

  static double lineTotal(InvoiceItem item, TaxMode mode) {
    return _round(netAmount(item, mode) + taxAmount(item, mode));
  }

  static double subtotal(List<InvoiceItem> items, TaxMode mode) {
    return _round(
      items.fold<double>(0, (sum, item) => sum + netAmount(item, mode)),
    );
  }

  static double tax(List<InvoiceItem> items, TaxMode mode) {
    return _round(
      items.fold<double>(0, (sum, item) => sum + taxAmount(item, mode)),
    );
  }

  static double total(List<InvoiceItem> items, TaxMode mode) {
    return _round(subtotal(items, mode) + tax(items, mode));
  }
}
