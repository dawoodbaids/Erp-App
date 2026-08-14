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
    return GetX<CreateInvoiceController>(
      builder: (controller) {
        return Obx(() {
          final currencies = settings.currencies;
          final selected = controller.selectedCurrency.value;
          final effectiveId = selected?.id ?? settings.defaultCurrencyId;

          if (currencies.isEmpty) {
            return const SizedBox(
              width: double.infinity,
              child: Padding(
                padding: EdgeInsets.symmetric(vertical: 12),
                child: Text('No currencies are configured in Firebase yet.'),
              ),
            );
          }

          return DropdownButtonFormField<Currency>(
            key: ValueKey('currency-$effectiveId'),
            initialValue: settings.currencyById(effectiveId),
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
        });
      },
    );
  }
}
