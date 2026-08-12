import 'json_helpers.dart';

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

  factory Currency.fromJson(Map<String, dynamic> json) => Currency(
    id: toStr(json['id']),
    code: toStr(json['code']),
    name: toStr(json['name']),
    symbol: toStr(json['symbol']),
    isBaseCurrency: toBool(json['isBaseCurrency']),
    isActive: toBool(json['isActive']),
  );

  Map<String, dynamic> toJson() => {
    'id': int.tryParse(id) ?? id,
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
