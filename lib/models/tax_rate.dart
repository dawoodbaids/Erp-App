import '../core/utils/firestore_helpers.dart';

/// A tax configuration loaded from the `taxes` collection.
class TaxRate {
  final String id;
  final String name;
  final double rate;
  final bool isActive;

  const TaxRate({
    required this.id,
    required this.name,
    required this.rate,
    this.isActive = true,
  });

  factory TaxRate.fromFirestore(String id, Map<String, dynamic> data) {
    return TaxRate(
      id: id,
      name: firestoreString(data['name']),
      rate: firestoreDouble(data['rate']),
      isActive: data.containsKey('isActive')
          ? firestoreBool(data['isActive'])
          : true,
    );
  }
}
