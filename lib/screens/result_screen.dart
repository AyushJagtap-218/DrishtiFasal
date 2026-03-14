import 'package:flutter/material.dart';
import 'dart:io';

class ResultScreen extends StatelessWidget {

  final File? image;

  const ResultScreen({super.key, this.image});

  @override
  Widget build(BuildContext context) {

    // Dummy result (will be replaced with AI output later)
    String disease = "Leaf Blight";
    String confidence = "92%";
    String treatment = "Apply recommended fungicide and remove infected leaves.";

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

              // Show image ONLY if available
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

              const Text(
                "Detected Disease",
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
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

              const Text(
                "Confidence",
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),

              const SizedBox(height: 8),

              Card(
                child: Padding(
                  padding: const EdgeInsets.all(15),
                  child: Text(
                    confidence,
                    style: const TextStyle(fontSize: 16),
                  ),
                ),
              ),

              const SizedBox(height: 20),

              const Text(
                "Recommended Treatment",
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),

              const SizedBox(height: 8),

              Card(
                child: Padding(
                  padding: const EdgeInsets.all(15),
                  child: Text(
                    treatment,
                    style: const TextStyle(fontSize: 16),
                  ),
                ),
              ),

              const SizedBox(height: 40),

              SizedBox(
                width: double.infinity,
                height: 50,

                child: ElevatedButton(
                  onPressed: () {
                    // Navigator.pop(context);
                    Navigator.of(context).popUntil((route) => route.isFirst);
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