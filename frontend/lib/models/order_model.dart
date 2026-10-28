import 'package:equatable/equatable.dart';

class ShippingAddress extends Equatable {
  final String fullName;
  final String phone;
  final String addressLine;
  final String city;
  final String postalCode;

  const ShippingAddress({
    required this.fullName,
    required this.phone,
    required this.addressLine,
    required this.city,
    required this.postalCode,
  });

  factory ShippingAddress.fromJson(Map<String, dynamic> json) => ShippingAddress(
    fullName: json['fullName'] ?? '',
    phone: json['phone'] ?? '',
    addressLine: json['addressLine'] ?? '',
    city: json['city'] ?? '',
    postalCode: json['postalCode'] ?? '',
  );

  Map<String, dynamic> toJson() => {
    'fullName': fullName,
    'phone': phone,
    'addressLine': addressLine,
    'city': city,
    'postalCode': postalCode,
  };

  @override
  List<Object?> get props => [fullName, phone, addressLine, city, postalCode];
}

class OrderItemModel extends Equatable {
  final String productId;
  final String name;
  final String? imageUrl;
  final int unitPrice; // integer paise, snapshot at order time
  final int quantity;
  final int lineTotal;

  const OrderItemModel({
    required this.productId,
    required this.name,
    required this.imageUrl,
    required this.unitPrice,
    required this.quantity,
    required this.lineTotal,
  });

  factory OrderItemModel.fromJson(Map<String, dynamic> json) => OrderItemModel(
    productId: json['productId'] ?? '',
    name: json['name'] ?? '',
    imageUrl: json['imageUrl'] as String?,
    unitPrice: (json['unitPrice'] as num?)?.toInt() ?? 0,
    quantity: (json['quantity'] as num?)?.toInt() ?? 0,
    lineTotal: (json['lineTotal'] as num?)?.toInt() ?? 0,
  );

  @override
  List<Object?> get props => [productId, name, imageUrl, unitPrice, quantity, lineTotal];
}

class StatusEntry extends Equatable {
  final String status;
  final DateTime? at;

  const StatusEntry({required this.status, required this.at});

  factory StatusEntry.fromJson(Map<String, dynamic> json) => StatusEntry(
    status: json['status'] ?? '',
    at: DateTime.tryParse(json['at'] ?? '')?.toLocal(),
  );

  @override
  List<Object?> get props => [status, at];
}

class OrderCustomer extends Equatable {
  final String id;
  final String name;
  final String email;

  const OrderCustomer({required this.id, required this.name, required this.email});

  factory OrderCustomer.fromJson(Map<String, dynamic> json) =>
      OrderCustomer(id: json['id'] ?? '', name: json['name'] ?? '', email: json['email'] ?? '');

  @override
  List<Object?> get props => [id, name, email];
}

OrderCustomer? _customerFrom(dynamic raw) =>
    raw is Map<String, dynamic> ? OrderCustomer.fromJson(raw) : null;

// Display only: the server enforces the real transitions.
List<String> adminNextStatuses(String status) {
  switch (status) {
    case 'PENDING':
      return const ['CONFIRMED', 'CANCELLED'];
    case 'CONFIRMED':
      return const ['SHIPPED', 'CANCELLED'];
    case 'SHIPPED':
      return const ['DELIVERED'];
    default:
      return const [];
  }
}

const adminOrderStatusFilters = ['PENDING', 'CONFIRMED', 'SHIPPED', 'DELIVERED', 'CANCELLED'];

class OrderModel extends Equatable {
  final String id;
  final String status;
  final String paymentMethod;
  final String paymentStatus;
  final int total;
  final int itemCount;
  final DateTime? createdAt;
  final List<OrderItemModel> items;
  final ShippingAddress shippingAddress;
  final List<StatusEntry> statusHistory;
  final OrderCustomer? customer; // only sent by the admin endpoints

  const OrderModel({
    required this.id,
    required this.status,
    required this.paymentMethod,
    required this.paymentStatus,
    required this.total,
    required this.itemCount,
    required this.createdAt,
    required this.items,
    required this.shippingAddress,
    required this.statusHistory,
    this.customer,
  });

  bool get canCancel => status == 'PENDING';

  factory OrderModel.fromJson(Map<String, dynamic> json) => OrderModel(
    id: json['id'] ?? '',
    status: json['status'] ?? '',
    paymentMethod: json['paymentMethod'] ?? '',
    paymentStatus: json['paymentStatus'] ?? '',
    total: (json['total'] as num?)?.toInt() ?? 0,
    itemCount: (json['itemCount'] as num?)?.toInt() ?? 0,
    createdAt: DateTime.tryParse(json['createdAt'] ?? '')?.toLocal(),
    items: (json['items'] as List<dynamic>? ?? const [])
        .map((e) => OrderItemModel.fromJson(e as Map<String, dynamic>))
        .toList(),
    shippingAddress: ShippingAddress.fromJson(
      (json['shippingAddress'] as Map<String, dynamic>?) ?? const <String, dynamic>{},
    ),
    statusHistory: (json['statusHistory'] as List<dynamic>? ?? const [])
        .map((e) => StatusEntry.fromJson(e as Map<String, dynamic>))
        .toList(),
    customer: _customerFrom(json['customer']),
  );

  @override
  List<Object?> get props => [
    id, status, paymentMethod, paymentStatus, total, itemCount, createdAt, items, shippingAddress, statusHistory, customer,
  ];
}

class OrderSummaryModel extends Equatable {
  final String id;
  final String status;
  final String paymentMethod;
  final String paymentStatus;
  final int total;
  final int itemCount;
  final DateTime? createdAt;
  final String firstItemName;
  final OrderCustomer? customer; // only sent by the admin endpoints

  const OrderSummaryModel({
    required this.id,
    required this.status,
    required this.paymentMethod,
    required this.paymentStatus,
    required this.total,
    required this.itemCount,
    required this.createdAt,
    required this.firstItemName,
    this.customer,
  });

  factory OrderSummaryModel.fromJson(Map<String, dynamic> json) => OrderSummaryModel(
    id: json['id'] ?? '',
    status: json['status'] ?? '',
    paymentMethod: json['paymentMethod'] ?? '',
    paymentStatus: json['paymentStatus'] ?? '',
    total: (json['total'] as num?)?.toInt() ?? 0,
    itemCount: (json['itemCount'] as num?)?.toInt() ?? 0,
    createdAt: DateTime.tryParse(json['createdAt'] ?? '')?.toLocal(),
    firstItemName: json['firstItemName'] ?? '',
    customer: _customerFrom(json['customer']),
  );

  @override
  List<Object?> get props => [id, status, paymentMethod, paymentStatus, total, itemCount, createdAt, firstItemName, customer];
}

class OrderPage extends Equatable {
  final List<OrderSummaryModel> items;
  final int page;
  final int pages;
  final int total;

  const OrderPage({required this.items, required this.page, required this.pages, required this.total});

  factory OrderPage.fromJson(Map<String, dynamic> data) {
    final pagination = (data['pagination'] as Map<String, dynamic>?) ?? const <String, dynamic>{};
    final list = (data['items'] as List<dynamic>? ?? const []);
    return OrderPage(
      items: list.map((e) => OrderSummaryModel.fromJson(e as Map<String, dynamic>)).toList(),
      page: (pagination['page'] as num?)?.toInt() ?? 1,
      pages: (pagination['pages'] as num?)?.toInt() ?? 1,
      total: (pagination['total'] as num?)?.toInt() ?? 0,
    );
  }

  @override
  List<Object?> get props => [items, page, pages, total];
}

String orderStatusLabel(String s) {
  switch (s) {
    case 'PENDING':
      return 'Pending';
    case 'CONFIRMED':
      return 'Confirmed';
    case 'SHIPPED':
      return 'Shipped';
    case 'DELIVERED':
      return 'Delivered';
    case 'CANCELLED':
      return 'Cancelled';
    default:
      return s;
  }
}

String paymentMethodLabel(String m) {
  switch (m) {
    case 'COD':
      return 'Cash on Delivery';
    case 'MOCK_PAY':
      return 'Paid online (demo)';
    default:
      return m;
  }
}

String paymentStatusLabel(String s) {
  switch (s) {
    case 'PAID':
      return 'Paid';
    case 'UNPAID':
      return 'Unpaid';
    case 'REFUNDED':
      return 'Refunded';
    default:
      return s;
  }
}

String shortOrderId(String id) {
  final tail = id.length > 8 ? id.substring(id.length - 8) : id;
  return '#${tail.toUpperCase()}';
}
