import 'package:afrimarket/core/services/supabase_service.dart';

class NotificationDataSource {
  Future<List<Map<String, dynamic>>> getNotifications(String userId,
      {int limit = 50}) async {
    try {
      final res = await SupabaseService.client
          .from('notifications')
          .select()
          .eq('user_id', userId)
          .order('created_at', ascending: false)
          .limit(limit);
      return List<Map<String, dynamic>>.from(res);
    } catch (_) {
      return [];
    }
  }

  Future<void> markAsRead(String notificationId) async {
    try {
      await SupabaseService.client
          .from('notifications')
          .update({'is_read': true}).eq('id', notificationId);
    } catch (_) {}
  }

  Future<void> markAllAsRead(String userId) async {
    try {
      await SupabaseService.client
          .from('notifications')
          .update({'is_read': true})
          .eq('user_id', userId)
          .eq('is_read', false);
    } catch (_) {}
  }

  Future<int> getUnreadCount(String userId) async {
    try {
      final res = await SupabaseService.client
          .from('notifications')
          .select('id')
          .eq('user_id', userId)
          .eq('is_read', false);
      return (res as List).length;
    } catch (_) {
      return 0;
    }
  }
}
