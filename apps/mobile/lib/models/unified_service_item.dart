import 'package:flutter/material.dart';
import '../core/theme/wari_colors.dart';
import 'models_exports.dart';

/// Unified presentation model adapting Food, Water, Medical, Toilet, Shelter, and Wellness models.
class UnifiedServiceItem {
  final String id;
  final String name;
  final String categoryKey; // food, water, medical, toilets, shelters, wellness
  final String categoryLabel;
  final IconData icon;
  final Color color;
  final double latitude;
  final double longitude;
  final bool availableNow;
  final int? distanceM;
  final int? walkMinutes;
  final int? queueMinutes;
  final int? capacity;
  final double? rating;
  final String? subtext;
  final List<String> tags;
  final dynamic originalModel;

  const UnifiedServiceItem({
    required this.id,
    required this.name,
    required this.categoryKey,
    required this.categoryLabel,
    required this.icon,
    required this.color,
    required this.latitude,
    required this.longitude,
    required this.availableNow,
    this.distanceM,
    this.walkMinutes,
    this.queueMinutes,
    this.capacity,
    this.rating,
    this.subtext,
    this.tags = const [],
    this.originalModel,
  });

  factory UnifiedServiceItem.fromFood(FoodCentre fc) => UnifiedServiceItem(
        id: fc.id,
        name: fc.name,
        categoryKey: 'food',
        categoryLabel: 'Annadan Food',
        icon: Icons.restaurant,
        color: WariColors.foodColor,
        latitude: fc.latitude,
        longitude: fc.longitude,
        availableNow: fc.availableNow,
        distanceM: fc.distanceM ?? 150,
        walkMinutes: fc.walkMinutes ?? 2,
        queueMinutes: fc.estimatedQueueMinutes,
        capacity: fc.capacity,
        rating: fc.hygieneRating,
        subtext: 'Provider: ${fc.provider ?? "Seva Trust"}',
        tags: fc.mealTypes,
        originalModel: fc,
      );

  factory UnifiedServiceItem.fromWater(WaterPoint wp) => UnifiedServiceItem(
        id: wp.id,
        name: wp.name,
        categoryKey: 'water',
        categoryLabel: 'Water Station',
        icon: Icons.water_drop,
        color: WariColors.waterColor,
        latitude: wp.latitude,
        longitude: wp.longitude,
        availableNow: wp.status != WaterStatus.MAINTENANCE && wp.status != WaterStatus.EMPTY,
        distanceM: wp.distanceM ?? 120,
        walkMinutes: wp.walkMinutes ?? 2,
        subtext: 'Status: ${wp.status.name}',
        originalModel: wp,
      );

  factory UnifiedServiceItem.fromMedical(MedicalLocation ml) => UnifiedServiceItem(
        id: ml.id,
        name: ml.name,
        categoryKey: 'medical',
        categoryLabel: 'Medical Camp',
        icon: Icons.local_hospital,
        color: WariColors.medicalColor,
        latitude: ml.latitude,
        longitude: ml.longitude,
        availableNow: ml.available,
        subtext: 'Hours: ${ml.operatingHours}',
        tags: ml.services,
        originalModel: ml,
      );

  factory UnifiedServiceItem.fromToilet(ToiletPoint tp) => UnifiedServiceItem(
        id: tp.id,
        name: tp.name,
        categoryKey: 'toilets',
        categoryLabel: 'Sanitation Block',
        icon: Icons.wc,
        color: WariColors.toiletColor,
        latitude: tp.latitude,
        longitude: tp.longitude,
        availableNow: tp.status != ToiletStatus.CLOSED && tp.status != ToiletStatus.MAINTENANCE,
        rating: tp.rating,
        subtext: 'Status: ${tp.status.name}',
        originalModel: tp,
      );

  factory UnifiedServiceItem.fromShelter(Shelter s) => UnifiedServiceItem(
        id: s.id,
        name: s.name,
        categoryKey: 'shelters',
        categoryLabel: 'Relief Shelter',
        icon: Icons.home,
        color: WariColors.shelterColor,
        latitude: s.latitude,
        longitude: s.longitude,
        availableNow: s.availableNow,
        capacity: s.capacity,
        subtext: '${s.availableSpots} spots available',
        tags: s.amenities,
        originalModel: s,
      );

  factory UnifiedServiceItem.fromWellness(WellnessCentre wc) => UnifiedServiceItem(
        id: wc.id,
        name: wc.name,
        categoryKey: 'wellness',
        categoryLabel: 'Wellness Seva',
        icon: Icons.spa,
        color: WariColors.wellnessColor,
        latitude: wc.latitude,
        longitude: wc.longitude,
        availableNow: wc.availableNow,
        subtext: wc.services.isNotEmpty ? wc.services.first : 'Footcare Seva',
        tags: wc.services,
        originalModel: wc,
      );
}
