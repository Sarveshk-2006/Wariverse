class EmergencyContact {
  final String id;
  final String userId;
  final String name;
  final String phoneNumber;
  final String relationship;
  final int priority; // 1 to 5
  final bool isActive;
  final DateTime createdAt;
  final DateTime updatedAt;

  const EmergencyContact({
    required this.id,
    required this.userId,
    required this.name,
    required this.phoneNumber,
    required this.relationship,
    required this.priority,
    this.isActive = true,
    required this.createdAt,
    required this.updatedAt,
  });

  /// Validates phone numbers and normalizes format.
  static String normalizePhoneNumber(String input) {
    var cleaned = input.replaceAll(RegExp(r'\s+|-|\(|\)'), '');
    if (cleaned.startsWith('+91')) {
      return cleaned;
    }
    if (cleaned.length == 10 && RegExp(r'^[6-9]\d{9}$').hasMatch(cleaned)) {
      return '+91$cleaned';
    }
    return cleaned;
  }

  factory EmergencyContact.fromJson(Map<String, dynamic> json) {
    return EmergencyContact(
      id: json['id'] as String,
      userId: json['user_id'] as String? ?? json['userId'] as String? ?? '',
      name: json['name'] as String,
      phoneNumber: json['phone_number'] as String? ?? json['phoneNumber'] as String? ?? '',
      relationship: json['relationship'] as String,
      priority: (json['priority'] as num).toInt(),
      isActive: json['is_active'] as bool? ?? json['isActive'] as bool? ?? true,
      createdAt: json['created_at'] != null ? DateTime.parse(json['created_at'] as String) : DateTime.now(),
      updatedAt: json['updated_at'] != null ? DateTime.parse(json['updated_at'] as String) : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'user_id': userId,
        'name': name,
        'phone_number': phoneNumber,
        'relationship': relationship,
        'priority': priority,
        'is_active': isActive,
        'created_at': createdAt.toIso8601String(),
        'updated_at': updatedAt.toIso8601String(),
      };
}
