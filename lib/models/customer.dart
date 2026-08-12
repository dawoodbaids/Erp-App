import 'json_helpers.dart';

class Customer {
  final String id;
  final String name;
  final String? phone;
  final String email;
  final String? address;
  final bool isActive;
  final DateTime? createdAt;

  const Customer({
    required this.id,
    required this.name,
    this.phone,
    this.email = '',
    this.address,
    this.isActive = true,
    this.createdAt,
  });

  factory Customer.fromJson(Map<String, dynamic> json) => Customer(
    id: toStr(json['id']),
    name: toStr(json['name']),
    phone: toStrOrNull(json['phone']),
    email: toStr(json['email']),
    address: toStrOrNull(json['address']),
    isActive: toBool(json['isActive']),
    createdAt: toDateOrNull(json['createdAt']),
  );

  Map<String, dynamic> toJson() => {
    'id': int.tryParse(id) ?? id,
    'name': name,
    'phone': phone,
    'email': email,
    'address': address,
    'isActive': isActive,
    'createdAt': createdAt?.toIso8601String(),
  };

  Map<String, dynamic> toCreateRequest() => {
    'name': name,
    'phone': phone,
    'email': email,
    'address': address,
  };

  Customer copyWith({
    String? name,
    String? phone,
    String? email,
    String? address,
    bool? isActive,
    DateTime? createdAt,
  }) {
    return Customer(
      id: id,
      name: name ?? this.name,
      phone: phone ?? this.phone,
      email: email ?? this.email,
      address: address ?? this.address,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
