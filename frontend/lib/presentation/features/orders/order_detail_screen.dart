import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/di/injection_container.dart';
import '../../../core/network/api_client.dart';
import '../../../core/utils/money.dart';
import '../../../models/order_model.dart';
import '../../../repositories/order_repository.dart';
import '../../../core/theme/app_tokens.dart';
import '../../../core/theme/status_colors.dart';
import '../../../core/utils/date_format.dart';
import '../../components/app_snack.dart';
import '../../components/confirm_dialog.dart';
import '../../components/empty_state.dart';
import '../../components/error_state.dart';
import '../../components/loading_skeleton.dart';
import '../../components/order_sections.dart';
import '../../components/order_timeline.dart';
import '../../components/page_container.dart';
import '../../components/section_card.dart';
import '../../components/order_progress.dart';
import '../../components/page_header.dart';
import '../../components/status_pill.dart';
import '../../components/step_indicator.dart';

class OrderDetailScreen extends StatefulWidget {
  final String orderId;
  final bool justPlaced;

  const OrderDetailScreen({super.key, required this.orderId, this.justPlaced = false});

  @override
  State<OrderDetailScreen> createState() => _OrderDetailScreenState();
}

class _OrderDetailScreenState extends State<OrderDetailScreen> {
  OrderModel? _order;
  bool _loading = true;
  String? _error;
  bool _notFound = false;
  bool _cancelling = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
      _notFound = false;
    });
    try {
      final order = await sl<OrderRepository>().getOrder(widget.orderId);
      if (!mounted) return;
      setState(() => _order = order);
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() {
        _notFound = e.statusCode == 404 || e.statusCode == 400;
        _error = e.message;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _error = 'Something went wrong');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _cancel() async {
    final ok = await showConfirmDialog(
      context,
      title: 'Cancel this order?',
      message: 'The items go back to stock. This cannot be undone.',
      confirmLabel: 'Cancel order',
      cancelLabel: 'Keep order',
      destructive: true,
    );
    if (!ok || !mounted) return;
    setState(() => _cancelling = true);
    try {
      final order = await sl<OrderRepository>().cancelOrder(widget.orderId);
      if (!mounted) return;
      setState(() => _order = order);
      showAppSnack(context, 'Order cancelled');
    } on ApiException catch (e) {
      if (!mounted) return;
      if (e.statusCode != 401) showAppSnack(context, e.message, error: true);
      await _load();
    } catch (_) {
      if (mounted) showAppSnack(context, 'Something went wrong', error: true);
    } finally {
      if (mounted) setState(() => _cancelling = false);
    }
  }

  Widget _placedBanner(BuildContext context, OrderModel order) {
    final theme = Theme.of(context);
    final tone = StatusColors.of(context).success;
    return Container(
      padding: const EdgeInsets.all(AppSpacing.xl),
      decoration: BoxDecoration(
        color: tone.bg,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: tone.fg.withValues(alpha: 0.18)),
      ),
      child: Row(
        children: [
          TweenAnimationBuilder<double>(
            tween: Tween(begin: 0.4, end: 1),
            duration: AppMotion.image,
            curve: Curves.elasticOut,
            builder: (context, v, child) => Transform.scale(scale: v, child: child),
            child: Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(color: tone.fg, shape: BoxShape.circle),
              child: Icon(Icons.check_rounded, color: tone.bg, size: 30),
            ),
          ),
          const SizedBox(width: AppSpacing.lg),
          Expanded(
            child: DefaultTextStyle.merge(
              style: TextStyle(color: tone.fg),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Order placed', style: theme.textTheme.headlineSmall?.copyWith(color: tone.fg)),
                  const SizedBox(height: AppSpacing.xs),
                  Text('Payment: ${paymentStatusLabel(order.paymentStatus)}'),
                  if (order.paymentMethod == 'COD') Text('Pay ${formatPaise(order.total)} when it arrives'),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _content(BuildContext context, OrderModel order) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final timeline = SectionCard(
      title: 'Status history',
      icon: Icons.history_rounded,
      child: OrderTimeline(history: order.statusHistory),
    );
    final cancel = order.canCancel
        ? OutlinedButton.icon(
            onPressed: _cancelling ? null : _cancel,
            icon: const Icon(Icons.close_rounded, size: 18),
            label: const Text('Cancel order'),
            style: OutlinedButton.styleFrom(
              foregroundColor: scheme.error,
              side: BorderSide(color: scheme.error.withValues(alpha: 0.6)),
            ),
          )
        : null;
    final progress = SectionCard(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl, vertical: AppSpacing.xl),
      child: OrderProgress(status: order.status),
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (widget.justPlaced) ...[
          const StepIndicator(current: 2),
          const SizedBox(height: AppSpacing.xl),
          _placedBanner(context, order),
          const SizedBox(height: AppSpacing.xl),
        ],
        Text('ORDER DETAILS', style: theme.textTheme.labelSmall?.copyWith(color: scheme.secondary)),
        const SizedBox(height: AppSpacing.sm),
        Wrap(
          spacing: AppSpacing.md,
          runSpacing: AppSpacing.sm,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            Text(
              'Order ${shortOrderId(order.id)}',
              style: context.isPhone ? theme.textTheme.headlineMedium : theme.textTheme.headlineLarge,
            ),
            OrderStatusChip(order.status),
          ],
        ),
        const SizedBox(height: AppSpacing.xs),
        Text(
          'Placed on ${formatOrderDate(order.createdAt)}',
          style: theme.textTheme.bodyLarge?.copyWith(color: scheme.onSurfaceVariant),
        ),
        const SizedBox(height: AppSpacing.xl),
        progress,
        const SizedBox(height: AppSpacing.lg),
        if (context.isDesktop)
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                flex: 3,
                child: Column(
                  children: [OrderItemsSection(order: order), const SizedBox(height: AppSpacing.lg), timeline],
                ),
              ),
              const SizedBox(width: AppSpacing.lg),
              Expanded(
                flex: 2,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    ShippingAddressSection(address: order.shippingAddress),
                    const SizedBox(height: AppSpacing.lg),
                    PaymentSection(order: order),
                    if (cancel != null) ...[const SizedBox(height: AppSpacing.lg), cancel],
                  ],
                ),
              ),
            ],
          )
        else
          Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              OrderItemsSection(order: order),
              const SizedBox(height: AppSpacing.lg),
              ShippingAddressSection(address: order.shippingAddress),
              const SizedBox(height: AppSpacing.lg),
              PaymentSection(order: order),
              const SizedBox(height: AppSpacing.lg),
              timeline,
              if (cancel != null) ...[const SizedBox(height: AppSpacing.lg), cancel],
            ],
          ),
      ],
    );
  }

  Widget _body(BuildContext context) {
    final order = _order;
    if (_loading && order == null) {
      return const DetailSkeleton();
    }
    if (order == null) {
      if (_notFound) {
        return EmptyState(
          icon: Icons.search_off_rounded,
          title: 'Order not found',
          action: TextButton(onPressed: () => context.go('/orders'), child: const Text('Back to my orders')),
        );
      }
      return ErrorState(message: _error ?? 'Something went wrong', onRetry: _load);
    }
    return _content(context, order);
  }

  @override
  Widget build(BuildContext context) {
    return PageContainer(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          BackLink(label: 'My orders', onPressed: () => context.go('/orders')),
          const SizedBox(height: AppSpacing.lg),
          _body(context),
        ],
      ),
    );
  }
}
