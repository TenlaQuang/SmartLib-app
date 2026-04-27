import 'package:flutter/material.dart';
import 'presentation/screens/intro_screen.dart'; // Import màn hình vào đây

void main() {
  runApp(const SmartLibApp());
}

class SmartLibApp extends StatelessWidget {
  const SmartLibApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Real 3D SmartLib Book',
      theme: ThemeData(
        brightness: Brightness.light,
        scaffoldBackgroundColor: const Color(0xFFFFF7DD),
        colorSchemeSeed: const Color(0xFF91C4C3),
      ),
      home: const ProfessionalIntroScreen(),
    );
  }
}