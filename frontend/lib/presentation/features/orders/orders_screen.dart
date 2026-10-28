import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/di/injection_container.dart';
import '../../../core/network/api_client.dart';
import '../../../core/utils/date_format.dart';
import '../../../models/order_model.dart';
import '../../../repositories/order_repository.dart';
import '../../components/empty_state.dart';
import '../../components/hover_card.dart';
import '../../components/error_state.dart';
import '../../components/loading_skeleton.dart';
import '../../components/page_container.dart';
import '../../components/page_header.dart';
import '../../components/pager.dart';
import '../../components/price_text.dart';
import '../../components/status_pill.dart';
import '../../../core/theme/app_tokens.dart';

class OrdersScreen extends StatefulWidget {
  const OrdersScreen({super.key});

  @override
  State<OrdersScreen> createState() => _OrdersScreenState();
}

class _OrdersScreenState extends State<OrdersScreen> {
  int _page = 1;
  OrderPage? _result;
  bool _loading = true;
  String? _error;

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
      final result = await sl<OrderRepository>().getMyOrders(page: _page);
      if (!mounted) return;
      setState(() => _result = result);
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

  void _goTo(int page) {
    _page = page;
    _load();
  }

  Widget _tile(BuildContext context, OrderSummaryModel o) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final muted = theme.textTheme.bodySmall?.copyWith(color: scheme.onSurfaceVariant);
    final phone = context.isPhone;
    final icon = Container(
      width: 48,
      height: 48,
      decoration: BoxDecoration(color: scheme.surfaceContainer, borderRadius: BorderRadius.circular(AppRadius.md)),
      child: Icon(Icons.inventory_2_outlined, color: scheme.onSurface, size: 22),
    );
    final summary = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Flexible(child: Text(shortOrderId(o.id), style: theme.textTheme.titleMedium)),
            const SizedBox(width: AppSpacing.sm),
            OrderStatusChip(o.status),
          ],
        ),
        const SizedBox(height: AppSpacing.xs),
        Text(
          '${o.firstItemName}${o.itemCount > 1 ? ' and more' : ''}',
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: theme.textTheme.bodyMedium,
        ),
        const SizedBox(height: 2),
        Text(
          '${formatOrderDate(o.createdAt)} · ${o.itemCount} items · ${paymentMethodLabel(o.paymentMethod)}',
          style: muted,
        ),
      ],
    );
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.md),
      child: HoverCard(
        onTap: () => context.go('/orders/${o.id}'),
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: phone
            ? Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  summary,
                  const SizedBox(height: AppSpacing.md),
                  Row(
                    children: [
                      PriceText(o.total, size: PriceSize.md),
                      const Spacer(),
                      Icon(Icons.arrow_forward_rounded, size: 18, color: scheme.onSurfaceVariant),
                    ],
                  ),
                ],
              )
            : Row(
                children: [
                  icon,
                  const SizedBox(width: AppSpacing.lg),
                  Expanded(child: summary),
                  const SizedBox(width: AppSpacing.lg),
                  PriceText(o.total, size: PriceSize.lg),
                  const SizedBox(width: AppSpacing.md),
                  Icon(Icons.chevron_right_rounded, color: scheme.onSurfaceVariant),
                ],
              ),
      ),
    );
  }

  Widget _body(BuildContext context) {
    if (_loading && _result == null) {
      return const ListSkeleton(rows: 4);
    }
    if (_error != null) {
      return ErrorState(message: _error!, onRetry: _load);
    }
    final result = _result;
    if (result == null || result.items.isEmpty) {
      return EmptyState(
        icon: Icons.receipt_long_outlined,
        title: 'You have no orders yet',
        message: 'When you place an order, you can follow it here.',
        action: FilledButton(onPressed: () => context.go('/'), child: const Text('Start shopping')),
      );
    }
    return Column(
      children: [
        for (final o in result.items) _tile(context, o),
        if (result.pages > 1)
          Padding(
            padding: const EdgeInsets.only(top: AppSpacing.lg),
            child: Pager(page: result.page, pages: result.pages, loading: _loading, onPage: _goTo),
          ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return PageContainer(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const PageHeader(title: 'My orders', subtitle: 'Track deliveries and revisit past purchases.'),
          _body(context),
        ],
      ),
    );
  }
}
