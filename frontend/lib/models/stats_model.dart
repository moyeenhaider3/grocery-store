import 'package:equatable/equatable.dart';

import 'order_model.dart';

class LowStockItem extends Equatable {
  final String id;
  final String name;
  final int stock;
  final String stockStatus;

  const LowStockItem({required this.id, required this.name, required this.stock, required this.stockStatus});

  factory LowStockItem.fromJson(Map<String, dynamic> json) => LowStockItem(
        id: json['id'] as String,
        name: (json['name'] as String?) ?? '',
        stock: (json['stock'] as num?)?.toInt() ?? 0,
        stockStatus: (json['stockStatus'] as String?) ?? 'low_stock',
      );

  @override
  List<Object?> get props => [id, name, stock, stockStatus];
}

// Server-computed dashboard figures; the app only displays them.
class DashboardStats extends Equatable {
  final int paidRevenue;
  final int paidOrders;
  final int totalOrders;
  final Map<String, int> ordersByStatus;
  final int lowStockThreshold;
  final int lowStockCount;
  final List<LowStockItem> lowStock;
  final List<OrderSummaryModel> recentOrders;

  const DashboardStats({
    required this.paidRevenue,
    required this.paidOrders,
    required this.totalOrders,
    required this.ordersByStatus,
    this.lowStockThreshold = 0,
    this.lowStockCount = 0,
    this.lowStock = const [],
    this.recentOrders = const [],
  });

  factory DashboardStats.fromJson(Map<String, dynamic> json) {
    final revenue = (json['revenue'] as Map<String, dynamic>?) ?? const {};
    final byStatus = (json['ordersByStatus'] as Map<String, dynamic>?) ?? const {};
    final low = (json['lowStock'] as Map<String, dynamic>?) ?? const {};
    final lowItems = (low['items'] as List<dynamic>?) ?? const [];
    final recent = (json['recentOrders'] as List<dynamic>?) ?? const [];
    return DashboardStats(
      paidRevenue: (revenue['paid'] as num?)?.toInt() ?? 0,
      paidOrders: (revenue['paidOrders'] as num?)?.toInt() ?? 0,
      totalOrders: (json['totalOrders'] as num?)?.toInt() ?? 0,
      ordersByStatus: {for (final e in byStatus.entries) e.key: (e.value as num?)?.toInt() ?? 0},
      lowStockThreshold: (low['threshold'] as num?)?.toInt() ?? 0,
      lowStockCount: (low['count'] as num?)?.toInt() ?? 0,
      lowStock: [for (final i in lowItems) LowStockItem.fromJson(i as Map<String, dynamic>)],
      recentOrders: [for (final o in recent) OrderSummaryModel.fromJson(o as Map<String, dynamic>)],
    );
  }

  int countFor(String status) => ordersByStatus[status] ?? 0;

  @override
  List<Object?> get props => [paidRevenue, paidOrders, totalOrders, ordersByStatus, lowStockThreshold, lowStockCount, lowStock, recentOrders];
}
