import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'presentation/views/main/main_navigation.dart';
import 'services/theme_service.dart';

class MirugangApp extends StatefulWidget {
  const MirugangApp({super.key});

  @override
  State<MirugangApp> createState() => _MirugangAppState();
}

class _MirugangAppState extends State<MirugangApp> with WidgetsBindingObserver {
  final ThemeService _themeService = ThemeService();

  @override
  void initState() {
    super.initState();
    _themeService.loadThemeMode();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);

    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.detached) {
      // 앱이 백그라운드로 가거나 종료될 때 시간 기록
      _recordAppCloseTime();
    }
  }

  _recordAppCloseTime() async {
    final prefs = await SharedPreferences.getInstance();
    final currentTime = DateTime.now().millisecondsSinceEpoch;
    await prefs.setInt('last_app_close_time', currentTime);
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _themeService,
      builder: (context, child) {
        return MaterialApp(
          debugShowCheckedModeBanner: false,
          title: '미루장',
          locale: const Locale('ko', 'KR'),
          localizationsDelegates: const [
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          supportedLocales: const [Locale('ko', 'KR'), Locale('en', 'US')],
          theme: _themeService.lightTheme.copyWith(
            textTheme: _themeService.lightTheme.textTheme.apply(
              fontFamily: 'Pretendard',
            ),
            colorScheme: const ColorScheme.light(
              primary: Color(0xFF1976D2), // Material Blue
              secondary: Color(0xFF1976D2),
              surface: Color(0xFFF0F4F8), // 파란 계열의 회색 배경
              onPrimary: Colors.white,
              onSecondary: Colors.white,
              onSurface: Color(0xFF212121), // 진한 회색 텍스트
            ),
          ),
          darkTheme: _themeService.darkTheme.copyWith(
            textTheme: _themeService.darkTheme.textTheme.apply(
              fontFamily: 'Pretendard',
            ),
            colorScheme: const ColorScheme.dark(
              primary: Color(0xFF90CAF9), // 밝은 파란색
              secondary: Color(0xFF90CAF9),
              surface: Color(0xFF121212), // 진한 회색 배경
              onPrimary: Color(0xFF121212),
              onSecondary: Color(0xFF121212),
              onSurface: Color(0xFFE0E0E0), // 밝은 회색 텍스트
            ),
          ),
          themeMode: _themeService.themeMode,
          home: const MainNavigation(),
        );
      },
    );
  }
}
