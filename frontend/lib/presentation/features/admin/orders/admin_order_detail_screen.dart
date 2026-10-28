import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/di/injection_container.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/theme/app_tokens.dart';
import '../../../../core/theme/status_colors.dart';
import '../../../../core/utils/date_format.dart';
import '../../../../models/order_model.dart';
import '../../../../repositories/order_repository.dart';
import '../../../components/app_snack.dart';
import '../../../components/confirm_dialog.dart';
import '../../../components/error_state.dart';
import '../../../components/loading_skeleton.dart';
import '../../../components/order_sections.dart';
import '../../../components/order_timeline.dart';
import '../../../components/page_container.dart';
import '../../../components/section_card.dart';
import '../../../components/status_pill.dart';

class AdminOrderDetailScreen extends StatefulWidget {
  final String orderId;

  const AdminOrderDetailScreen({super.key, required this.orderId});

  @override
  State<AdminOrderDetailScreen> createState() => _AdminOrderDetailScreenState();
}

class _AdminOrderDetailScreenState extends State<AdminOrderDetailScreen> {
  OrderModel? _order;
  bool _loading = true;
  String? _error;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final order = await sl<OrderRepository>().getAdminOrder(widget.orderId);
      if (!mounted) return;
      setState(() => _order = order);
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() => _error = e.message);
    } catch (_) {
      if (!mounted) return;
      setState(() => _error = 'Something went wrong');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _change(String status) async {
    if (status == 'CANCELLED') {
      final ok = await showConfirmDialog(
        context,
        title: 'Cancel this order?',
        message: 'Cancel this order? Items go back into stock.',
        confirmLabel: 'Cancel order',
        cancelLabel: 'Keep order',
        destructive: true,
      );
      if (!ok || !mounted) return;
    }
    setState(() => _saving = true);
    try {
      final order = await sl<OrderRepository>().updateOrderStatus(widget.orderId, status);
      if (!mounted) return;
      setState(() => _order = order);
      showAppSnack(context, 'Order marked ${orderStatusLabel(status).toLowerCase()}');
    } on ApiException catch (e) {
      if (!mounted) return;
      if (e.statusCode != 401) showAppSnack(context, e.message, error: true);
      if (e.code == 'INVALID_STATUS_TRANSITION' || e.code == 'ORDER_STATUS_CHANGED') await _load();
    } catch (_) {
      if (mounted) showAppSnack(context, 'Something went wrong', error: true);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Widget _actions(OrderModel order) {
    final next = adminNextStatuses(order.status);
    if (next.isEmpty) return const SizedBox.shrink();
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.lg),
      child: SectionCard(
        title: 'Actions',
        child: Wrap(
          spacing: AppSpacing.md,
          runSpacing: AppSpacing.md,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            for (final s in next)
              if (s == 'CANCELLED')
                OutlinedButton.icon(
                  onPressed: _saving ? null : () => _change(s),
                  icon: const Icon(Icons.cancel_outlined),
                  label: const Text('Cancel order'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: scheme.error,
                    side: BorderSide(color: scheme.error),
                  ),
                )
              else
                Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    FilledButton(
                      onPressed: _saving ? null : () => _change(s),
                      child: Text(switch (s) {
                        'CONFIRMED' => 'Mark confirmed',
                        'SHIPPED' => 'Mark shipped',
                        _ => 'Mark delivered',
                      }),
                    ),
                    if (s == 'DELIVERED' && order.paymentMethod == 'COD')
                      Padding(
                        padding: const EdgeInsets.only(top: AppSpacing.xs),
                        child: Text(
                          'Marks Cash on Delivery as paid',
                          style: theme.textTheme.bodySmall?.copyWith(color: StatusColors.of(context).warning.fg),
                        ),
                      ),
                  ],
                ),
            if (_saving) const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2)),
          ],
        ),
      ),
    );
  }

  Widget _content(BuildContext context, OrderModel order) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final c = order.customer;
    final customer = SectionCard(
      title: 'Customer',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(c?.name ?? 'Deleted user'),
          if (c != null)
            Text(c.email, style: theme.textTheme.bodySmall?.copyWith(color: scheme.onSurfaceVariant)),
        ],
      ),
    );
    final history = SectionCard(
      title: 'Status history',
      child: OrderTimeline(history: order.statusHistory),
    );
    const gap = SizedBox(height: AppSpacing.lg);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Wrap(
          spacing: AppSpacing.md,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            Text('Order ${shortOrderId(order.id)}', style: theme.textTheme.headlineSmall),
            OrderStatusChip(order.status),
          ],
        ),
        Text(
          'Placed on ${formatOrderDate(order.createdAt)}',
          style: theme.textTheme.bodyMedium?.copyWith(color: scheme.onSurfaceVariant),
        ),
        gap,
        _actions(order),
        if (context.isDesktop)
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                flex: 3,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [OrderItemsSection(order: order), gap, history],
                ),
              ),
              const SizedBox(width: AppSpacing.xl),
              Expanded(
                flex: 2,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    customer,
                    gap,
                    ShippingAddressSection(address: order.shippingAddress),
                    gap,
                    PaymentSection(order: order),
                  ],
                ),
              ),
            ],
          )
        else
          Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              customer,
              gap,
              ShippingAddressSection(address: order.shippingAddress),
              gap,
              OrderItemsSection(order: order),
              gap,
              PaymentSection(order: order),
              gap,
              history,
            ],
          ),
      ],
    );
  }

  Widget _body(BuildContext context) {
    final order = _order;
    if (_loading && order == null) return const DetailSkeleton();
    if (order == null) return ErrorState(message: _error ?? 'Something went wrong', onRetry: _load);
    return _content(context, order);
  }

  @override
  Widget build(BuildContext context) {
    return PageContainer(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TextButton.icon(
            onPressed: () => context.go('/admin/orders'),
            icon: const Icon(Icons.arrow_back),
            label: const Text('All orders'),
          ),
          _body(context),
        ],
      ),
    );
  }
}
