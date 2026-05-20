import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:afrimarket/core/services/supabase_service.dart';
import 'package:afrimarket/core/errors/exceptions.dart' as app_ex;

class OrderDataSource {
  SupabaseClient get _client => SupabaseService.client;

  // Creates one order for a single seller's items. Returns the order id.
  Future<String> createOrder({
    required String buyerId,
    required String sellerId,
    required String paymentMethod,
    required double subtotal,
    required double total,
    required String buyerPhone,
    required List<Map<String, dynamic>> items,
    double deliveryFee = 0,
    String? deliveryAddress,
    String? notes,
  }) async {
    try {
      final order = await _client
          .from('orders')
          .insert({
            'buyer_id': buyerId,
            'seller_id': sellerId,
            'status': 'pending',
            'subtotal': subtotal,
            'delivery_fee': deliveryFee,
            'total': total,
            'payment_method': paymentMethod,
            'payment_status': 'pending',
            'buyer_phone': buyerPhone,
            if (deliveryAddress != null) 'delivery_address': deliveryAddress,
            if (notes != null) 'notes': notes,
          })
          .select('id')
          .single();

      final orderId = order['id'] as String;

      await _client.from('order_items').insert(items
          .map((i) => {
                'order_id': orderId,
                'product_id': i['product_id'],
                'product_name': i['product_name'],
                'product_price': i['product_price'],
                'quantity': i['quantity'],
                'subtotal': i['subtotal'],
              })
          .toList());

      return orderId;
    } catch (e) {
      throw app_ex.ServerException('Failed to create order: $e');
    }
  }

  Future<List<Map<String, dynamic>>> getBuyerOrders(String buyerId) async {
    try {
      final response = await _client
          .from('orders')
          .select('*, order_items(*)')
          .eq('buyer_id', buyerId)
          .order('created_at', ascending: false);
      return List<Map<String, dynamic>>.from(
          (response as List).map((e) => Map<String, dynamic>.from(e as Map)));
    } catch (_) {
      return [];
    }
  }

  Future<List<Map<String, dynamic>>> getSellerOrders(String sellerId) async {
    try {
      final response = await _client
          .from('orders')
          .select('*, order_items(*)')
          .eq('seller_id', sellerId)
          .order('created_at', ascending: false);
      return List<Map<String, dynamic>>.from(
          (response as List).map((e) => Map<String, dynamic>.from(e as Map)));
    } catch (_) {
      return [];
    }
  }

  Future<void> updateOrderStatus(String orderId, String status) async {
    try {
      await _client
          .from('orders')
          .update({'status': status})
          .eq('id', orderId);
    } catch (_) {}
  }
}
