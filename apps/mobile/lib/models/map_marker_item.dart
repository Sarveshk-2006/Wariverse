import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';
import '../core/theme/wari_colors.dart';

/// Unified model for all map markers (Services, Crowd, SOS, User).
class MapMarkerItem {
  final String id;
  final String title;
  final String layer; // food, water, medical, toilets, shelters, wellness, sos, crowd, user
  final double latitude;
  final double longitude;
  final IconData icon;
  final Color color;
  final String? statusLabel;
  final int? distanceM;
  final int? walkMinutes;
  final int? queueMinutes;
  final bool? availableNow;
  final dynamic originalData;

  const MapMarkerItem({
    required this.id,
    required this.title,
    required this.layer,
    required this.latitude,
    required this.longitude,
    required this.icon,
    required this.color,
    this.statusLabel,
    this.distanceM,
    this.walkMinutes,
    this.queueMinutes,
    this.availableNow,
    this.originalData,
  });

  LatLng get location => LatLng(latitude, longitude);

  static Color getLayerColor(String layer) {
    switch (layer) {
      case 'user':     return WariColors.primary;
      case 'food':     return WariColors.foodColor;
      case 'water':    return WariColors.waterColor;
      case 'medical':  return WariColors.medicalColor;
      case 'toilets':  return WariColors.toiletColor;
      case 'shelters': return WariColors.shelterColor;
      case 'wellness': return WariColors.wellnessColor;
      case 'sos':      return WariColors.sosColor;
      case 'crowd':    return WariColors.crowdOrange;
      default:         return WariColors.slate600;
    }
  }

  static IconData getLayerIcon(String layer) {
    switch (layer) {
      case 'user':     return Icons.flag;
      case 'food':     return Icons.restaurant;
      case 'water':    return Icons.water_drop;
      case 'medical':  return Icons.local_hospital;
      case 'toilets':  return Icons.wc;
      case 'shelters': return Icons.home;
      case 'wellness': return Icons.spa;
      case 'sos':      return Icons.emergency;
      case 'crowd':    return Icons.people;
      default:         return Icons.location_on;
    }
  }

  static String getLayerLabel(String layer) {
    switch (layer) {
      case 'user':     return 'Your Location';
      case 'food':     return 'Annadan Food';
      case 'water':    return 'Water Station';
      case 'medical':  return 'Medical Camp';
      case 'toilets':  return 'Sanitation Block';
      case 'shelters': return 'Relief Shelter';
      case 'wellness': return 'Wellness Seva';
      case 'sos':      return 'Emergency SOS';
      case 'crowd':    return 'Crowd Monitoring';
      default:         return 'Service Point';
    }
  }
}
