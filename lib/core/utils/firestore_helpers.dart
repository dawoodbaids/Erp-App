import 'package:cloud_firestore/cloud_firestore.dart';

String firestoreString(Object? value) =>
    value is String ? value : (value?.toString() ?? '');

String? firestoreStringOrNull(Object? value) {
  final result = firestoreString(value);
  return result.isEmpty ? null : result;
}

double firestoreDouble(Object? value) => value is num
    ? value.toDouble()
    : (double.tryParse(value?.toString() ?? '') ?? 0);

bool firestoreBool(Object? value) {
  if (value is bool) return value;
  return value == true || value == 1 || value == '1' || value == 'true';
}

DateTime? firestoreDate(Object? value) {
  if (value is Timestamp) return value.toDate();
  if (value is DateTime) return value;
  final text = firestoreString(value);
  return text.isEmpty ? null : DateTime.tryParse(text);
}

DateTime requiredFirestoreDate(Object? value) =>
    firestoreDate(value) ?? DateTime.fromMillisecondsSinceEpoch(0);

/// Reads the trailing numeric value of an invoice number. New invoices store
/// a readable string such as "INV-2026-0003" (sequence 3), legacy invoices
/// store an int or a string such as "INV-000007". Returns 0 when missing so
/// old documents never crash.
int firestoreInvoiceNumber(Object? value) {
  if (value is num) return value.toInt();
  final matches = RegExp(r'\d+').allMatches(value?.toString() ?? '').toList();
  if (matches.isEmpty) return 0;
  return int.tryParse(matches.last.group(0)!) ?? 0;
}

/// Reads the display label of an invoice number. Numeric legacy values are
/// converted to strings so every invoice has a stable, non-empty label.
String firestoreInvoiceNumberLabel(Object? value) {
  if (value is num) return value.toInt().toString();
  final text = firestoreString(value).trim();
  return text.isEmpty ? '0' : text;
}
