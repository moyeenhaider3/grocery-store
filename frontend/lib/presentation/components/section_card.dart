import 'package:flutter/material.dart';

import '../../core/theme/app_tokens.dart';

class SectionCard extends StatelessWidget {
  final String? title;
  final Widget? trailing;
  final Widget child;
  final EdgeInsetsGeometry padding;

  /// Optional step number shown in a small ink disc before the title (checkout sections).
  final int? step;

  /// Optional icon shown before the title.
  final IconData? icon;

  const SectionCard({
    super.key,
    this.title,
    this.trailing,
    required this.child,
    this.padding = const EdgeInsets.all(AppSpacing.xl),
    this.step,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    Widget? lead;
    if (step != null) {
      lead = Container(
        width: 28,
        height: 28,
        alignment: Alignment.center,
        decoration: BoxDecoration(color: scheme.primary, shape: BoxShape.circle),
        child: Text('$step', style: theme.textTheme.labelLarge?.copyWith(color: scheme.onPrimary)),
      );
    } else if (icon != null) {
      lead = Container(
        width: 32,
        height: 32,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: scheme.surfaceContainer,
          borderRadius: BorderRadius.circular(AppRadius.sm),
        ),
        child: Icon(icon, size: 18, color: scheme.onSurface),
      );
    }
    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AppRadius.lg),
        boxShadow: AppShadows.soft(scheme.brightness),
      ),
      child: Card(
        child: Padding(
          padding: padding,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (title != null) ...[
                Row(
                  children: [
                    if (lead != null) ...[lead, const SizedBox(width: AppSpacing.md)],
                    Expanded(child: Text(title!, style: theme.textTheme.titleLarge)),
                    ?trailing,
                  ],
                ),
                const SizedBox(height: AppSpacing.lg),
              ],
              child,
            ],
          ),
        ),
      ),
    );
  }
}
