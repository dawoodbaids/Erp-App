import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';

import '../controllers/product_controller.dart';
import '../controllers/settings_controller.dart';
import '../core/utils/product_image.dart';
import '../models/currency.dart';
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
  final _imagePicker = ImagePicker();
  late final TextEditingController _nameController;
  late final TextEditingController _barcodeController;
  late final TextEditingController _priceController;
  late final TextEditingController _taxRateController;
  late String? _image;
  String? _pickedImagePath;
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
      text: product == null ? '' : _number(product.taxRate),
    );
    _image = product?.image;
    _currencyId = product?.currencyId ?? settings.defaultCurrencyId;
    _isActive = product?.isActive ?? true;
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

  Future<void> _pickImage() async {
    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      showDragHandle: true,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.photo_library_outlined),
              title: Text('productForm.gallery'.tr),
              onTap: () => Navigator.of(context).pop(ImageSource.gallery),
            ),
            ListTile(
              leading: const Icon(Icons.photo_camera_outlined),
              title: Text('productForm.camera'.tr),
              onTap: () => Navigator.of(context).pop(ImageSource.camera),
            ),
            if (_pickedImagePath != null)
              ListTile(
                leading: Icon(
                  Icons.delete_outline,
                  color: Theme.of(context).colorScheme.error,
                ),
                title: Text('productForm.removeImage'.tr),
                onTap: () {
                  setState(() => _pickedImagePath = null);
                  Navigator.of(context).pop();
                },
              ),
          ],
        ),
      ),
    );
    if (source == null) return;

    try {
      final picked = await _imagePicker.pickImage(
        source: source,
        imageQuality: 85,
        maxWidth: 1600,
      );
      if (picked != null && mounted) {
        setState(() {
          _pickedImagePath = picked.path;
          _image = null;
        });
      }
    } catch (_) {
      if (mounted) {
        Get.snackbar('productForm.imageFailed'.tr, 'error.retry'.tr);
      }
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
    final draft = Product(
      id: widget.product?.id ?? '',
      name: _nameController.text.trim(),
      barcode: _barcodeController.text.trim(),
      image: _image,
      price: double.parse(_priceController.text),
      taxRate: double.parse(_taxRateController.text),
      currencyId: _currencyId,
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

    if (_pickedImagePath != null) {
      final imageError = await controller.uploadImage(
        result.product!.id,
        _pickedImagePath!,
      );
      if (!mounted) return;
      if (imageError != null) {
        setState(() => _saving = false);
        Get.snackbar('productForm.imageFailed'.tr, imageError);
        return;
      }
    }

    Navigator.of(context).pop(true);
  }

  Widget _imagePreview(BuildContext context) {
    if (_pickedImagePath != null) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(10),
        child: Image.file(
          File(_pickedImagePath!),
          width: 64,
          height: 64,
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) =>
              buildProductImage(null, size: 64, context: context),
        ),
      );
    }
    return buildProductImage(_image, size: 64, context: context);
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
                keyboardType: TextInputType.number,
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp(r'[0-9]')),
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
              DropdownButtonFormField<Currency>(
                key: ValueKey('currency-$_currencyId'),
                initialValue: settings.currencyById(_currencyId),
                isExpanded: true,
                decoration: InputDecoration(
                  labelText: 'productForm.currency'.tr,
                  prefixIcon: const Icon(Icons.currency_exchange),
                ),
                items: settings.currencies
                    .map((c) => DropdownMenuItem(value: c, child: Text(c.code)))
                    .toList(),
                onChanged: (value) {
                  if (value != null) setState(() => _currencyId = value.id);
                },
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  _imagePreview(context),
                  const SizedBox(width: 14),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: _saving ? null : _pickImage,
                      icon: const Icon(Icons.add_a_photo_outlined),
                      label: Text(
                        _pickedImagePath == null
                            ? 'productForm.selectImage'.tr
                            : 'productForm.replaceImage'.tr,
                      ),
                    ),
                  ),
                ],
              ),
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
