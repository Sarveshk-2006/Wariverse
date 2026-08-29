import '../models/models_exports.dart';

/// Pure calculation engine for preventive Varkari heat, dehydration, and fatigue risk awareness.
class HealthRiskEngine {
  /// Evaluates risk levels from weather metrics and optional movement context.
  static VarkariHealthRisk calculateRisk({
    required WeatherInfo weather,
    DindiLocationUpdate? movement,
    bool isDemo = true,
  }) {
    final temp = weather.temperatureC;
    final humidity = weather.humidityPct.toDouble();
    final heatIndex = weather.feelsLikeC;

    // 1. Heat Risk Level Calculation
    VarkariHealthRiskLevel heatRisk = VarkariHealthRiskLevel.NORMAL;
    if (temp >= 40.0 || heatIndex >= 42.0) {
      heatRisk = VarkariHealthRiskLevel.CRITICAL;
    } else if (temp > 38.0 || heatIndex >= 37.0) {
      heatRisk = VarkariHealthRiskLevel.HIGH;
    } else if (temp >= 33.0 || heatIndex >= 34.0) {
      heatRisk = VarkariHealthRiskLevel.MODERATE;
    }

    // 2. Dehydration Risk Level Calculation
    VarkariHealthRiskLevel dehydrationRisk = VarkariHealthRiskLevel.NORMAL;
    if (heatIndex >= 36.0 && humidity >= 65.0) {
      dehydrationRisk = VarkariHealthRiskLevel.HIGH;
    } else if (temp >= 32.0 || humidity >= 55.0) {
      dehydrationRisk = VarkariHealthRiskLevel.MODERATE;
    }

    // 3. Fatigue Risk Level (Derived strictly from movement context if available)
    VarkariHealthRiskLevel fatigueRisk = VarkariHealthRiskLevel.NORMAL;
    if (movement != null) {
      if (movement.status == DindiMovementStatus.MOVING && movement.speedKmh >= 4.0) {
        fatigueRisk = heatRisk == VarkariHealthRiskLevel.HIGH
            ? VarkariHealthRiskLevel.HIGH
            : VarkariHealthRiskLevel.MODERATE;
      } else if (movement.status == DindiMovementStatus.AT_HALT) {
        fatigueRisk = VarkariHealthRiskLevel.NORMAL;
      }
    }

    // 4. Advisory Message Construction
    String advisory;
    List<String> actions = [];

    if (temp > 38.0) {
      advisory = 'Extreme heat (>38°C) detected along the Wari route. Take immediate shade, rest, and hydrate frequently.';
      actions = [
        'Drink water at the nearest Seva Pandal (पाणी प्या)',
        'Seek shaded shelter or resting camp (विश्रांती घ्या)',
        'Seek medical assistance if feeling dizzy (वैद्यकीय मदत घ्या)',
      ];
    } else if (heatRisk == VarkariHealthRiskLevel.HIGH || heatRisk == VarkariHealthRiskLevel.CRITICAL) {
      advisory = 'High heat conditions detected. Reduce walking pace, wear a cap/towel, and drink water regularly.';
      actions = [
        'Hydrate every 20 minutes',
        'Rest at the next scheduled Dindi halt',
      ];
    } else if (heatRisk == VarkariHealthRiskLevel.MODERATE) {
      advisory = 'Elevated temperatures along the procession route. Stay hydrated and rest as needed.';
      actions = [
        'Keep a water bottle filled',
        'Take regular short breaks',
      ];
    } else {
      advisory = 'Weather conditions are comfortable for marching. Continue your devotional journey safely.';
      actions = [
        'Maintain steady hydration',
      ];
    }

    return VarkariHealthRisk(
      temperatureCelsius: temp,
      humidityPercent: humidity,
      heatIndex: heatIndex,
      heatRiskLevel: heatRisk,
      dehydrationRiskLevel: dehydrationRisk,
      fatigueRiskLevel: fatigueRisk,
      advisoryMessage: advisory,
      recommendedActions: actions,
      measuredAt: DateTime.now(),
      isDemo: isDemo,
    );
  }
}
