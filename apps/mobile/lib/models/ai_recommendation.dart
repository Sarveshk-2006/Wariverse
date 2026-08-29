/// A single service recommendation returned by AI recommend endpoints.
class AiServiceItem {
  final String name;
  final int distanceM;
  final int walkMinutes;
  final int? estimatedQueueMinutes;
  final String? waterType;
  final double aiScore;

  const AiServiceItem({
    required this.name,
    required this.distanceM,
    required this.walkMinutes,
    this.estimatedQueueMinutes,
    this.waterType,
    required this.aiScore,
  });

  factory AiServiceItem.fromJson(Map<String, dynamic> json) => AiServiceItem(
        name: json['name'] as String? ?? '',
        distanceM: json['distance_m'] as int? ?? 0,
        walkMinutes: json['walk_minutes'] as int? ?? 0,
        estimatedQueueMinutes: json['estimated_queue_minutes'] as int?,
        waterType: json['water_type'] as String?,
        aiScore: (json['ai_score'] as num?)?.toDouble() ?? 0.0,
      );
}

/// AI recommendation response from /ai/recommend-food or /ai/recommend-water.
class AiRecommendation {
  final String explanation;
  final List<AiServiceItem> recommendations;

  const AiRecommendation({
    required this.explanation,
    required this.recommendations,
  });

  factory AiRecommendation.fromJson(Map<String, dynamic> json) =>
      AiRecommendation(
        explanation: json['explanation'] as String? ?? '',
        recommendations: (json['recommendations'] as List<dynamic>? ?? [])
            .map((e) => AiServiceItem.fromJson(e as Map<String, dynamic>))
            .toList(),
      );
}

/// Resource prediction from /resources/prediction endpoint.
class ResourcePrediction {
  final int totalPilgrimsEstimate;
  final ResourceCategory food;
  final ResourceCategory water;
  final ResourceCategory medical;

  const ResourcePrediction({
    required this.totalPilgrimsEstimate,
    required this.food,
    required this.water,
    required this.medical,
  });

  factory ResourcePrediction.fromJson(Map<String, dynamic> json) =>
      ResourcePrediction(
        totalPilgrimsEstimate: json['total_pilgrims_estimate'] as int? ?? 0,
        food: ResourceCategory.fromJson(
            json['food'] as Map<String, dynamic>? ?? {}),
        water: ResourceCategory.fromJson(
            json['water'] as Map<String, dynamic>? ?? {}),
        medical: ResourceCategory.fromJson(
            json['medical'] as Map<String, dynamic>? ?? {}),
      );
}

class ResourceCategory {
  final String shortageRisk;
  final String recommendation;
  final Map<String, dynamic> raw;

  const ResourceCategory({
    required this.shortageRisk,
    required this.recommendation,
    required this.raw,
  });

  factory ResourceCategory.fromJson(Map<String, dynamic> json) =>
      ResourceCategory(
        shortageRisk: json['shortage_risk'] as String? ?? 'LOW',
        recommendation: json['recommendation'] as String? ?? '',
        raw: json,
      );
}
