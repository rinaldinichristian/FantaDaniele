import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;

class WeatherData {
  final double temperature;
  final int weatherCode;

  WeatherData({required this.temperature, required this.weatherCode});

  String get description {
    // WMO Weather interpretation codes
    if (weatherCode == 0) return 'Soleggiato';
    if (weatherCode == 1 || weatherCode == 2 || weatherCode == 3) return 'Parz. Nuvoloso';
    if (weatherCode == 45 || weatherCode == 48) return 'Nebbia';
    if (weatherCode >= 51 && weatherCode <= 67) return 'Pioggia';
    if (weatherCode >= 71 && weatherCode <= 77) return 'Neve';
    if (weatherCode >= 80 && weatherCode <= 82) return 'Acquazzoni';
    if (weatherCode >= 95) return 'Temporale';
    return 'Nuvoloso';
  }
}

final weatherProvider = FutureProvider<WeatherData>((ref) async {
  // Coordinate per Brescia
  final url = Uri.parse('https://api.open-meteo.com/v1/forecast?latitude=45.5416&longitude=10.2166&current_weather=true');
  final response = await http.get(url);

  if (response.statusCode == 200) {
    final data = json.decode(response.body);
    final current = data['current_weather'];
    return WeatherData(
      temperature: current['temperature'],
      weatherCode: current['weathercode'],
    );
  } else {
    throw Exception('Failed to load weather');
  }
});
