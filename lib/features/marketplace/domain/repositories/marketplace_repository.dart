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
}
