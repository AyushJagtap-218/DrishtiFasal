import 'package:flutter/material.dart';
import 'loading_screen.dart';
import '../services/location_service.dart';
import '../services/weather_service.dart';

class WeatherInputScreen extends StatefulWidget {
  const WeatherInputScreen({super.key});

  @override
  State<WeatherInputScreen> createState() => _WeatherInputScreenState();
}

class _WeatherInputScreenState extends State<WeatherInputScreen> {

  final TextEditingController temperature = TextEditingController();
  final TextEditingController humidity = TextEditingController();
  final TextEditingController rainfall = TextEditingController();

  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    fetchWeather();
  }

  Future<void> fetchWeather() async {
    try {
      final locationService = LocationService();
      final weatherService = WeatherService();

      final position = await locationService.getLocation();

      final data = await weatherService.fetchWeather(
        position.latitude,
        position.longitude,
      );

      temperature.text = data['main']['temp'].toString();
      humidity.text = data['main']['humidity'].toString();

      rainfall.text = data['rain'] != null
          ? (data['rain']['1h'] ?? 0.0).toString()
          : "0.0";

    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error fetching weather: $e")),
      );
    }

    setState(() {
      isLoading = false;
    });
  }

  void predictDisease() {
    if (temperature.text.isEmpty ||
        humidity.text.isEmpty ||
        rainfall.text.isEmpty) {

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please enter all weather details")),
      );
      return;
    }

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => const LoadingScreen(),
      ),
    );
  }

  Widget weatherField(
      IconData icon,
      String label,
      TextEditingController controller) {

    return Padding(
      padding: const EdgeInsets.only(bottom: 18),
      child: TextField(
        controller: controller,
        keyboardType: TextInputType.number,
        decoration: InputDecoration(
          prefixIcon: Icon(icon, color: Colors.green),
          labelText: label,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {

    return Scaffold(
      appBar: AppBar(
        title: const Text("Weather Based Prediction"),
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [

                  weatherField(
                    Icons.thermostat,
                    "Temperature (°C)",
                    temperature,
                  ),

                  weatherField(
                    Icons.water_drop,
                    "Humidity (%)",
                    humidity,
                  ),

                  weatherField(
                    Icons.cloud,
                    "Rainfall (mm)",
                    rainfall,
                  ),

                  const SizedBox(height: 30),

                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      onPressed: predictDisease,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text(
                        "Predict Disease",
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}