/// Small helpers for safely converting JSON values into Dart types.
/// Backend ids are integers and money values are decimals, so plain `as int`
/// / `as double` casts are not reliable.
String toStr(Object? value) =>
    value is String ? value : (value?.toString() ?? '');

String? toStrOrNull(Object? value) {
  final s = toStr(value);
  return s.isEmpty ? null : s;
}

int toInt(Object? value) =>
    value is int ? value : (int.tryParse(value?.toString() ?? '') ?? 0);

double toDouble(Object? value) => value is num
    ? value.toDouble()
    : (double.tryParse(value?.toString() ?? '') ?? 0);

bool toBool(Object? value) {
  if (value is bool) return value;
  return value == true || value == 1 || value == '1' || value == 'true';
}

DateTime? toDateOrNull(Object? value) {
  final s = toStr(value);
  if (s.isEmpty) return null;
  return DateTime.tryParse(s);
}

DateTime toDate(Object? value) =>
    toDateOrNull(value) ?? DateTime.fromMillisecondsSinceEpoch(0);
