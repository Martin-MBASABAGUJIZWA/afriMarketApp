import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:afrimarket/features/marketplace/domain/entities/product_entity.dart';
import 'package:afrimarket/features/auth/presentation/providers/auth_providers.dart';
import 'package:afrimarket/features/cart/data/datasources/cart_data_source.dart';
import 'package:afrimarket/core/services/supabase_service.dart';

class CartItem {
  final ProductEntity product;
  final int quantity;

  const CartItem({required this.product, this.quantity = 1});

  CartItem copyWith({int? quantity}) =>
      CartItem(product: product, quantity: quantity ?? this.quantity);

  double get totalPrice => product.price * quantity;
}

final _cartDataSourceProvider =
    Provider<CartDataSource>((ref) => CartDataSource());

class CartNotifier extends Notifier<List<CartItem>> {
  @override
  List<CartItem> build() {
    ref.listen<AsyncValue<User?>>(authStateProvider, (prev, next) {
      final userId = next.value?.id;
      final prevId = prev?.value?.id;
      if (userId != null && userId != prevId) {
        Future.microtask(() => _loadFromSupabase(userId));
      } else if (userId == null) {
        state = [];
      }
    });

    final userId = ref.read(authStateProvider).value?.id;
    if (userId != null) {
      Future.microtask(() => _loadFromSupabase(userId));
    }
    return [];
  }

  Future<void> _loadFromSupabase(String userId) async {
    if (!SupabaseService.isInitialized) return;
    try {
      final rows = await ref.read(_cartDataSourceProvider).getCartItems(userId);
      final items = <CartItem>[];
      for (final row in rows) {
        final productMap = row['products'];
        if (productMap != null) {
          try {
            final product = ProductEntity.fromJson(
                Map<String, dynamic>.from(productMap as Map));
            items.add(CartItem(
              product: product,
              quantity: (row['quantity'] as num).toInt(),
            ));
          } catch (_) {}
        }
      }
      state = items;
    } catch (_) {}
  }

  String? get _userId => ref.read(authStateProvider).value?.id;

  void addItem(ProductEntity product) {
    final index = state.indexWhere((i) => i.product.id == product.id);
    int newQty;
    if (index >= 0) {
      newQty = state[index].quantity + 1;
      state = [
        for (int i = 0; i < state.length; i++)
          i == index ? state[i].copyWith(quantity: newQty) : state[i],
      ];
    } else {
      newQty = 1;
      state = [...state, CartItem(product: product)];
    }
    final uid = _userId;
    if (uid != null) {
      ref.read(_cartDataSourceProvider).upsertItem(uid, product.id, newQty);
    }
  }

  void removeItem(String productId) {
    state = state.where((i) => i.product.id != productId).toList();
    final uid = _userId;
    if (uid != null) {
      ref.read(_cartDataSourceProvider).removeItem(uid, productId);
    }
  }

  void increaseQuantity(String productId) {
    int newQty = 1;
    state = [
      for (final item in state)
        if (item.product.id == productId)
          () {
            newQty = item.quantity + 1;
            return item.copyWith(quantity: newQty);
          }()
        else
          item,
    ];
    final uid = _userId;
    if (uid != null) {
      ref.read(_cartDataSourceProvider).upsertItem(uid, productId, newQty);
    }
  }

  void decreaseQuantity(String productId) {
    final List<CartItem> next = [];
    int newQty = 0;
    for (final item in state) {
      if (item.product.id == productId) {
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
      if (newQty == 0) {
        ref.read(_cartDataSourceProvider).removeItem(uid, productId);
      } else {
        ref.read(_cartDataSourceProvider).upsertItem(uid, productId, newQty);
      }
    }
  }

  Future<void> clearAll() async {
    state = [];
    final uid = _userId;
    if (uid != null) {
      await ref.read(_cartDataSourceProvider).clearCart(uid);
    }
  }

  double get totalPrice =>
      state.fold(0.0, (sum, item) => sum + item.totalPrice);

  int get itemCount => state.fold(0, (sum, item) => sum + item.quantity);
}

final cartProvider =
    NotifierProvider<CartNotifier, List<CartItem>>(CartNotifier.new);
