import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'screens/thinq_home_screen.dart';

/// 부드러운 페이드 + 슬라이드 전환 효과
class SmoothPageTransitionsBuilder extends PageTransitionsBuilder {
  const SmoothPageTransitionsBuilder();

  @override
  Widget buildTransitions<T extends Object?>(
    PageRoute<T> route,
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) {
    // 페이드 효과
    final fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(
      CurvedAnimation(
        parent: animation,
        curve: Curves.easeInOut,
      ),
    );

    // 슬라이드 효과 (오른쪽에서 왼쪽으로)
    final slideAnimation = Tween<Offset>(
      begin: const Offset(0.1, 0.0), // 약간만 슬라이드
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: animation,
        curve: Curves.easeOutCubic,
      ),
    );

    return FadeTransition(
      opacity: fadeAnimation,
      child: SlideTransition(
        position: slideAnimation,
        child: child,
      ),
    );
  }
}

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
        // 부드러운 화면 전환 효과 설정
        pageTransitionsTheme: const PageTransitionsTheme(
          builders: {
            TargetPlatform.android: SmoothPageTransitionsBuilder(),
            TargetPlatform.iOS: SmoothPageTransitionsBuilder(),
          },
        ),
      ),
      home: const ThinQHomeScreen(),
    );
  }
}
