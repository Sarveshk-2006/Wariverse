/// Weather info returned from /weather endpoint.
class WeatherInfo {
  final double temperatureC;
  final double feelsLikeC;
  final int humidityPct;
  final double windKmh;
  final String condition;
  final int rainProbabilityPct;
  final List<WeatherAlert> alerts;

  const WeatherInfo({
    required this.temperatureC,
    required this.feelsLikeC,
    required this.humidityPct,
    required this.windKmh,
    required this.condition,
    required this.rainProbabilityPct,
    required this.alerts,
  });

  factory WeatherInfo.fromJson(Map<String, dynamic> json) => WeatherInfo(
        temperatureC: (json['temperature_c'] as num?)?.toDouble() ?? 30.0,
        feelsLikeC: (json['feels_like_c'] as num?)?.toDouble() ?? 32.0,
        humidityPct: json['humidity_pct'] as int? ?? 60,
        windKmh: (json['wind_kmh'] as num?)?.toDouble() ?? 10.0,
        condition: json['condition'] as String? ?? 'Clear',
        rainProbabilityPct: json['rain_probability_pct'] as int? ?? 0,
        alerts: (json['alerts'] as List<dynamic>? ?? [])
            .map((e) => WeatherAlert.fromJson(e as Map<String, dynamic>))
            .toList(),
      );
}

class WeatherAlert {
  final String id;
  final String alertType;
  final String message;

  const WeatherAlert({
    required this.id,
    required this.alertType,
    required this.message,
  });

  factory WeatherAlert.fromJson(Map<String, dynamic> json) => WeatherAlert(
        id: json['id'] as String? ?? '',
        alertType: json['alert_type'] as String? ?? 'INFO',
        message: json['message'] as String? ?? '',
      );
}
