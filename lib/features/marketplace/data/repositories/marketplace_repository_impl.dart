import 'package:afrimarket/features/marketplace/domain/entities/product_entity.dart';
import 'package:afrimarket/features/marketplace/domain/repositories/marketplace_repository.dart';
import 'package:afrimarket/features/marketplace/data/datasources/marketplace_data_source.dart';
import 'package:afrimarket/core/errors/exceptions.dart' as app_exceptions;

class MarketplaceRepositoryImpl implements MarketplaceRepository {
  final MarketplaceDataSource _dataSource;

  MarketplaceRepositoryImpl(this._dataSource);

  @override
  Future<List<ProductEntity>> getProducts({
    String? categoryId,
    String? searchQuery,
    bool? isFeatured,
    int? limit,
    int? offset,
  }) async {
    try {
      final data = await _dataSource.getProducts(
        categoryId: categoryId,
        searchQuery: searchQuery,
        isFeatured: isFeatured,
        limit: limit,
        offset: offset,
      );
      return data.map((json) => ProductEntity.fromJson(json)).toList();
    } catch (e) {
      throw app_exceptions.ServerException('Failed to fetch products');
    }
  }

  @override
  Future<ProductEntity?> getProductById(String productId) async {
    try {
      final data = await _dataSource.getProductById(productId);
      if (data == null) return null;
      return ProductEntity.fromJson(data);
    } catch (e) {
      throw app_exceptions.NotFoundException('Product not found');
    }
  }

  @override
  Future<List<ProductEntity>> getProductsBySeller(String sellerId) async {
    try {
      final data = await _dataSource.getProductsBySeller(sellerId);
      return data.map((json) => ProductEntity.fromJson(json)).toList();
    } catch (e) {
      throw app_exceptions.ServerException('Failed to fetch seller products');
    }
  }

  @override
  Future<List<ProductEntity>> getFeaturedProducts({int limit = 4}) async {
    try {
      final data = await _dataSource.getFeaturedProducts(limit: limit);
      return data.map((json) => ProductEntity.fromJson(json)).toList();
    } catch (e) {
      throw app_exceptions.ServerException('Failed to fetch featured products');
    }
  }

  @override
  Future<List<ProductEntity>> searchProducts(String query) async {
    try {
      final data = await _dataSource.searchProducts(query);
      return data.map((json) => ProductEntity.fromJson(json)).toList();
    } catch (e) {
      throw app_exceptions.ServerException('Failed to search products');
    }
  }

  @override
  Future<void> createProduct({
    required String sellerId,
    required String name,
    required String categoryId,
    required double price,
    required int stockQuantity,
    String? description,
    String unit = 'each',
    List<String> imageUrls = const [],
  }) {
    return _dataSource.createProduct(
      sellerId: sellerId,
      name: name,
      categoryId: categoryId,
      price: price,
      stockQuantity: stockQuantity,
      description: description,
      unit: unit,
      imageUrls: imageUrls,
    );
  }

  @override
  Future<void> updateProduct({
    required String productId,
    String? name,
    String? description,
    double? price,
    int? stockQuantity,
    String? categoryId,
    String? unit,
    List<String>? imageUrls,
    bool? isDeleted,
  }) {
    return _dataSource.updateProduct(
      productId: productId,
      name: name,
      description: description,
      price: price,
      stockQuantity: stockQuantity,
      categoryId: categoryId,
      unit: unit,
      imageUrls: imageUrls,
      isDeleted: isDeleted,
    );
  }

  @override
  Future<void> deleteProduct(String productId) {
    return _dataSource.deleteProduct(productId);
  }
}
