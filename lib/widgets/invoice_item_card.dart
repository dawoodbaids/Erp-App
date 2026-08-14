import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';

import '../controllers/product_controller.dart';
import '../core/utils/formatters.dart';
import '../core/utils/product_image.dart';
import '../models/invoice_item.dart';
import 'ui/app_card.dart';

class InvoiceItemCard extends StatefulWidget {
  final InvoiceItem item;
  final bool editable;
  final String currencyCode;
  final ValueChanged<double>? onQuantityChanged;
  final VoidCallback? onRemove;

  const InvoiceItemCard({
    super.key,
    required this.item,
    required this.editable,
    this.currencyCode = '',
    this.onQuantityChanged,
    this.onRemove,
  });

  @override
  State<InvoiceItemCard> createState() => _InvoiceItemCardState();
}

class _InvoiceItemCardState extends State<InvoiceItemCard> {
  late final TextEditingController _quantityController;

  static String _display(double value) {
    if (value == value.truncateToDouble()) {
      return value.toStringAsFixed(0);
    }
    return value.toStringAsFixed(2);
  }

  @override
  void initState() {
    super.initState();
    _quantityController = TextEditingController(
      text: _display(widget.item.quantity),
    );
  }

  @override
  void didUpdateWidget(covariant InvoiceItemCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.item.quantity != oldWidget.item.quantity) {
      _quantityController.text = _display(widget.item.quantity);
    }
  }

  @override
  void dispose() {
    _quantityController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final textTheme = theme.textTheme;
    final lineTotal = widget.item.lineTotal;
    final showsConversion =
        widget.item.originalCurrencyCode.isNotEmpty &&
        widget.item.originalUnitPrice > 0 &&
        widget.item.originalCurrencyCode != widget.currencyCode;

    return AppCard(
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _productImage(context),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.item.productName,
                      style: textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${'details.barcode'.tr}: ${widget.item.barcode}',
                      style: textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              if (widget.editable && widget.onRemove != null)
                IconButton(
                  tooltip: 'form.removeItem'.tr,
                  onPressed: widget.onRemove,
                  icon: Icon(
                    Icons.delete_outline,
                    color: theme.colorScheme.error,
                  ),
                ),
            ],
          ),
          const Divider(height: 22),
          Row(
            children: [
              Expanded(
                child: _buildLabeledField(
                  context,
                  label: 'form.itemQuantity'.tr,
                  controller: _quantityController,
                  onChanged: (value) {
                    if (widget.onQuantityChanged != null) {
                      widget.onQuantityChanged!(value);
                    }
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: Text(
                  'form.unitPrice'.tr,
                  style: textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
              if (showsConversion) ...[
                Icon(
                  Icons.lock_outline,
                  size: 14,
                  color: theme.colorScheme.onSurfaceVariant,
                ),
                const SizedBox(width: 6),
              ],
              Text(
                '${widget.currencyCode} ${Formatters.amount(widget.item.unitPrice)}',
                style: textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
          if (showsConversion) ...[
            const SizedBox(height: 4),
            Row(
              children: [
                Expanded(
                  child: Text(
                    'form.originalPrice'.tr,
                    style: textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ),
                Text(
                  '${widget.item.originalCurrencyCode} '
                  '${Formatters.amount(widget.item.originalUnitPrice)}',
                  style: textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                    decoration: TextDecoration.lineThrough,
                  ),
                ),
              ],
            ),
          ],
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: Text(
                  'form.taxRate'.tr,
                  style: textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
              Icon(
                Icons.lock_outline,
                size: 14,
                color: theme.colorScheme.onSurfaceVariant,
              ),
              const SizedBox(width: 6),
              Text(
                '${Formatters.rate(widget.item.taxRate)}%',
                style: textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: Text(
                  'details.lineTotal'.tr,
                  style: textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
              Text(
                '${widget.currencyCode} ${Formatters.amount(lineTotal)}',
                style: textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w800,
                  color: theme.colorScheme.primary,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _productImage(BuildContext context) {
    final product = Get.find<ProductController>().byId(widget.item.productId);
    return buildProductImage(product?.image, size: 34, context: context);
  }

  Widget _buildLabeledField(
    BuildContext context, {
    required String label,
    required TextEditingController controller,
    required ValueChanged<double> onChanged,
  }) {
    final theme = Theme.of(context);
    return TextField(
      controller: controller,
      enabled: widget.editable,
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[0-9.]'))],
      style: TextStyle(
        color: widget.editable
            ? theme.colorScheme.onSurface
            : theme.colorScheme.onSurfaceVariant,
      ),
      decoration: InputDecoration(
        labelText: label,
        isDense: true,
        filled: true,
      ),
      onChanged: (text) {
        final value = double.tryParse(text);
        if (value != null) {
          onChanged(value);
        }
      },
    );
  }
}
