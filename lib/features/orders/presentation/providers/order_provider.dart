import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:afrimarket/features/orders/data/datasources/order_data_source.dart';
import 'package:afrimarket/features/auth/presentation/providers/auth_providers.dart';
import 'package:afrimarket/features/seller/presentation/providers/seller_providers.dart';

final orderDataSourceProvider =
    Provider<OrderDataSource>((ref) => OrderDataSource());

// Buyer's order history
final buyerOrdersProvider =
    FutureProvider<List<Map<String, dynamic>>>((ref) async {
  final userId = ref.watch(authStateProvider).value?.id;
  if (userId == null) return [];
  return ref.watch(orderDataSourceProvider).getBuyerOrders(userId);
});

// Seller's order list (uses current seller account)
final sellerOrdersProvider =
    FutureProvider<List<Map<String, dynamic>>>((ref) async {
  final seller = ref.watch(currentUserSellerProvider).value;
  if (seller == null) return [];
  return ref.watch(orderDataSourceProvider).getSellerOrders(seller.id);
});

// Derived analytics for seller dashboard
final sellerAnalyticsProvider = Provider<Map<String, dynamic>>((ref) {
  final orders = ref.watch(sellerOrdersProvider).value ?? [];
  final total = orders.fold<double>(0, (s, o) {
    final v = o['total'];
    return s + (v is num ? v.toDouble() : 0.0);
  });
  final pending = orders.where((o) => o['status'] == 'pending').length;
  final completed = orders.where((o) => o['status'] == 'completed').length;
  return {
    'totalRevenue': total,
    'totalOrders': orders.length,
    'pendingOrders': pending,
    'completedOrders': completed,
  };
});
