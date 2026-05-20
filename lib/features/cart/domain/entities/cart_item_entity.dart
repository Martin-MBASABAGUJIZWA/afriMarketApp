import 'package:afrimarket/features/marketplace/domain/entities/product_entity.dart';

class CartItemEntity {
  final ProductEntity product;
  final int quantity;

  const CartItemEntity({required this.product, this.quantity = 1});

  CartItemEntity copyWith({int? quantity}) =>
      CartItemEntity(product: product, quantity: quantity ?? this.quantity);

  double get totalPrice => product.price * quantity;

  String get productId => product.id;
  String get productName => product.name;
  double get unitPrice => product.price;
  String get imageUrl => product.imageUrl;
  String get sellerId => product.sellerId;
}
