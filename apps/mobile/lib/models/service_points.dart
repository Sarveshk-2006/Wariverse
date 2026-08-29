// ignore_for_file: constant_identifier_names

/// FoodCentre returned from /food and /food/nearby endpoints.
class FoodCentre {
  final String id;
  final String name;
  final String? provider;
  final double latitude;
  final double longitude;
  final bool availableNow;
  final int currentCount;
  final int capacity;
  final int estimatedQueueMinutes;
  final double hygieneRating;
  final String openingTime;
  final String closingTime;
  final List<String> mealTypes;
  final int? distanceM;
  final int? walkMinutes;
  final String? address;

  const FoodCentre({
    required this.id,
    required this.name,
    this.provider,
    required this.latitude,
    required this.longitude,
    required this.availableNow,
    required this.currentCount,
    required this.capacity,
    required this.estimatedQueueMinutes,
    required this.hygieneRating,
    required this.openingTime,
    required this.closingTime,
    required this.mealTypes,
    this.distanceM,
    this.walkMinutes,
    this.address,
  });

  factory FoodCentre.fromJson(Map<String, dynamic> json) => FoodCentre(
        id: json['id'] as String? ?? '',
        name: json['name'] as String? ?? '',
        provider: json['provider'] as String?,
        latitude: (json['latitude'] as num?)?.toDouble() ?? 17.6741,
        longitude: (json['longitude'] as num?)?.toDouble() ?? 75.3279,
        availableNow: json['available_now'] as bool? ?? true,
        currentCount: json['current_count'] as int? ?? 0,
        capacity: json['capacity'] as int? ?? 0,
        estimatedQueueMinutes: json['estimated_queue_minutes'] as int? ?? 0,
        hygieneRating: (json['hygiene_rating'] as num?)?.toDouble() ?? 4.0,
        openingTime: json['opening_time'] as String? ?? '06:00',
        closingTime: json['closing_time'] as String? ?? '21:00',
        mealTypes: List<String>.from(json['meal_types'] as List? ?? []),
        distanceM: json['distance_m'] as int?,
        walkMinutes: json['walk_minutes'] as int?,
        address: json['address'] as String?,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'provider': provider,
        'latitude': latitude,
        'longitude': longitude,
        'available_now': availableNow,
        'current_count': currentCount,
        'capacity': capacity,
        'estimated_queue_minutes': estimatedQueueMinutes,
        'hygiene_rating': hygieneRating,
        'opening_time': openingTime,
        'closing_time': closingTime,
        'meal_types': mealTypes,
        'distance_m': distanceM,
        'walk_minutes': walkMinutes,
        'address': address,
      };
}

/// WaterStatus enum matching backend.
enum WaterStatus { AVAILABLE, LOW, EMPTY, MAINTENANCE }

extension WaterStatusX on WaterStatus {
  static WaterStatus fromString(String s) => WaterStatus.values.firstWhere(
        (e) => e.name == s.toUpperCase(),
        orElse: () => WaterStatus.AVAILABLE,
      );
}

/// WaterPoint returned from /water and /water/nearby endpoints.
class WaterPoint {
  final String id;
  final String name;
  final double latitude;
  final double longitude;
  final WaterStatus status;
  final String waterType;
  final int? capacityLiters;
  final int? distanceM;
  final int? walkMinutes;
  final String? address;

  const WaterPoint({
    required this.id,
    required this.name,
    required this.latitude,
    required this.longitude,
    required this.status,
    required this.waterType,
    this.capacityLiters,
    this.distanceM,
    this.walkMinutes,
    this.address,
  });

  factory WaterPoint.fromJson(Map<String, dynamic> json) => WaterPoint(
        id: json['id'] as String? ?? '',
        name: json['name'] as String? ?? '',
        latitude: (json['latitude'] as num?)?.toDouble() ?? 17.6741,
        longitude: (json['longitude'] as num?)?.toDouble() ?? 75.3279,
        status: WaterStatusX.fromString(json['status'] as String? ?? 'AVAILABLE'),
        waterType: json['water_type'] as String? ?? 'drinking',
        capacityLiters: json['capacity_liters'] as int?,
        distanceM: json['distance_m'] as int?,
        walkMinutes: json['walk_minutes'] as int?,
        address: json['address'] as String?,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'latitude': latitude,
        'longitude': longitude,
        'status': status.name,
        'water_type': waterType,
        'capacity_liters': capacityLiters,
        'distance_m': distanceM,
        'walk_minutes': walkMinutes,
        'address': address,
      };
}

/// ToiletStatus enum matching backend.
enum ToiletStatus { CLEAN, NEEDS_CLEANING, MAINTENANCE, CLOSED }

extension ToiletStatusX on ToiletStatus {
  static ToiletStatus fromString(String s) => ToiletStatus.values.firstWhere(
        (e) => e.name == s.toUpperCase(),
        orElse: () => ToiletStatus.CLEAN,
      );
}

/// Toilet returned from /toilets endpoint.
class ToiletPoint {
  final String id;
  final String name;
  final double latitude;
  final double longitude;
  final ToiletStatus status;
  final int totalUnits;
  final String gender;
  final double rating;
  final String? lastCleanedAt;
  final String? address;

  const ToiletPoint({
    required this.id,
    required this.name,
    required this.latitude,
    required this.longitude,
    required this.status,
    required this.totalUnits,
    required this.gender,
    required this.rating,
    this.lastCleanedAt,
    this.address,
  });

  factory ToiletPoint.fromJson(Map<String, dynamic> json) => ToiletPoint(
        id: json['id'] as String? ?? '',
        name: json['name'] as String? ?? '',
        latitude: (json['latitude'] as num?)?.toDouble() ?? 17.6741,
        longitude: (json['longitude'] as num?)?.toDouble() ?? 75.3279,
        status: ToiletStatusX.fromString(json['status'] as String? ?? 'CLEAN'),
        totalUnits: json['total_units'] as int? ?? 4,
        gender: json['gender'] as String? ?? 'mixed',
        rating: (json['rating'] as num?)?.toDouble() ?? 4.0,
        lastCleanedAt: json['last_cleaned_at'] as String?,
        address: json['address'] as String?,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'latitude': latitude,
        'longitude': longitude,
        'status': status.name,
        'total_units': totalUnits,
        'gender': gender,
        'rating': rating,
        'last_cleaned_at': lastCleanedAt,
        'address': address,
      };
}

/// Shelter returned from /shelters endpoint.
class Shelter {
  final String id;
  final String name;
  final double latitude;
  final double longitude;
  final int capacity;
  final int currentOccupancy;
  final bool availableNow;
  final String? provider;
  final List<String> amenities;
  final String? address;

  const Shelter({
    required this.id,
    required this.name,
    required this.latitude,
    required this.longitude,
    required this.capacity,
    required this.currentOccupancy,
    required this.availableNow,
    this.provider,
    required this.amenities,
    this.address,
  });

  factory Shelter.fromJson(Map<String, dynamic> json) => Shelter(
        id: json['id'] as String? ?? '',
        name: json['name'] as String? ?? '',
        latitude: (json['latitude'] as num?)?.toDouble() ?? 17.6741,
        longitude: (json['longitude'] as num?)?.toDouble() ?? 75.3279,
        capacity: json['capacity'] as int? ?? 100,
        currentOccupancy: json['current_occupancy'] as int? ?? 0,
        availableNow: json['available_now'] as bool? ?? true,
        provider: json['provider'] as String?,
        amenities: List<String>.from(json['amenities'] as List? ?? []),
        address: json['address'] as String?,
      );

  int get availableSpots => capacity - currentOccupancy;

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'latitude': latitude,
        'longitude': longitude,
        'capacity': capacity,
        'current_occupancy': currentOccupancy,
        'available_now': availableNow,
        'provider': provider,
        'amenities': amenities,
        'address': address,
      };
}

/// MedicalLocation returned from /medical endpoint.
class MedicalLocation {
  final String id;
  final String name;
  final String locationType;
  final double latitude;
  final double longitude;
  final List<String> services;
  final bool available;
  final int capacity;
  final String? contact;
  final String operatingHours;
  final String? address;

  const MedicalLocation({
    required this.id,
    required this.name,
    required this.locationType,
    required this.latitude,
    required this.longitude,
    required this.services,
    required this.available,
    required this.capacity,
    this.contact,
    required this.operatingHours,
    this.address,
  });

  factory MedicalLocation.fromJson(Map<String, dynamic> json) => MedicalLocation(
        id: json['id'] as String? ?? '',
        name: json['name'] as String? ?? '',
        locationType: json['location_type'] as String? ?? 'first_aid',
        latitude: (json['latitude'] as num?)?.toDouble() ?? 17.6741,
        longitude: (json['longitude'] as num?)?.toDouble() ?? 75.3279,
        services: List<String>.from(json['services'] as List? ?? []),
        available: json['available'] as bool? ?? true,
        capacity: json['capacity'] as int? ?? 20,
        contact: json['contact'] as String?,
        operatingHours: json['operating_hours'] as String? ?? '24/7',
        address: json['address'] as String?,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'location_type': locationType,
        'latitude': latitude,
        'longitude': longitude,
        'services': services,
        'available': available,
        'capacity': capacity,
        'contact': contact,
        'operating_hours': operatingHours,
        'address': address,
      };
}

/// WellnessCentre returned from /wellness endpoint.
class WellnessCentre {
  final String id;
  final String name;
  final double latitude;
  final double longitude;
  final List<String> services;
  final bool availableNow;
  final int? waitingPilgrims;
  final String? address;

  const WellnessCentre({
    required this.id,
    required this.name,
    required this.latitude,
    required this.longitude,
    required this.services,
    required this.availableNow,
    this.waitingPilgrims,
    this.address,
  });

  factory WellnessCentre.fromJson(Map<String, dynamic> json) => WellnessCentre(
        id: json['id'] as String? ?? '',
        name: json['name'] as String? ?? '',
        latitude: (json['latitude'] as num?)?.toDouble() ?? 17.6741,
        longitude: (json['longitude'] as num?)?.toDouble() ?? 75.3279,
        services: List<String>.from(json['services'] as List? ?? []),
        availableNow: (json['available_now'] ?? json['status'] == 'OPEN') as bool? ?? true,
        waitingPilgrims: json['waiting_pilgrims'] as int?,
        address: json['address'] as String?,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'latitude': latitude,
        'longitude': longitude,
        'services': services,
        'available_now': availableNow,
        'waiting_pilgrims': waitingPilgrims,
        'address': address,
      };
}
