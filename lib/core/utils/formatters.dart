import '../../models/currency.dart';

class Formatters {
  static String amount(double value) {
    final rounded = (value * 100).round() / 100;
    final fixed = rounded.toStringAsFixed(2);
    final parts = fixed.split('.');
    final intPart = parts[0];
    final decimals = parts[1];
    final buffer = StringBuffer();
    for (var i = 0; i < intPart.length; i++) {
      final digit = intPart[i];
      final remaining = intPart.length - i;
      buffer.write(digit);
      if (remaining > 1 && (remaining - 1) % 3 == 0) buffer.write(',');
    }
    return '$buffer.$decimals';
  }

  static String rate(double value) {
    final rounded = (value * 1000).round() / 1000;
    return rounded.toStringAsFixed(3);
  }

  static String amountWithCurrency(Currency? currency, double value) {
    final code = currency?.code ?? '';
    return code.isEmpty ? amount(value) : '$code ${amount(value)}';
  }

  static String quantity(double value) {
    if (value == value.truncateToDouble()) {
      return value.toStringAsFixed(0);
    }
    return value.toStringAsFixed(2);
  }

  static String compact(double value) {
    if (value >= 1000) {
      return '${(value / 1000).toStringAsFixed(1)}K';
    }
    return value.toStringAsFixed(0);
  }

  static String date(DateTime dateTime) {
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    final day = dateTime.day.toString().padLeft(2, '0');
    return '$day ${months[dateTime.month - 1]} ${dateTime.year}';
  }

  static String dateTime(DateTime dateTime) {
    final time =
        '${dateTime.hour.toString().padLeft(2, '0')}:'
        '${dateTime.minute.toString().padLeft(2, '0')}';
    return '${date(dateTime)} · $time';
  }
}
