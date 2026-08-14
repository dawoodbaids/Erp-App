/// Pure, testable exchange-rate math for the `exchange_rates` collection.
///
/// Firestore stores one document per currency: `{currencyId, rateToBase}`
/// where `rateToBase` is how much of the BASE currency equals 1 unit of that
/// currency. The base currency has no rate document and always equals 1.
///
/// Conversion between two currencies is `fromRate / toRate`, which naturally
/// supports the inverse direction (1 / rate) without double-inverting: each
/// currency has exactly one rateToBase value.
class ExchangeRateResolver {
  /// The rate of [currencyId] against the base currency. The base currency
  /// always returns 1. Returns null when the currency is not the base and no
  /// (or an invalid) rate is configured.
  static double? rateToBase(
    Map<String, double> ratesByCurrencyId,
    String currencyId,
    String baseCurrencyId,
  ) {
    if (currencyId.isEmpty || baseCurrencyId.isEmpty) return null;
    if (currencyId == baseCurrencyId) return 1;
    final rate = ratesByCurrencyId[currencyId];
    if (rate == null || rate <= 0) return null;
    return rate;
  }

  /// Conversion rate from [fromCurrencyId] to [toCurrencyId].
  ///
  /// - Same currency returns 1.
  /// - Otherwise both currencies must have a valid rateToBase (or be the
  ///   base currency), otherwise null. It never invents a rate of 1.
  static double? rateBetween(
    Map<String, double> ratesByCurrencyId,
    String fromCurrencyId,
    String toCurrencyId,
    String baseCurrencyId,
  ) {
    if (fromCurrencyId == toCurrencyId) return 1;
    final from = rateToBase(ratesByCurrencyId, fromCurrencyId, baseCurrencyId);
    final to = rateToBase(ratesByCurrencyId, toCurrencyId, baseCurrencyId);
    if (from == null || to == null) return null;
    return from / to;
  }

  /// Converts [amount] from one currency to another. Returns null when a
  /// required rate is missing so callers never use a made-up rate.
  static double? convertAmount(
    double amount,
    Map<String, double> ratesByCurrencyId,
    String fromCurrencyId,
    String toCurrencyId,
    String baseCurrencyId,
  ) {
    final rate = rateBetween(
      ratesByCurrencyId,
      fromCurrencyId,
      toCurrencyId,
      baseCurrencyId,
    );
    if (rate == null) return null;
    return (amount * rate * 100).round() / 100;
  }
}
