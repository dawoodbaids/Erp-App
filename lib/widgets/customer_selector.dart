import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../controllers/customer_controller.dart';
import '../controllers/create_invoice_controller.dart';
import '../models/customer.dart';
import 'customer_form_sheet.dart';

class CustomerSelector extends StatelessWidget {
  final bool enabled;
  final ValueChanged<Customer?>? onChanged;

  const CustomerSelector({super.key, this.enabled = true, this.onChanged});

  @override
  Widget build(BuildContext context) {
    return GetX<CreateInvoiceController>(
      builder: (controller) {
        final customers = controller.customers;
        final selected = controller.selectedCustomer.value;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            DropdownButtonFormField<Customer>(
              key: ValueKey('customer-${selected?.id ?? 'none'}'),
              initialValue: selected,
              isExpanded: true,
              decoration: InputDecoration(
                labelText: 'form.customer'.tr,
                prefixIcon: const Icon(Icons.business_outlined),
              ),
              items: customers
                  .map((c) => DropdownMenuItem(value: c, child: Text(c.name)))
                  .toList(),
              onChanged: enabled
                  ? (value) {
                      controller.setCustomer(value);
                      onChanged?.call(value);
                    }
                  : null,
            ),
            if (enabled) ...[
              const SizedBox(height: 8),
              Align(
                alignment: AlignmentDirectional.centerStart,
                child: TextButton.icon(
                  key: const Key('new-customer-button'),
                  onPressed: () => _createCustomer(context, controller),
                  icon: const Icon(Icons.person_add_alt_1, size: 18),
                  label: Text('form.newCustomer'.tr),
                ),
              ),
            ],
          ],
        );
      },
    );
  }

  Future<void> _createCustomer(
    BuildContext context,
    CreateInvoiceController invoiceController,
  ) async {
    final draft = await CustomerFormSheet.show(context);
    if (draft == null) return;

    final customerController = Get.find<CustomerController>();
    final error = await customerController.createCustomer(
      name: draft.name,
      phone: draft.phone,
      email: draft.email,
      address: draft.address,
    );
    if (error != null) {
      Get.snackbar('form.customerCreateFailed'.tr, error);
      return;
    }

    final created = customerController.customers.firstWhere(
      (customer) => customer.name.toLowerCase() == draft.name.toLowerCase(),
    );
    invoiceController.setCustomer(created);
    onChanged?.call(created);
  }
}
