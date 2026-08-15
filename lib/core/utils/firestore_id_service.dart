import 'package:cloud_firestore/cloud_firestore.dart';

/// Creates a readable document ID without replacing an existing document.
Future<String> createWithUniqueId(
  CollectionReference<Map<String, dynamic>> collection,
  String baseId,
  Map<String, dynamic> Function(String id) data, {
  bool sanitize = true,
  }
) async {
  final cleanBase = sanitize ? sanitizeIdPart(baseId) : baseId.trim();
  if (cleanBase.isEmpty || cleanBase.contains('/')) {
    throw ArgumentError('The document ID is not valid.');
  }
  for (var sequence = 1; sequence <= 10000; sequence++) {
    final id = sequence == 1 ? cleanBase : '${cleanBase}_$sequence';
    try {
      final reference = collection.doc(id);
      await FirebaseFirestore.instance.runTransaction((transaction) async {
        final snapshot = await transaction.get(reference);
        if (snapshot.exists) throw const _IdTaken();
        transaction.set(reference, data(id));
      });
      return id;
    } on _IdTaken {
      continue;
    }
  }
  throw StateError('Could not find an unused Firestore document ID.');
}

class _IdTaken implements Exception {
  const _IdTaken();
}

String sanitizeIdPart(String value) {
  final sanitized = value
      .trim()
      .toLowerCase()
      .replaceAll(RegExp(r'[^a-z0-9]+'), '_')
      .replaceAll(RegExp(r'^_+|_+$'), '');
  return sanitized.isEmpty ? 'item' : sanitized;
}
