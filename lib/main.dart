import 'package:flutter/material.dart';

void main() {
  runApp(const MirugangApp());
}

class MirugangApp extends StatelessWidget {
  const MirugangApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: '미루장',
      theme: ThemeData(
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
      home: const HomeScreen(),
    );
  }
}

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    final imageHeight = screenHeight / 3;

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            // 상단 이미지 영역 (화면 높이의 1/3, 너비 full)
            Container(
              height: imageHeight,
              width: double.infinity,
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: Theme.of(context).brightness == Brightness.dark
                    ? null // 다크모드에서는 그라데이션 사용
                    : Colors.white, // 라이트모드에서는 하얀색 배경
                gradient: Theme.of(context).brightness == Brightness.dark
                    ? const LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          Color(0xFF2C2C2E), // 상단 (약간 밝음)
                          Color(0xFF1C1C1E), // 하단 (기본 배경)
                        ],
                      )
                    : null,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: Theme.of(context).brightness == Brightness.dark
                      ? const Color(0xFF3A3A3C).withOpacity(0.3)
                      : const Color(0xFFE0E0E0).withOpacity(0.8),
                  width: 0.5,
                ),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.asset(
                  'assets/images/miru_lazy.png',
                  fit: BoxFit.contain,
                  errorBuilder: (context, error, stackTrace) {
                    return Container(
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.surface,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        Icons.image_not_supported,
                        size: 50,
                        color: Theme.of(
                          context,
                        ).colorScheme.onSurface.withOpacity(0.5),
                      ),
                    );
                  },
                ),
              ),
            ),
            // 나머지 콘텐츠 영역
            Expanded(
              child: const Center(
                child: Text('홈화면', style: TextStyle(fontSize: 24)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
