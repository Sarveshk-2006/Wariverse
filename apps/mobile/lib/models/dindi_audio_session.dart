// ignore_for_file: constant_identifier_names

/// Status of live audio broadcast stream.
enum DindiAudioStatus {
  CONNECTING,
  LIVE,
  PAUSED,
  ENDED,
  OFFLINE,
  ERROR,
}

extension DindiAudioStatusX on DindiAudioStatus {
  String get statusBadge {
    switch (this) {
      case DindiAudioStatus.CONNECTING: return '● CONNECTING...';
      case DindiAudioStatus.LIVE:       return '🔴 LIVE';
      case DindiAudioStatus.PAUSED:     return '⏸ PAUSED';
      case DindiAudioStatus.ENDED:      return '⚫ ENDED';
      case DindiAudioStatus.OFFLINE:    return '⚫ AUDIO OFFLINE';
      case DindiAudioStatus.ERROR:      return '⚠️ AUDIO ERROR';
    }
  }
}

/// Represents an active or scheduled audio session broadcast for a Dindi.
class DindiAudioSession {
  final String id;
  final String dindiId;
  final String title;
  final String hostName;
  final String hostRole;
  final String description;
  final DindiAudioStatus status;
  final DateTime startedAt;
  final int listenerCount;
  final bool isDemo;

  const DindiAudioSession({
    required this.id,
    required this.dindiId,
    required this.title,
    required this.hostName,
    required this.hostRole,
    required this.description,
    required this.status,
    required this.startedAt,
    this.listenerCount = 42,
    this.isDemo = true,
  });

  bool get isLive => status == DindiAudioStatus.LIVE;
  bool get isConnecting => status == DindiAudioStatus.CONNECTING;

  factory DindiAudioSession.fromJson(Map<String, dynamic> json) => DindiAudioSession(
        id: json['id'] as String? ?? '',
        dindiId: json['dindi_id'] as String? ?? '',
        title: json['title'] as String? ?? 'Palkhi Voice Live',
        hostName: json['host_name'] as String? ?? 'Dindi Pramukh',
        hostRole: json['host_role'] as String? ?? 'LEADER',
        description: json['description'] as String? ?? '',
        status: DindiAudioStatus.values.firstWhere(
          (e) => e.name == (json['status'] as String? ?? 'LIVE'),
          orElse: () => DindiAudioStatus.LIVE,
        ),
        startedAt: DateTime.tryParse(json['started_at'] as String? ?? '') ?? DateTime.now(),
        listenerCount: json['listener_count'] as int? ?? 42,
        isDemo: json['is_demo'] as bool? ?? true,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'dindi_id': dindiId,
        'title': title,
        'host_name': hostName,
        'host_role': hostRole,
        'description': description,
        'status': status.name,
        'started_at': startedAt.toIso8601String(),
        'listener_count': listenerCount,
        'is_demo': isDemo,
      };
}
