import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:afrimarket/core/services/supabase_service.dart';
import 'package:afrimarket/core/errors/exceptions.dart' as app_exceptions;
import 'package:afrimarket/core/constants/app_constants.dart';

class MarketplaceDataSource {
  SupabaseClient get _client => SupabaseService.isInitialized
      ? SupabaseService.client
      : throw app_exceptions.ServerException('Supabase not configured');

  Future<List<Map<String, dynamic>>> getProducts({
    String? categoryId,
    String? searchQuery,
    bool? isFeatured,
    int? limit,
    int? offset,
  }) async {
    try {
      // Build filter first
      var filterBuilder = _client
          .from(DatabaseTables.products)
          .select('''
            *,
            sellers!inner(
              id,
              business_name,
              category,
              location,
              phone,
              logo_url,
              is_verified,
              is_open,
              rating
            )
          ''');

      // Apply filters
      filterBuilder = filterBuilder.isFilter('deleted_at', null);
      
      if (categoryId != null) {
        filterBuilder = filterBuilder.eq('category_id', categoryId);
      }

      if (isFeatured != null && isFeatured) {
        filterBuilder = filterBuilder.eq('is_featured', true);
      }

      if (searchQuery != null && searchQuery.isNotEmpty) {
        filterBuilder = filterBuilder.or(
          'name.ilike.%$searchQuery%,description.ilike.%$searchQuery%',
        );
      }

      // Apply ordering and limits
      var query = filterBuilder.order('created_at', ascending: false);

      if (limit != null) {
        query = query.limit(limit);
      }

      if (offset != null) {
        query = query.range(offset, offset + (limit ?? 20) - 1);
      }

      final response = await query;
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      throw app_exceptions.ServerException('Failed to fetch products');
    }
  }

  Future<Map<String, dynamic>?> getProductById(String productId) async {
    try {
      final response = await _client
          .from(DatabaseTables.products)
          .select('''
            *,
            sellers!inner(
              id,
              business_name,
              category,
              location,
              phone,
              logo_url,
              is_verified,
              is_open,
              rating
            )
          ''')
          .eq('id', productId)
          .isFilter('deleted_at', null)
          .maybeSingle();

      return response;
    } catch (e) {
      return null;
    }
  }

  Future<List<Map<String, dynamic>>> getProductsBySeller(
    String sellerId,
  ) async {
    try {
      final response = await _client
          .from(DatabaseTables.products)
          .select()
          .eq('seller_id', sellerId)
          .isFilter('deleted_at', null)
          .order('created_at', ascending: false);

      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      throw app_exceptions.ServerException('Failed to fetch seller products');
    }
  }

  Future<List<Map<String, dynamic>>> getFeaturedProducts({
    int limit = 4,
  }) async {
    try {
      final response = await _client
          .from(DatabaseTables.products)
          .select('''
            *,
            sellers!inner(
              id,
              business_name,
              category,
              location,
              phone,
              logo_url,
              is_verified,
              is_open,
              rating
            )
          ''')
          .eq('is_featured', true)
          .isFilter('deleted_at', null)
          .order('rating', ascending: false)
          .limit(limit);

      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      throw app_exceptions.ServerException('Failed to fetch featured products');
    }
  }

  Future<List<Map<String, dynamic>>> searchProducts(String query) async {
    try {
      final response = await _client
          .from(DatabaseTables.products)
          .select('''
            *,
            sellers!inner(
              id,
              business_name,
              category,
              location,
              phone,
              logo_url,
              is_verified,
              is_open,
              rating
            )
          ''')
          .or('name.ilike.%$query%,description.ilike.%$query%')
          .isFilter('deleted_at', null)
          .order('rating', ascending: false)
          .limit(20);

      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      throw app_exceptions.ServerException('Failed to search products');
    }
  }

  Future<void> createProduct({
    required String sellerId,
    required String name,
    required String categoryId,
    required double price,
    required int stockQuantity,
    String? description,
    String unit = 'each',
    List<String> imageUrls = const [],
  }) async {
    try {
      await _client.from(DatabaseTables.products).insert({
        'seller_id': sellerId,
        'name': name,
        'category_id': categoryId,
        'price': price,
        'stock_quantity': stockQuantity,
        if (description != null && description.isNotEmpty)
          'description': description,
        'unit': unit,
        'image_urls': imageUrls,
      });
    } catch (e) {
      throw app_exceptions.ServerException('Failed to create product');
    }
  }

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
  }) async {
    try {
      final updates = <String, dynamic>{};
      if (name != null) updates['name'] = name;
      if (description != null) updates['description'] = description;
      if (price != null) updates['price'] = price;
      if (stockQuantity != null) updates['stock_quantity'] = stockQuantity;
      if (categoryId != null) updates['category_id'] = categoryId;
      if (unit != null) updates['unit'] = unit;
      if (imageUrls != null) updates['image_urls'] = imageUrls;
      if (isDeleted == true) {
        updates['deleted_at'] = DateTime.now().toIso8601String();
      }
      if (updates.isEmpty) return;
      await _client
          .from(DatabaseTables.products)
          .update(updates)
          .eq('id', productId);
    } catch (e) {
      throw app_exceptions.ServerException('Failed to update product');
    }
  }

  Future<void> deleteProduct(String productId) async {
    try {
      await _client.from(DatabaseTables.products).update({
        'deleted_at': DateTime.now().toIso8601String(),
      }).eq('id', productId);
    } catch (e) {
      throw app_exceptions.ServerException('Failed to delete product');
    }
  }
}
