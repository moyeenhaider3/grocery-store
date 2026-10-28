import 'package:flutter/material.dart';

import '../../core/theme/app_tokens.dart';

class EmptyState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? message;
  final Widget? action;

  const EmptyState({super.key, required this.icon, required this.title, this.message, this.action});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final muted = scheme.onSurfaceVariant;
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 440),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: AppSpacing.huge, horizontal: AppSpacing.lg),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              EmblemIcon(icon: icon),
              const SizedBox(height: AppSpacing.xl),
              Text(title, style: theme.textTheme.headlineSmall, textAlign: TextAlign.center),
              if (message != null) ...[
                const SizedBox(height: AppSpacing.sm),
                Text(message!, style: theme.textTheme.bodyLarge?.copyWith(color: muted), textAlign: TextAlign.center),
              ],
              if (action != null) ...[const SizedBox(height: AppSpacing.xl), action!],
            ],
          ),
        ),
      ),
    );
  }
}

/// Large icon inside a soft disc with a fine outer ring, for empty, error and success moments.
class EmblemIcon extends StatelessWidget {
  final IconData icon;
  final Color? color;
  final Color? background;
  final double size;

  const EmblemIcon({super.key, required this.icon, this.color, this.background, this.size = 96});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      width: size,
      height: size,
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: (color ?? scheme.outlineVariant).withValues(alpha: color == null ? 1 : 0.25)),
      ),
      child: DecoratedBox(
        decoration: BoxDecoration(shape: BoxShape.circle, color: background ?? scheme.surfaceContainer),
        child: Icon(icon, size: size * 0.36, color: color ?? scheme.onSurfaceVariant),
      ),
    );
  }
}
