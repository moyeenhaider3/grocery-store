import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/di/injection_container.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/theme/app_tokens.dart';
import '../../../../core/utils/date_format.dart';
import '../../../../models/order_model.dart';
import '../../../../repositories/order_repository.dart';
import '../../../components/admin_list.dart';
import '../../../components/empty_state.dart';
import '../../../components/error_state.dart';
import '../../../components/loading_skeleton.dart';
import '../../../components/page_container.dart';
import '../../../components/page_header.dart';
import '../../../components/pager.dart';
import '../../../components/price_text.dart';
import '../../../components/status_pill.dart';

class AdminOrdersScreen extends StatefulWidget {
  const AdminOrdersScreen({super.key});

  @override
  State<AdminOrdersScreen> createState() => _AdminOrdersScreenState();
}

class _AdminOrdersScreenState extends State<AdminOrdersScreen> {
  int _page = 1;
  String? _status; // null = All
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
      final result = await sl<OrderRepository>().getAdminOrders(
        page: _page,
        status: _status,
      );
      if (!mounted) return;
      setState(() {
        _result = result;
        _loading = false;
      });
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.message;
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _error = 'Something went wrong';
        _loading = false;
      });
    }
  }

  void _setStatus(String? status) {
    _status = status;
    _page = 1;
    _load();
  }

  void _goToPage(int page) {
    _page = page;
    _load();
  }

  Widget _filters() {
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.md),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            Padding(
              padding: const EdgeInsets.only(right: AppSpacing.sm),
              child: ChoiceChip(
                label: const Text('All'),
                selected: _status == null,
                onSelected: (_) => _setStatus(null),
                labelStyle: TextStyle(
                  color: _status == null ? scheme.onPrimary : scheme.onSurface,
                ),
              ),
            ),
            for (final s in adminOrderStatusFilters)
              Padding(
                padding: const EdgeInsets.only(right: AppSpacing.sm),
                child: ChoiceChip(
                  labelStyle: TextStyle(
                    color:  _status == s
                        ? scheme.onPrimary
                        : scheme.onSurface,
                  ),
                  label: Text(orderStatusLabel(s)),
                  selected: _status == s,
                  onSelected: (_) => _setStatus(s),
                ),
              ),
          ],
        ),
      ),
    );
  }

  static const _columns = [
    AdminColumn('Order', flex: 2),
    AdminColumn('Customer', flex: 3),
    AdminColumn('Date', flex: 2),
    AdminColumn('Items'),
    AdminColumn('Total', flex: 2),
    AdminColumn('Status', flex: 2),
    AdminColumn('Payment', flex: 2),
  ];

  Widget _tableRow(OrderSummaryModel o) {
    final theme = Theme.of(context);
    final c = o.customer;
    return AdminTableRow(
      columns: _columns,
      onTap: () => context.go('/admin/orders/${o.id}'),
      cells: [
        Text(shortOrderId(o.id), maxLines: 1, overflow: TextOverflow.ellipsis),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              c?.name ?? 'Deleted user',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            Text(
              c?.email ?? '-',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
        Text(
          formatOrderDate(o.createdAt),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        Text('${o.itemCount}', maxLines: 1),
        FittedBox(
          fit: BoxFit.scaleDown,
          alignment: Alignment.centerLeft,
          child: PriceText(o.total, size: PriceSize.sm),
        ),
        FittedBox(
          fit: BoxFit.scaleDown,
          alignment: Alignment.centerLeft,
          child: OrderStatusChip(o.status),
        ),
        FittedBox(
          fit: BoxFit.scaleDown,
          alignment: Alignment.centerLeft,
          child: PaymentStatusChip(o.paymentStatus),
        ),
      ],
    );
  }

  Widget _card(OrderSummaryModel o) {
    final theme = Theme.of(context);
    final muted = theme.colorScheme.onSurfaceVariant;
    final c = o.customer;
    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => context.go('/admin/orders/${o.id}'),
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text(shortOrderId(o.id), style: theme.textTheme.titleMedium),
                  const Spacer(),
                  OrderStatusChip(o.status),
                ],
              ),
              const SizedBox(height: AppSpacing.xs),
              Text(
                c?.name ?? 'Deleted user',
                style: theme.textTheme.bodyMedium,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              Text(
                c?.email ?? '-',
                style: theme.textTheme.bodySmall?.copyWith(color: muted),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: AppSpacing.sm),
              Row(
                children: [
                  Expanded(
                    child: Wrap(
                      spacing: AppSpacing.sm,
                      runSpacing: AppSpacing.xs,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        Text(
                          formatOrderDate(o.createdAt),
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: muted,
                          ),
                        ),
                        Text(
                          '${o.itemCount} items',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: muted,
                          ),
                        ),
                        PaymentStatusChip(o.paymentStatus),
                      ],
                    ),
                  ),
                  PriceText(o.total, size: PriceSize.md),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return PageContainer(
      scroll: false,
      child: LayoutBuilder(
        builder: (context, c) {
          final table = c.maxWidth >= kAdminTableMinWidth;
          final result = _result;
          final items = result?.items ?? const <OrderSummaryModel>[];
          return CustomScrollView(
            slivers: [
              const SliverToBoxAdapter(child: PageHeader(title: 'Orders')),
              SliverToBoxAdapter(child: _filters()),
              if (_loading && result == null)
                const SliverToBoxAdapter(child: ListSkeleton(rows: 6))
              else if (_error != null)
                SliverFillRemaining(
                  hasScrollBody: false,
                  child: ErrorState(message: _error!, onRetry: _load),
                )
              else if (items.isEmpty)
                SliverFillRemaining(
                  hasScrollBody: false,
                  child: EmptyState(
                    icon: Icons.receipt_long_outlined,
                    title: _status == null
                        ? 'No orders'
                        : 'No ${orderStatusLabel(_status!).toLowerCase()} orders',
                  ),
                )
              else
                SliverOpacity(
                  opacity: _loading ? 0.5 : 1,
                  sliver: table
                      ? SliverToBoxAdapter(
                          child: AdminListCard(
                            columns: _columns,
                            rows: [for (final o in items) _tableRow(o)],
                          ),
                        )
                      : SliverList.separated(
                          itemCount: items.length,
                          separatorBuilder: (_, _) =>
                              const SizedBox(height: AppSpacing.md),
                          itemBuilder: (_, i) => _card(items[i]),
                        ),
                ),
              if (result != null)
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      vertical: AppSpacing.lg,
                    ),
                    child: Pager(
                      page: result.page,
                      pages: result.pages,
                      total: result.total,
                      noun: 'orders',
                      loading: _loading,
                      onPage: _goToPage,
                    ),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
}
