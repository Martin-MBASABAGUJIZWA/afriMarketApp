import 'package:afrimarket/features/cart/data/datasources/cart_data_source.dart';
import 'package:afrimarket/features/cart/domain/entities/cart_item_entity.dart';
import 'package:afrimarket/features/cart/domain/repositories/cart_repository.dart';
import 'package:afrimarket/features/marketplace/domain/entities/product_entity.dart';

class CartRepositoryImpl implements CartRepository {
  final CartDataSource _dataSource;

  const CartRepositoryImpl(this._dataSource);

  @override
  Future<List<CartItemEntity>> getCartItems(String userId) async {
    final rows = await _dataSource.getCartItems(userId);
    final items = <CartItemEntity>[];
    for (final row in rows) {
      final productMap = row['products'];
      if (productMap != null) {
        try {
          final product = ProductEntity.fromJson(
              Map<String, dynamic>.from(productMap as Map));
          items.add(CartItemEntity(
            product: product,
            quantity: (row['quantity'] as num).toInt(),
          ));
        } catch (_) {}
      }
    }
    return items;
  }

  @override
  Future<void> addItem(
      String userId, ProductEntity product, int quantity) async {
    await _dataSource.upsertItem(userId, product.id, quantity);
  }

  @override
  Future<void> updateQuantity(
      String userId, String productId, int quantity) async {
    if (quantity <= 0) {
      await _dataSource.removeItem(userId, productId);
    } else {
      await _dataSource.upsertItem(userId, productId, quantity);
    }
  }

  @override
  Future<void> removeItem(String userId, String productId) async {
    await _dataSource.removeItem(userId, productId);
  }

  @override
  Future<void> clearCart(String userId) async {
    await _dataSource.clearCart(userId);
  }
}
