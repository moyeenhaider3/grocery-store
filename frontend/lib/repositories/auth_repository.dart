import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../core/network/api_client.dart';
import '../models/user_model.dart';

class AuthRepository {
  final ApiClient apiClient;
  final SharedPreferences prefs;

  AuthRepository({required this.apiClient, required this.prefs});

  Future<UserModel> signup({
    required String name,
    required String email,
    required String password,
  }) async {
    try {
      final response = await apiClient.dio.post('/auth/signup', data: {
        'name': name,
        'email': email,
        'password': password,
      });
      await prefs.setString(ApiClient.tokenKey, response.data['data']['token'] as String);
      return UserModel.fromJson(response.data['data']['user']);
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }

  Future<UserModel> login({
    required String email,
    required String password,
  }) async {
    try {
      final response = await apiClient.dio.post('/auth/login', data: {
        'email': email,
        'password': password,
      });
      await prefs.setString(ApiClient.tokenKey, response.data['data']['token'] as String);
      return UserModel.fromJson(response.data['data']['user']);
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }

  /// Returns null when no token is stored. Never deletes the token itself: the
  /// interceptor removes it on 401 / ACCOUNT_BLOCKED, and timeouts / 5xx keep it.
  Future<UserModel?> getCurrentUser() async {
    final token = prefs.getString(ApiClient.tokenKey);
    if (token == null || token.isEmpty) return null;
    try {
      final response = await apiClient.dio.get('/auth/me');
      return UserModel.fromJson(response.data['data']['user']);
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }

  Future<UserModel> getProfile() async {
    try {
      final response = await apiClient.dio.get('/users/me');
      return UserModel.fromJson(response.data['data']['user']);
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }

  Future<UserModel> updateName(String name) async {
    try {
      final response = await apiClient.dio.patch('/users/me', data: {'name': name});
      return UserModel.fromJson(response.data['data']['user']);
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }

  Future<void> changePassword({required String currentPassword, required String newPassword}) async {
    try {
      await apiClient.dio.patch('/users/me/password', data: {
        'currentPassword': currentPassword,
        'newPassword': newPassword,
      });
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }

  Future<void> logout() async {
    try {
      await apiClient.dio.post('/auth/logout');
    } catch (_) {
      // best-effort: the token is removed below regardless
    } finally {
      await prefs.remove(ApiClient.tokenKey);
    }
  }
}
