// ignore_for_file: constant_identifier_names
import 'package:flutter/material.dart';

/// Categories for NGO Aid Distributions & Realtime Deployments.
enum DistributionCategory {
  FOOD,
  WATER,
  MEDICAL_SUPPLIES,
  MEDICINE,
  CLOTHING,
  BLANKETS,
  SHELTER,
  TOILETS_SANITATION,
  HYGIENE_KITS,
  FIRST_AID,
  ORS_GLUCOSE,
  BABY_CARE,
  ELDERLY_SUPPORT,
  TRANSPORT,
  CHARGING,
  LOST_AND_FOUND_SUPPORT,
  VOLUNTEER_SUPPORT,
  OTHER,
}

extension DistributionCategoryX on DistributionCategory {
  String get displayName {
    switch (this) {
      case DistributionCategory.FOOD: return 'Food & Annadan';
      case DistributionCategory.WATER: return 'Water & Hydration';
      case DistributionCategory.MEDICAL_SUPPLIES: return 'Medical Supplies';
      case DistributionCategory.MEDICINE: return 'Medicines';
      case DistributionCategory.CLOTHING: return 'Clothing';
      case DistributionCategory.BLANKETS: return 'Blankets & Warmth';
      case DistributionCategory.SHELTER: return 'Shelter & Rest Tent';
      case DistributionCategory.TOILETS_SANITATION: return 'Toilets & Sanitation';
      case DistributionCategory.HYGIENE_KITS: return 'Hygiene Kits';
      case DistributionCategory.FIRST_AID: return 'First Aid Station';
      case DistributionCategory.ORS_GLUCOSE: return 'ORS & Glucose';
      case DistributionCategory.BABY_CARE: return 'Baby Care & Diapers';
      case DistributionCategory.ELDERLY_SUPPORT: return 'Elderly Support';
      case DistributionCategory.TRANSPORT: return 'Emergency Transport';
      case DistributionCategory.CHARGING: return 'Mobile Charging Station';
      case DistributionCategory.LOST_AND_FOUND_SUPPORT: return 'Lost & Found Booth';
      case DistributionCategory.VOLUNTEER_SUPPORT: return 'Volunteer Support';
      case DistributionCategory.OTHER: return 'Other Aid';
    }
  }

  IconData get icon {
    switch (this) {
      case DistributionCategory.FOOD: return Icons.restaurant;
      case DistributionCategory.WATER: return Icons.water_drop;
      case DistributionCategory.MEDICAL_SUPPLIES: return Icons.medical_services;
      case DistributionCategory.MEDICINE: return Icons.medication;
      case DistributionCategory.CLOTHING: return Icons.checkroom;
      case DistributionCategory.BLANKETS: return Icons.bed;
      case DistributionCategory.SHELTER: return Icons.home;
      case DistributionCategory.TOILETS_SANITATION: return Icons.clean_hands;
      case DistributionCategory.HYGIENE_KITS: return Icons.sanitizer;
      case DistributionCategory.FIRST_AID: return Icons.healing;
      case DistributionCategory.ORS_GLUCOSE: return Icons.local_drink;
      case DistributionCategory.BABY_CARE: return Icons.child_care;
      case DistributionCategory.ELDERLY_SUPPORT: return Icons.accessible;
      case DistributionCategory.TRANSPORT: return Icons.directions_bus;
      case DistributionCategory.CHARGING: return Icons.battery_charging_full;
      case DistributionCategory.LOST_AND_FOUND_SUPPORT: return Icons.person_search;
      case DistributionCategory.VOLUNTEER_SUPPORT: return Icons.handshake;
      case DistributionCategory.OTHER: return Icons.card_giftcard;
    }
  }

  Color get color {
    switch (this) {
      case DistributionCategory.FOOD: return const Color(0xFFE65100);
      case DistributionCategory.WATER: return const Color(0xFF0288D1);
      case DistributionCategory.MEDICAL_SUPPLIES: return const Color(0xFFD32F2F);
      case DistributionCategory.MEDICINE: return const Color(0xFFC2185B);
      case DistributionCategory.CLOTHING: return const Color(0xFF7B1FA2);
      case DistributionCategory.BLANKETS: return const Color(0xFF512DA8);
      case DistributionCategory.SHELTER: return const Color(0xFF388E3C);
      case DistributionCategory.TOILETS_SANITATION: return const Color(0xFF00796B);
      case DistributionCategory.HYGIENE_KITS: return const Color(0xFF0097A7);
      case DistributionCategory.FIRST_AID: return const Color(0xFFE53935);
      case DistributionCategory.ORS_GLUCOSE: return const Color(0xFFF57C00);
      case DistributionCategory.BABY_CARE: return const Color(0xFFEC407A);
      case DistributionCategory.ELDERLY_SUPPORT: return const Color(0xFF8D6E63);
      case DistributionCategory.TRANSPORT: return const Color(0xFF1976D2);
      case DistributionCategory.CHARGING: return const Color(0xFFFBC02D);
      case DistributionCategory.LOST_AND_FOUND_SUPPORT: return const Color(0xFF5D4037);
      case DistributionCategory.VOLUNTEER_SUPPORT: return const Color(0xFF43A047);
      case DistributionCategory.OTHER: return const Color(0xFF616161);
    }
  }

  static DistributionCategory fromString(String key) {
    final clean = key.replaceAll('/', '_').replaceAll(' ', '_').toUpperCase();
    return DistributionCategory.values.firstWhere(
      (c) => c.name == clean,
      orElse: () {
        if (clean.contains('MEDICAL')) return DistributionCategory.MEDICAL_SUPPLIES;
        if (clean.contains('TOILET') || clean.contains('SANITATION')) return DistributionCategory.TOILETS_SANITATION;
        if (clean.contains('FIRST') || clean.contains('AID')) return DistributionCategory.FIRST_AID;
        if (clean.contains('ORS')) return DistributionCategory.ORS_GLUCOSE;
        return DistributionCategory.OTHER;
      },
    );
  }
}

/// Firestore Model representing a Real-Time NGO Aid Distribution.
class ResourceDistribution {
  final String id;
  final String ngoId;
  final String ngoName;
  final String title;
  final DistributionCategory category;
  final String? subcategory;
  final String? description;
  final int quantity;
  final String unit;
  final int remainingQuantity;
  final double latitude;
  final double longitude;
  final String locationName;
  final String? address;
  final DateTime distributionDate;
  final DateTime startTime;
  final DateTime? endTime;
  final String? instructions;
  final int? servingCapacity;
  final int? currentQueue;
  final int? estimatedQueueMinutes;
  final bool tokensRequired;
  final String? contactName;
  final String? contactPhone;
  final String severity; // NORMAL, IMPORTANT, URGENT
  final bool isVerified;
  final String? inventoryItemId;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? startedAt;
  final DateTime? completedAt;
  final DateTime? cancelledAt;

  const ResourceDistribution({
    required this.id,
    required this.ngoId,
    required this.ngoName,
    required this.title,
    required this.category,
    this.subcategory,
    this.description,
    required this.quantity,
    required this.unit,
    required this.remainingQuantity,
    required this.latitude,
    required this.longitude,
    required this.locationName,
    this.address,
    required this.distributionDate,
    required this.startTime,
    this.endTime,
    this.instructions,
    this.servingCapacity,
    this.currentQueue,
    this.estimatedQueueMinutes,
    this.tokensRequired = false,
    this.contactName,
    this.contactPhone,
    this.severity = 'NORMAL',
    this.isVerified = true,
    this.inventoryItemId,
    required this.createdAt,
    required this.updatedAt,
    this.startedAt,
    this.completedAt,
    this.cancelledAt,
  });

  /// Dynamically computes availability status from remaining quantity.
  String get computedAvailabilityStatus {
    if (remainingQuantity <= 0) return 'FINISHED';
    final ratio = remainingQuantity / (quantity > 0 ? quantity : 1);
    if (ratio <= 0.15) return 'ALMOST_FINISHED';
    if (ratio <= 0.40) return 'LIMITED';
    return 'AVAILABLE';
  }

  /// Dynamically computes distribution time lifecycle status.
  String get computedDistributionStatus {
    if (cancelledAt != null) return 'CANCELLED';
    if (completedAt != null || remainingQuantity <= 0) return 'COMPLETED';
    final now = DateTime.now();
    if (now.isBefore(startTime)) return 'UPCOMING';
    if (endTime != null && now.isAfter(endTime!)) return 'EXPIRED';
    if (endTime != null && endTime!.difference(now).inMinutes <= 30) return 'ENDING_SOON';
    return 'ACTIVE';
  }

  bool get isActive => computedDistributionStatus == 'ACTIVE' || computedDistributionStatus == 'ENDING_SOON';

  ResourceDistribution copyWith({
    String? id,
    String? ngoId,
    String? ngoName,
    String? title,
    DistributionCategory? category,
    String? subcategory,
    String? description,
    int? quantity,
    String? unit,
    int? remainingQuantity,
    double? latitude,
    double? longitude,
    String? locationName,
    String? address,
    DateTime? distributionDate,
    DateTime? startTime,
    DateTime? endTime,
    String? instructions,
    int? servingCapacity,
    int? currentQueue,
    int? estimatedQueueMinutes,
    bool? tokensRequired,
    String? contactName,
    String? contactPhone,
    String? severity,
    bool? isVerified,
    String? inventoryItemId,
    DateTime? createdAt,
    DateTime? updatedAt,
    DateTime? startedAt,
    DateTime? completedAt,
    DateTime? cancelledAt,
  }) {
    return ResourceDistribution(
      id: id ?? this.id,
      ngoId: ngoId ?? this.ngoId,
      ngoName: ngoName ?? this.ngoName,
      title: title ?? this.title,
      category: category ?? this.category,
      subcategory: subcategory ?? this.subcategory,
      description: description ?? this.description,
      quantity: quantity ?? this.quantity,
      unit: unit ?? this.unit,
      remainingQuantity: remainingQuantity ?? this.remainingQuantity,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      locationName: locationName ?? this.locationName,
      address: address ?? this.address,
      distributionDate: distributionDate ?? this.distributionDate,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
      instructions: instructions ?? this.instructions,
      servingCapacity: servingCapacity ?? this.servingCapacity,
      currentQueue: currentQueue ?? this.currentQueue,
      estimatedQueueMinutes: estimatedQueueMinutes ?? this.estimatedQueueMinutes,
      tokensRequired: tokensRequired ?? this.tokensRequired,
      contactName: contactName ?? this.contactName,
      contactPhone: contactPhone ?? this.contactPhone,
      severity: severity ?? this.severity,
      isVerified: isVerified ?? this.isVerified,
      inventoryItemId: inventoryItemId ?? this.inventoryItemId,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      startedAt: startedAt ?? this.startedAt,
      completedAt: completedAt ?? this.completedAt,
      cancelledAt: cancelledAt ?? this.cancelledAt,
    );
  }

  factory ResourceDistribution.fromJson(Map<String, dynamic> json) {
    return ResourceDistribution(
      id: json['id'] as String? ?? '',
      ngoId: json['ngo_id'] as String? ?? '',
      ngoName: json['ngo_name'] as String? ?? 'Wari Seva NGO',
      title: json['title'] as String? ?? 'Aid Distribution',
      category: DistributionCategoryX.fromString(json['category'] as String? ?? 'OTHER'),
      subcategory: json['subcategory'] as String?,
      description: json['description'] as String?,
      quantity: json['quantity'] as int? ?? 100,
      unit: json['unit'] as String? ?? 'items',
      remainingQuantity: json['remaining_quantity'] as int? ?? json['quantity'] as int? ?? 100,
      latitude: (json['latitude'] as num?)?.toDouble() ?? 18.5204,
      longitude: (json['longitude'] as num?)?.toDouble() ?? 73.8567,
      locationName: json['location_name'] as String? ?? 'Distribution Site',
      address: json['address'] as String?,
      distributionDate: json['distribution_date'] != null ? DateTime.parse(json['distribution_date'] as String) : DateTime.now(),
      startTime: json['start_time'] != null ? DateTime.parse(json['start_time'] as String) : DateTime.now(),
      endTime: json['end_time'] != null ? DateTime.parse(json['end_time'] as String) : null,
      instructions: json['instructions'] as String?,
      servingCapacity: json['serving_capacity'] as int?,
      currentQueue: json['current_queue'] as int?,
      estimatedQueueMinutes: json['estimated_queue_minutes'] as int?,
      tokensRequired: json['tokens_required'] as bool? ?? false,
      contactName: json['contact_name'] as String?,
      contactPhone: json['contact_phone'] as String?,
      severity: json['severity'] as String? ?? 'NORMAL',
      isVerified: json['is_verified'] as bool? ?? true,
      inventoryItemId: json['inventory_item_id'] as String?,
      createdAt: json['created_at'] != null ? DateTime.parse(json['created_at'] as String) : DateTime.now(),
      updatedAt: json['updated_at'] != null ? DateTime.parse(json['updated_at'] as String) : DateTime.now(),
      startedAt: json['started_at'] != null ? DateTime.parse(json['started_at'] as String) : null,
      completedAt: json['completed_at'] != null ? DateTime.parse(json['completed_at'] as String) : null,
      cancelledAt: json['cancelled_at'] != null ? DateTime.parse(json['cancelled_at'] as String) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'ngo_id': ngoId,
      'ngo_name': ngoName,
      'title': title,
      'category': category.name,
      'subcategory': subcategory,
      'description': description,
      'quantity': quantity,
      'unit': unit,
      'remaining_quantity': remainingQuantity,
      'availability_status': computedAvailabilityStatus,
      'distribution_status': computedDistributionStatus,
      'latitude': latitude,
      'longitude': longitude,
      'location_name': locationName,
      'address': address,
      'distribution_date': distributionDate.toIso8601String(),
      'start_time': startTime.toIso8601String(),
      'end_time': endTime?.toIso8601String(),
      'instructions': instructions,
      'serving_capacity': servingCapacity,
      'currentQueue': currentQueue,
      'estimated_queue_minutes': estimatedQueueMinutes,
      'tokens_required': tokensRequired,
      'contact_name': contactName,
      'contact_phone': contactPhone,
      'severity': severity,
      'is_verified': isVerified,
      'inventory_item_id': inventoryItemId,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
      'started_at': startedAt?.toIso8601String(),
      'completed_at': completedAt?.toIso8601String(),
      'cancelled_at': cancelledAt?.toIso8601String(),
    };
  }
}
