import 'package:flutter/material.dart';
import 'loading_screen.dart';

class WeatherInputScreen extends StatefulWidget {
  const WeatherInputScreen({super.key});

  @override
  State<WeatherInputScreen> createState() => _WeatherInputScreenState();
}

class _WeatherInputScreenState extends State<WeatherInputScreen> {

  final TextEditingController temperature = TextEditingController();
  final TextEditingController humidity = TextEditingController();
  final TextEditingController rainfall = TextEditingController();

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

      body: Padding(
        padding: const EdgeInsets.all(20),

        child: Column(
          children: [

            const SizedBox(height: 10),

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