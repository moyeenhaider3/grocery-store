import 'package:flutter/material.dart';

import '../../core/theme/app_tokens.dart';

/// Shows a snackbar, always replacing any snackbar currently visible.
void showAppSnack(BuildContext context, String message, {bool error = false, SnackBarAction? action}) {
  final scheme = Theme.of(context).colorScheme;
  final messenger = ScaffoldMessenger.of(context);
  messenger.hideCurrentSnackBar();
  messenger.showSnackBar(
    SnackBar(
      content: Text(message, style: error ? TextStyle(color: scheme.onError) : null),
      backgroundColor: error ? scheme.error : null,
      action: action == null || !error
          ? action
          : SnackBarAction(label: action.label, textColor: scheme.onError, onPressed: action.onPressed),
      width: MediaQuery.sizeOf(context).width >= AppBreakpoints.tablet ? 480 : null,
    ),
  );
}
