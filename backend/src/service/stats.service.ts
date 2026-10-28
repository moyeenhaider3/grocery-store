import { Order, OrderStatus, PaymentStatus } from '../models/order.model';
import { LOW_STOCK_THRESHOLD, Product, StockStatus, stockStatusOf } from '../models/product.model';
import { AdminOrderSummary, OrderService } from './order.service';

export const LOW_STOCK_LIMIT = 10;
export const RECENT_ORDERS_LIMIT = 5;

export interface LowStockItem {
  id: string;
  name: string;
  stock: number;
  stockStatus: StockStatus;
}

export interface DashboardStats {
  revenue: { paid: number; paidOrders: number };
  ordersByStatus: Record<OrderStatus, number>;
  totalOrders: number;
  lowStock: { threshold: number; count: number; items: LowStockItem[] };
  recentOrders: AdminOrderSummary[];
}

export class StatsService {
  // Revenue counts only PAID orders (MOCK_PAY at placement, COD on delivery; REFUNDED excluded).
  public static async dashboard(): Promise<DashboardStats> {
    // Hidden (inactive) products are left out because they are not for sale.
    const lowStockFilter = { isActive: true, stock: { $lte: LOW_STOCK_THRESHOLD } };
    const [revenueRows, statusRows, lowProducts, lowCount, recentOrders] = await Promise.all([
      Order.aggregate<{ _id: null; paid: number; paidOrders: number }>([
        { $match: { paymentStatus: PaymentStatus.PAID } },
        { $group: { _id: null, paid: { $sum: '$total' }, paidOrders: { $sum: 1 } } },
      ]),
      Order.aggregate<{ _id: OrderStatus; count: number }>([
        { $group: { _id: '$status', count: { $sum: 1 } } },
      ]),
      Product.find(lowStockFilter)
        .sort({ stock: 1, name: 1, _id: 1 })
        .limit(LOW_STOCK_LIMIT)
        .select('name stock'),
      Product.countDocuments(lowStockFilter),
      OrderService.listRecent(RECENT_ORDERS_LIMIT),
    ]);

    const ordersByStatus = {} as Record<OrderStatus, number>;
    for (const s of Object.values(OrderStatus)) ordersByStatus[s] = 0;
    let totalOrders = 0;
    for (const row of statusRows) {
      if (Object.values(OrderStatus).includes(row._id)) {
        ordersByStatus[row._id] = row.count;
        totalOrders += row.count;
      }
    }

    return {
      revenue: { paid: revenueRows[0]?.paid ?? 0, paidOrders: revenueRows[0]?.paidOrders ?? 0 },
      ordersByStatus,
      totalOrders,
      lowStock: {
        threshold: LOW_STOCK_THRESHOLD,
        count: lowCount,
        items: lowProducts.map((p): LowStockItem => ({
          id: p._id.toString(),
          name: p.name,
          stock: p.stock,
          stockStatus: stockStatusOf(p.stock),
        })),
      },
      recentOrders,
    };
  }
}
