import { Cart, ICartDocument, MAX_CART_LINES, MAX_LINE_QUANTITY } from '../models/cart.model';
import { Product, IProductDocument, stockStatusOf, StockStatus } from '../models/product.model';
import { AppError } from '../middlewares/error.middleware';
import { assertObjectId } from '../validation/catalog.schemas';
import { AddCartItemInput, SetCartQuantityInput } from '../validation/cart.schemas';

export type CartIssue = 'unavailable' | 'out_of_stock' | 'insufficient_stock' | null;

export interface CartLineView {
  productId: string;
  name: string;
  imageUrl: string | null;
  price: number; // integer paise, current
  quantity: number;
  stock: number;
  stockStatus: StockStatus;
  lineTotal: number;
  issue: CartIssue;
}

export interface CartView {
  items: CartLineView[];
  itemCount: number;
  subtotal: number;
  hasIssues: boolean;
}

const EMPTY_VIEW: CartView = { items: [], itemCount: 0, subtotal: 0, hasIssues: false };

export class CartService {
  private static async buildView(cart: ICartDocument | null): Promise<CartView> {
    if (!cart || cart.items.length === 0) return { ...EMPTY_VIEW, items: [] };

    const ids = cart.items.map((i) => i.product);
    const products = await Product.find({ _id: { $in: ids } });
    const byId = new Map(products.map((p) => [p._id.toString(), p]));

    // Drop lines whose product no longer exists.
    const kept = cart.items.filter((i) => byId.has(i.product.toString()));
    if (kept.length !== cart.items.length) {
      cart.items = kept;
      await cart.save();
    }

    const items: CartLineView[] = kept.map((line) => {
      const product = byId.get(line.product.toString())!;
      let issue: CartIssue = null;
      if (!product.isActive) issue = 'unavailable';
      else if (product.stock === 0) issue = 'out_of_stock';
      else if (line.quantity > product.stock) issue = 'insufficient_stock';
      return {
        productId: product._id.toString(),
        name: product.name,
        imageUrl: product.imageUrl ?? null,
        price: product.price,
        quantity: line.quantity,
        stock: product.stock,
        stockStatus: stockStatusOf(product.stock),
        lineTotal: product.price * line.quantity,
        issue,
      };
    });

    return {
      items,
      itemCount: items.reduce((n, l) => n + l.quantity, 0),
      subtotal: items.filter((l) => l.issue === null).reduce((s, l) => s + l.lineTotal, 0),
      hasIssues: items.some((l) => l.issue !== null),
    };
  }

  public static async getView(userId: string): Promise<CartView> {
    const cart = await Cart.findOne({ user: userId });
    return CartService.buildView(cart);
  }

  private static async getOrCreate(userId: string): Promise<ICartDocument> {
    const cart = await Cart.findOneAndUpdate(
      { user: userId },
      { $setOnInsert: { user: userId, items: [] } },
      { upsert: true, returnDocument: 'after' }
    );
    return cart as ICartDocument;
  }

  private static async loadSellable(productId: string): Promise<IProductDocument> {
    assertObjectId(productId, 'product id');
    const product = await Product.findById(productId);
    if (!product || !product.isActive) throw new AppError('Product not found', 404, 'PRODUCT_NOT_FOUND');
    return product;
  }

  private static assertStock(product: IProductDocument, quantity: number): void {
    if (product.stock === 0) throw new AppError('This product is out of stock', 409, 'OUT_OF_STOCK');
    if (quantity > product.stock) {
      throw new AppError(`Only ${product.stock} left in stock`, 409, 'INSUFFICIENT_STOCK');
    }
  }

  public static async addItem(userId: string, input: AddCartItemInput): Promise<CartView> {
    const product = await CartService.loadSellable(input.productId);
    const cart = await CartService.getOrCreate(userId);

    const existing = cart.items.find((i) => i.product.toString() === product._id.toString());
    const newQty = (existing?.quantity ?? 0) + input.quantity;
    if (newQty > MAX_LINE_QUANTITY) {
      throw new AppError(`You can add at most ${MAX_LINE_QUANTITY} of one product`, 409, 'QUANTITY_LIMIT');
    }
    CartService.assertStock(product, newQty);

    if (existing) {
      existing.quantity = newQty;
    } else {
      if (cart.items.length >= MAX_CART_LINES) throw new AppError('Your cart is full', 409, 'CART_FULL');
      cart.items.push({ product: product._id, quantity: newQty });
    }
    await cart.save();
    return CartService.buildView(cart);
  }

  public static async setQuantity(userId: string, productId: string, input: SetCartQuantityInput): Promise<CartView> {
    assertObjectId(productId, 'product id');
    const cart = await Cart.findOne({ user: userId });
    const line = cart?.items.find((i) => i.product.toString() === productId);
    if (!cart || !line) throw new AppError('Item is not in your cart', 404, 'CART_ITEM_NOT_FOUND');

    const product = await Product.findById(productId);
    if (!product || !product.isActive) {
      throw new AppError('This product is no longer available', 409, 'PRODUCT_UNAVAILABLE');
    }
    // Decreases are always allowed so a customer can bring an over-stock line back down.
    if (input.quantity > line.quantity) CartService.assertStock(product, input.quantity);

    line.quantity = input.quantity;
    await cart.save();
    return CartService.buildView(cart);
  }

  public static async removeItem(userId: string, productId: string): Promise<CartView> {
    assertObjectId(productId, 'product id');
    const cart = await Cart.findOne({ user: userId });
    if (!cart || !cart.items.some((i) => i.product.toString() === productId)) {
      throw new AppError('Item is not in your cart', 404, 'CART_ITEM_NOT_FOUND');
    }
    cart.items = cart.items.filter((i) => i.product.toString() !== productId);
    await cart.save();
    return CartService.buildView(cart);
  }

  // Called by Phase 5 (place order); no route in this phase.
  public static async clear(userId: string): Promise<void> {
    await Cart.updateOne({ user: userId }, { $set: { items: [] } });
  }
}
