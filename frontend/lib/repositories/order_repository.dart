import 'package:dio/dio.dart';

import '../core/network/api_client.dart';
import '../models/order_model.dart';

class OrderRepository {
  final ApiClient apiClient;

  OrderRepository({required this.apiClient});

  OrderModel _parse(Response<dynamic> response) =>
      OrderModel.fromJson(response.data['data']['order'] as Map<String, dynamic>);

  Future<OrderModel> placeOrder({required ShippingAddress address, required String paymentMethod}) async {
    try {
      return _parse(
        await apiClient.dio.post(
          '/orders',
          data: {'shippingAddress': address.toJson(), 'paymentMethod': paymentMethod},
        ),
      );
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }

  Future<OrderPage> getMyOrders({int page = 1}) async {
    try {
      final response = await apiClient.dio.get('/orders', queryParameters: {'page': page});
      return OrderPage.fromJson(response.data['data'] as Map<String, dynamic>);
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }

  Future<OrderModel> getOrder(String id) async {
    try {
      return _parse(await apiClient.dio.get('/orders/${Uri.encodeComponent(id)}'));
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }

  Future<OrderModel> cancelOrder(String id) async {
    try {
      return _parse(await apiClient.dio.post('/orders/${Uri.encodeComponent(id)}/cancel'));
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }

  Future<OrderPage> getAdminOrders({int page = 1, String? status}) async {
    try {
      final response = await apiClient.dio.get(
        '/admin/orders',
        queryParameters: {'page': page, 'status': ?status},
      );
      return OrderPage.fromJson(response.data['data'] as Map<String, dynamic>);
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }

  Future<OrderModel> getAdminOrder(String id) async {
    try {
      return _parse(await apiClient.dio.get('/admin/orders/${Uri.encodeComponent(id)}'));
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }

  Future<OrderModel> updateOrderStatus(String id, String status) async {
    try {
      return _parse(
        await apiClient.dio.patch('/admin/orders/${Uri.encodeComponent(id)}/status', data: {'status': status}),
      );
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }
}
