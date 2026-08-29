/// Emergency Contact Model extracted from WoShield SOS system & WariVerse AI.
class EmergencyContact {
  final String id;
  final String userId;
  final String name;
  final String phoneNumber;
  final String relationship;
  final int priority;
  final bool isVerified;
  final dynamic createdAt;
  final dynamic updatedAt;

  const EmergencyContact({
    required this.id,
    this.userId = '',
    required this.name,
    required this.phoneNumber,
    this.relationship = 'Family',
    this.priority = 1,
    this.isVerified = true,
    this.createdAt,
    this.updatedAt,
  });

  static String normalizePhoneNumber(String phone) {
    return phone.replaceAll(RegExp(r'[^\d+]'), '');
  }

  factory EmergencyContact.fromJson(Map<String, dynamic> json) {
    return EmergencyContact(
      id: json['id'] as String? ?? 'contact_${DateTime.now().millisecondsSinceEpoch}',
      userId: json['user_id'] as String? ?? json['userId'] as String? ?? '',
      name: json['name'] as String? ?? json['display_name'] as String? ?? 'Emergency Contact',
      phoneNumber: normalizePhoneNumber(json['phone_number'] as String? ?? json['number'] as String? ?? json['phone'] as String? ?? ''),
      relationship: json['relationship_name'] as String? ?? json['relationship'] as String? ?? 'Family',
      priority: json['priority'] as int? ?? 1,
      isVerified: json['is_verified'] as bool? ?? true,
      createdAt: json['created_at'],
      updatedAt: json['updated_at'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'name': name,
      'phone_number': phoneNumber,
      'relationship_name': relationship,
      'relationship': relationship,
      'priority': priority,
      'is_verified': isVerified,
      'created_at': createdAt is DateTime ? (createdAt as DateTime).toIso8601String() : createdAt?.toString(),
      'updated_at': updatedAt is DateTime ? (updatedAt as DateTime).toIso8601String() : updatedAt?.toString(),
    };
  }
}
