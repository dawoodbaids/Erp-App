import '../core/utils/firestore_helpers.dart';

class Currency {
  final String id;
  final String code;
  final String name;
  final String symbol;
  final bool isBaseCurrency;
  final bool isActive;

  const Currency({
    required this.id,
    required this.code,
    required this.name,
    required this.symbol,
    this.isBaseCurrency = false,
    this.isActive = true,
  });

  factory Currency.fromFirestore(String id, Map<String, dynamic> data) {
    final code = firestoreString(data['code']);
    final name = firestoreString(data['name']);
    final symbol = firestoreString(data['symbol']);
    return Currency(
      id: id,
      // Tolerate alternative field names used by hand-created documents
      // (e.g. invoice-style `currencyCode`/`currencyName`/`currencySymbol`).
      code: code.isNotEmpty ? code : firestoreString(data['currencyCode']),
      name: name.isNotEmpty ? name : firestoreString(data['currencyName']),
      symbol: symbol.isNotEmpty
          ? symbol
          : firestoreString(data['currencySymbol']),
      isBaseCurrency: firestoreBool(data['isBaseCurrency']),
      isActive: data.containsKey('isActive')
          ? firestoreBool(data['isActive'])
          : true,
    );
  }

  Map<String, dynamic> toFirestore() => {
    'code': code,
    'name': name,
    'symbol': symbol,
    'isBaseCurrency': isBaseCurrency,
    'isActive': isActive,
  };

  Currency copyWith({bool? isBaseCurrency, bool? isActive}) {
    return Currency(
      id: id,
      code: code,
      name: name,
      symbol: symbol,
      isBaseCurrency: isBaseCurrency ?? this.isBaseCurrency,
      isActive: isActive ?? this.isActive,
    );
  }

  /// Short label for dropdowns and lists. Prefers the code, then the name,
  /// and finally the document ID so the UI never shows an empty string.
  String get displayLabel => code.isNotEmpty
      ? code
      : (name.isNotEmpty ? name : id);

  @override
  String toString() => code;
}
