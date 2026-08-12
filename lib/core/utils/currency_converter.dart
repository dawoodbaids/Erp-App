/// Universal currency conversion for the preview shown in the UI.
///
/// rateToBase = how much BASE currency equals 1 unit of the currency.
/// ConvertedAmount = Amount * SourceRateToBase / TargetRateToBase.
/// This single formula handles same-currency, base-to-foreign,
/// foreign-to-base and foreign-to-foreign conversions.
class CurrencyConverter {
  static double convert(
    double amount,
    double sourceRateToBase,
    double targetRateToBase,
  ) {
    if (targetRateToBase == 0) return amount;
    final raw = amount * sourceRateToBase / targetRateToBase;
    return (raw * 100).round() / 100;
  }
}
