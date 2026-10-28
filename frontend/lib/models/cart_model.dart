import 'package:equatable/equatable.dart';

class CartItemModel extends Equatable {
  final String productId;
  final String name;
  final String? imageUrl;
  final int price; // integer paise (server)
  final int quantity;
  final int stock;
  final String stockStatus;
  final int lineTotal; // integer paise (server)
  final String? issue; // unavailable | out_of_stock | insufficient_stock | null

  const CartItemModel({
    required this.productId,
    required this.name,
    required this.imageUrl,
    required this.price,
    required this.quantity,
    required this.stock,
    required this.stockStatus,
    required this.lineTotal,
    required this.issue,
  });

  bool get hasIssue => issue != null;
  bool get canIncrease => issue == null && quantity < stock;

  factory CartItemModel.fromJson(Map<String, dynamic> json) => CartItemModel(
    productId: json['productId'] ?? '',
    name: json['name'] ?? '',
    imageUrl: json['imageUrl'] as String?,
    price: (json['price'] as num?)?.toInt() ?? 0,
    quantity: (json['quantity'] as num?)?.toInt() ?? 0,
    stock: (json['stock'] as num?)?.toInt() ?? 0,
    stockStatus: json['stockStatus'] ?? 'in_stock',
    lineTotal: (json['lineTotal'] as num?)?.toInt() ?? 0,
    issue: json['issue'] as String?,
  );

  @override
  List<Object?> get props => [
    productId,
    name,
    imageUrl,
    price,
    quantity,
    stock,
    stockStatus,
    lineTotal,
    issue,
  ];
}

class CartModel extends Equatable {
  final List<CartItemModel> items;
  final int itemCount;
  final int subtotal; // integer paise (server)
  final bool hasIssues;

  const CartModel({
    required this.items,
    required this.itemCount,
    required this.subtotal,
    required this.hasIssues,
  });

  const CartModel.empty()
    : items = const [],
      itemCount = 0,
      subtotal = 0,
      hasIssues = false;

  factory CartModel.fromJson(Map<String, dynamic> json) {
    final list = (json['items'] as List<dynamic>? ?? const []);
    return CartModel(
      items: list
          .map((e) => CartItemModel.fromJson(e as Map<String, dynamic>))
          .toList(),
      itemCount: (json['itemCount'] as num?)?.toInt() ?? 0,
      subtotal: (json['subtotal'] as num?)?.toInt() ?? 0,
      hasIssues: json['hasIssues'] ?? false,
    );
  }

  @override
  List<Object?> get props => [items, itemCount, subtotal, hasIssues];
}
