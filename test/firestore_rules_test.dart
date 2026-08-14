import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// Regression tests for `firestore.rules`.
///
/// There is no local Firestore emulator in this project, so the rules are
/// tested as source: a normal signed-in user must be able to create invoices
/// (requirement: creating an invoice must not produce a permission error),
/// while security-critical documents stay protected.
void main() {
  late String rules;

  setUpAll(() {
    rules = File('firestore.rules').readAsStringSync();
  });

  /// Returns the full `match /path/... { ... }` block including the rules
  /// written inside it, using brace matching so the whole block is captured.
  /// Placeholder variables like `{invoiceId}` are skipped first so they do
  /// not count as the block braces.
  String block(String path) {
    final marker = 'match /$path';
    final start = rules.indexOf(marker);
    expect(start, isNot(-1), reason: 'missing match for /$path');

    var i = rules.indexOf('{', start);
    expect(i, isNot(-1), reason: 'missing block for /$path');

    // Skip `{variable}` placeholder pairs on the match line.
    while (i != -1) {
      final placeholderClose = rules.indexOf('}', i);
      final newline = rules.indexOf('\n', i);
      if (placeholderClose != -1 &&
          (newline == -1 || placeholderClose < newline)) {
        i = rules.indexOf('{', placeholderClose);
      } else {
        break;
      }
    }
    final open = i;
    expect(open, isNot(-1), reason: 'missing block for /$path');

    var depth = 0;
    for (var j = open; j < rules.length; j++) {
      if (rules[j] == '{') depth++;
      if (rules[j] == '}') {
        depth--;
        if (depth == 0) return rules.substring(start, j + 1);
      }
    }
    fail('unterminated block for /$path');
  }

  group('Invoice creation permission (no permission error for users)', () {
    test('invoices allow read/write for any signed-in user', () {
      final invoiceBlock = block('invoices');
      expect(
        invoiceBlock,
        contains('allow read, write: if signedIn();'),
        reason: invoiceBlock,
      );
    });

    test('invoices are not gated by admin or role claims', () {
      final invoiceBlock = block('invoices');
      expect(invoiceBlock.contains('token'), isFalse);
      expect(invoiceBlock.contains('admin'), isFalse);
    });

    test('the invoice counter can be read and written by signed-in users', () {
      final counterBlock = block('settings/');
      expect(counterBlock, contains('signedIn()'));
    });
  });

  group('Security-sensitive documents stay protected', () {
    test('user documents can never be deleted', () {
      final usersBlock = block('users');
      expect(usersBlock, contains('allow delete: if false;'));
    });

    test('users can only read and update their own document', () {
      final usersBlock = block('users');
      expect(usersBlock, contains('request.auth.uid == userId'));
    });
  });
}
