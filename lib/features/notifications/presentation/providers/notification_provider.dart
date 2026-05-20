import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:afrimarket/features/auth/presentation/providers/auth_providers.dart';
import 'package:afrimarket/features/notifications/data/datasources/notification_data_source.dart';
import 'package:afrimarket/features/notifications/data/repositories/notification_repository_impl.dart';
import 'package:afrimarket/features/notifications/domain/entities/notification_entity.dart';
import 'package:afrimarket/features/notifications/domain/repositories/notification_repository.dart';
import 'package:afrimarket/core/services/supabase_service.dart';

final _notificationDataSourceProvider =
    Provider<NotificationDataSource>((ref) => NotificationDataSource());

final notificationRepositoryProvider = Provider<NotificationRepository>((ref) {
  return NotificationRepositoryImpl(ref.read(_notificationDataSourceProvider));
});

final notificationsProvider =
    FutureProvider<List<NotificationEntity>>((ref) async {
  final userId = ref.watch(authStateProvider).value?.id;
  if (userId == null || !SupabaseService.isInitialized) return [];
  return ref.watch(notificationRepositoryProvider).getNotifications(userId);
});

final unreadNotificationCountProvider = FutureProvider<int>((ref) async {
  final userId = ref.watch(authStateProvider).value?.id;
  if (userId == null || !SupabaseService.isInitialized) return 0;
  return ref.watch(notificationRepositoryProvider).getUnreadCount(userId);
});
