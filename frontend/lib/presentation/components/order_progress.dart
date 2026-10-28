import 'package:flutter/material.dart';

import '../../core/theme/app_tokens.dart';
import '../../core/theme/status_colors.dart';
import '../../models/order_model.dart';
import 'status_banner.dart';

/// Display-only tracker of where an order is on its way: Pending -> Confirmed -> Shipped ->
/// Delivered. It only reads the server status; it never decides what can happen next.
class OrderProgress extends StatelessWidget {
  final String status;

  const OrderProgress({super.key, required this.status});

  static const _steps = ['PENDING', 'CONFIRMED', 'SHIPPED', 'DELIVERED'];
  static const _icons = [
    Icons.receipt_long_outlined,
    Icons.verified_outlined,
    Icons.local_shipping_outlined,
    Icons.home_outlined,
  ];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    if (status == 'CANCELLED') {
      return StatusBanner(
        tone: StatusColors.of(context).danger,
        icon: Icons.cancel_outlined,
        child: const Text('This order was cancelled.'),
      );
    }
    final current = _steps.indexOf(status);
    final phone = context.isPhone;

    Widget node(int i) {
      final reached = i <= current;
      final active = i == current;
      return SizedBox(
        width: phone ? 60 : 84,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AnimatedContainer(
              duration: AppMotion.slow,
              curve: AppMotion.ease,
              width: phone ? 36 : 44,
              height: phone ? 36 : 44,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: reached ? scheme.primary : scheme.surfaceContainerLowest,
                border: Border.all(color: reached ? scheme.primary : scheme.outlineVariant, width: 1.5),
                boxShadow: active
                    ? [BoxShadow(color: scheme.secondary.withValues(alpha: 0.35), spreadRadius: 4)]
                    : null,
              ),
              child: Icon(
                _icons[i],
                size: phone ? 17 : 20,
                color: reached ? scheme.onPrimary : scheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                orderStatusLabel(_steps[i]),
                maxLines: 1,
                style: theme.textTheme.labelMedium?.copyWith(
                  color: reached ? scheme.onSurface : scheme.onSurfaceVariant,
                  fontWeight: active ? FontWeight.w800 : FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
      );
    }

    Widget bar(int i) => Expanded(
      child: Padding(
        padding: EdgeInsets.only(bottom: phone ? 26 : 28),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(AppRadius.pill),
          child: TweenAnimationBuilder<double>(
            tween: Tween(begin: 0, end: i < current ? 1 : 0),
            duration: AppMotion.image,
            curve: AppMotion.ease,
            builder: (context, v, _) => LinearProgressIndicator(
              value: v,
              minHeight: 3,
              backgroundColor: scheme.outlineVariant,
              color: scheme.primary,
            ),
          ),
        ),
      ),
    );

    return Semantics(
      label: 'Order progress: ${orderStatusLabel(status)}',
      child: ExcludeSemantics(
        child: Row(
          children: [
            for (var i = 0; i < _steps.length; i++) ...[node(i), if (i < _steps.length - 1) bar(i)],
          ],
        ),
      ),
    );
  }
}
