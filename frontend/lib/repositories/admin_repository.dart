import 'package:dio/dio.dart';
import '../core/network/api_client.dart';
import '../models/stats_model.dart';
import '../models/user_model.dart';

class AdminRepository {
  final ApiClient apiClient;

  AdminRepository({required this.apiClient});

  Future<UserModel> ping() async {
    try {
      final response = await apiClient.dio.get('/admin/ping');
      return UserModel.fromJson(response.data['data']['user']);
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }

  Future<DashboardStats> getStats() async {
    try {
      final response = await apiClient.dio.get('/admin/stats');
      return DashboardStats.fromJson(response.data['data']['stats'] as Map<String, dynamic>);
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }

  Future<UserPage> getUsers({int page = 1, String? q}) async {
    try {
      final response = await apiClient.dio.get(
        '/admin/users',
        queryParameters: {'page': page, if (q != null && q.isNotEmpty) 'q': q},
      );
      return UserPage.fromJson(response.data['data'] as Map<String, dynamic>);
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }

  Future<UserModel> createUser({
    required String name,
    required String email,
    required String password,
    required String role,
  }) async {
    try {
      final response = await apiClient.dio.post(
        '/admin/users',
        data: {'name': name, 'email': email, 'password': password, 'role': role},
      );
      return UserModel.fromJson(response.data['data']['user']);
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }

  Future<UserModel> setUserRole(String id, String role) async {
    try {
      final response = await apiClient.dio.patch(
        '/admin/users/${Uri.encodeComponent(id)}/role',
        data: {'role': role},
      );
      return UserModel.fromJson(response.data['data']['user']);
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }

  Future<UserModel> setUserBlocked(String id, bool isBlocked) async {
    try {
      final response = await apiClient.dio.patch(
        '/admin/users/${Uri.encodeComponent(id)}/block',
        data: {'isBlocked': isBlocked},
      );
      return UserModel.fromJson(response.data['data']['user']);
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }
}
