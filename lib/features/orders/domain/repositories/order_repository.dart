import '../entities/order_entity.dart';
import '../entities/order_status.dart';

abstract class OrderRepository {
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
  });

  Future<List<OrderEntity>> getBuyerOrders(String buyerId);
  Future<List<OrderEntity>> getSellerOrders(String sellerId);
  Future<void> updateOrderStatus(String orderId, OrderStatus status);
}
