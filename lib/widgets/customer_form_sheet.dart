import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../controllers/settings_controller.dart';
import '../models/customer.dart';

class CustomerFormData {
  final String name;
  final String? phone;
  final String email;
  final String? address;
  final String currencyId;

  const CustomerFormData({
    required this.name,
    this.phone,
    required this.email,
    this.address,
    this.currencyId = '',
  });
}

/// Keyboard-safe customer creation sheet shared by invoices and customers.
class CustomerFormSheet extends StatefulWidget {
  final Customer? customer;

  const CustomerFormSheet({super.key, this.customer});

  static Future<CustomerFormData?> show(
    BuildContext context, {
    Customer? customer,
  }) {
    return showModalBottomSheet<CustomerFormData>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      showDragHandle: true,
      builder: (_) => CustomerFormSheet(customer: customer),
    );
  }

  @override
  State<CustomerFormSheet> createState() => _CustomerFormSheetState();
}

class _CustomerFormSheetState extends State<CustomerFormSheet> {
  final _formKey = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _phone = TextEditingController();
  final _email = TextEditingController();
  final _address = TextEditingController();
  String? _currencyId;

  bool get _isEditing => widget.customer != null;

  @override
  void initState() {
    super.initState();
    final customer = widget.customer;
    if (customer != null) {
      _name.text = customer.name;
      _phone.text = customer.phone ?? '';
      _email.text = customer.email;
      _address.text = customer.address ?? '';
      _currencyId = customer.currencyId.isNotEmpty
          ? customer.currencyId
          : Get.find<SettingsController>().defaultCurrencyId;
    } else {
      _currencyId = Get.find<SettingsController>().defaultCurrencyId;
    }
    final settings = Get.find<SettingsController>();
    if (settings.currencies.isEmpty) {
      settings.ensureCurrenciesLoaded();
    }
  }

  @override
  void dispose() {
    _name.dispose();
    _phone.dispose();
    _email.dispose();
    _address.dispose();
    super.dispose();
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    final settings = Get.find<SettingsController>();
    final currencyId = (_currencyId != null && _currencyId!.isNotEmpty)
        ? _currencyId!
        : settings.defaultCurrencyId;
    Navigator.of(context).pop(
      CustomerFormData(
        name: _name.text.trim(),
        phone: _phone.text.trim().isEmpty ? null : _phone.text.trim(),
        email: _email.text.trim(),
        address: _address.text.trim().isEmpty ? null : _address.text.trim(),
        currencyId: currencyId,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final bottomInset = MediaQuery.viewInsetsOf(context).bottom;
    final settings = Get.find<SettingsController>();

    return SingleChildScrollView(
      padding: EdgeInsets.fromLTRB(20, 4, 20, bottomInset + 20),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              (_isEditing ? 'form.editCustomer' : 'form.newCustomer').tr,
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'customers.addSubtitle'.tr,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 18),
            TextFormField(
              key: const Key('new-customer-name'),
              controller: _name,
              textCapitalization: TextCapitalization.words,
              textInputAction: TextInputAction.next,
              validator: (value) => value == null || value.trim().isEmpty
                  ? 'form.customerNameRequired'.tr
                  : null,
              decoration: InputDecoration(
                labelText: 'customers.name'.tr,
                prefixIcon: const Icon(Icons.person_outline),
              ),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _phone,
              keyboardType: TextInputType.phone,
              textInputAction: TextInputAction.next,
              decoration: InputDecoration(
                labelText: 'customers.phone'.tr,
                prefixIcon: const Icon(Icons.phone_outlined),
              ),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _email,
              keyboardType: TextInputType.emailAddress,
              textInputAction: TextInputAction.next,
              decoration: InputDecoration(
                labelText: 'customers.email'.tr,
                prefixIcon: const Icon(Icons.email_outlined),
              ),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _address,
              maxLines: 2,
              textInputAction: TextInputAction.newline,
              decoration: InputDecoration(
                labelText: 'customers.address'.tr,
                prefixIcon: const Icon(Icons.location_on_outlined),
              ),
            ),
            const SizedBox(height: 12),
            Obx(() {
              final currencies = settings.currencies;
              final effectiveId =
                  (_currencyId != null && _currencyId!.isNotEmpty)
                      ? _currencyId!
                      : settings.defaultCurrencyId;

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

              final resolved = settings.currencyById(effectiveId);
              // Value is the stable document ID so list reloads keep the
              // selection valid; null when the saved currency no longer exists.
              final value = resolved?.id;

              return DropdownButtonFormField<String>(
                key: ValueKey('customer-currency-$effectiveId'),
                initialValue: value,
                isExpanded: true,
                decoration: InputDecoration(
                  labelText: 'form.currency'.tr,
                  prefixIcon: const Icon(Icons.currency_exchange),
                ),
                items: currencies
                    .map((c) => DropdownMenuItem(
                        value: c.id, child: Text(c.displayLabel)))
                    .toList(),
                onChanged: (value) {
                  if (value != null) setState(() => _currencyId = value);
                },
              );
            }),
            const SizedBox(height: 18),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                key: const Key('new-customer-save'),
                onPressed: _submit,
                icon: const Icon(Icons.person_add_alt_1),
                label: Text(
                  (_isEditing ? 'form.updateCustomer' : 'form.createCustomer')
                      .tr,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

