/// Notification model matching backend notifications table.
class WariNotification {
  final String id;
  final String userId;
  final String title;
  final String message;
  final String notificationType;
  final String priority;
  final bool isRead;
  final Map<String, dynamic>? data;
  final DateTime createdAt;

  const WariNotification({
    required this.id,
    required this.userId,
    required this.title,
    required this.message,
    required this.notificationType,
    required this.priority,
    required this.isRead,
    this.data,
    required this.createdAt,
  });

  factory WariNotification.fromJson(Map<String, dynamic> json) =>
      WariNotification(
        id: json['id'] as String? ?? '',
        userId: json['user_id'] as String? ?? '',
        title: json['title'] as String? ?? '',
        message: json['message'] as String? ?? '',
        notificationType: json['notification_type'] as String? ?? 'INFO',
        priority: json['priority'] as String? ?? 'MEDIUM',
        isRead: json['is_read'] as bool? ?? false,
        data: json['data'] as Map<String, dynamic>?,
        createdAt: DateTime.tryParse(json['created_at'] as String? ?? '') ??
            DateTime.now(),
      );
}
