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

  /// Code of the currency [price] is stored in (e.g. "JOD"). Stored
  /// alongside [currencyId] so prices always keep their original currency.
  /// Empty for products created before this field existed; the UI resolves
  /// the code from the currency document in that case.
  final String currencyCode;

  final bool isActive;

  const Product({
    required this.id,
    required this.name,
    required this.barcode,
    this.image,
    required this.price,
    required this.taxRate,
    required this.currencyId,
    this.currencyCode = '',
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
      currencyCode: firestoreString(data['currencyCode']),
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
    'currencyCode': currencyCode,
    'isActive': isActive,
  };

  Product copyWith({
    String? name,
    String? barcode,
    Object? image = _unset,
    double? price,
    double? taxRate,
    String? currencyId,
    String? currencyCode,
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
      currencyCode: currencyCode ?? this.currencyCode,
      isActive: isActive ?? this.isActive,
    );
  }
}
