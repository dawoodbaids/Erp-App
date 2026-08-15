import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';

import '../controllers/product_controller.dart';
import '../controllers/settings_controller.dart';
import '../models/product.dart';
import 'barcode_dialog.dart';

class ProductFormDialog extends StatefulWidget {
  final Product? product;
  final String? initialBarcode;

  const ProductFormDialog({super.key, this.product, this.initialBarcode});

  static Future<bool?> show(
    BuildContext context, {
    Product? product,
    String? initialBarcode,
  }) {
    return showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (_) =>
          ProductFormDialog(product: product, initialBarcode: initialBarcode),
    );
  }

  @override
  State<ProductFormDialog> createState() => _ProductFormDialogState();
}

class _ProductFormDialogState extends State<ProductFormDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final TextEditingController _barcodeController;
  late final TextEditingController _priceController;
  late final TextEditingController _taxRateController;
  late String? _image;
  late String _currencyId;
  late bool _isActive;
  bool _saving = false;

  bool get _isEditing => widget.product != null;

  @override
  void initState() {
    super.initState();
    final settings = Get.find<SettingsController>();
    final product = widget.product;

    _nameController = TextEditingController(text: product?.name ?? '');
    _barcodeController = TextEditingController(
      text: product?.barcode ?? widget.initialBarcode ?? '',
    );
    _priceController = TextEditingController(
      text: product == null ? '' : _number(product.price),
    );
    _taxRateController = TextEditingController(
      text: product == null ? _number(settings.defaultTaxRate) : _number(product.taxRate),
    );
    _image = product?.image;
    _currencyId = product?.currencyId ?? settings.defaultCurrencyId;
    _isActive = product?.isActive ?? true;
    if (settings.currencies.isEmpty) {
      settings.ensureCurrenciesLoaded();
    }
  }

  static String _number(double value) {
    if (value == value.truncateToDouble()) {
      return value.toStringAsFixed(0);
    }
    return value.toStringAsFixed(2);
  }

  @override
  void dispose() {
    _nameController.dispose();
    _barcodeController.dispose();
    _priceController.dispose();
    _taxRateController.dispose();
    super.dispose();
  }

  Future<void> _scanBarcode() async {
    final result = await BarcodeDialog.show(context);
    if (result != null && result.isNotEmpty) {
      _barcodeController.text = result;
    }
  }

  String? _validateName(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'productForm.nameRequired'.tr;
    }
    return null;
  }

  String? _validateBarcode(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'productForm.barcodeRequired'.tr;
    }
    return null;
  }

  String? _validatePrice(String? value) {
    final number = double.tryParse(value ?? '');
    if (number == null) return 'productForm.priceInvalid'.tr;
    if (number < 0) return 'productForm.priceNegative'.tr;
    return null;
  }

  String? _validateTaxRate(String? value) {
    final number = double.tryParse(value ?? '');
    if (number == null) return 'productForm.taxRateInvalid'.tr;
    if (number < 0 || number > 100) return 'productForm.taxRateRange'.tr;
    return null;
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    final controller = Get.find<ProductController>();
    final settings = Get.find<SettingsController>();
    final selectedCurrency = settings.currencyById(_currencyId);
    final draft = Product(
      id: widget.product?.id ?? '',
      name: _nameController.text.trim(),
      barcode: _barcodeController.text.trim(),
      image: _image,
      price: double.parse(_priceController.text),
      taxRate: double.parse(_taxRateController.text),
      currencyId: _currencyId,
      currencyCode: selectedCurrency?.code ?? _currencyId,
      isActive: _isActive,
    );

    setState(() => _saving = true);
    final result = _isEditing
        ? await controller.updateProduct(draft)
        : await controller.createProduct(draft);
    if (!mounted) return;
    if (!result.isSuccess) {
      setState(() => _saving = false);
      Get.snackbar(
        'productForm.saveFailed'.tr,
        result.error ?? 'error.title'.tr,
      );
      return;
    }

    Navigator.of(context).pop(true);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final settings = Get.find<SettingsController>();

    return AlertDialog(
      title: Text(
        _isEditing ? 'productForm.editTitle'.tr : 'productForm.addTitle'.tr,
      ),
      content: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: _nameController,
                validator: _validateName,
                decoration: InputDecoration(
                  labelText: 'productForm.name'.tr,
                  prefixIcon: const Icon(Icons.shopping_bag_outlined),
                ),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _barcodeController,
                validator: _validateBarcode,
                keyboardType: TextInputType.text,
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp(r'[A-Za-z0-9-]')),
                  LengthLimitingTextInputFormatter(64),
                ],
                decoration: InputDecoration(
                  labelText: 'productForm.barcode'.tr,
                  prefixIcon: const Icon(Icons.qr_code),
                  suffixIcon: IconButton(
                    tooltip: 'productForm.scanBarcode'.tr,
                    onPressed: _scanBarcode,
                    icon: const Icon(Icons.qr_code_scanner),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _priceController,
                      validator: _validatePrice,
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      inputFormatters: [
                        FilteringTextInputFormatter.allow(RegExp(r'[0-9.]')),
                      ],
                      decoration: InputDecoration(
                        labelText: 'productForm.price'.tr,
                        prefixIcon: const Icon(Icons.attach_money),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextFormField(
                      controller: _taxRateController,
                      validator: _validateTaxRate,
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      inputFormatters: [
                        FilteringTextInputFormatter.allow(RegExp(r'[0-9.]')),
                      ],
                      decoration: InputDecoration(
                        labelText: 'productForm.taxRate'.tr,
                        prefixIcon: const Icon(Icons.percent),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Obx(() {
                final currencies = settings.currencies;
                final effectiveId = (_currencyId.isNotEmpty)
                    ? _currencyId
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
                // selection valid; null when the saved currency no longer
                // exists in the configured currencies.
                final value = resolved?.id;

                return DropdownButtonFormField<String>(
                  key: ValueKey('product-currency-$effectiveId'),
                  initialValue: value,
                  isExpanded: true,
                  validator: (value) =>
                      value == null ? 'productForm.currencyRequired'.tr : null,
                  decoration: InputDecoration(
                    labelText: 'productForm.currency'.tr,
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
              const SizedBox(height: 6),
              Row(
                children: [
                  Switch(
                    value: _isActive,
                    onChanged: _saving
                        ? null
                        : (value) => setState(() => _isActive = value),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    'productForm.active'.tr,
                    style: theme.textTheme.bodyMedium,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _saving ? null : () => Navigator.of(context).pop(false),
          child: Text('common.cancel'.tr),
        ),
        FilledButton.icon(
          onPressed: _saving ? null : _save,
          icon: _saving
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Icon(Icons.save_outlined),
          label: Text('common.save'.tr),
        ),
      ],
    );
  }
}
