import 'package:flutter/material.dart';
import 'dart:async';
import 'dart:io';
import 'result_screen.dart';

class LoadingScreen extends StatefulWidget {

  final File? image;

  const LoadingScreen({super.key, this.image});

  @override
  State<LoadingScreen> createState() => _LoadingScreenState();
}

class _LoadingScreenState extends State<LoadingScreen>
    with SingleTickerProviderStateMixin {

  late AnimationController _controller;
  late Animation<double> _animation;

  String message = "Analyzing Crop Image...";

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);

    _animation = Tween<double>(begin: 0.9, end: 1.2).animate(_controller);

    _simulateProcessing();
  }

  void _simulateProcessing() {

    Future.delayed(const Duration(seconds: 2), () {
      setState(() {
        message = "Running AI Model...";
      });
    });

    Future.delayed(const Duration(seconds: 4), () {
      setState(() {
        message = "Detecting Disease Patterns...";
      });
    });

    Future.delayed(const Duration(seconds: 6), () {

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => ResultScreen(image: widget.image),
        ),
      );

    });
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