import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../controllers/create_invoice_controller.dart';
import '../models/currency.dart';

class CurrencySelector extends StatelessWidget {
  final bool enabled;
  final ValueChanged<Currency?>? onChanged;

  const CurrencySelector({super.key, this.enabled = true, this.onChanged});

  @override
  Widget build(BuildContext context) {
    return GetX<CreateInvoiceController>(
      builder: (controller) {
        final currencies = controller.currencies;
        final selected = controller.selectedCurrency.value;

        return DropdownButtonFormField<Currency>(
          key: ValueKey('currency-${selected?.id ?? 'none'}'),
          initialValue: selected,
          isExpanded: true,
           decoration: InputDecoration(
             labelText: 'form.currency'.tr,
             prefixIcon: const Icon(Icons.currency_exchange),
           ),
          items: currencies
              .map((c) => DropdownMenuItem(value: c, child: Text(c.code)))
              .toList(),
          onChanged: enabled
              ? (value) {
                  controller.setCurrency(value);
                  onChanged?.call(value);
                }
              : null,
        );
      },
    );
  }
}
