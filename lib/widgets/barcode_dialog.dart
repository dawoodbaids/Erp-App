import 'dart:io';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_mlkit_barcode_scanning/google_mlkit_barcode_scanning.dart';
import 'package:image_picker/image_picker.dart';

import 'barcode_scanner_page.dart';

class BarcodeDialog extends StatefulWidget {
  final String? initialValue;

  const BarcodeDialog({super.key, this.initialValue});

  static Future<String?> show(BuildContext context, {String? initialValue}) {
    return showDialog<String>(
      context: context,
      builder: (_) => BarcodeDialog(initialValue: initialValue),
    );
  }

  @override
  State<BarcodeDialog> createState() => _BarcodeDialogState();
}

class _BarcodeDialogState extends State<BarcodeDialog> {
  final _picker = ImagePicker();
  final _barcodeScanner = BarcodeScanner();
  late final TextEditingController _controller;
  bool _scanning = false;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initialValue ?? '');
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _scan() async {
    final typed = _controller.text.trim();
    if (typed.isNotEmpty) {
      Navigator.of(context).pop(typed);
      return;
    }

    final result = await BarcodeScannerPage.show(context);
    if (!mounted) return;
    if (result != null && result.isNotEmpty) {
      Navigator.of(context).pop(result);
    }
  }

  Future<void> _uploadImage() async {
    setState(() => _scanning = true);

    XFile? picked;
    try {
      picked = await _picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 85,
        maxWidth: 1600,
      );
    } catch (_) {
      if (mounted) setState(() => _scanning = false);
      return;
    }

    if (!mounted) return;
    if (picked == null) {
      setState(() => _scanning = false);
      return;
    }

    try {
      final inputImage = InputImage.fromFilePath(picked.path);
      final barcodes = await _barcodeScanner.processImage(inputImage);

      if (!mounted) return;

      if (barcodes.isNotEmpty) {
        final value = barcodes.first.rawValue;
        if (value != null && value.isNotEmpty) {
          final confirmed = await _showConfirmDialog(picked.path, value);
          if (!mounted) return;
          if (confirmed == true) {
            Navigator.of(context).pop(value);
            return;
          }
        }
      } else {
        _showError('barcode.noImageBarcode'.tr);
      }
    } catch (_) {
      if (mounted) {
        _showError('barcode.imageError'.tr);
      }
    }

    if (mounted) setState(() => _scanning = false);
  }

  void _showError(String message) {
    setState(() => _scanning = false);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), duration: const Duration(seconds: 3)),
    );
  }

  Future<bool?> _showConfirmDialog(String imagePath, String barcode) async {
    return showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('barcode.foundTitle'.tr),
        content: SizedBox(
          width: double.maxFinite,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: Image.file(
                  File(imagePath),
                  width: 280,
                  height: 180,
                  fit: BoxFit.contain,
                ),
              ),
              const SizedBox(height: 14),
              Text(
                barcode,
                style: Theme.of(ctx).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1.5,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'barcode.foundMessage'.tr,
                style: Theme.of(ctx).textTheme.bodySmall,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text('common.cancel'.tr),
          ),
          FilledButton.icon(
            onPressed: () => Navigator.of(ctx).pop(true),
            icon: const Icon(Icons.check),
            label: Text('form.addProduct'.tr),
          ),
        ],
      ),
    );
  }

  void _submit() {
    final value = _controller.text.trim();
    if (value.isNotEmpty) {
      Navigator.of(context).pop(value);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return AlertDialog(
      title: Row(
        children: [
          Icon(Icons.qr_code_scanner, color: theme.colorScheme.primary),
          const SizedBox(width: 10),
          Expanded(child: Text('barcode.title'.tr)),
        ],
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'barcode.message'.tr,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 14),
          TextField(
            controller: _controller,
            autofocus: true,
            keyboardType: TextInputType.number,
            textInputAction: TextInputAction.done,
            onChanged: (_) => setState(() {}),
            onSubmitted: (_) => _submit(),
            decoration: const InputDecoration(
              labelText: 'Barcode',
              prefixIcon: Icon(Icons.qr_code),
            ),
          ),
          const SizedBox(height: 12),
          if (_scanning)
            const Padding(
              padding: EdgeInsets.only(bottom: 8),
              child: LinearProgressIndicator(),
            ),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _scanning ? null : _scan,
                  icon: const Icon(Icons.qr_code_scanner),
                  label: Text('barcode.title'.tr),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _scanning ? null : _uploadImage,
                  icon: const Icon(Icons.image_outlined),
                  label: Text('productForm.gallery'.tr),
                ),
              ),
            ],
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: _scanning ? null : () => Navigator.of(context).pop(null),
          child: Text('common.cancel'.tr),
        ),
        FilledButton.icon(
          onPressed: _controller.text.trim().isNotEmpty && !_scanning
              ? _submit
              : null,
          icon: const Icon(Icons.check),
          label: Text('barcode.enter'.tr),
        ),
      ],
    );
  }
}
