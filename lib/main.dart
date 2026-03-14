import 'package:flutter/material.dart';
import 'screens/onboarding_screen.dart';

void main() {
  runApp(const DrishtiFasalApp());
}

class DrishtiFasalApp extends StatelessWidget {
  const DrishtiFasalApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'DrishtiFasal',
      theme: ThemeData(
        primarySwatch: Colors.green,
      ),
      home: const OnboardingScreen(),
    );
  }
}