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
        brightness: Brightness.dark,
        scaffoldBackgroundColor: const Color(0xFF121212),
        colorSchemeSeed: Colors.blue,
      ),
      home: const ProfessionalIntroScreen(),
    );
  }
}