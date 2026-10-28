import 'package:flutter/material.dart';

import '../../core/theme/app_tokens.dart';
import '../../core/theme/status_colors.dart';
import 'empty_state.dart';

class ErrorState extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const ErrorState({super.key, required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final danger = StatusColors.of(context).danger;
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 440),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: AppSpacing.xxxl, horizontal: AppSpacing.lg),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              EmblemIcon(icon: Icons.cloud_off_rounded, color: danger.fg, background: danger.bg, size: 80),
              const SizedBox(height: AppSpacing.lg),
              Text(message, style: theme.textTheme.titleMedium, textAlign: TextAlign.center),
              const SizedBox(height: AppSpacing.lg),
              OutlinedButton.icon(
                onPressed: onRetry,
                icon: const Icon(Icons.refresh_rounded, size: 18),
                label: const Text('Retry'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
