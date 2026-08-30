// ignore_for_file: constant_identifier_names

/// Category of private Dindi community posts.
enum DindiPostType {
  GENERAL,
  ANNOUNCEMENT,
  ROUTE_UPDATE,
  SAFETY_ALERT,
}

extension DindiPostTypeX on DindiPostType {
  String get displayName {
    switch (this) {
      case DindiPostType.GENERAL:      return 'General Update (सामान्य माहिती)';
      case DindiPostType.ANNOUNCEMENT: return 'Dindi Announcement (दिंडी सूचना)';
      case DindiPostType.ROUTE_UPDATE: return 'Route Update (मार्ग अपडेट)';
      case DindiPostType.SAFETY_ALERT: return 'Safety Alert (सुरक्षा इशारा)';
    }
  }
}

/// Represents an authoritative broadcast from a Dindi leader or coordinator.
class DindiBroadcast {
  final String id;
  final String dindiId;
  final String? dindiCode;
  final String? senderUid;
  final String sender;
  final String senderRole;
  final String type; // ANNOUNCEMENT, PALKHI_AUDIO, ALERT
  final String title;
  final String message;
  final String? audioUrl;
  final String? imageUrl;
  final DateTime createdAt;
  final DateTime? updatedAt;
  final DateTime? expiresAt;
  final String priority; // HIGH, MEDIUM, CRITICAL
  final bool isActive;

  const DindiBroadcast({
    required this.id,
    required this.dindiId,
    this.dindiCode,
    this.senderUid,
    required this.sender,
    this.senderRole = 'LEADER',
    this.type = 'ANNOUNCEMENT',
    required this.title,
    required this.message,
    this.audioUrl,
    this.imageUrl,
    required this.createdAt,
    this.updatedAt,
    this.expiresAt,
    this.priority = 'HIGH',
    this.isActive = true,
  });

  static DateTime _parseDateTime(dynamic val) {
    if (val == null) return DateTime.now();
    if (val is DateTime) return val;
    if (val is String) return DateTime.tryParse(val) ?? DateTime.now();
    try {
      if (val is num) return DateTime.fromMillisecondsSinceEpoch(val.toInt());
      return (val as dynamic).toDate() as DateTime;
    } catch (_) {
      return DateTime.now();
    }
  }

  static DateTime? _parseNullableDateTime(dynamic val) {
    if (val == null) return null;
    if (val is DateTime) return val;
    if (val is String) return DateTime.tryParse(val);
    try {
      if (val is num) return DateTime.fromMillisecondsSinceEpoch(val.toInt());
      return (val as dynamic).toDate() as DateTime;
    } catch (_) {
      return null;
    }
  }

  factory DindiBroadcast.fromJson(Map<String, dynamic> json) => DindiBroadcast(
        id: json['id'] as String? ?? '',
        dindiId: json['dindi_id'] as String? ?? json['dindiId'] as String? ?? '',
        dindiCode: json['dindi_code'] as String?,
        senderUid: json['sender_uid'] as String? ?? json['sender_id'] as String?,
        sender: json['sender'] as String? ?? json['sender_name'] as String? ?? 'Dindi Pramukh',
        senderRole: json['sender_role'] as String? ?? 'LEADER',
        type: json['type'] as String? ?? (json['audio_url'] != null ? 'PALKHI_AUDIO' : 'ANNOUNCEMENT'),
        title: json['title'] as String? ?? 'Dindi Announcement',
        message: json['message'] as String? ?? '',
        audioUrl: json['audio_url'] as String?,
        imageUrl: json['image_url'] as String?,
        createdAt: _parseDateTime(json['created_at']),
        updatedAt: _parseNullableDateTime(json['updated_at']),
        expiresAt: _parseNullableDateTime(json['expires_at']),
        priority: json['priority'] as String? ?? 'HIGH',
        isActive: json['is_active'] as bool? ?? true,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'dindi_id': dindiId,
        'dindi_code': dindiCode,
        'sender_uid': senderUid,
        'sender': sender,
        'sender_role': senderRole,
        'type': type,
        'title': title,
        'message': message,
        'audio_url': audioUrl,
        'image_url': imageUrl,
        'created_at': createdAt.toIso8601String(),
        'updated_at': updatedAt?.toIso8601String(),
        'expires_at': expiresAt?.toIso8601String(),
        'priority': priority,
        'is_active': isActive,
      };
}

/// Represents a private post inside a specific Dindi community feed.
class DindiCommunityPost {
  final String id;
  final String dindiId;
  final String authorId;
  final String authorName;
  final String authorRole;
  final String content;
  final DindiPostType postType;
  final DateTime createdAt;
  final bool isVerified;
  final bool isPinned;

  const DindiCommunityPost({
    required this.id,
    required this.dindiId,
    required this.authorId,
    required this.authorName,
    required this.authorRole,
    required this.content,
    required this.postType,
    required this.createdAt,
    this.isVerified = false,
    this.isPinned = false,
  });

  bool get isSafetyAlert => postType == DindiPostType.SAFETY_ALERT;
  bool get isAnnouncement => postType == DindiPostType.ANNOUNCEMENT;

  factory DindiCommunityPost.fromJson(Map<String, dynamic> json) => DindiCommunityPost(
        id: json['id'] as String? ?? '',
        dindiId: json['dindi_id'] as String? ?? '',
        authorId: json['author_id'] as String? ?? '',
        authorName: json['author_name'] as String? ?? 'Varkari Pilgrim',
        authorRole: json['author_role'] as String? ?? 'VARKARI',
        content: json['content'] as String? ?? '',
        postType: DindiPostType.values.firstWhere(
          (e) => e.name == (json['post_type'] as String? ?? 'GENERAL'),
          orElse: () => DindiPostType.GENERAL,
        ),
        createdAt: DateTime.tryParse(json['created_at'] as String? ?? '') ?? DateTime.now(),
        isVerified: json['is_verified'] as bool? ?? false,
        isPinned: json['is_pinned'] as bool? ?? false,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'dindi_id': dindiId,
        'author_id': authorId,
        'author_name': authorName,
        'author_role': authorRole,
        'content': content,
        'post_type': postType.name,
        'created_at': createdAt.toIso8601String(),
        'is_verified': isVerified,
        'is_pinned': isPinned,
      };
}
