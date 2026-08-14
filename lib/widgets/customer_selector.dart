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
        final selectedId = controller.selectedCustomerId.value;

        // Deduplicate by Firebase document ID so a repeated document never
        // produces duplicate dropdown items (identity equality would also
        // break the value lookup below).
        final uniqueById = <String, Customer>{};
        for (final customer in customers) {
          uniqueById.putIfAbsent(customer.id, () => customer);
        }
        final items = uniqueById.values
            .map(
              (customer) => DropdownMenuItem<String>(
                value: customer.id,
                child: Text(customer.name),
              ),
            )
            .toList();

        // Edit mode: keep the saved customer visible even when it was removed
        // from the loaded list, so the value still exists exactly once.
        final snapshot = controller.selectedCustomerSnapshot;
        final showSnapshot = selectedId != null &&
            snapshot != null &&
            snapshot.id == selectedId &&
            !uniqueById.containsKey(selectedId);
        if (showSnapshot) {
          items.add(
            DropdownMenuItem<String>(
              value: snapshot.id,
              child: Text(snapshot.name),
            ),
          );
        }

        final value = selectedId != null &&
                (uniqueById.containsKey(selectedId) || showSnapshot)
            ? selectedId
            : null;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            DropdownButtonFormField<String>(
              key: ValueKey('customer-$value'),
              initialValue: value,
              isExpanded: true,
              decoration: InputDecoration(
                labelText: 'form.customer'.tr,
                prefixIcon: const Icon(Icons.business_outlined),
              ),
              items: items,
              onChanged: enabled
                  ? (id) {
                      controller.selectCustomerById(id);
                      onChanged?.call(controller.selectedCustomer);
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
      currencyId: draft.currencyId,
      // Select the newly created customer by its Firebase document ID so the
      // dropdown value is always a real, stable ID.
      onCreated: (created) => invoiceController.selectCustomerById(created.id),
    );
    if (error != null) {
      Get.snackbar('form.customerCreateFailed'.tr, error);
    }
  }
}
