enum NotificationType {
  order,
  payment,
  promo,
  system,
  review;

  static NotificationType fromString(String value) {
    return NotificationType.values.firstWhere(
      (t) => t.name == value,
      orElse: () => NotificationType.system,
    );
  }
}

class NotificationEntity {
  final String id;
  final String userId;
  final String title;
  final String body;
  final NotificationType type;
  final bool isRead;
  final String? actionUrl;
  final Map<String, dynamic> metadata;
  final DateTime createdAt;

  const NotificationEntity({
    required this.id,
    required this.userId,
    required this.title,
    required this.body,
    required this.type,
    required this.isRead,
    this.actionUrl,
    required this.metadata,
    required this.createdAt,
  });

  factory NotificationEntity.fromJson(Map<String, dynamic> json) {
    return NotificationEntity(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      title: json['title'] as String? ?? '',
      body: json['body'] as String? ?? json['message'] as String? ?? '',
      type: NotificationType.fromString(json['type'] as String? ?? 'system'),
      isRead: json['is_read'] as bool? ?? false,
      actionUrl: json['action_url'] as String?,
      metadata: json['metadata'] is Map
          ? Map<String, dynamic>.from(json['metadata'] as Map)
          : {},
      createdAt: DateTime.parse(
          json['created_at'] as String? ?? DateTime.now().toIso8601String()),
    );
  }

  NotificationEntity copyWith({bool? isRead}) {
    return NotificationEntity(
      id: id,
      userId: userId,
      title: title,
      body: body,
      type: type,
      isRead: isRead ?? this.isRead,
      actionUrl: actionUrl,
      metadata: metadata,
      createdAt: createdAt,
    );
  }

  String get timeAgo {
    final diff = DateTime.now().difference(createdAt);
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    return '${diff.inDays}d ago';
  }
}
