import 'package:flutter/material.dart';
import 'screens/home_screen.dart';
import 'package:flutter_animate/flutter_animate.dart';

void main() {
  Animate.restartOnHotReload = true; // For development
  runApp(const QIAApp());
}

class QIAApp extends StatelessWidget {
  const QIAApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'QIA Assistant',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.blue,
        brightness: Brightness.dark,  // Dark mode
        useMaterial3: true,
      ),
      home: const HomeScreen(),
    );
  }
} 