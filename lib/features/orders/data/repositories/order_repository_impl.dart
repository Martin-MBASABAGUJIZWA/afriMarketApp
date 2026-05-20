import 'package:afrimarket/features/orders/data/datasources/order_data_source.dart';
import 'package:afrimarket/features/orders/domain/entities/order_entity.dart';
import 'package:afrimarket/features/orders/domain/entities/order_status.dart';
import 'package:afrimarket/features/orders/domain/repositories/order_repository.dart';

class OrderRepositoryImpl implements OrderRepository {
  final OrderDataSource _dataSource;

  const OrderRepositoryImpl(this._dataSource);

  @override
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
  }) {
    return _dataSource.createOrder(
      buyerId: buyerId,
      sellerId: sellerId,
      paymentMethod: paymentMethod,
      subtotal: subtotal,
      total: total,
      buyerPhone: buyerPhone,
      items: items,
      deliveryFee: deliveryFee,
      deliveryAddress: deliveryAddress,
      notes: notes,
    );
  }

  @override
  Future<List<OrderEntity>> getBuyerOrders(String buyerId) async {
    final rows = await _dataSource.getBuyerOrders(buyerId);
    return rows.map(OrderEntity.fromJson).toList();
  }

  @override
  Future<List<OrderEntity>> getSellerOrders(String sellerId) async {
    final rows = await _dataSource.getSellerOrders(sellerId);
    return rows.map(OrderEntity.fromJson).toList();
  }

  @override
  Future<void> updateOrderStatus(String orderId, OrderStatus status) {
    return _dataSource.updateOrderStatus(orderId, status.name);
  }
}
