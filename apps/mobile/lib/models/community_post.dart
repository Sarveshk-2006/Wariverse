// ignore_for_file: constant_identifier_names

enum PostType {
  FOOD_AVAILABLE, WATER_AVAILABLE, SHELTER_AVAILABLE, MEDICAL_HELP,
  ROUTE_WARNING, WEATHER_WARNING, LOST_PERSON, FOUND_PERSON,
  HELP_REQUEST, GENERAL,
}

extension PostTypeX on PostType {
  String get displayName {
    switch (this) {
      case PostType.FOOD_AVAILABLE:    return 'Food Available';
      case PostType.WATER_AVAILABLE:   return 'Water Available';
      case PostType.SHELTER_AVAILABLE: return 'Shelter Available';
      case PostType.MEDICAL_HELP:      return 'Medical Help';
      case PostType.ROUTE_WARNING:     return 'Route Warning';
      case PostType.WEATHER_WARNING:   return 'Weather Warning';
      case PostType.LOST_PERSON:       return 'Lost Person';
      case PostType.FOUND_PERSON:      return 'Found Person';
      case PostType.HELP_REQUEST:      return 'Help Request';
      case PostType.GENERAL:           return 'General';
    }
  }

  static PostType fromString(String s) => PostType.values.firstWhere(
        (e) => e.name == s.toUpperCase(),
        orElse: () => PostType.GENERAL,
      );
}

class CommunityPost {
  final String id;
  final String authorId;
  final String authorName;
  final PostType postType;
  final String message;
  final double latitude;
  final double longitude;
  final double radiusKm;
  final bool isVerified;
  final int upvotes;
  final DateTime createdAt;
  final DateTime? expiresAt;

  const CommunityPost({
    required this.id,
    required this.authorId,
    required this.authorName,
    required this.postType,
    required this.message,
    required this.latitude,
    required this.longitude,
    required this.radiusKm,
    required this.isVerified,
    required this.upvotes,
    required this.createdAt,
    this.expiresAt,
  });

  factory CommunityPost.fromJson(Map<String, dynamic> json) => CommunityPost(
        id: json['id'] as String? ?? '',
        authorId: json['author_id'] as String? ?? '',
        authorName: json['author_name'] as String? ?? 'Pilgrim',
        postType: PostTypeX.fromString(json['post_type'] as String? ?? 'GENERAL'),
        message: json['message'] as String? ?? '',
        latitude: (json['latitude'] as num?)?.toDouble() ?? 17.6741,
        longitude: (json['longitude'] as num?)?.toDouble() ?? 75.3279,
        radiusKm: (json['radius_km'] as num?)?.toDouble() ?? 2.0,
        isVerified: json['is_verified'] as bool? ?? false,
        upvotes: json['upvotes'] as int? ?? 0,
        createdAt: DateTime.tryParse(json['created_at'] as String? ?? '') ??
            DateTime.now(),
        expiresAt: json['expires_at'] != null
            ? DateTime.tryParse(json['expires_at'] as String)
            : null,
      );

  Map<String, dynamic> toJson() => {
        'post_type': postType.name,
        'message': message,
        'latitude': latitude,
        'longitude': longitude,
        'radius_km': radiusKm,
      };
}
