import 'package:dio/dio.dart';
import '../core/network/api_client.dart';
import '../models/category_model.dart';
import '../models/product_model.dart';

class ImportTemplate {
  final String csv;
  final List<String> columns;
  final List<String> categories;

  const ImportTemplate({required this.csv, required this.columns, required this.categories});

  factory ImportTemplate.fromJson(Map<String, dynamic> json) => ImportTemplate(
        csv: json['csv'] as String,
        columns: (json['columns'] as List<dynamic>).map((e) => e as String).toList(),
        categories: (json['categories'] as List<dynamic>).map((e) => e as String).toList(),
      );
}

class CatalogRepository {
  final ApiClient apiClient;

  CatalogRepository({required this.apiClient});

  Future<List<CategoryModel>> getCategories() async {
    try {
      final response = await apiClient.dio.get('/admin/categories');
      final list = response.data['data']['categories'] as List<dynamic>;
      return list.map((e) => CategoryModel.fromJson(e as Map<String, dynamic>)).toList();
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }

  Future<CategoryModel> createCategory(String name) async {
    try {
      final response = await apiClient.dio.post('/admin/categories', data: {'name': name});
      return CategoryModel.fromJson(response.data['data']['category']);
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }

  Future<CategoryModel> renameCategory(String id, String name) async {
    try {
      final response = await apiClient.dio.patch('/admin/categories/$id', data: {'name': name});
      return CategoryModel.fromJson(response.data['data']['category']);
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }

  Future<void> deleteCategory(String id) async {
    try {
      await apiClient.dio.delete('/admin/categories/$id');
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }

  Future<ProductPage> getProducts({
    int page = 1,
    int limit = 20,
    String? q,
    String status = 'all',
    String? categoryId,
  }) async {
    try {
      final response = await apiClient.dio.get(
        '/admin/products',
        queryParameters: {
          'page': page,
          'limit': limit,
          'status': status,
          if (q != null && q.trim().isNotEmpty) 'q': q.trim(),
          if (categoryId != null && categoryId.isNotEmpty) 'category': categoryId,
        },
      );
      return ProductPage.fromJson(response.data['data'] as Map<String, dynamic>);
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }

  /// Public categories that have at least one active product.
  Future<List<CategoryModel>> getStoreCategories() async {
    try {
      final response = await apiClient.dio.get('/categories');
      final list = response.data['data']['categories'] as List<dynamic>;
      return list.map((e) => CategoryModel.fromJson(e as Map<String, dynamic>)).toList();
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }

  /// Public storefront listing (no auth). The server only returns active products.
  Future<ProductPage> getStoreProducts({
    int page = 1,
    int limit = 24,
    String? q,
    String? categoryId,
    String sort = 'newest',
  }) async {
    try {
      final response = await apiClient.dio.get(
        '/products',
        queryParameters: {
          'page': page,
          'limit': limit,
          'sort': sort,
          if (q != null && q.trim().isNotEmpty) 'q': q.trim(),
          if (categoryId != null && categoryId.isNotEmpty) 'category': categoryId,
        },
      );
      return ProductPage.fromJson(response.data['data'] as Map<String, dynamic>);
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }

  /// Public single product (no auth). 404 for unknown or inactive products.
  Future<ProductModel> getStoreProduct(String id) async {
    try {
      final response = await apiClient.dio.get('/products/${Uri.encodeComponent(id)}');
      return ProductModel.fromJson(response.data['data']['product']);
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }

  Future<ProductModel> createProduct(Map<String, dynamic> body) async {
    try {
      final response = await apiClient.dio.post('/admin/products', data: body);
      return ProductModel.fromJson(response.data['data']['product']);
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }

  Future<ProductModel> getProduct(String id) async {
    try {
      final response = await apiClient.dio.get('/admin/products/$id');
      return ProductModel.fromJson(response.data['data']['product']);
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }

  Future<ProductModel> updateProduct(String id, Map<String, dynamic> body) async {
    try {
      final response = await apiClient.dio.put('/admin/products/$id', data: body);
      return ProductModel.fromJson(response.data['data']['product']);
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }

  Future<ImportTemplate> getImportTemplate() async {
    try {
      final response = await apiClient.dio.get('/admin/products/import/template');
      return ImportTemplate.fromJson(response.data['data'] as Map<String, dynamic>);
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }

  /// Sends the raw CSV text; the server validates and converts rupees to paise.
  Future<int> importProducts(String csvText) async {
    try {
      final response = await apiClient.dio.post(
        '/admin/products/import',
        data: csvText,
        options: Options(contentType: 'text/csv'),
      );
      return response.data['data']['created'] as int;
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }
}
