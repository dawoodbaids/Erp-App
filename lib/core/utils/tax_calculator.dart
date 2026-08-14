import '../../models/invoice.dart';
import '../../models/invoice_item.dart';

/// Invoice amount calculations.
///
/// The flow is always:
///   product original price -> convert to invoice currency -> subtotal
///   -> discount -> tax -> final total
///
/// Tax is calculated once on the whole invoice, never per item:
///   taxableAmount = subtotal - discountAmount
///   taxAmount     = taxableAmount * taxRate / 100         (Exclusive)
///   taxAmount     = taxableAmount - taxableAmount / 1.16  (Inclusive)
///   total         = subtotal - discountAmount + taxAmount (Exclusive)
///   total         = subtotal - discountAmount             (Inclusive)
class TaxCalculator {
  static double _round(double value) => (value * 100).round() / 100;

  /// Invoice subtotal: the sum of every item's gross line value
  /// (`quantity * unitPrice`) after conversion into the invoice currency.
  static double subtotal(List<InvoiceItem> items) {
    var sum = 0.0;
    for (final item in items) {
      sum += _round(item.quantity * item.unitPrice);
    }
    return _round(sum);
  }

  /// The amount tax is calculated on: the subtotal minus the discount.
  static double taxableAmount(double subtotal, double discountAmount) {
    return _round(subtotal - discountAmount);
  }

  static double taxAmount(
    double subtotal,
    double discountAmount,
    double taxRate,
    TaxMode mode,
  ) {
    final taxable = taxableAmount(subtotal, discountAmount);
    if (mode == TaxMode.inclusive) {
      return _round(taxable - _round(taxable / (1 + taxRate / 100)));
    }
    return _round(taxable * taxRate / 100);
  }

  static double total(
    double subtotal,
    double discountAmount,
    double taxRate,
    TaxMode mode,
  ) {
    final taxable = taxableAmount(subtotal, discountAmount);
    if (mode == TaxMode.inclusive) {
      return _round(taxable);
    }
    return _round(taxable + taxAmount(subtotal, discountAmount, taxRate, mode));
  }

  /// A single item's line value in the invoice currency. Per-item tax is not
  /// computed here; tax is an invoice-level figure (see [taxAmount]).
  static double lineTotal(InvoiceItem item, TaxMode mode) {
    return _round(item.quantity * item.unitPrice);
  }
}
