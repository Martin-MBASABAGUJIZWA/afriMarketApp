import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:afrimarket/features/orders/data/datasources/order_data_source.dart';
import 'package:afrimarket/features/orders/data/repositories/order_repository_impl.dart';
import 'package:afrimarket/features/orders/domain/entities/order_entity.dart';
import 'package:afrimarket/features/orders/domain/entities/order_status.dart';
import 'package:afrimarket/features/orders/domain/repositories/order_repository.dart';
import 'package:afrimarket/features/auth/presentation/providers/auth_providers.dart';
import 'package:afrimarket/features/seller/presentation/providers/seller_providers.dart';

final orderDataSourceProvider =
    Provider<OrderDataSource>((ref) => OrderDataSource());

final orderRepositoryProvider = Provider<OrderRepository>((ref) {
  return OrderRepositoryImpl(ref.read(orderDataSourceProvider));
});

// Buyer's typed order history
final buyerOrdersProvider = FutureProvider<List<OrderEntity>>((ref) async {
  final userId = ref.watch(authStateProvider).value?.id;
  if (userId == null) return [];
  return ref.watch(orderRepositoryProvider).getBuyerOrders(userId);
});

// Seller's typed order list
final sellerOrdersProvider = FutureProvider<List<OrderEntity>>((ref) async {
  final seller = ref.watch(currentUserSellerProvider).value;
  if (seller == null) return [];
  return ref.watch(orderRepositoryProvider).getSellerOrders(seller.id);
});

// Derived analytics for seller dashboard
final sellerAnalyticsProvider = Provider<Map<String, dynamic>>((ref) {
  final orders = ref.watch(sellerOrdersProvider).value ?? [];
  final total = orders.fold<double>(0, (s, o) => s + o.total);
  final pending =
      orders.where((o) => o.status == OrderStatus.pending).length;
  final completed =
      orders.where((o) => o.status == OrderStatus.completed).length;
  return {
    'totalRevenue': total,
    'totalOrders': orders.length,
    'pendingOrders': pending,
    'completedOrders': completed,
  };
});
