import 'package:afrimarket/features/seller/domain/entities/seller_entity.dart';
import 'package:afrimarket/features/seller/domain/repositories/seller_repository.dart';
import 'package:afrimarket/features/seller/data/datasources/seller_data_source.dart';
import 'package:afrimarket/core/errors/exceptions.dart' as app_exceptions;

class SellerRepositoryImpl implements SellerRepository {
  final SellerDataSource _dataSource;

  SellerRepositoryImpl(this._dataSource);

  @override
  Future<List<SellerEntity>> getSellers({
    String? category,
    bool? isOpen,
    int? limit,
  }) async {
    try {
      final data = await _dataSource.getSellers(
        category: category,
        isOpen: isOpen,
        limit: limit,
      );
      return data.map((json) => SellerEntity.fromJson(json)).toList();
    } catch (e) {
      throw app_exceptions.ServerException('Failed to fetch sellers');
    }
  }

  @override
  Future<SellerEntity?> getSellerById(String sellerId) async {
    try {
      final data = await _dataSource.getSellerById(sellerId);
      if (data == null) return null;
      return SellerEntity.fromJson(data);
    } catch (e) {
      throw app_exceptions.NotFoundException('Seller not found');
    }
  }

  @override
  Future<SellerEntity?> getSellerByUserId(String userId) async {
    try {
      final data = await _dataSource.getSellerByUserId(userId);
      if (data == null) return null;
      return SellerEntity.fromJson(data);
    } catch (e) {
      return null;
    }
  }

  @override
  Future<void> createSeller({
    required String userId,
    required String businessName,
    required String category,
    required String location,
    required String phone,
    String? description,
    String? logoUrl,
  }) async {
    try {
      await _dataSource.createSeller(
        userId: userId,
        businessName: businessName,
        category: category,
        location: location,
        phone: phone,
        description: description,
        logoUrl: logoUrl,
      );
    } catch (e) {
      throw app_exceptions.ServerException('Failed to create seller account');
    }
  }

  @override
  Future<void> updateSeller({
    required String sellerId,
    String? businessName,
    String? category,
    String? location,
    String? phone,
    String? description,
    String? logoUrl,
    bool? isOpen,
  }) async {
    try {
      await _dataSource.updateSeller(
        sellerId: sellerId,
        businessName: businessName,
        category: category,
        location: location,
        phone: phone,
        description: description,
        logoUrl: logoUrl,
        isOpen: isOpen,
      );
    } catch (e) {
      throw app_exceptions.ServerException('Failed to update seller');
    }
  }
}
