import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;

import '../dummy_data/dummy_data.dart';
import '../models/weather_info.dart';

class WeatherService {
  WeatherService({http.Client? client}) : _client = client ?? http.Client();

  final http.Client _client;

  static const _bangkokLat = 13.7563;
  static const _bangkokLon = 100.5018;
  static const _timeout = Duration(seconds: 6);

  Future<WeatherInfo> getCurrentWeather({
    double latitude = _bangkokLat,
    double longitude = _bangkokLon,
  }) async {
    final key = _apiKey();
    if (key == null) {
      return DummyData.weather;
    }

    final uri = Uri.https('api.weatherapi.com', '/v1/current.json', {
      'key': key,
      'q': '$latitude,$longitude',
      'aqi': 'no',
    });

    try {
      final response = await _client.get(uri).timeout(_timeout);
      if (response.statusCode != 200) {
        debugPrint('WeatherService: HTTP ${response.statusCode} — falling back to dummy');
        return DummyData.weather;
      }
      final body = jsonDecode(response.body) as Map<String, dynamic>;
      return _parse(body);
    } catch (e) {
      debugPrint('WeatherService: $e — falling back to dummy');
      return DummyData.weather;
    }
  }

  static String? _apiKey() {
    if (!dotenv.isInitialized) return null;
    final raw = dotenv.maybeGet('WEATHER_API_KEY')?.trim();
    if (raw == null || raw.isEmpty) return null;
    return raw;
  }

  static WeatherInfo _parse(Map<String, dynamic> body) {
    final location = body['location'] as Map<String, dynamic>?;
    final current = body['current'] as Map<String, dynamic>?;
    if (current == null) return DummyData.weather;

    final name = (location?['name'] as String?) ?? 'Unknown';
    final country = (location?['country'] as String?) ?? '';
    final condition = (current['condition'] as Map<String, dynamic>?)?['text'] as String?;

    return WeatherInfo(
      location: country.isEmpty ? name : '$name, $country',
      temperatureC: _toInt(current['temp_c']) ?? DummyData.weather.temperatureC,
      feelsLikeC: _toInt(current['feelslike_c']) ?? DummyData.weather.feelsLikeC,
      humidity: _toInt(current['humidity']) ?? DummyData.weather.humidity,
      uvIndex: _uvLabel(_toDouble(current['uv'])),
      condition: condition ?? DummyData.weather.condition,
    );
  }

  static int? _toInt(Object? v) {
    if (v is num) return v.round();
    if (v is String) return int.tryParse(v) ?? double.tryParse(v)?.round();
    return null;
  }

  static double? _toDouble(Object? v) {
    if (v is num) return v.toDouble();
    if (v is String) return double.tryParse(v);
    return null;
  }

  static String _uvLabel(double? uv) {
    if (uv == null) return DummyData.weather.uvIndex;
    if (uv < 3) return 'Low';
    if (uv < 6) return 'Moderate';
    if (uv < 8) return 'High';
    if (uv < 11) return 'Very High';
    return 'Extreme';
  }
}
