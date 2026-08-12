import 'json_helpers.dart';

class InvoiceItem {
  final String id;
  final String productId;
  final String productName;
  final String barcode;
  final double originalUnitPrice;
  final String originalCurrencyId;
  final String originalCurrencyCode;
  final double quantity;
  final double unitPrice;
  final double taxRate;
  final double lineTotal;

  const InvoiceItem({
    required this.id,
    required this.productId,
    required this.productName,
    required this.barcode,
    this.originalUnitPrice = 0,
    this.originalCurrencyId = '',
    this.originalCurrencyCode = '',
    required this.quantity,
    required this.unitPrice,
    required this.taxRate,
    required this.lineTotal,
  });

  factory InvoiceItem.fromJson(Map<String, dynamic> json) => InvoiceItem(
    id: toStr(json['id']),
    productId: toStr(json['productId']),
    productName: toStr(json['productName']),
    barcode: toStr(json['barcode']),
    originalUnitPrice: toDouble(
      json['originalUnitPrice'] ?? json['unitPrice'],
    ),
    originalCurrencyId: toStr(json['originalCurrencyId']),
    originalCurrencyCode: toStr(json['originalCurrencyCode']),
    quantity: toDouble(json['quantity']),
    unitPrice: toDouble(json['unitPrice']),
    taxRate: toDouble(json['taxRate']),
    lineTotal: toDouble(json['subtotal'] ?? json['lineTotal']),
  );

  Map<String, dynamic> toJson() => {
    'id': int.tryParse(id) ?? id,
    'productId': int.tryParse(productId) ?? productId,
    'productName': productName,
    'barcode': barcode,
    'originalUnitPrice': originalUnitPrice,
    'originalCurrencyId': int.tryParse(originalCurrencyId) ??
        originalCurrencyId,
    'originalCurrencyCode': originalCurrencyCode,
    'quantity': quantity,
    'unitPrice': unitPrice,
    'taxRate': taxRate,
    'lineTotal': lineTotal,
  };

  /// The backend is the source of truth for pricing. It converts the product's
  /// original price and copies the product tax rate, so the client only sends
  /// the product reference and quantity.
  Map<String, dynamic> toCreateRequest() => {
    'productId': int.tryParse(productId),
    'quantity': quantity,
  };

  InvoiceItem copyWith({
    String? barcode,
    double? originalUnitPrice,
    String? originalCurrencyId,
    String? originalCurrencyCode,
    double? quantity,
    double? unitPrice,
    double? lineTotal,
  }) {
    return InvoiceItem(
      id: id,
      productId: productId,
      productName: productName,
      barcode: barcode ?? this.barcode,
      originalUnitPrice: originalUnitPrice ?? this.originalUnitPrice,
      originalCurrencyId: originalCurrencyId ?? this.originalCurrencyId,
      originalCurrencyCode:
          originalCurrencyCode ?? this.originalCurrencyCode,
      quantity: quantity ?? this.quantity,
      unitPrice: unitPrice ?? this.unitPrice,
      taxRate: taxRate,
      lineTotal: lineTotal ?? this.lineTotal,
    );
  }
}
