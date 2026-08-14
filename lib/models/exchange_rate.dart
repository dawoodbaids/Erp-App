import '../core/utils/firestore_helpers.dart';

/// An exchange rate document from the `exchange_rates` collection.
///
/// Two document shapes are tolerated:
/// - Canonical: `{currencyId, rateToBase}` where `rateToBase` is how much of
///   the BASE currency equals 1 unit of that currency.
/// - Pair: `{fromCurrency, toCurrency, rate}` (e.g. `JOD_USD` with
///   `rate: 1.41044` meaning 1 JOD = 1.41044 USD). Pair documents only make
///   sense for conversion when one side is the base currency.
class ExchangeRate {
  final String id;
  final String currencyId;
  final double rateToBase;

  /// Pair documents: the `fromCurrency` field (e.g. "JOD").
  final String? fromCurrency;

  /// Pair documents: the `toCurrency` field (e.g. "USD").
  final String? toCurrency;

  /// Pair documents: units of [toCurrency] per 1 [fromCurrency].
  final double? pairRate;

  final DateTime? effectiveDate;

  const ExchangeRate({
    required this.id,
    required this.currencyId,
    required this.rateToBase,
    this.fromCurrency,
    this.toCurrency,
    this.pairRate,
    this.effectiveDate,
  });

  /// True when the document is a `{fromCurrency, toCurrency, rate}` pair.
  bool get isPair => pairRate != null;

  factory ExchangeRate.fromFirestore(String id, Map<String, dynamic> data) {
    final rateToBase = firestoreDouble(data['rateToBase']);
    if (rateToBase > 0) {
      return ExchangeRate(
        id: id,
        currencyId: firestoreString(data['currencyId']),
        rateToBase: rateToBase,
        effectiveDate: firestoreDate(data['effectiveDate']),
      );
    }

    // Tolerate pair-style documents such as
    // `exchange_rates/JOD_USD: {fromCurrency: "JOD", toCurrency: "USD",
    // rate: 1.41044}`. The rate is resolved against the base currency later
    // (see `rateToBaseEntries`).
    final fromCurrency = firestoreString(data['fromCurrency']);
    final toCurrency = firestoreString(data['toCurrency']);
    final pairRate = firestoreDouble(data['rate']);
    if (fromCurrency.isNotEmpty &&
        toCurrency.isNotEmpty &&
        pairRate > 0) {
      return ExchangeRate(
        id: id,
        currencyId: fromCurrency,
        rateToBase: 0,
        fromCurrency: fromCurrency,
        toCurrency: toCurrency,
        pairRate: pairRate,
        effectiveDate: firestoreDate(data['effectiveDate']),
      );
    }

    return ExchangeRate(
      id: id,
      currencyId: firestoreString(data['currencyId']),
      rateToBase: 0,
      effectiveDate: firestoreDate(data['effectiveDate']),
    );
  }

  Map<String, dynamic> toFirestore() => {
    'currencyId': currencyId,
    'rateToBase': rateToBase,
    'effectiveDate': effectiveDate,
  };

  /// Resolves a pair document into `rateToBase` entries keyed by currency
  /// code, when the base currency is one of the two sides:
  ///
  /// - `JOD_USD` with base JOD: `{JOD: 1, USD: 1 / 1.41044}`.
  /// - `USD_JOD` with base JOD: `{USD: 0.709, JOD: 1}`.
  ///
  /// Returns an empty map when neither side is the base currency (the pair
  /// cannot be anchored to the base without a third rate).
  Map<String, double> rateToBaseEntries(String baseCurrencyCode) {
    final from = fromCurrency;
    final to = toCurrency;
    final rate = pairRate;
    if (from == null || to == null || rate == null || rate <= 0) {
      return const {};
    }
    final base = baseCurrencyCode.toLowerCase();
    if (from.toLowerCase() == base) {
      return {from.toUpperCase(): 1, to.toUpperCase(): 1 / rate};
    }
    if (to.toLowerCase() == base) {
      return {from.toUpperCase(): rate, to.toUpperCase(): 1};
    }
    return const {};
  }

  ExchangeRate copyWith({double? rateToBase, DateTime? effectiveDate}) {
    return ExchangeRate(
      id: id,
      currencyId: currencyId,
      rateToBase: rateToBase ?? this.rateToBase,
      fromCurrency: fromCurrency,
      toCurrency: toCurrency,
      pairRate: pairRate,
      effectiveDate: effectiveDate ?? this.effectiveDate,
    );
  }
}