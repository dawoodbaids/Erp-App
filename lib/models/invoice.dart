import '../core/utils/firestore_helpers.dart';
import 'currency.dart';
import 'customer.dart';
import 'invoice_item.dart';

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
    default:
      return InvoiceStatus.draft;
  }
}

enum TaxMode { exclusive, inclusive }

extension TaxModeX on TaxMode {
  String get translationKey => this == TaxMode.inclusive
      ? 'details.taxInclusive'
      : 'details.taxExclusive';
}

TaxMode parseTaxMode(String value) =>
    value.toLowerCase() == 'inclusive' ? TaxMode.inclusive : TaxMode.exclusive;

class Invoice {
  final String id;

  /// Sequential, unique invoice number shown to users, e.g. `INV-2026-0001`.
  /// The Firebase document ID is stored separately in [id] and never shown.
  final String invoiceNumber;
  final String invoiceName;
  final bool isHidden;
  final Customer customer;
  final Currency currency;
  final String baseCurrencyCode;
  final double exchangeRate;

  /// The tax rate (from Firebase) used when the invoice was created.
  final double taxRate;
  final TaxMode taxMode;
  final InvoiceStatus status;

  /// Discount applied before tax, in the invoice currency. Stored per
  /// invoice so later edits never change an existing invoice.
  final double discountAmount;
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
    this.taxRate = 0,
    required this.taxMode,
    required this.status,
    this.discountAmount = 0,
    required this.items,
    required this.subtotal,
    required this.taxAmount,
    required this.totalAmount,
    required this.createdAt,
    this.approvedAt,
    this.cancelledAt,
  });

  /// Human-readable number shown in the UI. New numbers preserve their
  /// leading zeroes; legacy numeric values keep their `#1` style.
  String get displayNumber =>
      RegExp(r'^\d{4,}$').hasMatch(invoiceNumber)
          ? invoiceNumber
          : (invoiceNumber.startsWith('INV-')
              ? invoiceNumber
              : '#$invoiceNumber');

  factory Invoice.fromFirestore(String id, Map<String, dynamic> data) {
    final items = (data['items'] as List?)
            ?.whereType<Map>()
            .indexed
            .map(
              (entry) => InvoiceItem.fromMap(
                Map<String, dynamic>.from(entry.$2),
                fallbackId: 'item-${entry.$1}',
              ),
            )
            .toList() ??
        const <InvoiceItem>[];
    return Invoice(
      id: id,
      invoiceNumber: firestoreInvoiceNumberLabel(data['invoiceNumber']),
      invoiceName: firestoreString(data['invoiceName']),
      isHidden: firestoreBool(data['isHidden']),
      customer: Customer(
        id: firestoreString(data['customerId']),
        name: firestoreString(data['customerName']),
      ),
      currency: Currency(
        id: firestoreString(data['currencyId']),
        code: firestoreString(data['currencyCode']),
        name: firestoreString(data['currencyName']),
        symbol: firestoreString(data['currencySymbol']),
      ),
      baseCurrencyCode: firestoreString(data['baseCurrencyCode']),
      exchangeRate: firestoreDouble(data['exchangeRate']),
      taxRate: firestoreDouble(data['taxRate']),
      taxMode: parseTaxMode(firestoreString(data['taxMode'])),
      status: parseInvoiceStatus(firestoreString(data['status'])),
      discountAmount: firestoreDouble(data['discountAmount']),
      items: items,
      subtotal: firestoreDouble(data['subtotal']),
      taxAmount: firestoreDouble(data['taxAmount']),
      totalAmount: firestoreDouble(data['totalAmount']),
      createdAt: requiredFirestoreDate(data['createdAt']),
      approvedAt: firestoreDate(data['approvedAt']),
      cancelledAt: firestoreDate(data['cancelledAt']),
    );
  }

  Map<String, dynamic> toFirestore() => {
    'invoiceNumber': invoiceNumber,
    'invoiceName': invoiceName,
    'isHidden': isHidden,
    'customerId': customer.id,
    'customerName': customer.name,
    'currencyId': currency.id,
    'currencyCode': currency.code,
    'currencyName': currency.name,
    'currencySymbol': currency.symbol,
    'baseCurrencyCode': baseCurrencyCode,
    'exchangeRate': exchangeRate,
    'taxRate': taxRate,
    'taxMode': taxMode == TaxMode.inclusive ? 'Inclusive' : 'Exclusive',
    'status': status.label,
    'discountAmount': discountAmount,
    'items': items.map((item) => item.toFirestore()).toList(),
    'subtotal': subtotal,
    'taxAmount': taxAmount,
    'totalAmount': totalAmount,
    'createdAt': createdAt,
    'approvedAt': approvedAt,
    'cancelledAt': cancelledAt,
  };

  bool get isEditable => status == InvoiceStatus.draft;

  Invoice copyWith({
    String? invoiceName,
    bool? isHidden,
    Customer? customer,
    Currency? currency,
    double? exchangeRate,
    double? taxRate,
    TaxMode? taxMode,
    InvoiceStatus? status,
    double? discountAmount,
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
      baseCurrencyCode: baseCurrencyCode,
      exchangeRate: exchangeRate ?? this.exchangeRate,
      taxRate: taxRate ?? this.taxRate,
      taxMode: taxMode ?? this.taxMode,
      status: status ?? this.status,
      discountAmount: discountAmount ?? this.discountAmount,
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
