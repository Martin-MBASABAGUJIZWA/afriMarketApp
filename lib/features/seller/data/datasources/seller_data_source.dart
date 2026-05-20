import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:afrimarket/core/services/supabase_service.dart';
import 'package:afrimarket/core/errors/exceptions.dart' as app_exceptions;
import 'package:afrimarket/core/constants/app_constants.dart';

class SellerDataSource {
  SupabaseClient get _client => SupabaseService.isInitialized
      ? SupabaseService.client
      : throw app_exceptions.ServerException('Supabase not configured');

  Future<List<Map<String, dynamic>>> getSellers({
    String? category,
    bool? isOpen,
    int? limit,
  }) async {
    try {
      var queryBuilder = _client
          .from(DatabaseTables.sellers)
          .select();
      
      if (category != null && category != 'all') {
        queryBuilder = queryBuilder.eq('category', category);
      }

      if (isOpen != null && isOpen) {
        queryBuilder = queryBuilder.eq('is_open', true);
      }

      var query = queryBuilder.order('rating', ascending: false);

      if (limit != null) {
        query = query.limit(limit);
      }

      final response = await query;
      return List<Map<String, dynamic>>.from(response)
          .map(_withTimestamps)
          .toList();
    } catch (e) {
      throw app_exceptions.ServerException('Failed to fetch sellers');
    }
  }

  Future<Map<String, dynamic>?> getSellerById(String sellerId) async {
    try {
      final response = await _client
          .from(DatabaseTables.sellers)
          .select()
          .eq('id', sellerId)
          .maybeSingle();
      return response != null ? _withTimestamps(response) : null;
    } catch (e) {
      return null;
    }
  }

  Future<Map<String, dynamic>?> getSellerByUserId(String userId) async {
    try {
      final response = await _client
          .from(DatabaseTables.sellers)
          .select()
          .eq('user_id', userId)
          .maybeSingle();
      return response != null ? _withTimestamps(response) : null;
    } catch (e) {
      return null;
    }
  }

  // Guarantee non-null timestamps so SellerEntity.fromJson never crashes.
  Map<String, dynamic> _withTimestamps(Map<String, dynamic> row) {
    final now = DateTime.now().toIso8601String();
    return {
      ...row,
      'created_at': row['created_at'] ?? now,
      'updated_at': row['updated_at'] ?? now,
    };
  }

  Future<void> createSeller({
    required String userId,
    required String businessName,
    required String category,
    required String location,
    required String phone,
    String? description,
    String? logoUrl,
  }) async {
    // The sellers FK points to profiles(id), not auth.users(id).
    // Ensure the profile row exists before inserting the seller.
    await _ensureProfileExists(userId);

    await _client.from(DatabaseTables.sellers).insert({
      'user_id': userId,
      'business_name': businessName,
      'category': category,
      'location': location,
      'phone': phone,
      if (description != null && description.isNotEmpty) 'description': description,
      if (logoUrl != null) 'logo_url': logoUrl,
    });
  }

  // Guarantees a profiles row exists for this user so FK constraints pass.
  Future<void> _ensureProfileExists(String userId) async {
    try {
      final existing = await _client
          .from('profiles')
          .select('id')
          .eq('id', userId)
          .maybeSingle();

      if (existing == null) {
        final authUser = _client.auth.currentUser;
        final meta = authUser?.userMetadata ?? {};
        final email = authUser?.email ?? '';
        final fullName =
            meta['full_name'] as String? ?? email.split('@').first;
        await _client.from('profiles').upsert({
          'id': userId,
          'email': email,
          'full_name': fullName,
          'role': 'seller',
        }, onConflict: 'id');
      }
    } catch (e) {
      // Non-fatal — the seller insert will reveal the real FK error if it persists.
      debugPrint('Profile ensure failed: $e');
    }
  }

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
      final updates = <String, dynamic>{};
      if (businessName != null) updates['business_name'] = businessName;
      if (category != null) updates['category'] = category;
      if (location != null) updates['location'] = location;
      if (phone != null) updates['phone'] = phone;
      if (description != null) updates['description'] = description;
      if (logoUrl != null) updates['logo_url'] = logoUrl;
      if (isOpen != null) updates['is_open'] = isOpen;

      if (updates.isEmpty) return;

      await _client.from(DatabaseTables.sellers).update(updates).eq('id', sellerId);
    } catch (e) {
      throw app_exceptions.ServerException('Failed to update seller');
    }
  }
}
