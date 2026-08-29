/// LostPerson model matching backend lost_persons table.
class LostPerson {
  final String id;
  final String name;
  final int? age;
  final String? gender;
  final String? description;
  final double? lastSeenLatitude;
  final double? lastSeenLongitude;
  final String? lastSeenAt;
  final String reportedBy;
  final String? emergencyContact;
  final String? bloodGroup;
  final String status; // MISSING | FOUND
  final String? photoUrl;
  final DateTime createdAt;

  const LostPerson({
    required this.id,
    required this.name,
    this.age,
    this.gender,
    this.description,
    this.lastSeenLatitude,
    this.lastSeenLongitude,
    this.lastSeenAt,
    required this.reportedBy,
    this.emergencyContact,
    this.bloodGroup,
    required this.status,
    this.photoUrl,
    required this.createdAt,
  });

  bool get isMissing => status.toUpperCase() == 'MISSING';

  factory LostPerson.fromJson(Map<String, dynamic> json) => LostPerson(
        id: json['id'] as String? ?? '',
        name: json['name'] as String? ?? '',
        age: json['age'] as int?,
        gender: json['gender'] as String?,
        description: json['description'] as String?,
        lastSeenLatitude: (json['last_seen_latitude'] as num?)?.toDouble(),
        lastSeenLongitude: (json['last_seen_longitude'] as num?)?.toDouble(),
        lastSeenAt: json['last_seen_at'] as String?,
        reportedBy: json['reported_by'] as String? ?? '',
        emergencyContact: json['emergency_contact'] as String?,
        bloodGroup: json['blood_group'] as String?,
        status: json['status'] as String? ?? 'MISSING',
        photoUrl: json['photo_url'] as String?,
        createdAt: DateTime.tryParse(json['created_at'] as String? ?? '') ??
            DateTime.now(),
      );

  Map<String, dynamic> toJson() => {
        'name': name,
        'age': age,
        'gender': gender,
        'description': description,
        'last_seen_latitude': lastSeenLatitude,
        'last_seen_longitude': lastSeenLongitude,
        'emergency_contact': emergencyContact,
        'blood_group': bloodGroup,
      };
}
