import 'package:flutter/material.dart';

import '../models/invoice.dart';
import 'ui/status_chip.dart';

/// Backwards-compatible alias for [StatusChip].
class StatusBadge extends StatelessWidget {
  final InvoiceStatus status;
  final bool showIcon;

  const StatusBadge({super.key, required this.status, this.showIcon = true});

  @override
  Widget build(BuildContext context) {
    return StatusChip(status: status, showIcon: showIcon);
  }
}
