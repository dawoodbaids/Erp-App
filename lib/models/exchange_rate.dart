import '../core/utils/firestore_helpers.dart';

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

  factory ExchangeRate.fromFirestore(String id, Map<String, dynamic> data) {
    return ExchangeRate(
      id: id,
      currencyId: firestoreString(data['currencyId']),
      rateToBase: firestoreDouble(data['rateToBase']),
      effectiveDate: firestoreDate(data['effectiveDate']),
    );
  }

  Map<String, dynamic> toFirestore() => {
    'currencyId': currencyId,
    'rateToBase': rateToBase,
    'effectiveDate': effectiveDate,
  };

  ExchangeRate copyWith({double? rateToBase, DateTime? effectiveDate}) {
    return ExchangeRate(
      id: id,
      currencyId: currencyId,
      rateToBase: rateToBase ?? this.rateToBase,
      effectiveDate: effectiveDate ?? this.effectiveDate,
    );
  }
}
