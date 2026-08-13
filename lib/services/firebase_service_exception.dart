import 'package:firebase_core/firebase_core.dart';

class FirebaseServiceException implements Exception {
  final String message;
  final String? code;

  const FirebaseServiceException(this.message, {this.code});

  @override
  String toString() => message;
}

Future<T> runFirebase<T>(
  Future<T> Function() action,
  String fallbackMessage,
) async {
  try {
    return await action();
  } catch (error) {
    if (error is FirebaseServiceException) rethrow;
    throw FirebaseServiceException(
      firebaseErrorMessage(error, fallbackMessage),
      code: error is FirebaseException ? error.code : null,
    );
  }
}

String firebaseErrorMessage(Object error, String fallbackMessage) {
  if (error is FirebaseException) {
    switch (error.code) {
      case 'invalid-credential':
      case 'invalid-email':
      case 'user-disabled':
      case 'user-not-found':
      case 'wrong-password':
        return 'Invalid email or password.';
      case 'email-already-in-use':
        return 'An account already exists for this email.';
      case 'weak-password':
        return 'Choose a stronger password.';
      case 'permission-denied':
        return 'You do not have permission to perform this action.';
      case 'unavailable':
      case 'network-request-failed':
        return 'No network connection. Please try again.';
      case 'not-found':
        return 'The requested record was not found.';
      case 'already-exists':
        return 'This record already exists.';
      case 'failed-precondition':
        return 'This action cannot be completed yet.';
    }
  }
  return fallbackMessage;
}
