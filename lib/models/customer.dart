import '../core/utils/firestore_helpers.dart';

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

  factory Customer.fromFirestore(String id, Map<String, dynamic> data) {
    return Customer(
      id: id,
      name: firestoreString(data['name']),
      phone: firestoreStringOrNull(data['phone']),
      email: firestoreString(data['email']),
      address: firestoreStringOrNull(data['address']),
      isActive: data.containsKey('isActive')
          ? firestoreBool(data['isActive'])
          : true,
      createdAt: firestoreDate(data['createdAt']),
    );
  }

  Map<String, dynamic> toFirestore() => {
    'name': name,
    'phone': phone,
    'email': email,
    'address': address,
    'isActive': isActive,
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
