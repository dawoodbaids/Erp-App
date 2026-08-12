import 'package:flutter/material.dart';

import '../models/invoice.dart';
import 'ui/invoice_card.dart';

/// Compact invoice list row used on the dashboard and invoices tab.
@Deprecated('Use InvoiceCard instead')
class InvoiceRow extends StatelessWidget {
  final Invoice invoice;
  final bool dense;

  const InvoiceRow({super.key, required this.invoice, this.dense = false});

  @override
  Widget build(BuildContext context) {
    return InvoiceCard(invoice: invoice, dense: dense);
  }
}
