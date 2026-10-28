import 'package:flutter/material.dart';

import '../../core/theme/app_tokens.dart';

/// Display-only progress through Cart -> Checkout -> Confirmation (0, 1 or 2).
class StepIndicator extends StatelessWidget {
  final int current;

  const StepIndicator({super.key, required this.current});

  static const _labels = ['Cart', 'Checkout', 'Confirmation'];

  Widget _step(BuildContext context, int i) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final done = i < current;
    final active = i == current;
    final circle = AnimatedContainer(
      duration: AppMotion.base,
      width: 28,
      height: 28,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: done || active ? scheme.primary : scheme.surfaceContainerLowest,
        border: Border.all(color: done || active ? scheme.primary : scheme.outlineVariant, width: 1.5),
        boxShadow: active
            ? [BoxShadow(color: scheme.primary.withValues(alpha: 0.18), blurRadius: 0, spreadRadius: 4)]
            : null,
      ),
      child: done
          ? Icon(Icons.check_rounded, size: 16, color: scheme.onPrimary)
          : Text(
              '${i + 1}',
              style: theme.textTheme.labelMedium?.copyWith(
                color: active ? scheme.onPrimary : scheme.onSurfaceVariant,
                fontWeight: FontWeight.w700,
              ),
            ),
    );
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        circle,
        if (!context.isPhone || active) ...[
          const SizedBox(width: AppSpacing.sm),
          Text(
            _labels[i],
            style: theme.textTheme.labelLarge?.copyWith(
              color: active || done ? scheme.onSurface : scheme.onSurfaceVariant,
              fontWeight: active ? FontWeight.w700 : FontWeight.w500,
            ),
          ),
        ],
      ],
    );
  }

  Widget _connector(BuildContext context, int i) {
    final scheme = Theme.of(context).colorScheme;
    return Expanded(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(AppRadius.pill),
          child: SizedBox(
            height: 2,
            child: ColoredBox(color: i < current ? scheme.primary : scheme.outlineVariant),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: 'Step ${current + 1} of 3: ${_labels[current]}',
      child: ExcludeSemantics(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 560),
          child: Row(
            children: [
              _step(context, 0),
              _connector(context, 0),
              _step(context, 1),
              _connector(context, 1),
              _step(context, 2),
            ],
          ),
        ),
      ),
    );
  }
}
