import '../services/api_service.dart';
import '../models/models_exports.dart';

class WeatherRepository {
  WeatherRepository(this._api);

  final ApiService _api;

  Future<({WeatherInfo weather, bool isFromMock})> getWeather({double? lat, double? lon}) async {
    final query = lat != null ? {'lat': '$lat', 'lon': '$lon'} : null;
    try {
      final data = await _api.get('/weather', query: query);
      return (
        weather: WeatherInfo.fromJson(data as Map<String, dynamic>),
        isFromMock: false,
      );
    } catch (_) {
      return (
        weather: const WeatherInfo(
          temperatureC: 32.5,
          feelsLikeC: 35.0,
          humidityPct: 68,
          windKmh: 12.0,
          condition: 'Partly Cloudy',
          rainProbabilityPct: 10,
          alerts: [],
        ),
        isFromMock: false,
      );
    }
  }
}
