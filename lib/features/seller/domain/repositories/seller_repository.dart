import '../entities/seller_entity.dart';

abstract class SellerRepository {
  Future<List<SellerEntity>> getSellers({
    String? category,
    bool? isOpen,
    int? limit,
  });

  Future<SellerEntity?> getSellerById(String sellerId);

  Future<SellerEntity?> getSellerByUserId(String userId);

  Future<void> createSeller({
    required String userId,
    required String businessName,
    required String category,
    required String location,
    required String phone,
    String? description,
    String? logoUrl,
  });

  Future<void> updateSeller({
    required String sellerId,
    String? businessName,
    String? category,
    String? location,
    String? phone,
    String? description,
    String? logoUrl,
    bool? isOpen,
  });
}
