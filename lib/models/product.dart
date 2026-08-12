import 'json_helpers.dart';

class Product {
  static const Object _unset = Object();

  final String id;
  final String name;
  final String barcode;
  final String? image;
  final double price;
  final double taxRate;
  final String currencyId;
  final bool isActive;

  const Product({
    required this.id,
    required this.name,
    required this.barcode,
    this.image,
    required this.price,
    required this.taxRate,
    required this.currencyId,
    this.isActive = true,
  });

  factory Product.fromJson(Map<String, dynamic> json) => Product(
    id: toStr(json['id']),
    name: toStr(json['name']),
    barcode: toStr(json['barcode']),
    image: toStrOrNull(json['imageUrl'] ?? json['image']),
    price: toDouble(json['price']),
    taxRate: toDouble(json['taxRate']),
    currencyId: toStr(json['currencyId']),
    isActive: toBool(json['isActive']),
  );

  Map<String, dynamic> toJson() => {
    'id': int.tryParse(id) ?? id,
    'name': name,
    'barcode': barcode,
    'image': image,
    'imageUrl': image,
    'price': price,
    'taxRate': taxRate,
    'currencyId': int.tryParse(currencyId) ?? currencyId,
    'isActive': isActive,
  };

  Map<String, dynamic> toCreateRequest() => {
    'name': name,
    'barcode': barcode,
    'price': price,
    'taxRate': taxRate,
    'currencyId': int.tryParse(currencyId) ?? currencyId,
    'isActive': isActive,
  };

  Product copyWith({
    String? name,
    String? barcode,
    Object? image = _unset,
    double? price,
    double? taxRate,
    String? currencyId,
    bool? isActive,
  }) {
    return Product(
      id: id,
      name: name ?? this.name,
      barcode: barcode ?? this.barcode,
      image: identical(image, _unset) ? this.image : image as String?,
      price: price ?? this.price,
      taxRate: taxRate ?? this.taxRate,
      currencyId: currencyId ?? this.currencyId,
      isActive: isActive ?? this.isActive,
    );
  }
}
