/// Model representing a system audit log entry in Cloud Firestore.
class AuditLog {
  final String id;
  final String actorUid;
  final String action;
  final String target;
  final Map<String, dynamic> metadata;
  final DateTime timestamp;

  const AuditLog({
    required this.id,
    required this.actorUid,
    required this.action,
    required this.target,
    required this.metadata,
    required this.timestamp,
  });

  factory AuditLog.fromJson(Map<String, dynamic> json) {
    return AuditLog(
      id: json['id'] as String? ?? '',
      actorUid: json['actor_uid'] as String? ?? json['actor'] as String? ?? 'SYSTEM',
      action: json['action'] as String? ?? 'UNKNOWN_ACTION',
      target: json['target'] as String? ?? '',
      metadata: json['metadata'] as Map<String, dynamic>? ?? {},
      timestamp: DateTime.tryParse(json['timestamp'] as String? ?? '') ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'actor_uid': actorUid,
      'action': action,
      'target': target,
      'metadata': metadata,
      'timestamp': timestamp.toIso8601String(),
    };
  }
}
