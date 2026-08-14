import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;

/// Ensures a user document exists for the signed-in user.
class FirestoreInitializer {
  static const bool enabled = true;

  FirebaseFirestore get _db => FirebaseFirestore.instance;

  Future<void>? _pending;

  Future<void> ensureSeedData() {
    return _pending ??= _initialize().whenComplete(() => _pending = null);
  }

  Future<void> _initialize() async {
    if (!enabled) return;
    final user = firebase_auth.FirebaseAuth.instance.currentUser;
    if (user == null) return;

    await _createIfMissing(_db.collection('users').doc(user.uid), {
      'email': user.email ?? '',
      'displayName': user.displayName ?? user.email ?? '',
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> _createIfMissing(
    DocumentReference<Map<String, dynamic>> reference,
    Map<String, dynamic> data,
  ) async {
    await _db.runTransaction((transaction) async {
      final snapshot = await transaction.get(reference);
      if (!snapshot.exists) transaction.set(reference, data);
    });
  }
}
