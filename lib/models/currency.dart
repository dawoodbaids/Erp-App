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
    return Currency(
      id: id,
      code: firestoreString(data['code']),
      name: firestoreString(data['name']),
      symbol: firestoreString(data['symbol']),
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

  @override
  String toString() => code;
}
