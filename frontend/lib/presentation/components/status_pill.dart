import 'package:flutter/material.dart';

import '../../core/theme/app_tokens.dart';
import '../../core/theme/status_colors.dart';
import '../../models/order_model.dart';

class StatusPill extends StatelessWidget {
  final String label;
  final StatusTone tone;
  final IconData? icon;
  final String? semanticLabel;

  /// Shows a small status dot before the label when no [icon] is given.
  final bool dot;

  const StatusPill({
    super.key,
    required this.label,
    required this.tone,
    this.icon,
    this.semanticLabel,
    this.dot = true,
  });

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: semanticLabel ?? label,
      child: ExcludeSemantics(
        child: Container(
          constraints: const BoxConstraints(minHeight: 26),
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm + 2, vertical: 3),
          decoration: BoxDecoration(color: tone.bg, borderRadius: BorderRadius.circular(AppRadius.pill)),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (icon != null) ...[
                Icon(icon, size: 14, color: tone.fg),
                const SizedBox(width: AppSpacing.xs + 2),
              ] else if (dot) ...[
                Container(
                  width: 6,
                  height: 6,
                  decoration: BoxDecoration(color: tone.fg, shape: BoxShape.circle),
                ),
                const SizedBox(width: AppSpacing.xs + 2),
              ],
              Text(
                label,
                style: Theme.of(context).textTheme.labelMedium?.copyWith(color: tone.fg, fontWeight: FontWeight.w700),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class OrderStatusChip extends StatelessWidget {
  final String status;

  const OrderStatusChip(this.status, {super.key});

  @override
  Widget build(BuildContext context) {
    return StatusPill(
      label: orderStatusLabel(status),
      tone: StatusColors.of(context).order(status),
      semanticLabel: 'Order status: ${orderStatusLabel(status)}',
    );
  }
}

class PaymentStatusChip extends StatelessWidget {
  final String paymentStatus;

  const PaymentStatusChip(this.paymentStatus, {super.key});

  @override
  Widget build(BuildContext context) {
    return StatusPill(
      label: paymentStatusLabel(paymentStatus),
      tone: StatusColors.of(context).payment(paymentStatus),
      semanticLabel: 'Payment: ${paymentStatusLabel(paymentStatus)}',
    );
  }
}
