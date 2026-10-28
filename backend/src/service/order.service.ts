import { Types } from 'mongoose';
import {
  Order,
  IOrderDocument,
  IOrderItem,
  OrderStatus,
  PaymentMethod,
  PaymentStatus,
} from '../models/order.model';
import { Cart } from '../models/cart.model';
import { Product } from '../models/product.model';
import { AppError } from '../middlewares/error.middleware';
import { assertObjectId } from '../validation/catalog.schemas';
import {
  AdminListOrdersQuery,
  ListOrdersQuery,
  ORDERS_PAGE_SIZE,
  PlaceOrderInput,
  UpdateOrderStatusInput,
} from '../validation/order.schemas';

export interface OrderView {
  id: string;
  status: OrderStatus;
  paymentMethod: PaymentMethod;
  paymentStatus: PaymentStatus;
  total: number;
  itemCount: number;
  createdAt: Date;
  items: {
    productId: string;
    name: string;
    imageUrl: string | null;
    unitPrice: number;
    quantity: number;
    lineTotal: number;
  }[];
  shippingAddress: {
    fullName: string;
    phone: string;
    addressLine: string;
    city: string;
    postalCode: string;
  };
  statusHistory: { status: OrderStatus; at: Date }[];
}

export interface OrderSummary {
  id: string;
  status: OrderStatus;
  paymentMethod: PaymentMethod;
  paymentStatus: PaymentStatus;
  total: number;
  itemCount: number;
  createdAt: Date;
  firstItemName: string;
}

// One step forward, or cancel before shipping.
export const ADMIN_TRANSITIONS: Record<OrderStatus, OrderStatus[]> = {
  [OrderStatus.PENDING]: [OrderStatus.CONFIRMED, OrderStatus.CANCELLED],
  [OrderStatus.CONFIRMED]: [OrderStatus.SHIPPED, OrderStatus.CANCELLED],
  [OrderStatus.SHIPPED]: [OrderStatus.DELIVERED],
  [OrderStatus.DELIVERED]: [],
  [OrderStatus.CANCELLED]: [],
};

export interface OrderCustomer {
  id: string;
  name: string;
  email: string;
}
export type AdminOrderView = OrderView & { customer: OrderCustomer | null };
export type AdminOrderSummary = OrderSummary & { customer: OrderCustomer | null };

interface StockProblem {
  productId: string;
  name: string;
  available: number;
  reason: 'unavailable' | 'insufficient_stock';
}

interface Decremented {
  productId: Types.ObjectId;
  quantity: number;
}

const itemCountOf = (order: IOrderDocument): number => order.items.reduce((n, i) => n + i.quantity, 0);

export class OrderService {
  public static toView(order: IOrderDocument): OrderView {
    return {
      id: order._id.toString(),
      status: order.status,
      paymentMethod: order.paymentMethod,
      paymentStatus: order.paymentStatus,
      total: order.total,
      itemCount: itemCountOf(order),
      createdAt: order.createdAt,
      items: order.items.map((i) => ({
        productId: i.product.toString(),
        name: i.name,
        imageUrl: i.imageUrl ?? null,
        unitPrice: i.unitPrice,
        quantity: i.quantity,
        lineTotal: i.lineTotal,
      })),
      shippingAddress: {
        fullName: order.shippingAddress.fullName,
        phone: order.shippingAddress.phone,
        addressLine: order.shippingAddress.addressLine,
        city: order.shippingAddress.city,
        postalCode: order.shippingAddress.postalCode,
      },
      statusHistory: order.statusHistory.map((s) => ({ status: s.status, at: s.at })),
    };
  }

  public static toSummary(order: IOrderDocument): OrderSummary {
    return {
      id: order._id.toString(),
      status: order.status,
      paymentMethod: order.paymentMethod,
      paymentStatus: order.paymentStatus,
      total: order.total,
      itemCount: itemCountOf(order),
      createdAt: order.createdAt,
      firstItemName: order.items[0]?.name ?? '',
    };
  }

  private static stockError(problems: StockProblem[]): AppError {
    const unavailable = problems.find((p) => p.reason === 'unavailable');
    if (unavailable) {
      return new AppError(`"${unavailable.name}" is no longer available`, 409, 'ITEM_UNAVAILABLE', problems);
    }
    const first = problems[0];
    const message = first.available === 0 ? `"${first.name}" is out of stock` : `Only ${first.available} left of "${first.name}"`;
    return new AppError(message, 409, 'INSUFFICIENT_STOCK', problems);
  }

  // Compensating action: give back stock already taken for earlier lines.
  private static async rollback(decremented: Decremented[]): Promise<void> {
    if (decremented.length === 0) return;
    try {
      await Product.bulkWrite(
        decremented.map((d) => ({ updateOne: { filter: { _id: d.productId }, update: { $inc: { stock: d.quantity } } } })),
        { ordered: false }
      );
    } catch (err) {
      // Do not mask the original error; log for manual stock reconciliation.
      console.error('Stock rollback failed, reconcile manually:', JSON.stringify(decremented), err);
    }
  }

  public static async placeOrder(userId: string, input: PlaceOrderInput): Promise<OrderView> {
    // Atomically claim the cart: only one concurrent request gets the items,
    // so a double tap or retry cannot create a duplicate order.
    const cart = await Cart.findOneAndUpdate(
      { user: userId, 'items.0': { $exists: true } },
      { $set: { items: [] } },
      { returnDocument: 'before' }
    );
    if (!cart) throw new AppError('Your cart is empty', 400, 'CART_EMPTY');

    try {
      return await OrderService.createFromCart(userId, cart.items, input);
    } catch (err) {
      // Give the customer their cart back (unless they already started a new one).
      await Cart.updateOne({ user: userId, 'items.0': { $exists: false } }, { $set: { items: cart.items } }).catch(
        () => undefined
      );
      throw err;
    }
  }

  private static async createFromCart(
    userId: string,
    cartItems: { product: Types.ObjectId; quantity: number }[],
    input: PlaceOrderInput
  ): Promise<OrderView> {
    const products = await Product.find({ _id: { $in: cartItems.map((i) => i.product) } });
    const byId = new Map(products.map((p) => [p._id.toString(), p]));

    // Pre-check every line; nothing is written yet.
    const problems: StockProblem[] = [];
    for (const line of cartItems) {
      const product = byId.get(line.product.toString());
      if (!product || !product.isActive) {
        problems.push({
          productId: line.product.toString(),
          name: product?.name ?? 'An item',
          available: 0,
          reason: 'unavailable',
        });
      } else if (product.stock < line.quantity) {
        problems.push({
          productId: product._id.toString(),
          name: product.name,
          available: product.stock,
          reason: 'insufficient_stock',
        });
      }
    }
    if (problems.length > 0) throw OrderService.stockError(problems);

    // Prices come only from the Product documents, never from the request.
    const items: IOrderItem[] = cartItems.map((line) => {
      const product = byId.get(line.product.toString())!;
      return {
        product: product._id,
        name: product.name,
        imageUrl: product.imageUrl ?? null,
        unitPrice: product.price,
        quantity: line.quantity,
        lineTotal: product.price * line.quantity,
      };
    });
    const total = items.reduce((s, i) => s + i.lineTotal, 0);

    // The conditional filter and $inc apply as one atomic update, so concurrent
    // orders for the last unit cannot both match.
    const decremented: Decremented[] = [];
    for (const item of items) {
      const res = await Product.updateOne(
        { _id: item.product, isActive: true, stock: { $gte: item.quantity } },
        { $inc: { stock: -item.quantity } }
      );
      if (res.modifiedCount !== 1) {
        await OrderService.rollback(decremented);
        const fresh = await Product.findById(item.product);
        const problem: StockProblem =
          !fresh || !fresh.isActive
            ? { productId: item.product.toString(), name: fresh?.name ?? item.name, available: 0, reason: 'unavailable' }
            : { productId: item.product.toString(), name: fresh.name, available: fresh.stock, reason: 'insufficient_stock' };
        throw OrderService.stockError([problem]);
      }
      decremented.push({ productId: item.product, quantity: item.quantity });
    }

    let order: IOrderDocument;
    try {
      order = await Order.create({
        user: userId,
        items,
        shippingAddress: input.shippingAddress,
        paymentMethod: input.paymentMethod,
        // The mock "Pay now" step always succeeds.
        paymentStatus: input.paymentMethod === PaymentMethod.MOCK_PAY ? PaymentStatus.PAID : PaymentStatus.UNPAID,
        status: OrderStatus.PENDING,
        statusHistory: [{ status: OrderStatus.PENDING, at: new Date() }],
        total,
      });
    } catch (err) {
      await OrderService.rollback(decremented);
      throw err;
    }

    return OrderService.toView(order);
  }

  public static async listMine(userId: string, query: ListOrdersQuery) {
    const filter = { user: userId };
    const [orders, total] = await Promise.all([
      Order.find(filter)
        .sort({ createdAt: -1, _id: -1 })
        .skip((query.page - 1) * ORDERS_PAGE_SIZE)
        .limit(ORDERS_PAGE_SIZE),
      Order.countDocuments(filter),
    ]);
    return {
      items: orders.map((o) => OrderService.toSummary(o)),
      pagination: {
        total,
        page: query.page,
        limit: ORDERS_PAGE_SIZE,
        pages: Math.max(1, Math.ceil(total / ORDERS_PAGE_SIZE)),
      },
    };
  }

  public static async getMine(userId: string, orderId: string): Promise<OrderView> {
    assertObjectId(orderId, 'order id');
    // Foreign ids look the same as unknown ids.
    const order = await Order.findOne({ _id: orderId, user: userId });
    if (!order) throw new AppError('Order not found', 404, 'ORDER_NOT_FOUND');
    return OrderService.toView(order);
  }

  // No isActive filter: an inactive product still gets its units back.
  public static async restock(order: IOrderDocument): Promise<void> {
    await Product.bulkWrite(
      order.items.map((i) => ({ updateOne: { filter: { _id: i.product }, update: { $inc: { stock: i.quantity } } } })),
      { ordered: false }
    );
  }

  public static async cancelMine(userId: string, orderId: string): Promise<OrderView> {
    assertObjectId(orderId, 'order id');
    // Single conditional transition: only the request that flips PENDING restocks.
    const order = await Order.findOneAndUpdate(
      { _id: orderId, user: userId, status: OrderStatus.PENDING },
      {
        $set: { status: OrderStatus.CANCELLED },
        $push: { statusHistory: { status: OrderStatus.CANCELLED, at: new Date() } },
      },
      { returnDocument: 'after' }
    );
    if (!order) {
      const exists = await Order.exists({ _id: orderId, user: userId });
      if (!exists) throw new AppError('Order not found', 404, 'ORDER_NOT_FOUND');
      throw new AppError('Only pending orders can be cancelled', 409, 'ORDER_NOT_CANCELLABLE');
    }
    await OrderService.finishCancel(order);
    return OrderService.toView(order);
  }

  // Shared tail of a cancel: restock exactly once, then refund a paid order.
  // The order stays CANCELLED even if restock fails; reverting would let a retry
  // re-increment lines that already succeeded and inflate stock.
  private static async finishCancel(order: IOrderDocument): Promise<void> {
    // Claim the restock first so concurrent or repeated calls can never double-increment.
    const claimed = await Order.findOneAndUpdate(
      { _id: order._id, restocked: { $ne: true } },
      { $set: { restocked: true } }
    );
    if (claimed) {
      try {
        await OrderService.restock(order);
      } catch (err) {
        console.error('Restock failed after cancel, reconcile stock for order', order._id.toString(), err);
      }
    }
    // Demo payments are refunded on cancel so the order does not stay "Paid".
    if (order.paymentStatus === PaymentStatus.PAID) {
      await Order.updateOne({ _id: order._id }, { $set: { paymentStatus: PaymentStatus.REFUNDED } });
      order.paymentStatus = PaymentStatus.REFUNDED;
    }
  }

  // The populated user is null when the account no longer exists.
  private static customerOf(order: IOrderDocument): OrderCustomer | null {
    const u = order.user as unknown as { _id: Types.ObjectId; name: string; email: string } | null;
    if (!u || !u.email) return null;
    return { id: u._id.toString(), name: u.name, email: u.email };
  }

  public static async listAll(query: AdminListOrdersQuery) {
    const filter = query.status ? { status: query.status } : {};
    const [orders, total] = await Promise.all([
      Order.find(filter)
        .sort({ createdAt: -1, _id: -1 })
        .skip((query.page - 1) * ORDERS_PAGE_SIZE)
        .limit(ORDERS_PAGE_SIZE)
        .populate('user', 'name email'),
      Order.countDocuments(filter),
    ]);
    return {
      items: orders.map((o): AdminOrderSummary => ({ ...OrderService.toSummary(o), customer: OrderService.customerOf(o) })),
      pagination: {
        total,
        page: query.page,
        limit: ORDERS_PAGE_SIZE,
        pages: Math.max(1, Math.ceil(total / ORDERS_PAGE_SIZE)),
      },
    };
  }

  public static async listRecent(limit: number): Promise<AdminOrderSummary[]> {
    const orders = await Order.find({})
      .sort({ createdAt: -1, _id: -1 })
      .limit(limit)
      .populate('user', 'name email');
    return orders.map((o): AdminOrderSummary => ({ ...OrderService.toSummary(o), customer: OrderService.customerOf(o) }));
  }

  public static async getAny(orderId: string): Promise<AdminOrderView> {
    assertObjectId(orderId, 'order id');
    const order = await Order.findById(orderId).populate('user', 'name email');
    if (!order) throw new AppError('Order not found', 404, 'ORDER_NOT_FOUND');
    return { ...OrderService.toView(order), customer: OrderService.customerOf(order) };
  }

  public static async updateStatus(orderId: string, input: UpdateOrderStatusInput): Promise<AdminOrderView> {
    assertObjectId(orderId, 'order id');
    const current = await Order.findById(orderId);
    if (!current) throw new AppError('Order not found', 404, 'ORDER_NOT_FOUND');
    if (!ADMIN_TRANSITIONS[current.status].includes(input.status)) {
      throw new AppError(
        `Cannot change an order from ${current.status} to ${input.status}`,
        409,
        'INVALID_STATUS_TRANSITION'
      );
    }
    const $set: Record<string, unknown> = { status: input.status };
    // Cash is collected on delivery.
    if (input.status === OrderStatus.DELIVERED && current.paymentMethod === PaymentMethod.COD) {
      $set.paymentStatus = PaymentStatus.PAID;
    }
    // The filter includes the status read above, so only one concurrent request wins.
    const updated = await Order.findOneAndUpdate(
      { _id: orderId, status: current.status },
      { $set, $push: { statusHistory: { status: input.status, at: new Date() } } },
      { returnDocument: 'after' }
    );
    if (!updated) {
      throw new AppError('This order was just updated by someone else. Reload and try again.', 409, 'ORDER_STATUS_CHANGED');
    }
    if (input.status === OrderStatus.CANCELLED) {
      await OrderService.finishCancel(updated);
    }
    return OrderService.getAny(orderId);
  }
}
