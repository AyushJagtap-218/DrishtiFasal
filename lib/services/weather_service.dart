import 'dart:convert';
import 'package:http/http.dart' as http;

class WeatherService {

  final String apiKey = dotenv.env['OPENWEATHER_API_KEY']!; // Replace this

  Future<Map<String, dynamic>> fetchWeather(double lat, double lon) async {

    final url =
        "https://api.openweathermap.org/data/2.5/weather?lat=$lat&lon=$lon&appid=$apiKey&units=metric";

    final response = await http.get(Uri.parse(url));

    print("STATUS CODE: ${response.statusCode}");
    print("BODY: ${response.body}");

    if (response.statusCode == 200) {
      return json.decode(response.body);
    } else {
      throw Exception("Failed to load weather data");
    }
  }
}