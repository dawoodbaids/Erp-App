import '../core/utils/firestore_helpers.dart';

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

  factory InvoiceItem.fromMap(
    Map<String, dynamic> data, {
    String fallbackId = '',
  }) {
    return InvoiceItem(
      id: firestoreString(data['id']).isEmpty
          ? fallbackId
          : firestoreString(data['id']),
      productId: firestoreString(data['productId']),
      productName: firestoreString(data['productName']),
      barcode: firestoreString(data['barcode']),
      originalUnitPrice: firestoreDouble(data['originalUnitPrice']),
      originalCurrencyId: firestoreString(data['originalCurrencyId']),
      originalCurrencyCode: firestoreString(data['originalCurrencyCode']),
      quantity: firestoreDouble(data['quantity']),
      unitPrice: firestoreDouble(data['unitPrice']),
      taxRate: firestoreDouble(data['taxRate']),
      lineTotal: firestoreDouble(data['lineTotal']),
    );
  }

  Map<String, dynamic> toFirestore() => {
    'id': id,
    'productId': productId,
    'productName': productName,
    'barcode': barcode,
    'originalUnitPrice': originalUnitPrice,
    'originalCurrencyId': originalCurrencyId,
    'originalCurrencyCode': originalCurrencyCode,
    'quantity': quantity,
    'unitPrice': unitPrice,
    'taxRate': taxRate,
    'lineTotal': lineTotal,
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
