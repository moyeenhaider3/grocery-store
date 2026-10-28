import 'package:dio/dio.dart';

import '../core/network/api_client.dart';
import '../models/cart_model.dart';

class CartRepository {
  final ApiClient apiClient;

  CartRepository({required this.apiClient});

  CartModel _parse(Response<dynamic> response) =>
      CartModel.fromJson(response.data['data']['cart'] as Map<String, dynamic>);

  Future<CartModel> getCart() async {
    try {
      return _parse(await apiClient.dio.get('/cart'));
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }

  Future<CartModel> addItem(String productId, {int quantity = 1}) async {
    try {
      return _parse(
        await apiClient.dio.post(
          '/cart/items',
          data: {'productId': productId, 'quantity': quantity},
        ),
      );
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }

  Future<CartModel> updateQuantity(String productId, int quantity) async {
    try {
      return _parse(
        await apiClient.dio.patch(
          '/cart/items/${Uri.encodeComponent(productId)}',
          data: {'quantity': quantity},
        ),
      );
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }

  Future<CartModel> removeItem(String productId) async {
    try {
      return _parse(
        await apiClient.dio.delete(
          '/cart/items/${Uri.encodeComponent(productId)}',
        ),
      );
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }
}
