import 'package:flutter/material.dart';
import 'theme_settings_view.dart';
import '../../../services/notification_service.dart';
import '../../../utils/logger.dart';

class SettingsView extends StatefulWidget {
  const SettingsView({super.key});

  @override
  State<SettingsView> createState() => _SettingsViewState();
}

class _SettingsViewState extends State<SettingsView>
    with TickerProviderStateMixin {
  final NotificationService _notificationService = NotificationService();
  late AnimationController _toggleAnimationController;
  bool _isNotificationEnabled = false; // 초기값을 false로 설정
  bool _isUserInteraction = false; // 사용자 상호작용 여부
  bool _isToggleReady = false; // 토글 버튼 준비 완료 여부

  @override
  void initState() {
    super.initState();
    _toggleAnimationController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );

    // 초기 상태 설정
    _loadNotificationState();
  }

  void _loadNotificationState() async {
    // NotificationService의 상태를 비동기로 로드
    await Future.delayed(const Duration(milliseconds: 100)); // 서비스 초기화 대기

    // 저장된 알림 설정 값을 가져와서 토글 버튼 상태 설정
    final actualValue = _notificationService.isNotificationEnabled;
    _isNotificationEnabled = actualValue;
    _toggleAnimationController.value = actualValue ? 1.0 : 0.0;
    // _isUserInteraction은 false로 유지 (사용자가 클릭할 때까지)

    // 토글 버튼 준비 완료 후 UI 업데이트
    _isToggleReady = true;
    setState(() {}); // UI 업데이트
  }

  @override
  void dispose() {
    _toggleAnimationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          '설정',
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // 앱 설정 섹션
          _buildSection(context, '앱 설정', [
            _buildSettingItem(
              context,
              icon: Icons.palette_rounded,
              title: '테마',
              subtitle: '앱의 테마를 변경할 수 있습니다',
              trailing: const Icon(Icons.chevron_right_rounded),
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) => const ThemeSettingsView(),
                  ),
                );
              },
            ),
            _buildSettingItem(
              context,
              icon: Icons.notifications_rounded,
              title: '앱 알림 설정',
              subtitle: '앱 알림을 받을 수 있습니다',
              trailing: _buildCustomToggle(),
            ),
          ]),

          const SizedBox(height: 24),

          // 지원 섹션
          _buildSection(context, '지원', [
            _buildSettingItem(
              context,
              icon: Icons.feedback_rounded,
              title: '의견 보내기',
              subtitle: '앱에 대한 의견을 보내주세요',
              trailing: const Icon(Icons.chevron_right_rounded),
              onTap: () {
                _showFeedbackDialog(context);
              },
            ),
            _buildSettingItem(
              context,
              icon: Icons.help_rounded,
              title: '자주 묻는 질문',
              subtitle: '자주 묻는 질문과 답변을 확인하세요',
              trailing: const Icon(Icons.chevron_right_rounded),
              onTap: () {
                _showFAQDialog(context);
              },
            ),
          ]),
        ],
      ),
    );
  }

  Widget _buildSection(
    BuildContext context,
    String title,
    List<Widget> children,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 8, bottom: 12),
          child: Text(
            title,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Theme.of(context).brightness == Brightness.dark
                  ? Colors.white.withOpacity(0.7)
                  : Colors.black.withOpacity(0.7),
            ),
          ),
        ),
        Container(
          decoration: BoxDecoration(
            color: Theme.of(context).brightness == Brightness.dark
                ? const Color(0xFF2D3748) // 다크모드용 pale slate
                : const Color(0xFFF7FAFC), // 라이트모드용 pale slate
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: Theme.of(context).brightness == Brightness.dark
                  ? Colors.white.withOpacity(0.1)
                  : Colors.black.withOpacity(0.1),
            ),
          ),
          child: Column(children: children),
        ),
      ],
    );
  }

  Widget _buildSettingItem(
    BuildContext context, {
    required IconData icon,
    required String title,
    String? subtitle,
    Widget? trailing,
    VoidCallback? onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: Theme.of(context).primaryColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                icon,
                size: 20,
                color: Theme.of(context).primaryColor,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  if (subtitle != null) ...[
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontSize: 14,
                        color: Theme.of(context).brightness == Brightness.dark
                            ? Colors.white.withOpacity(0.6)
                            : Colors.black.withOpacity(0.6),
                      ),
                    ),
                  ],
                ],
              ),
            ),
            if (trailing != null) ...[const SizedBox(width: 8), trailing],
          ],
        ),
      ),
    );
  }

  // 의견 보내기 다이얼로그
  void _showFeedbackDialog(BuildContext context) {
    final TextEditingController feedbackController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('의견 보내기'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('앱에 대한 의견이나 개선사항을 알려주세요.'),
            const SizedBox(height: 16),
            TextField(
              controller: feedbackController,
              maxLines: 4,
              decoration: const InputDecoration(
                hintText: '의견을 입력해주세요...',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('취소'),
          ),
          TextButton(
            onPressed: () {
              // 의견 전송 로직
              Navigator.of(context).pop();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('의견이 전송되었습니다. 감사합니다!')),
              );
            },
            child: const Text('전송'),
          ),
        ],
      ),
    );
  }

  // 자주 묻는 질문 다이얼로그
  void _showFAQDialog(BuildContext context) {
    final List<Map<String, String>> faqs = [
      {
        'question': '알림이 오지 않아요',
        'answer': '앱 설정에서 알림 권한을 확인해주세요. 또한 기기의 알림 설정도 확인해보세요.',
      },
      {
        'question': '데이터가 사라졌어요',
        'answer': '앱을 삭제하거나 기기를 초기화하면 데이터가 사라집니다. 정기적으로 백업을 권장합니다.',
      },
      {'question': '앱이 느려요', 'answer': '기기를 재시작하거나 앱을 완전히 종료 후 다시 실행해보세요.'},
      {
        'question': '다른 기기에서 사용할 수 있나요?',
        'answer': '현재는 로컬 저장만 지원합니다. 클라우드 동기화는 추후 업데이트 예정입니다.',
      },
    ];

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('자주 묻는 질문'),
        content: SizedBox(
          width: double.maxFinite,
          height: 400,
          child: ListView.builder(
            itemCount: faqs.length,
            itemBuilder: (context, index) {
              final faq = faqs[index];
              return ExpansionTile(
                title: Text(
                  faq['question']!,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                children: [
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Text(
                      faq['answer']!,
                      style: TextStyle(
                        fontSize: 13,
                        color: Theme.of(context).brightness == Brightness.dark
                            ? Colors.white.withOpacity(0.7)
                            : Colors.black.withOpacity(0.7),
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('닫기'),
          ),
        ],
      ),
    );
  }

  Widget _buildCustomToggle() {
    // 토글 버튼이 준비되지 않았으면 빈 컨테이너 반환
    if (!_isToggleReady) {
      return Container(
        width: 50,
        height: 30,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(15),
          color: const Color(0xFFD0D0D0), // 기본 회색 배경
        ),
      );
    }

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: _handleNotificationToggle,
      child: Container(
        width: 50,
        height: 30,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(15),
          color: _isNotificationEnabled
              ? const Color(0xFFF4B41F) // #F4B41F 색상 (켜짐)
              : const Color(0xFFD0D0D0), // 더 어두운 회색 배경 (꺼짐)
        ),
        child: Stack(
          children: [
            // 토글 원 - 사용자 상호작용 시에만 애니메이션 사용
            _isUserInteraction
                ? AnimatedPositioned(
                    duration: const Duration(milliseconds: 200),
                    curve: Curves.easeInOut,
                    left: _isNotificationEnabled ? 22 : 2,
                    top: 2,
                    child: Container(
                      width: 26,
                      height: 26,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: _isNotificationEnabled
                            ? Colors
                                  .white // 하얀색 원 (켜짐)
                            : const Color(0xFFF5F5F5), // 밝은 회색 원 (꺼짐)
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.1),
                            blurRadius: 4,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                    ),
                  )
                : Positioned(
                    left: _isNotificationEnabled ? 22 : 2,
                    top: 2,
                    child: Container(
                      width: 26,
                      height: 26,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: _isNotificationEnabled
                            ? Colors
                                  .white // 하얀색 원 (켜짐)
                            : const Color(0xFFF5F5F5), // 밝은 회색 원 (꺼짐)
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.1),
                            blurRadius: 4,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                    ),
                  ),
          ],
        ),
      ),
    );
  }

  void _handleNotificationToggle() async {
    setState(() {
      _isUserInteraction = true; // 사용자 상호작용 시작 - setState 내에서 설정
      _isNotificationEnabled = !_isNotificationEnabled;
    });

    // 애니메이션 실행
    if (_isNotificationEnabled) {
      _toggleAnimationController.forward();
    } else {
      _toggleAnimationController.reverse();
    }

    // 실제 알림 설정 변경
    await _notificationService.setNotificationEnabled(_isNotificationEnabled);

    if (_isNotificationEnabled) {
      await _notificationService.requestPermissions();
    }

    // 사용자 액션 로깅
    Logger.userAction(
      'Global notification setting changed',
      data: {
        'enabled': _isNotificationEnabled,
        'changeTime': DateTime.now().toIso8601String(),
      },
    );
  }
}
