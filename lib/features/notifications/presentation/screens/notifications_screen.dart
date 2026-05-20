import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:afrimarket/core/theme/app_theme.dart';
import 'package:afrimarket/features/auth/presentation/providers/auth_providers.dart';
import 'package:afrimarket/features/notifications/domain/entities/notification_entity.dart';
import 'package:afrimarket/features/notifications/presentation/providers/notification_provider.dart';

class NotificationsScreen extends ConsumerWidget {
  const NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notificationsAsync = ref.watch(notificationsProvider);
    final userId = ref.watch(authStateProvider).value?.id;
    final notifRepo = ref.read(notificationRepositoryProvider);

    return Scaffold(
      backgroundColor: AppTheme.surfaceColor,
      appBar: AppBar(
        title: Text(
          'Notifications',
          style: GoogleFonts.poppins(fontWeight: FontWeight.w700),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
        actions: [
          if (userId != null)
            TextButton(
              onPressed: () async {
                await notifRepo.markAllAsRead(userId);
                ref.invalidate(notificationsProvider);
                ref.invalidate(unreadNotificationCountProvider);
              },
              child: Text(
                'Mark all read',
                style: GoogleFonts.poppins(
                    fontSize: 13, color: AppTheme.primaryGreen),
              ),
            ),
        ],
      ),
      body: notificationsAsync.when(
        data: (notifications) {
          if (notifications.isEmpty) {
            return _EmptyNotifications();
          }
          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: notifications.length,
            separatorBuilder: (_, __) => const SizedBox(height: 8),
            itemBuilder: (context, i) {
              final n = notifications[i];
              return _NotificationCard(
                notification: n,
                onTap: () async {
                  if (!n.isRead) {
                    await notifRepo.markAsRead(n.id);
                    ref.invalidate(notificationsProvider);
                    ref.invalidate(unreadNotificationCountProvider);
                  }
                },
              );
            },
          );
        },
        loading: () => const Center(
          child: CircularProgressIndicator(color: AppTheme.primaryGreen),
        ),
        error: (e, _) =>
            const Center(child: Text('Error loading notifications')),
      ),
    );
  }
}

class _NotificationCard extends StatelessWidget {
  final NotificationEntity notification;
  final VoidCallback onTap;

  const _NotificationCard({
    required this.notification,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    IconData icon;
    Color color;
    switch (notification.type) {
      case NotificationType.order:
        icon = Icons.shopping_bag_outlined;
        color = AppTheme.accentOrange;
        break;
      case NotificationType.payment:
        icon = Icons.payment_outlined;
        color = const Color(0xFF9C27B0);
        break;
      case NotificationType.promo:
        icon = Icons.local_offer_outlined;
        color = const Color(0xFF1E88E5);
        break;
      default:
        icon = Icons.notifications_outlined;
        color = AppTheme.primaryGreen;
    }

    return Material(
      color:
          notification.isRead ? Colors.white : const Color(0xFFF1F8E9),
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: notification.isRead
                  ? const Color(0xFFE0E0E0)
                  : AppTheme.primaryGreen.withOpacity(0.3),
            ),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, size: 22, color: color),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            notification.title,
                            style: GoogleFonts.poppins(
                              fontSize: 14,
                              fontWeight: notification.isRead
                                  ? FontWeight.w500
                                  : FontWeight.w700,
                              color: AppTheme.textPrimary,
                            ),
                          ),
                        ),
                        if (!notification.isRead)
                          Container(
                            width: 8,
                            height: 8,
                            decoration: const BoxDecoration(
                              color: AppTheme.primaryGreen,
                              shape: BoxShape.circle,
                            ),
                          ),
                      ],
                    ),
                    if (notification.body.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(
                        notification.body,
                        style: GoogleFonts.poppins(
                          fontSize: 13,
                          color: AppTheme.textSecondary,
                          height: 1.4,
                        ),
                      ),
                    ],
                    const SizedBox(height: 6),
                    Text(
                      notification.timeAgo,
                      style: GoogleFonts.poppins(
                        fontSize: 11,
                        color: AppTheme.textTertiary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _EmptyNotifications extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 100,
            height: 100,
            decoration: const BoxDecoration(
              color: Color(0xFFE8F5E9),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.notifications_none,
                size: 50, color: AppTheme.primaryGreen),
          ),
          const SizedBox(height: 20),
          Text(
            'No notifications yet',
            style: GoogleFonts.poppins(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: AppTheme.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'You\'ll see order updates and promotions here',
            style: GoogleFonts.poppins(
                fontSize: 14, color: AppTheme.textSecondary),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
