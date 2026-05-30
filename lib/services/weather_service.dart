import '../dummy_data/dummy_data.dart';
import '../models/weather_info.dart';

class WeatherService {
  Future<WeatherInfo> getCurrentWeather() async {
    return DummyData.weather;
  }
}
