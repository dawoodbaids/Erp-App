import 'currency.dart';
import 'customer.dart';
import 'invoice_item.dart';
import 'json_helpers.dart';

enum InvoiceStatus { draft, approved, cancelled }

extension InvoiceStatusX on InvoiceStatus {
  String get label {
    switch (this) {
      case InvoiceStatus.draft:
        return 'Draft';
      case InvoiceStatus.approved:
        return 'Approved';
      case InvoiceStatus.cancelled:
        return 'Cancelled';
    }
  }

  String get translationKey {
    switch (this) {
      case InvoiceStatus.draft:
        return 'status.draft';
      case InvoiceStatus.approved:
        return 'status.approved';
      case InvoiceStatus.cancelled:
        return 'status.cancelled';
    }
  }
}

InvoiceStatus parseInvoiceStatus(String value) {
  switch (value.toLowerCase()) {
    case 'approved':
      return InvoiceStatus.approved;
    case 'cancelled':
      return InvoiceStatus.cancelled;
    case 'draft':
    default:
      return InvoiceStatus.draft;
  }
}

enum TaxMode { exclusive, inclusive }

extension TaxModeX on TaxMode {
  String get label {
    switch (this) {
      case TaxMode.exclusive:
        return 'Tax Exclusive';
      case TaxMode.inclusive:
        return 'Tax Inclusive';
    }
  }

  String get translationKey {
    switch (this) {
      case TaxMode.exclusive:
        return 'details.taxExclusive';
      case TaxMode.inclusive:
        return 'details.taxInclusive';
    }
  }
}

TaxMode parseTaxMode(String value) =>
    value.toLowerCase() == 'inclusive' ? TaxMode.inclusive : TaxMode.exclusive;

class Invoice {
  final String id;
  final String invoiceNumber;
  final String invoiceName;
  final bool isHidden;
  final Customer customer;
  final Currency currency;
  final String baseCurrencyCode;
  final double exchangeRate;
  final TaxMode taxMode;
  final InvoiceStatus status;
  final List<InvoiceItem> items;
  final double subtotal;
  final double taxAmount;
  final double totalAmount;
  final DateTime createdAt;
  final DateTime? approvedAt;
  final DateTime? cancelledAt;

  const Invoice({
    required this.id,
    required this.invoiceNumber,
    this.invoiceName = '',
    this.isHidden = false,
    required this.customer,
    required this.currency,
    this.baseCurrencyCode = '',
    required this.exchangeRate,
    required this.taxMode,
    required this.status,
    required this.items,
    required this.subtotal,
    required this.taxAmount,
    required this.totalAmount,
    required this.createdAt,
    this.approvedAt,
    this.cancelledAt,
  });

  factory Invoice.fromJson(Map<String, dynamic> json) => Invoice(
    id: toStr(json['id']),
    invoiceNumber: toStr(json['invoiceNumber']),
    invoiceName: toStr(json['invoiceName']),
    isHidden: toBool(json['isHidden']),
    customer: Customer(
      id: toStr(json['customerId']),
      name: toStr(json['customerName']),
    ),
    currency: Currency(
      id: toStr(json['currencyId']),
      code: toStr(json['currencyCode']),
      name: toStr(json['currencyCode']),
      symbol: toStr(json['currencyCode']),
    ),
    baseCurrencyCode: toStr(json['baseCurrencyCode']),
    exchangeRate: toDouble(json['exchangeRate']),
    taxMode: parseTaxMode(toStr(json['taxMode'])),
    status: parseInvoiceStatus(toStr(json['status'])),
    items:
        (json['items'] as List?)
            ?.map((e) => InvoiceItem.fromJson(e as Map<String, dynamic>))
            .toList() ??
        const [],
    subtotal: toDouble(json['subtotal']),
    taxAmount: toDouble(json['taxAmount']),
    totalAmount: toDouble(json['totalAmount']),
    createdAt: toDate(json['createdAt']),
    approvedAt: toDateOrNull(json['approvedAt']),
    cancelledAt: toDateOrNull(json['cancelledAt']),
  );

  Map<String, dynamic> toJson() => {
    'id': int.tryParse(id) ?? id,
    'invoiceNumber': invoiceNumber,
    'invoiceName': invoiceName,
    'isHidden': isHidden,
    'customerId': int.tryParse(customer.id) ?? customer.id,
    'customerName': customer.name,
    'currencyId': int.tryParse(currency.id) ?? currency.id,
    'currencyCode': currency.code,
    'exchangeRate': exchangeRate,
    'taxMode': taxMode == TaxMode.inclusive ? 'Inclusive' : 'Exclusive',
    'status': status.label,
    'subtotal': subtotal,
    'taxAmount': taxAmount,
    'totalAmount': totalAmount,
    'createdAt': createdAt.toIso8601String(),
    'approvedAt': approvedAt?.toIso8601String(),
    'cancelledAt': cancelledAt?.toIso8601String(),
    'items': items.map((i) => i.toJson()).toList(),
  };

  Map<String, dynamic> toCreateRequest() => {
    'customerId': int.tryParse(customer.id),
    'currencyId': int.tryParse(currency.id),
    'taxMode': taxMode == TaxMode.inclusive ? 'Inclusive' : 'Exclusive',
    'invoiceName': invoiceName,
    'invoiceDate': createdAt.toUtc().toIso8601String(),
    'items': items.map((i) => i.toCreateRequest()).toList(),
  };

  bool get isEditable => status == InvoiceStatus.draft;

  Invoice copyWith({
    String? invoiceName,
    bool? isHidden,
    Customer? customer,
    Currency? currency,
    double? exchangeRate,
    TaxMode? taxMode,
    InvoiceStatus? status,
    List<InvoiceItem>? items,
    double? subtotal,
    double? taxAmount,
    double? totalAmount,
    DateTime? approvedAt,
    DateTime? cancelledAt,
  }) {
    return Invoice(
      id: id,
      invoiceNumber: invoiceNumber,
      invoiceName: invoiceName ?? this.invoiceName,
      isHidden: isHidden ?? this.isHidden,
      customer: customer ?? this.customer,
      currency: currency ?? this.currency,
      exchangeRate: exchangeRate ?? this.exchangeRate,
      taxMode: taxMode ?? this.taxMode,
      status: status ?? this.status,
      items: items ?? this.items,
      subtotal: subtotal ?? this.subtotal,
      taxAmount: taxAmount ?? this.taxAmount,
      totalAmount: totalAmount ?? this.totalAmount,
      createdAt: createdAt,
      approvedAt: approvedAt ?? this.approvedAt,
      cancelledAt: cancelledAt ?? this.cancelledAt,
    );
  }
}
