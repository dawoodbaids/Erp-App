/// Universal currency conversion for the preview shown in the UI.
///
/// rateToBase = how much BASE currency equals 1 unit of the currency.
/// ConvertedAmount = Amount * SourceRateToBase / TargetRateToBase.
///
/// Callers must resolve rates first (see ExchangeRateResolver). This utility
/// throws on non-positive rates rather than silently converting with 1, so a
/// missing rate is always surfaced as an error.
class CurrencyConverter {
  static double convert(
    double amount,
    double sourceRateToBase,
    double targetRateToBase,
  ) {
    if (sourceRateToBase <= 0 || targetRateToBase <= 0) {
      throw ArgumentError(
        'Exchange rates must be greater than zero. '
        'Got source=$sourceRateToBase target=$targetRateToBase.',
      );
    }
    final raw = amount * sourceRateToBase / targetRateToBase;
    return (raw * 100).round() / 100;
  }
}
