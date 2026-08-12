import 'package:flutter/material.dart';

class ConfirmationDialog {
  static Future<bool?> show(
    BuildContext context, {
    required String title,
    required String message,
    String confirmText = 'Confirm',
    String cancelText = 'Cancel',
    bool destructive = false,
    IconData? confirmIcon,
  }) {
    return showDialog<bool>(
      context: context,
      builder: (context) {
        final theme = Theme.of(context);
        return AlertDialog(
          title: Text(title),
          content: Text(message),
          actions: [
            TextButton(
              key: const Key('confirm-dialog-cancel'),
              onPressed: () => Navigator.of(context).pop(false),
              child: Text(cancelText),
            ),
            FilledButton(
              key: const Key('confirm-dialog-confirm'),
              style: destructive
                  ? FilledButton.styleFrom(
                      backgroundColor: theme.colorScheme.error,
                      foregroundColor: theme.colorScheme.onError,
                    )
                  : null,
              onPressed: () => Navigator.of(context).pop(true),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (confirmIcon != null) ...[
                    Icon(confirmIcon, size: 18),
                    const SizedBox(width: 6),
                  ],
                  Text(confirmText),
                ],
              ),
            ),
          ],
        );
      },
    );
  }
}
