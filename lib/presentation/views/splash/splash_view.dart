import 'package:flutter/material.dart';
import '../../../app.dart';

class SplashView extends StatefulWidget {
  const SplashView({super.key});

  @override
  State<SplashView> createState() => _SplashViewState();
}

class _SplashViewState extends State<SplashView>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();

    // 페이드 인 애니메이션 설정
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );

    // 애니메이션 시작
    _animationController.forward();

    // 2초 후 홈화면으로 이동
    _navigateAfterDelay();
  }

  void _navigateAfterDelay() async {
    await Future.delayed(const Duration(seconds: 2));
    if (mounted) {
      _navigateToMainApp();
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _navigateToMainApp() {
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (context) => const MirugangApp()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).brightness == Brightness.dark
          ? const Color(0xFF000000)
          : const Color(0xFFFFFFFF),
      body: Center(
        child: FadeTransition(
          opacity: _fadeAnimation,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Image.asset(
                'assets/images/cropped_miru_lazy.png',
                width: MediaQuery.of(context).size.width * 0.50,
              ),
              const SizedBox(height: 20),
              Text(
                '미루장',
                style: TextStyle(
                  fontFamily: 'memomentKukkuk',
                  fontSize: 48,
                  fontWeight: FontWeight.w400,
                  color: const Color(0xFFF4B41F), // 테마 상관없이 고정 색상
                ),
              ),
              const SizedBox(height: 1),
              Text(
                '갓생을 위한 나만의 미루기 메모장',
                style: TextStyle(
                  fontFamily: 'memomentKukkuk',
                  fontSize: 24,
                  fontWeight: FontWeight.w400,
                  color: Theme.of(context).brightness == Brightness.dark
                      ? Colors.white
                      : Colors.black,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
