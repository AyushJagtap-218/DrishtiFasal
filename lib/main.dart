import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:drishti_fasal/screens/onboarding_screen.dart';

Future<void> main() async {
  await dotenv.load(fileName: ".env"); 
  runApp(const DrishtiFasalApp());
}

class DrishtiFasalApp extends StatelessWidget {
  const DrishtiFasalApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: OnboardingScreen(),
    );
  }
}