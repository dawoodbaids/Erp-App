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

  /// Resolves a currency reference to its canonical document ID. The
  /// reference may already be a document ID or a currency code (e.g. "JOD").
  /// Returns the original value when it cannot be resolved.
  static String resolveCurrencyId(
    Map<String, double> ratesByCurrencyId,
    String currencyIdOrCode,
    Map<String, String> currencyIdsByLowerCode,
  ) {
    if (currencyIdOrCode.isEmpty) return currencyIdOrCode;
    if (ratesByCurrencyId.containsKey(currencyIdOrCode)) {
      return currencyIdOrCode;
    }
    return currencyIdsByLowerCode[currencyIdOrCode.toLowerCase()] ??
        currencyIdOrCode;
  }

  /// Looks up a rate by currency document ID or, when not found, by the
  /// currency code. Handles case differences in stored codes. Returns null
  /// when no positive rate exists. This tolerates `exchange_rates` documents
  /// whose `currencyId` stores either the `currencies` document ID or the
  /// currency code (e.g. "JOD"), matching whichever structure exists.
  static double? rateForCurrencyOrCode(
    Map<String, double> ratesByCurrencyId,
    String currencyId,
    String? currencyCode,
  ) {
    if (currencyId.isNotEmpty) {
      final byId = ratesByCurrencyId[currencyId];
      if (byId != null && byId > 0) return byId;
    }
    if (currencyCode != null && currencyCode.isNotEmpty) {
      final byCode = ratesByCurrencyId[currencyCode];
      if (byCode != null && byCode > 0) return byCode;
      final byLowerCode = ratesByCurrencyId[currencyCode.toLowerCase()];
      if (byLowerCode != null && byLowerCode > 0) return byLowerCode;
      final byUpperCode = ratesByCurrencyId[currencyCode.toUpperCase()];
      if (byUpperCode != null && byUpperCode > 0) return byUpperCode;
    }
    return null;
  }

  /// Rate of a currency against the base. Same as [rateToBase] but resolves
  /// the rate by document ID or code.
  static double? rateToBaseAny(
    Map<String, double> ratesByCurrencyId,
    String currencyId,
    String? currencyCode,
    String baseCurrencyId,
    String? baseCurrencyCode,
  ) {
    if (currencyId.isNotEmpty && currencyId == baseCurrencyId) return 1;
    if (currencyCode != null &&
        currencyCode.isNotEmpty &&
        baseCurrencyCode != null &&
        currencyCode.toLowerCase() == baseCurrencyCode.toLowerCase()) {
      return 1;
    }
    return rateForCurrencyOrCode(
      ratesByCurrencyId,
      currencyId,
      currencyCode,
    );
  }

  /// Conversion rate between two currencies resolving each side by document
  /// ID or code. Returns null when a required rate is missing.
  static double? rateBetweenAny(
    Map<String, double> ratesByCurrencyId,
    String fromCurrencyId,
    String? fromCurrencyCode,
    String toCurrencyId,
    String? toCurrencyCode,
    String baseCurrencyId,
    String? baseCurrencyCode,
  ) {
    if (fromCurrencyId == toCurrencyId ||
        (fromCurrencyCode != null &&
            toCurrencyCode != null &&
            fromCurrencyCode.toLowerCase() == toCurrencyCode.toLowerCase())) {
      return 1;
    }
    final from = rateToBaseAny(
      ratesByCurrencyId,
      fromCurrencyId,
      fromCurrencyCode,
      baseCurrencyId,
      baseCurrencyCode,
    );
    final to = rateToBaseAny(
      ratesByCurrencyId,
      toCurrencyId,
      toCurrencyCode,
      baseCurrencyId,
      baseCurrencyCode,
    );
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
