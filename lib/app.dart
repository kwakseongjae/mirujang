import 'package:flutter/material.dart';
import 'presentation/views/home/home_view.dart';

class MirugangApp extends StatelessWidget {
  const MirugangApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: '미루장',
      theme: ThemeData(
        fontFamily: 'Pretendard',
        colorScheme: const ColorScheme.light(
          primary: Color(0xFF1976D2), // Material Blue
          secondary: Color(0xFF1976D2),
          surface: Color(0xFFF0F4F8), // 파란 계열의 회색 배경
          onPrimary: Colors.white,
          onSecondary: Colors.white,
          onSurface: Color(0xFF212121), // 진한 회색 텍스트
        ),
        useMaterial3: true,
      ),
      darkTheme: ThemeData(
        fontFamily: 'Pretendard',
        colorScheme: const ColorScheme.dark(
          primary: Color(0xFF90CAF9), // 밝은 파란색
          secondary: Color(0xFF90CAF9),
          surface: Color(0xFF121212), // 진한 회색 배경
          onPrimary: Color(0xFF121212),
          onSecondary: Color(0xFF121212),
          onSurface: Color(0xFFE0E0E0), // 밝은 회색 텍스트
        ),
        useMaterial3: true,
      ),
      themeMode: ThemeMode.system, // 시스템 설정을 따라감
      home: const HomeView(),
    );
  }
}
