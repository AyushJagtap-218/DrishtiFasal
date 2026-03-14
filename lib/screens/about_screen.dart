import 'package:flutter/material.dart';

class AboutScreen extends StatelessWidget {
  const AboutScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("About DrishtiFasal"),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [

            const Center(
              child: Icon(
                Icons.eco,
                size: 80,
                color: Colors.green,
              ),
            ),

            const SizedBox(height: 10),

            const Center(
              child: Text(
                "DrishtiFasal",
                style: TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),

            const SizedBox(height: 10),

            const Center(
              child: Text(
                "A Decision Support Approach for Pest Risk Management",
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey,
                ),
              ),
            ),

            const SizedBox(height: 30),

            const Text(
              "Key Features",
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 15),

            _featureCard(
              icon: Icons.image,
              title: "Image-Based Detection",
              description:
                  "Upload crop leaf images to detect plant diseases using deep learning models.",
            ),

            const SizedBox(height: 15),

            _featureCard(
              icon: Icons.cloud,
              title: "Weather-Based Prediction",
              description:
                  "Analyze environmental conditions such as temperature and humidity to predict pest risks.",
            ),

            const SizedBox(height: 15),

            _featureCard(
              icon: Icons.psychology,
              title: "Hybrid AI Model",
              description:
                  "Combine both image data and weather features for more accurate disease prediction.",
            ),

            const SizedBox(height: 30),

            const Text(
              "About the Project",
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 10),

            const Text(
              "DrishtiFasal is an AI-powered decision support system designed to assist farmers in early detection of crop diseases and pest risks. By analyzing crop images and environmental factors, the system provides intelligent insights that help farmers take timely preventive measures.",
              style: TextStyle(fontSize: 16, height: 1.5),
            ),

            const SizedBox(height: 30),

            const Divider(),

            const SizedBox(height: 10),

            const Center(
              child: Text(
                "Developed as an academic AI project for smart agriculture.",
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.grey,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _featureCard({
    required IconData icon,
    required String title,
    required String description,
  }) {
    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(15),
      ),
      child: ListTile(
        leading: Icon(icon, color: Colors.green, size: 35),
        title: Text(
          title,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Text(description),
      ),
    );
  }
}