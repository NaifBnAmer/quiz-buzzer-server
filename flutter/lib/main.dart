// ============================================================
//  main.dart — نقطة دخول التطبيق
// ============================================================

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'providers/game_provider.dart';
import 'screens/home_screen.dart';

void main() {
  runApp(
    ChangeNotifierProvider(
      create: (_) => GameProvider(),
      child: const QuizBuzzerApp(),
    ),
  );
}

class QuizBuzzerApp extends StatelessWidget {
  const QuizBuzzerApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'جرس المسابقة',
      debugShowCheckedModeBanner: false,
      theme: ThemeData.dark().copyWith(
        colorScheme: const ColorScheme.dark(
          primary  : Color(0xFFE94560),
          secondary: Color(0xFF0F3460),
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFF16213E),
        ),
      ),
      home: const HomeScreen(),
    );
  }
}
