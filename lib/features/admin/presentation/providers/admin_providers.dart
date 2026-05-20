import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:afrimarket/core/services/supabase_service.dart';

final adminStatsProvider = FutureProvider<Map<String, dynamic>>((ref) async {
  if (!SupabaseService.isInitialized) {
    return {'users': 0, 'sellers': 0, 'revenue': 0.0, 'orders': 0};
  }
  final client = SupabaseService.client;
  try {
    final usersData = await client.from('profiles').select('id');
    final sellersData = await client.from('sellers').select('id');
    final ordersData = await client.from('orders').select('total');

    final userCount = (usersData as List).length;
    final sellerCount = (sellersData as List).length;
    final orderList = ordersData as List;
    final orderCount = orderList.length;
    final revenue = orderList.fold<double>(0, (sum, o) {
      final v = o['total'];
      return sum + (v is num ? v.toDouble() : 0.0);
    });

    return {
      'users': userCount,
      'sellers': sellerCount,
      'revenue': revenue,
      'orders': orderCount,
    };
  } catch (_) {
    return {'users': 0, 'sellers': 0, 'revenue': 0.0, 'orders': 0};
  }
});

final adminUsersProvider =
    FutureProvider<List<Map<String, dynamic>>>((ref) async {
  if (!SupabaseService.isInitialized) return [];
  try {
    final res = await SupabaseService.client
        .from('profiles')
        .select()
        .order('created_at', ascending: false)
        .limit(50);
    return List<Map<String, dynamic>>.from(res);
  } catch (_) {
    return [];
  }
});

final adminRecentOrdersProvider =
    FutureProvider<List<Map<String, dynamic>>>((ref) async {
  if (!SupabaseService.isInitialized) return [];
  try {
    final res = await SupabaseService.client
        .from('orders')
        .select('id, total, status, created_at')
        .order('created_at', ascending: false)
        .limit(10);
    return List<Map<String, dynamic>>.from(res);
  } catch (_) {
    return [];
  }
});
