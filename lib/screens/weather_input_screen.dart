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

  final List<String> cropStages = [
    "Flowering",
    "Fruiting",
    "Maturity",
    "Seedling",
    "Vegetative"
  ];

  String? selectedStage;

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
        rainfall.text.isEmpty ||
        selectedStage == null) {

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please complete all inputs")),
      );
      return;
    }

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => LoadingScreen(
          temperature: double.parse(temperature.text),
          humidity: double.parse(humidity.text),
          rainfall: double.parse(rainfall.text),
          cropStage: selectedStage!,
        ),
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
          contentPadding: const EdgeInsets.symmetric(vertical: 16),
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

                  /// 🔥 WARNING BOX
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.orange.shade100,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Text(
                      "⚠️ Predictions using only weather data may be less accurate.\n"
                      "For best results, use Image + Weather mode.",
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 14),
                    ),
                  ),

                  const SizedBox(height: 20),

                  weatherField(Icons.thermostat, "Temperature (°C)", temperature),
                  weatherField(Icons.water_drop, "Humidity (%)", humidity),
                  weatherField(Icons.cloud, "Rainfall (mm)", rainfall),

                  Padding(
                    padding: const EdgeInsets.only(bottom: 18),
                    child: DropdownButtonFormField<String>(
                      value: selectedStage,
                      isExpanded: true,
                      style: const TextStyle(
                        fontSize: 16,
                        color: Colors.black,
                      ),
                      decoration: InputDecoration(
                        prefixIcon: const Icon(Icons.eco, color: Colors.green),
                        labelText: "Crop Stage",
                        contentPadding: const EdgeInsets.symmetric(vertical: 16),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      items: cropStages.map((stage) {
                        return DropdownMenuItem(
                          value: stage,
                          child: Text(stage),
                        );
                      }).toList(),
                      onChanged: (value) {
                        setState(() {
                          selectedStage = value;
                        });
                      },
                    ),
                  ),

                  const SizedBox(height: 10),

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
                      child: const Text("Predict Disease"),
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}