import 'package:flutter/material.dart';
import 'image_input_screen.dart';
import 'weather_input_screen.dart';
import 'image_weather_input_screen.dart';
import 'about_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF2E7D32), Color(0xFF66BB6A)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: SafeArea(
          child: Stack(
            children: [

              // INFO ICON
              Positioned(
                right: 10,
                top: 10,
                child: IconButton(
                  icon: const Icon(Icons.info_outline, color: Colors.white),
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const AboutScreen(),
                      ),
                    );
                  },
                ),
              ),

              Column(
                children: [

                  const SizedBox(height: 30),

                  const Icon(
                    Icons.eco,
                    color: Colors.white,
                    size: 60,
                  ),

                  const SizedBox(height: 10),

                  const Text(
                    "DrishtiFasal",
                    style: TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),

                  const SizedBox(height: 5),

                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 20),
                    child: Text(
                      "A Decision Support Approach for Pest\nRisk Management",
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.white70,
                        height: 1.5,
                      ),
                    ),
                  ),

                  const SizedBox(height: 40),

                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.all(20),
                      decoration: const BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.vertical(
                          top: Radius.circular(30),
                        ),
                      ),
                      child: Column(
                        children: [

                          const Text(
                            "Select Prediction Method",
                            style: TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                            ),
                          ),

                          const SizedBox(height: 30),

                          _buildOptionCard(
                            context,
                            icon: Icons.image,
                            title: "Image Only",
                            subtitle: "Detect disease using crop image",
                            screen: const ImageInputScreen(),
                          ),

                          const SizedBox(height: 20),

                          _buildOptionCard(
                            context,
                            icon: Icons.cloud,
                            title: "Weather Only",
                            subtitle: "Predict using weather conditions",
                            screen: const WeatherInputScreen(),
                          ),

                          const SizedBox(height: 20),

                          _buildOptionCard(
                            context,
                            icon: Icons.psychology,
                            title: "Smart Prediction",
                            subtitle: "Image + Weather AI model",
                            screen: const ImageWeatherInputScreen(),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildOptionCard(
      BuildContext context, {
        required IconData icon,
        required String title,
        required String subtitle,
        required Widget screen,
      }) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => screen),
        );
      },
      child: Card(
        elevation: 4,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(15),
        ),
        child: ListTile(
          leading: Icon(icon, size: 35, color: Colors.green),
          title: Text(title,
              style: const TextStyle(fontWeight: FontWeight.bold)),
          subtitle: Text(subtitle),
          trailing: const Icon(Icons.arrow_forward_ios),
        ),
      ),
    );
  }
}