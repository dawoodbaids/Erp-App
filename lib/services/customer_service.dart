import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/customer.dart';
import 'firebase_service_exception.dart';

class CustomerService {
  FirebaseFirestore get _db => FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> get _customers =>
      _db.collection('customers');

  Future<List<Customer>> getCustomers() {
    return runFirebase(() async {
      final snapshot = await _customers.get();
      final customers = snapshot.docs
          .map((doc) => Customer.fromFirestore(doc.id, doc.data()))
          .toList();
      customers.sort((a, b) {
        final left = a.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0);
        final right = b.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0);
        return right.compareTo(left);
      });
      return customers;
    }, 'Could not load customers. Please try again.');
  }

  Future<Customer> getCustomer(String id) {
    return runFirebase(() async {
      final snapshot = await _customers.doc(id).get();
      if (!snapshot.exists || snapshot.data() == null) {
        throw const FirebaseServiceException(
          'The customer was not found.',
          code: 'not-found',
        );
      }
      return Customer.fromFirestore(snapshot.id, snapshot.data()!);
    }, 'Could not load the customer. Please try again.');
  }

  Future<Customer> createCustomer(Customer draft) {
    return runFirebase(() async {
      final existing = await _customers
          .where('nameLower', isEqualTo: draft.name.toLowerCase())
          .limit(1)
          .get();
      if (existing.docs.isNotEmpty) {
        throw const FirebaseServiceException(
          'A customer with this name already exists.',
          code: 'already-exists',
        );
      }

      final reference = _customers.doc();
      final now = DateTime.now();
      await reference.set({
        ...draft.toFirestore(),
        'nameLower': draft.name.toLowerCase(),
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });
      return Customer(
        id: reference.id,
        name: draft.name,
        phone: draft.phone,
        email: draft.email,
        address: draft.address,
        currencyId: draft.currencyId,
        isActive: draft.isActive,
        createdAt: now,
      );
    }, 'Could not create the customer. Please try again.');
  }

  Future<Customer> updateCustomer(Customer customer) {
    return runFirebase(() async {
      final reference = _customers.doc(customer.id);
      final snapshot = await reference.get();
      if (!snapshot.exists) {
        throw const FirebaseServiceException(
          'The customer was not found.',
          code: 'not-found',
        );
      }
      final duplicate = await _customers
          .where('nameLower', isEqualTo: customer.name.toLowerCase())
          .limit(1)
          .get();
      if (duplicate.docs.any((doc) => doc.id != customer.id)) {
        throw const FirebaseServiceException(
          'A customer with this name already exists.',
          code: 'already-exists',
        );
      }
      await reference.update({
        ...customer.toFirestore(),
        'nameLower': customer.name.toLowerCase(),
        'updatedAt': FieldValue.serverTimestamp(),
      });
      return customer;
    }, 'Could not save the customer. Please try again.');
  }

  Future<void> deleteCustomer(String id) {
    return runFirebase(() async {
      final reference = _customers.doc(id);
      final snapshot = await reference.get();
      if (!snapshot.exists) {
        throw const FirebaseServiceException(
          'The customer was not found.',
          code: 'not-found',
        );
      }
      await reference.delete();
    }, 'Could not delete the customer. Please try again.');
  }
}
