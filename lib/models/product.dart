import '../core/utils/firestore_helpers.dart';

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

  factory Product.fromFirestore(String id, Map<String, dynamic> data) {
    return Product(
      id: id,
      name: firestoreString(data['name']),
      barcode: firestoreString(data['barcode']),
      image: firestoreStringOrNull(data['imageUrl']),
      price: firestoreDouble(data['price']),
      taxRate: firestoreDouble(data['taxRate']),
      currencyId: firestoreString(data['currencyId']),
      isActive: data.containsKey('isActive')
          ? firestoreBool(data['isActive'])
          : true,
    );
  }

  Map<String, dynamic> toFirestore() => {
    'name': name,
    'barcode': barcode,
    'imageUrl': image,
    'price': price,
    'taxRate': taxRate,
    'currencyId': currencyId,
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
