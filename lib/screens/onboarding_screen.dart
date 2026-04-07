import 'package:flutter/material.dart';
import 'package:introduction_screen/introduction_screen.dart';
import 'home_screen.dart';

class OnboardingScreen extends StatelessWidget {
  const OnboardingScreen({super.key});

  void _onIntroEnd(context) {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (_) => const HomeScreen(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {

    return IntroductionScreen(

      globalBackgroundColor: Colors.white,

      pages: [

        // PAGE 1
        PageViewModel(
          title: "Welcome to DrishtiFasal",
          body:
              "A decision support system for crop disease detection and pest risk management.",
          image: const Icon(
            Icons.eco,
            size: 120,
            color: Colors.green,
          ),
        ),

        // PAGE 2
        PageViewModel(
          title: "Smart Crop Analysis",
          body:
              // "Analyze crops using image-based detection, weather-based prediction, or hybrid AI analysis.",
              "Analyze crops using image-based detection or hybrid AI analysis.",
          image: const Icon(
            Icons.camera_alt,
            size: 120,
            color: Colors.green,
          ),
        ),

        // PAGE 3
        PageViewModel(
          title: "Instant Results",
          body:
              "Get disease prediction, confidence score, and recommended treatment for better crop management.",
          image: const Icon(
            Icons.analytics,
            size: 120,
            color: Colors.green,
          ),
        ),
      ],

      onDone: () => _onIntroEnd(context),

      showSkipButton: true,
      skip: const Text("Skip"),

      next: const Icon(Icons.arrow_forward),

      done: const Text(
        "Start",
        style: TextStyle(fontWeight: FontWeight.bold),
      ),

      dotsDecorator: const DotsDecorator(
        activeColor: Colors.green,
      ),
    );
  }
}