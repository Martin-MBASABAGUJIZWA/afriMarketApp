import 'package:afrimarket/features/notifications/data/datasources/notification_data_source.dart';
import 'package:afrimarket/features/notifications/domain/entities/notification_entity.dart';
import 'package:afrimarket/features/notifications/domain/repositories/notification_repository.dart';

class NotificationRepositoryImpl implements NotificationRepository {
  final NotificationDataSource _dataSource;

  const NotificationRepositoryImpl(this._dataSource);

  @override
  Future<List<NotificationEntity>> getNotifications(String userId,
      {int limit = 50}) async {
    final rows = await _dataSource.getNotifications(userId, limit: limit);
    return rows.map(NotificationEntity.fromJson).toList();
  }

  @override
  Future<void> markAsRead(String notificationId) {
    return _dataSource.markAsRead(notificationId);
  }

  @override
  Future<void> markAllAsRead(String userId) {
    return _dataSource.markAllAsRead(userId);
  }

  @override
  Future<int> getUnreadCount(String userId) {
    return _dataSource.getUnreadCount(userId);
  }
}
