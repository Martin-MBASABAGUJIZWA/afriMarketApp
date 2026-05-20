import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:afrimarket/core/services/supabase_service.dart';

class CartDataSource {
  SupabaseClient get _client => SupabaseService.client;

  Future<List<Map<String, dynamic>>> getCartItems(String userId) async {
    try {
      final response = await _client
          .from('cart_items')
          .select('*, products(*)')
          .eq('user_id', userId);
      return List<Map<String, dynamic>>.from(
          (response as List).map((e) => Map<String, dynamic>.from(e as Map)));
    } catch (_) {
      return [];
    }
  }

  Future<void> upsertItem(
      String userId, String productId, int quantity) async {
    try {
      await _client.from('cart_items').upsert(
        {
          'user_id': userId,
          'product_id': productId,
          'quantity': quantity,
        },
        onConflict: 'user_id,product_id',
      );
    } catch (_) {}
  }

  Future<void> removeItem(String userId, String productId) async {
    try {
      await _client
          .from('cart_items')
          .delete()
          .eq('user_id', userId)
          .eq('product_id', productId);
    } catch (_) {}
  }

  Future<void> clearCart(String userId) async {
    try {
      await _client.from('cart_items').delete().eq('user_id', userId);
    } catch (_) {}
  }
}
