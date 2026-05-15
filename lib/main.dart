import 'package:flutter/material.dart';
import 'screens/home_screen.dart';

void main() {
  runApp(const ShootingTrackerApp());
}

class ShootingTrackerApp extends StatelessWidget {
  const ShootingTrackerApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Mitti',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: const Color(0xFF0D1117),
        colorScheme: const ColorScheme.dark(
          primary: Color(0xFF58A6FF),
          secondary: Color(0xFF3FB950),
          surface: Color(0xFF161B22),
          error: Color(0xFFF85149),
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFF161B22),
          foregroundColor: Colors.white,
          elevation: 0,
        ),
        floatingActionButtonTheme: const FloatingActionButtonThemeData(
          backgroundColor: Color(0xFF58A6FF),
          foregroundColor: Colors.black,
        ),
      ),
      home: const HomeScreen(),
    );
  }
}
