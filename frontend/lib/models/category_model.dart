import 'package:equatable/equatable.dart';

class CategoryModel extends Equatable {
  final String id;
  final String name;
  final int productCount;

  const CategoryModel({required this.id, required this.name, this.productCount = 0});

  factory CategoryModel.fromJson(Map<String, dynamic> json) {
    return CategoryModel(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      productCount: (json['productCount'] as num?)?.toInt() ?? 0,
    );
  }

  @override
  List<Object?> get props => [id, name, productCount];
}
