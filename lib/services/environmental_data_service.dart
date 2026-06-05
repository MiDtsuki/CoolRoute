import '../dummy_data/dummy_data.dart';
import '../models/environmental_layer.dart';
import '../models/weather_info.dart';
import 'weather_service.dart';

class EnvironmentalDataSnapshot {
  const EnvironmentalDataSnapshot({
    required this.layers,
    required this.weather,
  });

  final List<EnvironmentalLayer> layers;
  final WeatherInfo weather;
}

/// Surfaces the six environmental layers plus the current weather reading
/// behind a single call. NASA GIBS imagery is fetched in the UI layer (see
/// [NasaGibsService] + [CachedNetworkImage]); this service owns the *values*
/// shown on the info panel and merges the WeatherAPI signal into the UV and
/// Heat Index rows so they read live rather than stale.
class EnvironmentalDataService {
  EnvironmentalDataService({WeatherService? weatherService})
      : _weatherService = weatherService ?? WeatherService();

  final WeatherService _weatherService;

  Future<EnvironmentalDataSnapshot> load() async {
    final weather = await _weatherService.getCurrentWeather();
    final layers = _mergeWeather(DummyData.layers, weather);
    return EnvironmentalDataSnapshot(layers: layers, weather: weather);
  }

  static List<EnvironmentalLayer> _mergeWeather(
      List<EnvironmentalLayer> base, WeatherInfo weather) {
    return base.map((layer) {
      switch (layer.name) {
        case 'UV / Ozone Layer':
          return layer.copyWith(
            status: _uvStatus(weather.uvIndex),
            value: weather.uvIndex,
          );
        case 'Weather Heat Index':
          return layer.copyWith(
            status: _heatStatus(weather.feelsLikeC),
            value: '${weather.feelsLikeC} C',
          );
        default:
          return layer;
      }
    }).toList(growable: false);
  }

  static String _uvStatus(String uv) {
    switch (uv) {
      case 'Low':
        return 'Safe — full sun OK';
      case 'Moderate':
        return 'Mild caution outdoors';
      case 'High':
        return 'Cover up midday';
      case 'Very High':
        return 'Limit direct exposure';
      case 'Extreme':
        return 'Avoid direct exposure';
      default:
        return 'Avoid direct exposure';
    }
  }

  static String _heatStatus(int feelsLikeC) {
    if (feelsLikeC >= 41) return 'Hydration breaks advised';
    if (feelsLikeC >= 33) return 'Heat caution outdoors';
    if (feelsLikeC >= 27) return 'Comfortable with breaks';
    return 'Cool — no heat risk';
  }
}
