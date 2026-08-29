// ignore_for_file: constant_identifier_names

/// Schedule event type for Dindi micro-itinerary.
enum DindiScheduleType {
  DEPARTURE,
  BREAKFAST,
  ANNACHHATRA,
  RINGAN,
  TEMPLE,
  REST,
  SERVICE_HALT,
  NIGHT_SHELTER,
}

extension DindiScheduleTypeX on DindiScheduleType {
  String get displayName {
    switch (this) {
      case DindiScheduleType.DEPARTURE:     return 'Departure (प्रस्थान)';
      case DindiScheduleType.BREAKFAST:     return 'Breakfast (नाश्ता)';
      case DindiScheduleType.ANNACHHATRA:   return 'Annachhatra Lunch (अन्नछत्र)';
      case DindiScheduleType.RINGAN:        return 'Ringan Event (रिंगण सोहळा)';
      case DindiScheduleType.TEMPLE:        return 'Temple Visit (दर्शन दर्शन)';
      case DindiScheduleType.REST:          return 'Rest Halt (विश्रांती)';
      case DindiScheduleType.SERVICE_HALT:  return 'Service Stop (सेवा केंद्र)';
      case DindiScheduleType.NIGHT_SHELTER: return 'Night Shelter (पालखी मुक्काम)';
    }
  }
}

/// Dynamic status of a schedule item.
enum DindiScheduleStatus {
  COMPLETED,
  CURRENT,
  UPCOMING,
}

/// Represents a single micro-itinerary entry for a Dindi.
class DindiScheduleItem {
  final String id;
  final String dindiId;
  final String title;
  final DindiScheduleType type;
  final DindiScheduleStatus status;
  final String scheduledTime;
  final String locationName;
  final double? latitude;
  final double? longitude;
  final String description;
  final int orderIndex;

  const DindiScheduleItem({
    required this.id,
    required this.dindiId,
    required this.title,
    required this.type,
    required this.status,
    required this.scheduledTime,
    required this.locationName,
    this.latitude,
    this.longitude,
    this.description = '',
    required this.orderIndex,
  });

  bool get isCompleted => status == DindiScheduleStatus.COMPLETED;
  bool get isCurrent => status == DindiScheduleStatus.CURRENT;
  bool get isUpcoming => status == DindiScheduleStatus.UPCOMING;
  bool get hasLocation => latitude != null && longitude != null;

  factory DindiScheduleItem.fromJson(Map<String, dynamic> json) => DindiScheduleItem(
        id: json['id'] as String? ?? '',
        dindiId: json['dindi_id'] as String? ?? '',
        title: json['title'] as String? ?? '',
        type: DindiScheduleType.values.firstWhere(
          (e) => e.name == (json['type'] as String? ?? 'REST'),
          orElse: () => DindiScheduleType.REST,
        ),
        status: DindiScheduleStatus.values.firstWhere(
          (e) => e.name == (json['status'] as String? ?? 'UPCOMING'),
          orElse: () => DindiScheduleStatus.UPCOMING,
        ),
        scheduledTime: json['scheduled_time'] as String? ?? '00:00',
        locationName: json['location_name'] as String? ?? '',
        latitude: (json['latitude'] as num?)?.toDouble(),
        longitude: (json['longitude'] as num?)?.toDouble(),
        description: json['description'] as String? ?? '',
        orderIndex: json['order_index'] as int? ?? 0,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'dindi_id': dindiId,
        'title': title,
        'type': type.name,
        'status': status.name,
        'scheduled_time': scheduledTime,
        'location_name': locationName,
        'latitude': latitude,
        'longitude': longitude,
        'description': description,
        'order_index': orderIndex,
      };
}
