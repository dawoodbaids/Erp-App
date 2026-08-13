import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;

import '../models/user.dart';
import 'firebase_service_exception.dart';

class AuthService {
  firebase_auth.FirebaseAuth get _auth => firebase_auth.FirebaseAuth.instance;
  FirebaseFirestore get _db => FirebaseFirestore.instance;

  Stream<firebase_auth.User?> get authStateChanges => _auth.authStateChanges();

  Future<User> login(String email, String password) async {
    return runFirebase(() async {
      final credential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      final user = credential.user;
      if (user == null) {
        throw const FirebaseServiceException('Could not sign in.');
      }
      return _loadProfile(user);
    }, 'Could not sign in. Please try again.');
  }

  Future<User?> currentUser() async {
    return runFirebase(() async {
      final user = _auth.currentUser;
      return user == null ? null : _loadProfile(user);
    }, 'Could not restore the signed-in user. Please try again.');
  }

  Future<void> logout() async {
    await runFirebase(_auth.signOut, 'Could not sign out. Please try again.');
  }

  Future<User> _loadProfile(firebase_auth.User user) async {
    final reference = _db.collection('users').doc(user.uid);
    final snapshot = await reference.get();
    final data = snapshot.data() ?? <String, dynamic>{};
    final displayName = (data['displayName'] as String?)?.trim();
    final profile = User(
      id: user.uid,
      username: user.email ?? '',
      displayName: displayName?.isNotEmpty == true
          ? displayName!
          : user.email ?? '',
    );

    await reference.set({
      'email': user.email,
      'displayName': profile.displayName,
      'updatedAt': FieldValue.serverTimestamp(),
      if (!snapshot.exists) 'createdAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
    return profile;
  }
}
