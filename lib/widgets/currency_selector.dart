import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../controllers/create_invoice_controller.dart';
import '../controllers/settings_controller.dart';
import '../models/currency.dart';

class CurrencySelector extends StatelessWidget {
  final bool enabled;
  final ValueChanged<Currency?>? onChanged;

  const CurrencySelector({super.key, this.enabled = true, this.onChanged});

  @override
  Widget build(BuildContext context) {
    final settings = Get.find<SettingsController>();
    final controller = Get.find<CreateInvoiceController>();

    return Obx(() {
      final currencies = settings.currencies;
      final selected = controller.selectedCurrency.value;
      final effectiveId = selected?.id ?? settings.defaultCurrencyId;
      final resolved = settings.currencyById(effectiveId);

      if (currencies.isEmpty) {
        return const SizedBox(
          width: double.infinity,
          child: Padding(
            padding: EdgeInsets.symmetric(vertical: 12),
            child: Text(
              'No currencies are configured in Firebase yet.',
            ),
          ),
        );
      }

      // Value is the stable document ID, never the Currency object, so a
      // list reload with new instances keeps the selection valid.
      final value = resolved?.id;

      return DropdownButtonFormField<String>(
        key: ValueKey('currency-$value'),
        initialValue: value,
        isExpanded: true,
        decoration: InputDecoration(
          labelText: 'form.currency'.tr,
          prefixIcon: const Icon(Icons.currency_exchange),
        ),
        items: currencies
            .map((c) =>
                DropdownMenuItem(value: c.id, child: Text(c.displayLabel)))
            .toList(),
        onChanged: enabled
            ? (id) {
                if (id == null) return;
                final currency = settings.currencyById(id);
                controller.setCurrency(currency);
                onChanged?.call(currency);
              }
            : null,
      );
    });
  }
}
