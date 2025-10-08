import 'package:flutter/material.dart';
import '../../../app.dart';
import '../../../services/first_run_service.dart';
import '../../../services/notification_service.dart';

class GuideView extends StatefulWidget {
  final bool isFromSettings;

  const GuideView({super.key, this.isFromSettings = false});

  @override
  State<GuideView> createState() => _GuideViewState();
}

class _GuideViewState extends State<GuideView> with TickerProviderStateMixin {
  late PageController _pageController;
  late AnimationController _buttonAnimationController;
  late Animation<double> _buttonAnimation;
  int _currentPage = 0;
  final NotificationService _notificationService = NotificationService();

  final List<String> _guideImages = [
    'assets/images/guide/miru_guide_1.png',
    'assets/images/guide/miru_guide_2.png',
    'assets/images/guide/miru_guide_3.png',
    'assets/images/guide/miru_guide_4.png',
  ];

  @override
  void initState() {
    super.initState();
    _pageController = PageController();

    // 시작하기 버튼 애니메이션 설정
    _buttonAnimationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _buttonAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _buttonAnimationController,
        curve: Curves.easeOutBack,
      ),
    );
  }

  @override
  void dispose() {
    _pageController.dispose();
    _buttonAnimationController.dispose();
    super.dispose();
  }

  void _onPageChanged(int page) {
    setState(() {
      _currentPage = page;
    });

    // 마지막 페이지(4번째)에서 시작하기 버튼 애니메이션 시작
    if (page == _guideImages.length - 1) {
      _buttonAnimationController.forward();
    } else {
      _buttonAnimationController.reset();
    }
  }

  Future<void> _handleStartApp() async {
    if (widget.isFromSettings) {
      // 설정에서 호출된 경우: 그냥 닫기
      if (mounted) {
        Navigator.of(context).pop();
      }
    } else {
      // 최초 실행인 경우: 기존 로직
      // 알림 권한 요청
      await _requestNotificationPermission();

      // 최초 실행 완료 표시
      await FirstRunService.setFirstRunCompleted();

      // 홈 화면으로 이동
      if (mounted) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (context) => const MirujangApp()),
        );
      }
    }
  }

  Future<void> _requestNotificationPermission() async {
    try {
      // 알림 권한 요청
      await _notificationService.requestPermissions();

      // 시스템 설정과 동기화
      await _notificationService.syncWithSystemSettings();

      // 사용자에게 알림 권한 요청 완료 안내
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('알림 권한이 설정되었습니다. 미루기 알림을 받을 수 있어요! 🔔'),
            duration: Duration(seconds: 3),
            backgroundColor: Color(0xFF4CAF50),
          ),
        );
      }
    } catch (e) {
      // 권한 요청 실패 시에도 앱은 정상 진행
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('알림 권한 설정에 실패했습니다. 나중에 설정에서 다시 시도해주세요.'),
            duration: Duration(seconds: 3),
            backgroundColor: Color(0xFFFF9800),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            // 가이드 이미지 영역
            Expanded(
              child: PageView.builder(
                controller: _pageController,
                onPageChanged: _onPageChanged,
                itemCount: _guideImages.length,
                itemBuilder: (context, index) {
                  return Center(
                    child: Container(
                      margin: const EdgeInsets.symmetric(horizontal: 20),
                      child: Image.asset(
                        _guideImages[index],
                        fit: BoxFit.contain,
                        width: double.infinity,
                      ),
                    ),
                  );
                },
              ),
            ),

            // 하단 인디케이터 및 시작하기 버튼 영역
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
              child: Column(
                children: [
                  // 페이지 인디케이터
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(
                      _guideImages.length,
                      (index) => Container(
                        margin: const EdgeInsets.symmetric(horizontal: 4),
                        width: 8,
                        height: 8,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: _currentPage == index
                              ? const Color(0xFFF4B41F)
                              : const Color(0xFFE5E5E5),
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 32),

                  // 시작하기 버튼 (마지막 페이지에서만 표시)
                  if (_currentPage == _guideImages.length - 1)
                    AnimatedBuilder(
                      animation: _buttonAnimation,
                      builder: (context, child) {
                        return Transform.scale(
                          scale: _buttonAnimation.value.clamp(0.0, 1.0),
                          child: Opacity(
                            opacity: _buttonAnimation.value.clamp(0.0, 1.0),
                            child: SizedBox(
                              width: double.infinity,
                              height: 56,
                              child: ElevatedButton(
                                onPressed: _handleStartApp,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFFF4B41F),
                                  foregroundColor: Colors.white,
                                  elevation: 0,
                                  shadowColor: Colors.transparent,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                ),
                                child: Text(
                                  widget.isFromSettings ? '완료' : '시작하기',
                                  style: const TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.w600,
                                    fontFamily: 'Pretendard',
                                  ),
                                ),
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
