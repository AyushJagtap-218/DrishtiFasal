import 'package:flutter/material.dart';
import 'dart:io';
import '../services/model_service.dart';
import 'result_screen.dart';

class LoadingScreen extends StatefulWidget {

  final File? image;
  final double? temperature;
  final double? humidity;
  final double? rainfall;

  // ✅ UPDATED: cropStage as STRING
  final String? cropStage;

  const LoadingScreen({
    super.key,
    this.image,
    this.temperature,
    this.humidity,
    this.rainfall,
    this.cropStage,
  });

  @override
  State<LoadingScreen> createState() => _LoadingScreenState();
}

class _LoadingScreenState extends State<LoadingScreen>
    with SingleTickerProviderStateMixin {

  late AnimationController _controller;
  late Animation<double> _animation;

  String message = "Loading AI Model...";

  final ModelService modelService = ModelService();

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);

    _animation = Tween<double>(begin: 0.9, end: 1.2).animate(_controller);

    runModel();
  }

  Future<void> runModel() async {
    try {
      setState(() => message = "Initializing Model...");
      await modelService.loadModel();

      setState(() => message = "Processing Data...");

      final result = modelService.predict(
        image: widget.image,
        temperature: widget.temperature,
        humidity: widget.humidity,
        rainfall: widget.rainfall,
        cropStage: widget.cropStage, // ✅ STRING
      );

      setState(() => message = "Finalizing Results...");

      await Future.delayed(const Duration(seconds: 1));

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => ResultScreen(
            image: widget.image,
            result: result,
          ),
        ),
      );

    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error: $e")),
      );

      Navigator.pop(context);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

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
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [

              ScaleTransition(
                scale: _animation,
                child: const Icon(
                  Icons.eco,
                  size: 100,
                  color: Colors.white,
                ),
              ),

              const SizedBox(height: 30),

              const Text(
                "AI Analysis in Progress",
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),

              const SizedBox(height: 25),

              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 40),
                child: Text(
                  message,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 16,
                    color: Colors.white70,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}