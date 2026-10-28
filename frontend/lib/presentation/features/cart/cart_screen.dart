import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../bloc/cart/cart_bloc.dart';
import '../../../bloc/cart/cart_event.dart';
import '../../../bloc/cart/cart_state.dart';
import '../../../core/theme/app_tokens.dart';
import '../../../core/theme/status_colors.dart';
import '../../../core/utils/money.dart';
import '../../../models/cart_model.dart';
import '../../components/empty_state.dart';
import '../../components/error_state.dart';
import '../../components/loading_skeleton.dart';
import '../../components/page_container.dart';
import '../../components/page_header.dart';
import '../../components/price_text.dart';
import '../../components/product_thumbnail.dart';
import '../../components/section_card.dart';
import '../../components/status_banner.dart';
import '../../components/step_indicator.dart';

class CartScreen extends StatefulWidget {
  const CartScreen({super.key});

  @override
  State<CartScreen> createState() => _CartScreenState();
}

class _CartScreenState extends State<CartScreen> {
  @override
  void initState() {
    super.initState();
    // Fresh flags whenever the screen opens.
    context.read<CartBloc>().add(CartLoadRequested());
  }

  String? _flag(CartItemModel item) {
    switch (item.issue) {
      case 'unavailable':
        return 'No longer available';
      case 'out_of_stock':
        return 'Out of stock';
      case 'insufficient_stock':
        return 'Only ${item.stock} left — reduce the quantity';
      default:
        return null;
    }
  }

  Widget _stepper(BuildContext context, CartItemModel item, bool busy) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final bloc = context.read<CartBloc>();
    final minusEnabled =
        item.quantity > 1 && item.issue != 'unavailable' && item.issue != 'out_of_stock' && !busy;
    final plusEnabled = item.canIncrease && !busy;
    final buttonStyle = IconButton.styleFrom(minimumSize: const Size(40, 40), iconSize: 18);
    return Container(
      decoration: BoxDecoration(
        color: scheme.surfaceContainerLow,
        border: Border.all(color: scheme.outlineVariant),
        borderRadius: BorderRadius.circular(AppRadius.pill),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            tooltip: 'Decrease',
            style: buttonStyle,
            icon: const Icon(Icons.remove_rounded),
            onPressed: minusEnabled
                ? () => bloc.add(CartQuantityChanged(item.productId, item.quantity - 1))
                : null,
          ),
          SizedBox(
            width: 28,
            child: Text(
              '${item.quantity}',
              textAlign: TextAlign.center,
              style: theme.textTheme.titleMedium?.copyWith(fontFeatures: const [FontFeature.tabularFigures()]),
            ),
          ),
          IconButton(
            tooltip: 'Increase',
            style: buttonStyle,
            icon: const Icon(Icons.add_rounded),
            onPressed: plusEnabled
                ? () => bloc.add(CartQuantityChanged(item.productId, item.quantity + 1))
                : null,
          ),
        ],
      ),
    );
  }

  Widget _line(BuildContext context, CartItemModel item, bool busy) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final bloc = context.read<CartBloc>();
    final flag = _flag(item);
    final danger = StatusColors.of(context).danger;

    Widget remove() => IconButton(
      tooltip: 'Remove',
      style: IconButton.styleFrom(foregroundColor: scheme.onSurfaceVariant),
      icon: const Icon(Icons.delete_outline_rounded, size: 20),
      onPressed: busy ? null : () => bloc.add(CartItemRemoved(item.productId)),
    );

    Widget lineTotal() => Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      mainAxisSize: MainAxisSize.min,
      children: [
        PriceText(item.lineTotal, size: PriceSize.md),
        Text('${formatPaise(item.price)} each', style: theme.textTheme.bodySmall?.copyWith(color: scheme.onSurfaceVariant)),
      ],
    );

    Widget info() => Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _ProductLink(name: item.name, onTap: () => context.push('/products/${item.productId}')),
        if (flag != null) ...[
          const SizedBox(height: AppSpacing.sm),
          StatusBanner(tone: danger, icon: Icons.warning_amber_rounded, child: Text(flag)),
        ],
      ],
    );

    final thumb = ClipRRect(
      borderRadius: BorderRadius.circular(AppRadius.md),
      child: ProductThumbnail(name: item.name, imageUrl: item.imageUrl, size: context.isPhone ? 72 : 88),
    );

    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.md),
      child: AnimatedContainer(
        duration: AppMotion.base,
        decoration: BoxDecoration(
          color: scheme.surfaceContainerLowest,
          borderRadius: BorderRadius.circular(AppRadius.lg),
          border: item.hasIssue
              ? Border.all(color: danger.fg, width: 1.5)
              : Border.all(color: scheme.outlineVariant),
          boxShadow: AppShadows.soft(scheme.brightness),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(AppRadius.lg),
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(AppSpacing.lg),
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    if (constraints.maxWidth >= 600) {
                      return Row(
                        children: [
                          thumb,
                          const SizedBox(width: AppSpacing.lg),
                          Expanded(child: info()),
                          const SizedBox(width: AppSpacing.lg),
                          _stepper(context, item, busy),
                          const SizedBox(width: AppSpacing.lg),
                          SizedBox(width: 120, child: Align(alignment: Alignment.centerRight, child: lineTotal())),
                          const SizedBox(width: AppSpacing.xs),
                          remove(),
                        ],
                      );
                    }
                    return Column(
                      children: [
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            thumb,
                            const SizedBox(width: AppSpacing.md),
                            Expanded(child: info()),
                            remove(),
                          ],
                        ),
                        const SizedBox(height: AppSpacing.md),
                        Row(
                          children: [
                            _stepper(context, item, busy),
                            const Spacer(),
                            lineTotal(),
                          ],
                        ),
                      ],
                    );
                  },
                ),
              ),
              if (busy) const LinearProgressIndicator(minHeight: 2),
            ],
          ),
        ),
      ),
    );
  }

  VoidCallback? _checkoutAction(CartModel cart) =>
      cart.items.isEmpty || cart.hasIssues ? null : () => context.go('/checkout');

  Widget _summary(CartModel cart) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final muted = theme.textTheme.bodySmall?.copyWith(color: scheme.onSurfaceVariant);
    return SectionCard(
      title: 'Summary',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Expanded(
                child: Text(
                  'Subtotal (${cart.itemCount} items)',
                  style: theme.textTheme.bodyMedium?.copyWith(color: scheme.onSurfaceVariant),
                ),
              ),
              PriceText(cart.subtotal, size: PriceSize.lg),
            ],
          ),
          if (cart.hasIssues) ...[
            const SizedBox(height: AppSpacing.sm),
            Text('Flagged items are not included in the subtotal.', style: muted),
            Text('Remove or fix flagged items to check out.', style: muted),
          ],
          const SizedBox(height: AppSpacing.lg),
          const Divider(),
          const SizedBox(height: AppSpacing.lg),
          FilledButton.icon(
            style: FilledButton.styleFrom(minimumSize: const Size(64, AppSizes.buttonHeightLarge)),
            onPressed: _checkoutAction(cart),
            icon: const Icon(Icons.lock_outline_rounded, size: 18),
            label: const Text('Checkout'),
          ),
          const SizedBox(height: AppSpacing.sm),
          TextButton(onPressed: () => context.go('/'), child: const Text('Continue shopping')),
          const SizedBox(height: AppSpacing.md),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.payments_outlined, size: 16, color: scheme.onSurfaceVariant),
              const SizedBox(width: AppSpacing.sm),
              Flexible(child: Text('Cash on delivery or demo payment at checkout', style: muted)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _bottomBar(CartModel cart) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: scheme.surfaceContainerLowest,
        border: Border(top: BorderSide(color: scheme.outlineVariant)),
        boxShadow: AppShadows.bar(scheme.brightness),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(AppSpacing.lg, AppSpacing.md, AppSpacing.lg, AppSpacing.md),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Subtotal (${cart.itemCount} items)',
                      style: theme.textTheme.bodySmall?.copyWith(color: scheme.onSurfaceVariant),
                    ),
                    PriceText(cart.subtotal, size: PriceSize.lg),
                    if (cart.hasIssues)
                      Text(
                        'Remove or fix flagged items to check out.',
                        style: theme.textTheme.bodySmall?.copyWith(color: scheme.error),
                      ),
                  ],
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              FilledButton.icon(
                onPressed: _checkoutAction(cart),
                icon: const Icon(Icons.lock_outline_rounded, size: 18),
                label: const Text('Checkout'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _body(BuildContext context, CartState state) {
    final cart = state.cart;
    if (cart.items.isEmpty) {
      if (state.status == CartStatus.initial || state.status == CartStatus.loading) {
        return PageContainer(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: const [
              StepIndicator(current: 0),
              SizedBox(height: AppSpacing.xxl),
              ListSkeleton(rows: 3),
            ],
          ),
        );
      }
      if (state.status == CartStatus.error) {
        return PageContainer(
          child: ErrorState(
            message: state.message ?? 'Could not load your cart',
            onRetry: () => context.read<CartBloc>().add(CartLoadRequested()),
          ),
        );
      }
      return PageContainer(
        child: EmptyState(
          icon: Icons.shopping_bag_outlined,
          title: 'Your cart is empty',
          message: 'Find something you love and it will show up here.',
          action: FilledButton(onPressed: () => context.go('/'), child: const Text('Continue shopping')),
        ),
      );
    }

    final header = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const StepIndicator(current: 0),
        SizedBox(height: context.isPhone ? AppSpacing.xl : AppSpacing.xxl),
        PageHeader(title: 'Your cart', subtitle: '${cart.itemCount} items'),
      ],
    );
    final lines = Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (final item in cart.items) _line(context, item, state.busyProductId == item.productId),
      ],
    );

    if (context.isDesktop) {
      return PageContainer(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            header,
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(child: lines),
                const SizedBox(width: AppSpacing.xxl),
                SizedBox(width: 380, child: _summary(cart)),
              ],
            ),
          ],
        ),
      );
    }
    if (!context.isPhone) {
      return PageContainer(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [header, lines, const SizedBox(height: AppSpacing.lg), _summary(cart)],
        ),
      );
    }
    final theme = Theme.of(context);
    return Column(
      children: [
        Expanded(
          child: PageContainer(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                header,
                lines,
                if (cart.hasIssues)
                  Text(
                    'Flagged items are not included in the subtotal.',
                    style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                  ),
              ],
            ),
          ),
        ),
        _bottomBar(cart),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<CartBloc, CartState>(builder: _body);
  }
}

/// Product name that opens the product page; underlines on hover.
class _ProductLink extends StatefulWidget {
  final String name;
  final VoidCallback onTap;

  const _ProductLink({required this.name, required this.onTap});

  @override
  State<_ProductLink> createState() => _ProductLinkState();
}

class _ProductLinkState extends State<_ProductLink> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return InkWell(
      onTap: widget.onTap,
      onHover: (h) => setState(() => _hovered = h),
      borderRadius: BorderRadius.circular(AppRadius.xs),
      hoverColor: Colors.transparent,
      child: Text(
        widget.name,
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
        style: theme.textTheme.titleMedium?.copyWith(
          decoration: _hovered ? TextDecoration.underline : TextDecoration.none,
        ),
      ),
    );
  }
}
