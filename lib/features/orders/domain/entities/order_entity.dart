import 'order_item_entity.dart';
import 'order_status.dart';

class OrderEntity {
  final String id;
  final String buyerId;
  final String sellerId;
  final OrderStatus status;
  final PaymentMethod paymentMethod;
  final PaymentStatus paymentStatus;
  final double subtotal;
  final double deliveryFee;
  final double total;
  final String? buyerPhone;
  final String? deliveryAddress;
  final String? notes;
  final List<OrderItemEntity> items;
  final DateTime createdAt;
  final DateTime? updatedAt;

  const OrderEntity({
    required this.id,
    required this.buyerId,
    required this.sellerId,
    required this.status,
    required this.paymentMethod,
    required this.paymentStatus,
    required this.subtotal,
    required this.deliveryFee,
    required this.total,
    this.buyerPhone,
    this.deliveryAddress,
    this.notes,
    required this.items,
    required this.createdAt,
    this.updatedAt,
  });

  factory OrderEntity.fromJson(Map<String, dynamic> json) {
    final rawItems = json['order_items'] as List<dynamic>? ?? [];
    return OrderEntity(
      id: json['id'] as String,
      buyerId: json['buyer_id'] as String,
      sellerId: json['seller_id'] as String,
      status: OrderStatus.fromString(json['status'] as String? ?? 'pending'),
      paymentMethod: PaymentMethod.fromString(
          json['payment_method'] as String? ?? 'mobile_money'),
      paymentStatus: PaymentStatus.fromString(
          json['payment_status'] as String? ?? 'pending'),
      subtotal: (json['subtotal'] as num?)?.toDouble() ?? 0.0,
      deliveryFee: (json['delivery_fee'] as num?)?.toDouble() ?? 0.0,
      total: (json['total'] as num?)?.toDouble() ?? 0.0,
      buyerPhone: json['buyer_phone'] as String?,
      deliveryAddress: json['delivery_address'] as String?,
      notes: json['notes'] as String?,
      items: rawItems
          .map((i) =>
              OrderItemEntity.fromJson(Map<String, dynamic>.from(i as Map)))
          .toList(),
      createdAt: DateTime.parse(
          json['created_at'] as String? ?? DateTime.now().toIso8601String()),
      updatedAt: json['updated_at'] != null
          ? DateTime.tryParse(json['updated_at'] as String)
          : null,
    );
  }

  OrderEntity copyWith({OrderStatus? status, PaymentStatus? paymentStatus}) {
    return OrderEntity(
      id: id,
      buyerId: buyerId,
      sellerId: sellerId,
      status: status ?? this.status,
      paymentMethod: paymentMethod,
      paymentStatus: paymentStatus ?? this.paymentStatus,
      subtotal: subtotal,
      deliveryFee: deliveryFee,
      total: total,
      buyerPhone: buyerPhone,
      deliveryAddress: deliveryAddress,
      notes: notes,
      items: items,
      createdAt: createdAt,
      updatedAt: updatedAt,
    );
  }

  String get formattedTotal => 'RWF ${total.toStringAsFixed(0)}';
  String get itemCount => '${items.length} item${items.length == 1 ? '' : 's'}';
}
