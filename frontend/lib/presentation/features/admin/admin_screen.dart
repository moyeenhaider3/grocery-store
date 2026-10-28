import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/di/injection_container.dart';
import '../../../core/network/api_client.dart';
import '../../../core/theme/app_tokens.dart';
import '../../../core/theme/status_colors.dart';
import '../../../core/utils/date_format.dart';
import '../../../core/utils/money.dart';
import '../../../models/order_model.dart';
import '../../../models/stats_model.dart';
import '../../../repositories/admin_repository.dart';
import '../../components/error_state.dart';
import '../../components/loading_skeleton.dart';
import '../../components/page_container.dart';
import '../../components/page_header.dart';
import '../../components/price_text.dart';
import '../../components/section_card.dart';
import '../../components/status_pill.dart';
import '../../components/stock_badge.dart';

class AdminScreen extends StatefulWidget {
  const AdminScreen({super.key});

  @override
  State<AdminScreen> createState() => _AdminScreenState();
}

class _AdminScreenState extends State<AdminScreen> {
  DashboardStats? _stats;
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
      final stats = await sl<AdminRepository>().getStats();
      if (!mounted) return;
      setState(() {
        _stats = stats;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e is ApiException ? e.message : 'Something went wrong';
        _loading = false;
      });
    }
  }

  static IconData _statusIcon(String s) => switch (s) {
    'PENDING' => Icons.hourglass_empty,
    'CONFIRMED' => Icons.check_circle_outline,
    'SHIPPED' => Icons.local_shipping_outlined,
    'DELIVERED' => Icons.done_all,
    'CANCELLED' => Icons.cancel_outlined,
    _ => Icons.receipt_long_outlined,
  };

  Widget _buildStats() {
    if (_loading && _stats == null) {
      return Wrap(
        spacing: AppSpacing.md,
        runSpacing: AppSpacing.md,
        children: [for (var i = 0; i < 7; i++) const SkeletonBox(width: 200, height: 112, radius: AppRadius.lg)],
      );
    }
    final stats = _stats;
    if (stats == null) {
      return ErrorState(message: _error ?? 'Something went wrong', onRetry: _load);
    }
    final colors = StatusColors.of(context);
    return LayoutBuilder(
      builder: (context, constraints) {
        const gap = AppSpacing.md;
        final maxWidth = constraints.maxWidth;
        final phoneWidth = maxWidth < 600;
        final columns = phoneWidth ? 2 : math.max(2, (maxWidth / 240).floor());
        final cardWidth = (maxWidth - gap * (columns - 1)) / columns;
        return Wrap(
          spacing: gap,
          runSpacing: gap,
          children: [
            SizedBox(
              width: phoneWidth ? maxWidth : cardWidth,
              child: _StatCard(
                label: 'Paid revenue',
                value: formatPaise(stats.paidRevenue),
                subtitle: '${stats.paidOrders} paid orders',
                icon: Icons.payments_outlined,
                tone: colors.success,
              ),
            ),
            SizedBox(
              width: cardWidth,
              child: _StatCard(
                label: 'All orders',
                value: '${stats.totalOrders}',
                icon: Icons.receipt_long_outlined,
                tone: colors.info,
              ),
            ),
            for (final s in adminOrderStatusFilters)
              SizedBox(
                width: cardWidth,
                child: _StatCard(
                  label: orderStatusLabel(s),
                  value: '${stats.countFor(s)}',
                  icon: _statusIcon(s),
                  tone: StatusColors.of(context).order(s),
                ),
              ),
          ],
        );
      },
    );
  }

  Widget _lowStockCard(DashboardStats stats) {
    final theme = Theme.of(context);
    return SectionCard(
      title: 'Low stock (${stats.lowStockCount})',
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
            child: Text(
              'Active products with stock at or below ${stats.lowStockThreshold}',
              style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
            ),
          ),
          if (stats.lowStock.isEmpty)
            const Padding(padding: EdgeInsets.all(AppSpacing.lg), child: Text('No low-stock products'))
          else
            for (final p in stats.lowStock)
              ListTile(
                title: Text(p.name, overflow: TextOverflow.ellipsis),
                subtitle: Text('Stock: ${p.stock}'),
                trailing: StockBadge(stockStatus: p.stockStatus),
                onTap: () => context.go('/admin/products/${p.id}'),
              ),
          if (stats.lowStockCount > stats.lowStock.length)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
              child: TextButton(onPressed: () => context.go('/admin/products'), child: const Text('View all products')),
            ),
        ],
      ),
    );
  }

  Widget _recentOrdersCard(DashboardStats stats) {
    return SectionCard(
      title: 'Recent orders',
      trailing: TextButton(onPressed: () => context.go('/admin/orders'), child: const Text('View all orders')),
      child: stats.recentOrders.isEmpty
          ? const Text('No orders yet')
          : Column(
              children: [
                for (final o in stats.recentOrders)
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: Text(
                      '${shortOrderId(o.id)} · ${o.customer?.name ?? 'Deleted user'}',
                      overflow: TextOverflow.ellipsis,
                    ),
                    subtitle: Text(formatOrderDate(o.createdAt)),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        PriceText(o.total, size: PriceSize.sm),
                        const SizedBox(width: AppSpacing.sm),
                        OrderStatusChip(o.status),
                      ],
                    ),
                    onTap: () => context.go('/admin/orders/${o.id}'),
                  ),
              ],
            ),
    );
  }

  Widget _panels(DashboardStats stats) {
    if (context.isDesktop) {
      return Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(child: _lowStockCard(stats)),
          const SizedBox(width: AppSpacing.xl),
          Expanded(child: _recentOrdersCard(stats)),
        ],
      );
    }
    return Column(
      children: [
        _lowStockCard(stats),
        const SizedBox(height: AppSpacing.xl),
        _recentOrdersCard(stats),
      ],
    );
  }

  Widget _quickLink(IconData icon, String title, String path) {
    return SizedBox(
      width: 220,
      child: Card(
        child: ListTile(
          leading: Icon(icon),
          title: Text(title),
          trailing: const Icon(Icons.chevron_right),
          onTap: () => context.go(path),
        ),
      ),
    );
  }

  Widget _manage() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Manage', style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: AppSpacing.sm),
        Wrap(
          spacing: AppSpacing.md,
          runSpacing: AppSpacing.md,
          children: [
            _quickLink(Icons.receipt_long_outlined, 'Orders', '/admin/orders'),
            _quickLink(Icons.people_outline, 'Users', '/admin/users'),
            _quickLink(Icons.inventory_2_outlined, 'Products', '/admin/products'),
            _quickLink(Icons.category_outlined, 'Categories', '/admin/categories'),
          ],
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final stats = _stats;
    return PageContainer(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          PageHeader(
            title: 'Dashboard',
            actions: [IconButton(icon: const Icon(Icons.refresh), tooltip: 'Refresh', onPressed: _load)],
          ),
          _buildStats(),
          if (stats != null) ...[
            const SizedBox(height: AppSpacing.xl),
            _panels(stats),
          ],
          const SizedBox(height: AppSpacing.xl),
          _manage(),
        ],
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String label;
  final String value;
  final String? subtitle;
  final IconData icon;
  final StatusTone tone;

  const _StatCard({required this.label, required this.value, required this.icon, required this.tone, this.subtitle});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final muted = theme.colorScheme.onSurfaceVariant;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(color: tone.bg, borderRadius: BorderRadius.circular(AppRadius.md)),
                  child: Icon(icon, size: 18, color: tone.fg),
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(child: Text(label, style: theme.textTheme.bodyMedium?.copyWith(color: muted))),
              ],
            ),
            const SizedBox(height: AppSpacing.md),
            Align(
              alignment: Alignment.centerLeft,
              child: FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.centerLeft,
                child: Text(
                  value,
                  maxLines: 1,
                  style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w700),
                ),
              ),
            ),
            if (subtitle != null) Text(subtitle!, style: theme.textTheme.bodySmall?.copyWith(color: muted)),
          ],
        ),
      ),
    );
  }
}
