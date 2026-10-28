import 'package:equatable/equatable.dart';

class ProductModel extends Equatable {
  final String id;
  final String name;
  final String description;
  final int price; // integer paise
  final int stock;
  final String stockStatus; // in_stock | low_stock | out_of_stock (server-computed)
  final String categoryId;
  final String categoryName;
  final String? imageUrl;
  final bool isActive;

  const ProductModel({
    required this.id,
    required this.name,
    required this.description,
    required this.price,
    required this.stock,
    required this.stockStatus,
    required this.categoryId,
    required this.categoryName,
    required this.imageUrl,
    required this.isActive,
  });

  bool get isLowOrOut => stockStatus != 'in_stock';

  factory ProductModel.fromJson(Map<String, dynamic> json) {
    final category = json['category'];
    final cat = category is Map<String, dynamic> ? category : const <String, dynamic>{};
    return ProductModel(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      description: json['description'] ?? '',
      price: (json['price'] as num?)?.toInt() ?? 0,
      stock: (json['stock'] as num?)?.toInt() ?? 0,
      stockStatus: json['stockStatus'] ?? 'in_stock',
      categoryId: cat['id'] ?? '',
      categoryName: cat['name'] ?? '',
      imageUrl: json['imageUrl'] as String?,
      isActive: json['isActive'] ?? true,
    );
  }

  @override
  List<Object?> get props => [id, name, description, price, stock, stockStatus, categoryId, categoryName, imageUrl, isActive];
}

class ProductPage extends Equatable {
  final List<ProductModel> items;
  final int total;
  final int page;
  final int limit;
  final int pages;

  const ProductPage({
    required this.items,
    required this.total,
    required this.page,
    required this.limit,
    required this.pages,
  });

  factory ProductPage.fromJson(Map<String, dynamic> data) {
    final pagination = (data['pagination'] as Map<String, dynamic>?) ?? const <String, dynamic>{};
    final list = (data['items'] as List<dynamic>? ?? const []);
    return ProductPage(
      items: list.map((e) => ProductModel.fromJson(e as Map<String, dynamic>)).toList(),
      total: (pagination['total'] as num?)?.toInt() ?? 0,
      page: (pagination['page'] as num?)?.toInt() ?? 1,
      limit: (pagination['limit'] as num?)?.toInt() ?? 20,
      pages: (pagination['pages'] as num?)?.toInt() ?? 1,
    );
  }

  @override
  List<Object?> get props => [items, total, page, limit, pages];
}
