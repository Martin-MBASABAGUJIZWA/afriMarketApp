class OrderItemEntity {
  final String id;
  final String orderId;
  final String productId;
  final String productName;
  final double productPrice;
  final int quantity;
  final double subtotal;

  const OrderItemEntity({
    required this.id,
    required this.orderId,
    required this.productId,
    required this.productName,
    required this.productPrice,
    required this.quantity,
    required this.subtotal,
  });

  factory OrderItemEntity.fromJson(Map<String, dynamic> json) {
    return OrderItemEntity(
      id: json['id'] as String? ?? '',
      orderId: json['order_id'] as String? ?? '',
      productId: json['product_id'] as String? ?? '',
      productName: json['product_name'] as String? ?? '',
      productPrice: (json['product_price'] as num?)?.toDouble() ?? 0.0,
      quantity: (json['quantity'] as num?)?.toInt() ?? 1,
      subtotal: (json['subtotal'] as num?)?.toDouble() ?? 0.0,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'order_id': orderId,
        'product_id': productId,
        'product_name': productName,
        'product_price': productPrice,
        'quantity': quantity,
        'subtotal': subtotal,
      };
}
