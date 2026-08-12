import 'json_helpers.dart';

/// Exchange rate of a currency relative to the system BASE currency.
/// rateToBase = how much BASE currency equals 1 unit of this currency.
/// Example: USD with rateToBase 0.709 against a JOD base means 1 USD = 0.709 JOD.
class ExchangeRate {
  final String id;
  final String currencyId;
  final double rateToBase;
  final DateTime? effectiveDate;

  const ExchangeRate({
    required this.id,
    required this.currencyId,
    required this.rateToBase,
    this.effectiveDate,
  });

  factory ExchangeRate.fromJson(Map<String, dynamic> json) => ExchangeRate(
    id: toStr(json['id']),
    currencyId: toStr(json['currencyId']),
    rateToBase: toDouble(json['rateToBase']),
    effectiveDate: toDateOrNull(json['effectiveDate']),
  );

  Map<String, dynamic> toJson() => {
    'id': int.tryParse(id) ?? id,
    'currencyId': int.tryParse(currencyId) ?? currencyId,
    'rateToBase': rateToBase,
    'effectiveDate': effectiveDate?.toIso8601String(),
  };

  ExchangeRate copyWith({double? rateToBase}) {
    return ExchangeRate(
      id: id,
      currencyId: currencyId,
      rateToBase: rateToBase ?? this.rateToBase,
      effectiveDate: effectiveDate,
    );
  }
}
