import '../entities/cart_item_entity.dart';
import 'package:afrimarket/features/marketplace/domain/entities/product_entity.dart';

abstract class CartRepository {
  Future<List<CartItemEntity>> getCartItems(String userId);
  Future<void> addItem(String userId, ProductEntity product, int quantity);
  Future<void> updateQuantity(String userId, String productId, int quantity);
  Future<void> removeItem(String userId, String productId);
  Future<void> clearCart(String userId);
}
