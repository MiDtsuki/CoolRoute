class WeatherInfo {
  const WeatherInfo({
    required this.location,
    required this.temperatureC,
    required this.feelsLikeC,
    required this.humidity,
    required this.uvIndex,
    required this.condition,
  });

  final String location;
  final int temperatureC;
  final int feelsLikeC;
  final int humidity;
  final String uvIndex;
  final String condition;
}
