import 'package:flutter/material.dart';

Future<bool> showConfirmDialog(
  BuildContext context, {
  required String title,
  String? message,
  required String confirmLabel,
  String cancelLabel = 'Cancel',
  bool destructive = false,
}) async {
  final scheme = Theme.of(context).colorScheme;
  final result = await showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: Text(title),
      content: message == null
          ? null
          : ConstrainedBox(constraints: const BoxConstraints(maxWidth: 480), child: Text(message)),
      actions: [
        TextButton(onPressed: () => Navigator.of(ctx).pop(false), child: Text(cancelLabel)),
        FilledButton(
          style: destructive ? FilledButton.styleFrom(backgroundColor: scheme.error, foregroundColor: scheme.onError) : null,
          onPressed: () => Navigator.of(ctx).pop(true),
          child: Text(confirmLabel),
        ),
      ],
    ),
  );
  return result == true;
}
