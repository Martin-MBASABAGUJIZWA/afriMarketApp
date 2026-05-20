import '../entities/product_entity.dart';

abstract class MarketplaceRepository {
  Future<List<ProductEntity>> getProducts({
    String? categoryId,
    String? searchQuery,
    bool? isFeatured,
    int? limit,
    int? offset,
  });

  Future<ProductEntity?> getProductById(String productId);

  Future<List<ProductEntity>> getProductsBySeller(String sellerId);

  Future<List<ProductEntity>> getFeaturedProducts({int limit = 4});

  Future<List<ProductEntity>> searchProducts(String query);

  Future<void> createProduct({
    required String sellerId,
    required String name,
    required String categoryId,
    required double price,
    required int stockQuantity,
    String? description,
    String unit = 'each',
    List<String> imageUrls = const [],
  });

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
  });

  Future<void> deleteProduct(String productId);
}
