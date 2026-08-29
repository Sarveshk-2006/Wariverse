// ignore_for_file: constant_identifier_names

/// Risk levels for heat, dehydration, and fatigue awareness.
enum VarkariHealthRiskLevel {
  NORMAL,
  MODERATE,
  HIGH,
  CRITICAL,
}

extension VarkariHealthRiskLevelX on VarkariHealthRiskLevel {
  String get displayName {
    switch (this) {
      case VarkariHealthRiskLevel.NORMAL:   return 'NORMAL (अनुकूल)';
      case VarkariHealthRiskLevel.MODERATE: return 'MODERATE (मध्यम सावधगिरी)';
      case VarkariHealthRiskLevel.HIGH:     return 'HIGH (उच्च धोका)';
      case VarkariHealthRiskLevel.CRITICAL: return 'CRITICAL (अति-उच्च धोका)';
    }
  }
}

/// Preventive heat & dehydration risk awareness model.
/// Note: This is an AI-assisted environmental risk awareness tool, NOT a medical diagnosis.
class VarkariHealthRisk {
  final double temperatureCelsius;
  final double humidityPercent;
  final double heatIndex;
  final VarkariHealthRiskLevel heatRiskLevel;
  final VarkariHealthRiskLevel dehydrationRiskLevel;
  final VarkariHealthRiskLevel fatigueRiskLevel;
  final String advisoryMessage;
  final List<String> recommendedActions;
  final DateTime measuredAt;
  final bool isDemo;
  final double? distanceToNearestWaterKm;
  final double? distanceToNearestMedicalKm;

  const VarkariHealthRisk({
    required this.temperatureCelsius,
    required this.humidityPercent,
    required this.heatIndex,
    required this.heatRiskLevel,
    required this.dehydrationRiskLevel,
    required this.fatigueRiskLevel,
    required this.advisoryMessage,
    required this.recommendedActions,
    required this.measuredAt,
    this.isDemo = true,
    this.distanceToNearestWaterKm = 0.6,
    this.distanceToNearestMedicalKm = 1.4,
  });

  bool get isExtremeHeat => temperatureCelsius > 38.0;
  bool get requiresUrgentRest => heatRiskLevel == VarkariHealthRiskLevel.HIGH || heatRiskLevel == VarkariHealthRiskLevel.CRITICAL;

  factory VarkariHealthRisk.fromJson(Map<String, dynamic> json) => VarkariHealthRisk(
        temperatureCelsius: (json['temperature_celsius'] as num?)?.toDouble() ?? 32.0,
        humidityPercent: (json['humidity_percent'] as num?)?.toDouble() ?? 60.0,
        heatIndex: (json['heat_index'] as num?)?.toDouble() ?? 34.0,
        heatRiskLevel: VarkariHealthRiskLevel.values.firstWhere(
          (e) => e.name == (json['heat_risk_level'] as String? ?? 'NORMAL'),
          orElse: () => VarkariHealthRiskLevel.NORMAL,
        ),
        dehydrationRiskLevel: VarkariHealthRiskLevel.values.firstWhere(
          (e) => e.name == (json['dehydration_risk_level'] as String? ?? 'NORMAL'),
          orElse: () => VarkariHealthRiskLevel.NORMAL,
        ),
        fatigueRiskLevel: VarkariHealthRiskLevel.values.firstWhere(
          (e) => e.name == (json['fatigue_risk_level'] as String? ?? 'NORMAL'),
          orElse: () => VarkariHealthRiskLevel.NORMAL,
        ),
        advisoryMessage: json['advisory_message'] as String? ?? 'Conditions are comfortable.',
        recommendedActions: (json['recommended_actions'] as List?)?.map((e) => e.toString()).toList() ?? ['Drink water regularly'],
        measuredAt: DateTime.tryParse(json['measured_at'] as String? ?? '') ?? DateTime.now(),
        isDemo: json['is_demo'] as bool? ?? true,
      );

  Map<String, dynamic> toJson() => {
        'temperature_celsius': temperatureCelsius,
        'humidity_percent': humidityPercent,
        'heat_index': heatIndex,
        'heat_risk_level': heatRiskLevel.name,
        'dehydration_risk_level': dehydrationRiskLevel.name,
        'fatigue_risk_level': fatigueRiskLevel.name,
        'advisory_message': advisoryMessage,
        'recommended_actions': recommendedActions,
        'measured_at': measuredAt.toIso8601String(),
        'is_demo': isDemo,
      };
}
