import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:afrimarket/features/marketplace/domain/entities/product_entity.dart';
import 'package:afrimarket/features/auth/presentation/providers/auth_providers.dart';
import 'package:afrimarket/features/cart/data/datasources/cart_data_source.dart';
import 'package:afrimarket/features/cart/data/repositories/cart_repository_impl.dart';
import 'package:afrimarket/features/cart/domain/entities/cart_item_entity.dart';
import 'package:afrimarket/features/cart/domain/repositories/cart_repository.dart';
import 'package:afrimarket/core/services/supabase_service.dart';

// Re-export for convenience so existing code using CartItem still compiles.
typedef CartItem = CartItemEntity;

final _cartDataSourceProvider =
    Provider<CartDataSource>((ref) => CartDataSource());

final cartRepositoryProvider = Provider<CartRepository>((ref) {
  return CartRepositoryImpl(ref.read(_cartDataSourceProvider));
});

class CartNotifier extends Notifier<List<CartItemEntity>> {
  @override
  List<CartItemEntity> build() {
    ref.listen<AsyncValue<User?>>(authStateProvider, (prev, next) {
      final userId = next.value?.id;
      final prevId = prev?.value?.id;
      if (userId != null && userId != prevId) {
        Future.microtask(() => _loadFromRepository(userId));
      } else if (userId == null) {
        state = [];
      }
    });

    final userId = ref.read(authStateProvider).value?.id;
    if (userId != null) {
      Future.microtask(() => _loadFromRepository(userId));
    }
    return [];
  }

  Future<void> _loadFromRepository(String userId) async {
    if (!SupabaseService.isInitialized) return;
    try {
      final items =
          await ref.read(cartRepositoryProvider).getCartItems(userId);
      state = items;
    } catch (_) {}
  }

  String? get _userId => ref.read(authStateProvider).value?.id;

  void addItem(ProductEntity product) {
    final index = state.indexWhere((i) => i.productId == product.id);
    int newQty;
    if (index >= 0) {
      newQty = state[index].quantity + 1;
      state = [
        for (int i = 0; i < state.length; i++)
          i == index ? state[i].copyWith(quantity: newQty) : state[i],
      ];
    } else {
      newQty = 1;
      state = [...state, CartItemEntity(product: product)];
    }
    final uid = _userId;
    if (uid != null) {
      ref.read(cartRepositoryProvider).addItem(uid, product, newQty);
    }
  }

  void removeItem(String productId) {
    state = state.where((i) => i.productId != productId).toList();
    final uid = _userId;
    if (uid != null) {
      ref.read(cartRepositoryProvider).removeItem(uid, productId);
    }
  }

  void increaseQuantity(String productId) {
    int newQty = 1;
    state = [
      for (final item in state)
        if (item.productId == productId)
          () {
            newQty = item.quantity + 1;
            return item.copyWith(quantity: newQty);
          }()
        else
          item,
    ];
    final uid = _userId;
    if (uid != null) {
      ref
          .read(cartRepositoryProvider)
          .updateQuantity(uid, productId, newQty);
    }
  }

  void decreaseQuantity(String productId) {
    final List<CartItemEntity> next = [];
    int newQty = 0;
    for (final item in state) {
      if (item.productId == productId) {
        if (item.quantity > 1) {
          newQty = item.quantity - 1;
          next.add(item.copyWith(quantity: newQty));
        } else {
          newQty = 0;
        }
      } else {
        next.add(item);
      }
    }
    state = next;
    final uid = _userId;
    if (uid != null) {
      ref
          .read(cartRepositoryProvider)
          .updateQuantity(uid, productId, newQty);
    }
  }

  Future<void> clearAll() async {
    state = [];
    final uid = _userId;
    if (uid != null) {
      await ref.read(cartRepositoryProvider).clearCart(uid);
    }
  }

  double get totalPrice =>
      state.fold(0.0, (sum, item) => sum + item.totalPrice);

  int get itemCount => state.fold(0, (sum, item) => sum + item.quantity);
}

final cartProvider =
    NotifierProvider<CartNotifier, List<CartItemEntity>>(CartNotifier.new);
