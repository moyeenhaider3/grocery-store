import 'package:equatable/equatable.dart';

class UserModel extends Equatable {
  final String id;
  final String name;
  final String email;
  final String role;
  final DateTime? createdAt;
  final bool isBlocked;

  static const roleAdmin = 'ADMIN';
  static const roleUser = 'USER';

  const UserModel({
    required this.id,
    required this.name,
    required this.email,
    required this.role,
    this.createdAt,
    this.isBlocked = false,
  });

  bool get isAdmin => role == roleAdmin;

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      email: json['email'] ?? '',
      role: json['role'] ?? roleUser,
      createdAt: DateTime.tryParse(json['createdAt'] ?? '')?.toLocal(),
      isBlocked: json['isBlocked'] == true,
    );
  }

  @override
  List<Object?> get props => [id, name, email, role, createdAt, isBlocked];
}

class UserPage extends Equatable {
  final List<UserModel> items;
  final int page;
  final int pages;
  final int total;

  const UserPage({required this.items, required this.page, required this.pages, required this.total});

  factory UserPage.fromJson(Map<String, dynamic> data) {
    final pagination = (data['pagination'] as Map<String, dynamic>?) ?? const <String, dynamic>{};
    final list = (data['items'] as List<dynamic>? ?? const []);
    return UserPage(
      items: list.map((e) => UserModel.fromJson(e as Map<String, dynamic>)).toList(),
      page: (pagination['page'] as num?)?.toInt() ?? 1,
      pages: (pagination['pages'] as num?)?.toInt() ?? 1,
      total: (pagination['total'] as num?)?.toInt() ?? 0,
    );
  }

  @override
  List<Object?> get props => [items, page, pages, total];
}
