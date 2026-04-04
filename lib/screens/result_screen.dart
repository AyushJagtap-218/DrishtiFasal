import 'package:flutter/material.dart';
import 'dart:io';

class ResultScreen extends StatelessWidget {
  final File? image;
  final Map<String, dynamic> result;

  const ResultScreen({
    super.key,
    this.image,
    required this.result,
  });

  String getTreatment(String disease) {
    switch (disease) {
      case "Healthy":
        return "No treatment needed. Maintain good crop practices.";
      case "Powdery_mildew":
        return "Apply sulfur-based fungicide.";
      case "Early_blight":
        return "Use fungicides and remove infected leaves.";
      case "Late_blight":
        return "Apply copper fungicide immediately.";
      case "Bacterial_spot":
        return "Use copper sprays and avoid overhead watering.";
      case "Leaf_Mold":
        return "Improve ventilation and apply fungicide.";
      default:
        return "Consult agricultural expert for treatment.";
    }
  }

  @override
  Widget build(BuildContext context) {
    final disease = result["label"] ?? "Unknown";
    final confidence = result["confidence"] ?? 0;

    // ✅ Only keep crop stage
    final cropStage = result["crop_stage"];

    return Scaffold(
      appBar: AppBar(
        title: const Text("Prediction Result"),
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [

              /// 🌿 IMAGE
              if (image != null)
                Container(
                  height: 200,
                  width: double.infinity,
                  margin: const EdgeInsets.only(bottom: 25),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(15),
                    image: DecorationImage(
                      image: FileImage(image!),
                      fit: BoxFit.cover,
                    ),
                  ),
                ),

              /// 🦠 DISEASE
              const Text(
                "Detected Disease",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),

              Card(
                child: Padding(
                  padding: const EdgeInsets.all(15),
                  child: Text(
                    disease,
                    style: const TextStyle(fontSize: 16),
                  ),
                ),
              ),

              const SizedBox(height: 20),

              /// 📊 CONFIDENCE
              const Text(
                "Confidence",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),

              Card(
                child: Padding(
                  padding: const EdgeInsets.all(15),
                  child: Text(
                    "${confidence.toStringAsFixed(2)}%",
                    style: const TextStyle(fontSize: 16),
                  ),
                ),
              ),

              const SizedBox(height: 20),

              /// 🌱 CROP STAGE
              if (cropStage != null) ...[
                const Text(
                  "Crop Stage",
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),

                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(15),
                    child: Text(
                      cropStage.toString(),
                      style: const TextStyle(fontSize: 16),
                    ),
                  ),
                ),

                const SizedBox(height: 20),
              ],

              /// 💊 TREATMENT
              const Text(
                "Recommended Treatment",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),

              Card(
                child: Padding(
                  padding: const EdgeInsets.all(15),
                  child: Text(
                    getTreatment(disease),
                    style: const TextStyle(fontSize: 16),
                  ),
                ),
              ),

              const SizedBox(height: 40),

              /// 🔙 BUTTON
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.of(context)
                        .popUntil((route) => route.isFirst);
                  },
                  child: const Text("Back to Home"),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}