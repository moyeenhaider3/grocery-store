import 'package:flutter/material.dart';

import '../../core/theme/app_tokens.dart';
import '../../core/utils/money.dart';
import '../../models/order_model.dart';
import 'price_text.dart';
import 'product_thumbnail.dart';
import 'section_card.dart';
import 'status_pill.dart';

class OrderItemsSection extends StatelessWidget {
  final OrderModel order;

  const OrderItemsSection({super.key, required this.order});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return SectionCard(
      title: 'Items',
      icon: Icons.shopping_bag_outlined,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (var i = 0; i < order.items.length; i++) ...[
            if (i > 0) const Divider(height: AppSpacing.xl),
            Row(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(AppRadius.sm),
                  child: ProductThumbnail(name: order.items[i].name, imageUrl: order.items[i].imageUrl, size: 56),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(order.items[i].name, style: theme.textTheme.titleSmall),
                      const SizedBox(height: 2),
                      Text(
                        '${formatPaise(order.items[i].unitPrice)} × ${order.items[i].quantity}',
                        style: theme.textTheme.bodySmall?.copyWith(color: scheme.onSurfaceVariant),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                PriceText(order.items[i].lineTotal, size: PriceSize.sm),
              ],
            ),
          ],
          const SizedBox(height: AppSpacing.lg),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: AppSpacing.md),
            decoration: BoxDecoration(
              color: scheme.surfaceContainerLow,
              borderRadius: BorderRadius.circular(AppRadius.md),
            ),
            child: Row(
              children: [
                Expanded(child: Text('Total', style: theme.textTheme.titleMedium)),
                PriceText(order.total, size: PriceSize.lg),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class ShippingAddressSection extends StatelessWidget {
  final ShippingAddress address;

  const ShippingAddressSection({super.key, required this.address});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final muted = theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant);
    final a = address;
    return SectionCard(
      title: 'Shipping address',
      icon: Icons.location_on_outlined,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(a.fullName, style: theme.textTheme.titleSmall),
          const SizedBox(height: AppSpacing.xs),
          Text(a.addressLine, style: muted),
          Text('${a.city} - ${a.postalCode}', style: muted),
          const SizedBox(height: AppSpacing.sm),
          Row(
            children: [
              Icon(Icons.phone_outlined, size: 16, color: theme.colorScheme.onSurfaceVariant),
              const SizedBox(width: AppSpacing.xs + 2),
              Text(a.phone, style: muted),
            ],
          ),
        ],
      ),
    );
  }
}

class PaymentSection extends StatelessWidget {
  final OrderModel order;

  const PaymentSection({super.key, required this.order});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return SectionCard(
      title: 'Payment',
      icon: Icons.account_balance_wallet_outlined,
      trailing: PaymentStatusChip(order.paymentStatus),
      child: Text(
        '${paymentMethodLabel(order.paymentMethod)} · ${paymentStatusLabel(order.paymentStatus)}',
        style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant),
      ),
    );
  }
}
