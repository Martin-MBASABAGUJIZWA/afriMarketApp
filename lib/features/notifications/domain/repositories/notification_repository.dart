import '../entities/notification_entity.dart';

abstract class NotificationRepository {
  Future<List<NotificationEntity>> getNotifications(String userId, {int limit = 50});
  Future<void> markAsRead(String notificationId);
  Future<void> markAllAsRead(String userId);
  Future<int> getUnreadCount(String userId);
}
