import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'screens/thinq_home_screen.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    // Set status bar style to match Figma design (Android status bar with gradient)
    // Figma shows gradient: #bdd2e6 -> #dceef6 -> #e8f3f8 -> #edf6f7
    SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
      statusBarColor: Color(0xFFEDF6F7), // Figma gradient end color
      statusBarIconBrightness: Brightness.dark, // Dark icons on light background
      systemNavigationBarColor: Colors.white,
      systemNavigationBarIconBrightness: Brightness.dark,
    ));

    return MaterialApp(
      title: 'Vision App',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        scaffoldBackgroundColor: Colors.white,
        useMaterial3: true,
      ),
      home: const ThinQHomeScreen(),
    );
  }
}
