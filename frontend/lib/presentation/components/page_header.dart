import 'package:flutter/material.dart';

import '../../core/theme/app_tokens.dart';

class PageHeader extends StatelessWidget {
  final String title;
  final String? subtitle;
  final String? eyebrow;
  final List<Widget> actions;
  final String? backLabel;
  final VoidCallback? onBack;

  const PageHeader({
    super.key,
    required this.title,
    this.subtitle,
    this.eyebrow,
    this.actions = const [],
    this.backLabel,
    this.onBack,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final phone = context.isPhone;
    final titleStyle = phone ? theme.textTheme.headlineMedium : theme.textTheme.headlineLarge;
    final titleBlock = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (eyebrow != null)
          Padding(
            padding: const EdgeInsets.only(bottom: AppSpacing.sm),
            child: Text(eyebrow!.toUpperCase(), style: theme.textTheme.labelSmall?.copyWith(color: scheme.secondary)),
          ),
        Text(title, style: titleStyle),
        if (subtitle != null)
          Padding(
            padding: const EdgeInsets.only(top: AppSpacing.sm),
            child: Text(
              subtitle!,
              style: theme.textTheme.bodyLarge?.copyWith(color: scheme.onSurfaceVariant),
            ),
          ),
      ],
    );
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.xl),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (backLabel != null && onBack != null)
            Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.md),
              child: BackLink(label: backLabel!, onPressed: onBack!),
            ),
          if (phone || actions.isEmpty) ...[
            titleBlock,
            if (actions.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: AppSpacing.lg),
                child: Wrap(spacing: AppSpacing.sm, runSpacing: AppSpacing.sm, children: actions),
              ),
          ] else
            Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Expanded(child: titleBlock),
                const SizedBox(width: AppSpacing.md),
                Wrap(spacing: AppSpacing.sm, runSpacing: AppSpacing.sm, children: actions),
              ],
            ),
        ],
      ),
    );
  }
}

/// Quiet "← Label" link used above page titles.
class BackLink extends StatelessWidget {
  final String label;
  final VoidCallback onPressed;

  const BackLink({super.key, required this.label, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return TextButton.icon(
      onPressed: onPressed,
      style: TextButton.styleFrom(
        foregroundColor: scheme.onSurfaceVariant,
        padding: const EdgeInsets.only(left: 6, right: 12),
      ),
      icon: const Icon(Icons.arrow_back_rounded, size: 18),
      label: Text(label),
    );
  }
}
