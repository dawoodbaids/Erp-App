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
