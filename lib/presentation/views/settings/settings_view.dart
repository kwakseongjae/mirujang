import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_email_sender/flutter_email_sender.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'dart:io';
import 'theme_settings_view.dart';
import '../../../services/notification_service.dart';
import '../../../utils/logger.dart';
import '../guide/guide_view.dart';

class SettingsView extends StatefulWidget {
  const SettingsView({super.key});

  @override
  State<SettingsView> createState() => _SettingsViewState();
}

class _SettingsViewState extends State<SettingsView>
    with TickerProviderStateMixin, WidgetsBindingObserver {
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

    // 앱 생명주기 관찰자 등록
    WidgetsBinding.instance.addObserver(this);

    // 초기 상태 설정
    _loadNotificationState();
  }

  void _loadNotificationState() async {
    // NotificationService의 상태를 비동기로 로드
    await Future.delayed(const Duration(milliseconds: 100)); // 서비스 초기화 대기

    // 시스템 설정과 동기화
    await _notificationService.syncWithSystemSettings();

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
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);

    // 앱이 포그라운드로 돌아올 때 시스템 설정과 동기화
    if (state == AppLifecycleState.resumed) {
      _syncWithSystemSettings();
    }
  }

  void _syncWithSystemSettings() async {
    // 시스템 설정과 동기화
    await _notificationService.syncWithSystemSettings();

    // UI 상태 업데이트
    if (mounted) {
      final actualValue = _notificationService.isNotificationEnabled;
      if (_isNotificationEnabled != actualValue) {
        setState(() {
          _isNotificationEnabled = actualValue;
          _toggleAnimationController.value = actualValue ? 1.0 : 0.0;
        });
      }
    }
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
              icon: Icons.play_circle_outline_rounded,
              title: '앱 사용법 보기',
              subtitle: '미루장의 주요 기능을 확인해보세요',
              trailing: const Icon(Icons.chevron_right_rounded),
              onTap: () {
                _showAppTutorial();
              },
            ),
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

  // 의견 카테고리 선택 다이얼로그
  void _showFeedbackDialog(BuildContext context) {
    String selectedCategory = '';

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => Dialog(
          backgroundColor: Colors.transparent,
          child: Container(
            width: MediaQuery.of(context).size.width * 0.95,
            height: 460, // 고정 높이
            decoration: BoxDecoration(
              color: Theme.of(context).brightness == Brightness.dark
                  ? const Color(0xFF1C1C1E)
                  : Colors.white,
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 20,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Stack(
              children: [
                // 상단 헤더
                Positioned(
                  top: 0,
                  left: 0,
                  right: 0,
                  child: Container(
                    height: 140,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFFF4B41F), Color(0xFFFFD700)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(24),
                        topRight: Radius.circular(24),
                      ),
                    ),
                    child: Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // 미루장 캐릭터 아이콘
                          Container(
                            width: 32,
                            height: 32,
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: const Icon(
                              Icons.favorite_rounded,
                              color: Colors.white,
                              size: 18,
                            ),
                          ),
                          const SizedBox(height: 4),
                          const Text(
                            '미루장에게 말해주세요! 💬',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                              fontFamily: 'Pretendard',
                            ),
                          ),
                          const Text(
                            '소중한 의견을 들려주세요',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.white,
                              fontFamily: 'Pretendard',
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),

                // 내용 영역
                Positioned(
                  top: 140,
                  left: 0,
                  right: 0,
                  height: 260,
                  child: Container(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // 질문
                        const Text(
                          '어떤 의견을 보내려 하시나요?',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            fontFamily: 'Pretendard',
                          ),
                        ),
                        const SizedBox(height: 8),

                        // 카테고리 선택 옵션들
                        Expanded(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                            children: [
                              _buildRadioOption(
                                '문의',
                                selectedCategory,
                                () => setState(() => selectedCategory = '문의'),
                              ),
                              _buildRadioOption(
                                '버그',
                                selectedCategory,
                                () => setState(() => selectedCategory = '버그'),
                              ),
                              _buildRadioOption(
                                '제안',
                                selectedCategory,
                                () => setState(() => selectedCategory = '제안'),
                              ),
                              _buildRadioOption(
                                '칭찬',
                                selectedCategory,
                                () => setState(() => selectedCategory = '칭찬'),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                // 하단 버튼 영역
                Positioned(
                  bottom: 0,
                  left: 0,
                  right: 0,
                  child: Container(
                    height: 80,
                    padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
                    child: Row(
                      children: [
                        // 닫기 버튼
                        Expanded(
                          child: Container(
                            height: 44,
                            margin: const EdgeInsets.only(right: 8),
                            child: OutlinedButton(
                              onPressed: () => Navigator.of(context).pop(),
                              style: OutlinedButton.styleFrom(
                                side: BorderSide(color: Colors.grey[400]!),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                              ),
                              child: const Text(
                                '닫기',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  fontFamily: 'Pretendard',
                                ),
                              ),
                            ),
                          ),
                        ),
                        // 다음 버튼
                        Expanded(
                          child: Container(
                            height: 44,
                            margin: const EdgeInsets.only(left: 8),
                            child: ElevatedButton(
                              onPressed: selectedCategory.isEmpty
                                  ? null
                                  : () async {
                                      Navigator.of(context).pop();
                                      await _sendFeedbackWithCategory(
                                        context,
                                        selectedCategory,
                                      );
                                    },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: selectedCategory.isEmpty
                                    ? Colors.grey[400]
                                    : const Color(0xFFF4B41F),
                                foregroundColor: Colors.white,
                                elevation: 0,
                                shadowColor: Colors.transparent,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                              ),
                              child: const Text(
                                '다음',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  fontFamily: 'Pretendard',
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // 라디오 옵션 위젯
  Widget _buildRadioOption(
    String title,
    String selectedCategory,
    VoidCallback onTap,
  ) {
    final isSelected = selectedCategory == title;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        child: Row(
          children: [
            // 라디오 버튼
            Container(
              width: 20,
              height: 20,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: isSelected
                      ? const Color(0xFFF4B41F)
                      : Colors.grey[400]!,
                  width: 2,
                ),
                color: isSelected
                    ? const Color(0xFFF4B41F)
                    : Colors.transparent,
              ),
              child: isSelected
                  ? const Icon(Icons.check, color: Colors.white, size: 12)
                  : null,
            ),
            const SizedBox(width: 12),

            // 텍스트
            Text(
              title,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: isSelected
                    ? const Color(0xFFF4B41F)
                    : (Theme.of(context).brightness == Brightness.dark
                          ? Colors.white
                          : Colors.black),
                fontFamily: 'Pretendard',
              ),
            ),
          ],
        ),
      ),
    );
  }

  // 자주 묻는 질문 다이얼로그
  void _showFAQDialog(BuildContext context) {
    int? expandedIndex;

    final List<Map<String, String>> faqs = [
      {
        'question': '미루장이 뭔가요? 어떻게 사용하나요?',
        'answer':
            '미루장은 미룬 일을 놓치지 않고 처리할 수 있게 도와주는 앱입니다. 할 일을 등록하면 설정한 시간에 알림을 보내드려요. 알림을 받으면 "지금 하기" 또는 "나중에 하기"를 선택할 수 있어요. "나중에 하기"를 선택하면 다음 알림 시간이 자동으로 연장되어 결국 놓치지 않고 처리할 수 있게 도와드립니다.',
      },
      {
        'question': '알림이 오지 않아요. 어떻게 해야 하나요?',
        'answer':
            '먼저 앱 설정에서 알림이 켜져 있는지 확인해주세요. 그리고 기기의 설정 > 알림 > 미루장에서 알림이 허용되어 있는지 확인해보세요. 배터리 최적화 설정이 켜져 있으면 알림이 지연될 수 있으니 확인해보시기 바랍니다.',
      },
      {
        'question': '할 일을 완료했는데 어떻게 표시하나요?',
        'answer':
            '할 일을 완료하셨다면 해당 할 일을 길게 눌러서 "완료" 버튼을 선택하거나, 할 일 상세 화면에서 완료 버튼을 눌러주세요. 완료된 할 일은 히스토리에서 확인할 수 있어요.',
      },
      {
        'question': '할 일을 수정하거나 삭제할 수 있나요?',
        'answer':
            '네, 가능합니다! 할 일을 길게 누르면 수정, 삭제, 완료 옵션이 나타납니다. 또는 할 일을 탭해서 상세 화면으로 들어가서 수정하거나 삭제할 수 있어요.',
      },
      {
        'question': '앱을 삭제하면 데이터가 사라지나요?',
        'answer':
            '네, 앱을 삭제하면 모든 데이터가 사라집니다. 현재는 클라우드 백업 기능이 없어서 앱을 삭제하기 전에 중요한 할 일들을 따로 기록해두시기 바랍니다. 향후 백업 기능을 추가할 예정이에요!',
      },
    ];

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => Dialog(
          backgroundColor: Colors.transparent,
          child: Container(
            width: MediaQuery.of(context).size.width * 0.95,
            constraints: BoxConstraints(
              maxHeight: MediaQuery.of(context).size.height * 0.85,
            ),
            decoration: BoxDecoration(
              color: Theme.of(context).brightness == Brightness.dark
                  ? const Color(0xFF1C1C1E)
                  : Colors.white,
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 20,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // 상단 헤더
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.fromLTRB(24, 32, 24, 16),
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Color(0xFF9C27B0), Color(0xFFBA68C8)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(24),
                      topRight: Radius.circular(24),
                    ),
                  ),
                  child: Column(
                    children: [
                      // FAQ 아이콘
                      Container(
                        width: 60,
                        height: 60,
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(30),
                        ),
                        child: const Icon(
                          Icons.help_rounded,
                          color: Colors.white,
                          size: 30,
                        ),
                      ),
                      const SizedBox(height: 12),
                      const Text(
                        '자주 묻는 질문 💬',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                          fontFamily: 'Pretendard',
                        ),
                      ),
                      const SizedBox(height: 4),
                      const Text(
                        '미루장 사용법과 궁금한 점들을 확인해보세요',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.white,
                          fontFamily: 'Pretendard',
                        ),
                      ),
                    ],
                  ),
                ),

                // FAQ 리스트
                Expanded(
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: faqs.length,
                    itemBuilder: (context, index) {
                      return _buildFAQItem(
                        faqs[index],
                        isLast: index == faqs.length - 1,
                        isExpanded: expandedIndex == index,
                        onTap: () {
                          setState(() {
                            if (expandedIndex == index) {
                              expandedIndex = null; // 같은 아이템을 클릭하면 접기
                            } else {
                              expandedIndex = index; // 다른 아이템을 클릭하면 펼치기
                            }
                          });
                        },
                      );
                    },
                  ),
                ),

                // 하단 닫기 버튼
                Container(
                  padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
                  child: SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: ElevatedButton(
                      onPressed: () => Navigator.of(context).pop(),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF9C27B0),
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shadowColor: Colors.transparent,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text(
                        '확인',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          fontFamily: 'Pretendard',
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // FAQ 아이템 위젯
  Widget _buildFAQItem(
    Map<String, String> faq, {
    bool isLast = false,
    bool isExpanded = false,
    VoidCallback? onTap,
  }) {
    return _FAQItemWidget(
      faq: faq,
      isLast: isLast,
      isExpanded: isExpanded,
      onTap: onTap,
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
    final newValue = !_isNotificationEnabled;

    setState(() {
      _isUserInteraction = true; // 사용자 상호작용 시작 - setState 내에서 설정
      _isNotificationEnabled = newValue;
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
      // 알림을 켜려고 할 때 시스템 권한 요청
      await _notificationService.requestPermissions();

      // 시스템 설정과 동기화하여 실제로 허용되었는지 확인
      await _notificationService.syncWithSystemSettings();

      // 시스템에서 여전히 비활성화되어 있다면 사용자에게 안내
      final systemEnabled = await _notificationService
          .isSystemNotificationEnabled();
      if (!systemEnabled && mounted) {
        _showSystemSettingsDialog();
      }
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

  void _showSystemSettingsDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('알림 설정이 필요해요'),
          content: const Text(
            '앱에서 알림을 켰지만, 시스템 설정에서 여전히 꺼져있어요.\n\n'
            '시스템 설정으로 이동해서 알림을 허용해주세요.',
          ),
          actions: [
            TextButton(
              onPressed: () async {
                Navigator.of(context).pop();
                // 나중에 버튼을 누르면 토글을 Off로 되돌림
                await _revertNotificationToggle();
              },
              child: const Text('나중에'),
            ),
            TextButton(
              onPressed: () async {
                Navigator.of(context).pop();
                // 설정으로 이동 버튼을 누르면 토글을 Off로 되돌리고 시스템 설정으로 이동
                await _revertNotificationToggle();
                _openSystemNotificationSettings();
              },
              child: const Text('설정으로 이동'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _revertNotificationToggle() async {
    // 토글을 Off로 되돌림
    setState(() {
      _isNotificationEnabled = false;
      _toggleAnimationController.value = 0.0;
    });

    // 알림 서비스 설정도 Off로 변경
    await _notificationService.setNotificationEnabled(false);

    // 사용자에게 안내
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('알림이 꺼졌습니다. 나중에 설정에서 다시 켜주세요.'),
          duration: Duration(seconds: 2),
        ),
      );
    }
  }

  void _openSystemNotificationSettings() async {
    try {
      // iOS의 경우 시스템 설정으로 이동
      await _notificationService.openSystemNotificationSettings();

      // 사용자 액션 로깅
      Logger.userAction(
        'System notification settings opened',
        data: {'timestamp': DateTime.now().toIso8601String()},
      );
    } catch (e) {
      Logger.error('Failed to open system notification settings', error: e);

      // 에러 발생 시 사용자에게 안내
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('시스템 설정을 열 수 없습니다. 수동으로 설정 > 알림에서 확인해주세요.'),
            duration: Duration(seconds: 3),
          ),
        );
      }
    }
  }

  void _showAppTutorial() {
    // 사용자 액션 로깅
    Logger.userAction(
      'App tutorial opened from settings',
      data: {'timestamp': DateTime.now().toIso8601String()},
    );

    // 가이드 페이지로 바로 이동 (탐색 가능)
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => const GuideView(isFromSettings: true),
        fullscreenDialog: true, // 모달 스타일로 표시
      ),
    );
  }

  // 하단 시트 메일 작성 화면 (iOS 스타일) - 제거됨
  /*
    final TextEditingController subjectController = TextEditingController(
      text: '미루장 앱 의견 - $category',
    );
    final TextEditingController bodyController = TextEditingController();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.85,
        decoration: BoxDecoration(
          color: Theme.of(context).brightness == Brightness.dark
              ? const Color(0xFF1C1C1E)
              : Colors.white,
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(20),
            topRight: Radius.circular(20),
          ),
        ),
        child: Column(
          children: [
            // 상단 핸들바
            Container(
              margin: const EdgeInsets.only(top: 8),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[400],
                borderRadius: BorderRadius.circular(2),
              ),
            ),

            // 헤더
            Container(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
              child: Row(
                children: [
                  const Icon(
                    Icons.email_rounded,
                    color: Color(0xFF2196F3),
                    size: 24,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          '메일 작성',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                            fontFamily: 'Pretendard',
                          ),
                        ),
                        Text(
                          '카테고리: $category',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[600],
                            fontFamily: 'Pretendard',
                          ),
                        ),
                      ],
                    ),
                  ),
                  GestureDetector(
                    onTap: () => Navigator.of(context).pop(),
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      child: const Icon(
                        Icons.close_rounded,
                        color: Colors.grey,
                        size: 20,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // 메일 내용 영역
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // 받는 사람
                    const Text(
                      '받는 사람',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        fontFamily: 'Pretendard',
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.grey[100],
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.grey[300]!),
                      ),
                      child: const Text(
                        'gkffhdnls13@gmail.com',
                        style: TextStyle(
                          fontSize: 16,
                          fontFamily: 'Pretendard',
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // 제목
                    const Text(
                      '제목',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        fontFamily: 'Pretendard',
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: subjectController,
                      decoration: InputDecoration(
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: BorderSide(color: Colors.grey[300]!),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: const BorderSide(
                            color: Color(0xFF2196F3),
                            width: 2,
                          ),
                        ),
                        contentPadding: const EdgeInsets.all(12),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // 본문
                    const Text(
                      '내용',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        fontFamily: 'Pretendard',
                      ),
                    ),
                    const SizedBox(height: 8),
                    Expanded(
                      child: TextField(
                        controller: bodyController,
                        maxLines: null,
                        expands: true,
                        textAlignVertical: TextAlignVertical.top,
                        decoration: InputDecoration(
                          hintText: '여기에 의견을 자세히 작성해주세요...',
                          hintStyle: TextStyle(
                            color: Colors.grey[500],
                            fontFamily: 'Pretendard',
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: BorderSide(color: Colors.grey[300]!),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: const BorderSide(
                              color: Color(0xFF2196F3),
                              width: 2,
                            ),
                          ),
                          contentPadding: const EdgeInsets.all(12),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // 하단 전송 버튼
            Container(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
              child: Row(
                children: [
                  // 취소 버튼
                  Expanded(
                    child: Container(
                      height: 48,
                      margin: const EdgeInsets.only(right: 8),
                      child: OutlinedButton(
                        onPressed: () => Navigator.of(context).pop(),
                        style: OutlinedButton.styleFrom(
                          side: BorderSide(color: Colors.grey[400]!),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        child: const Text(
                          '취소',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            fontFamily: 'Pretendard',
                          ),
                        ),
                      ),
                    ),
                  ),
                  // 전송 버튼 (종이비행기 아이콘)
                  Container(
                    height: 48,
                    margin: const EdgeInsets.only(left: 8),
                    child: ElevatedButton.icon(
                      onPressed: () async {
                        if (bodyController.text.trim().isEmpty) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('의견을 입력해주세요! 💭'),
                              backgroundColor: Color(0xFFFF9800),
                            ),
                          );
                          return;
                        }

                        try {
                          // flutter_email_sender를 사용하여 이메일 전송
                          await _sendEmailWithFlutterEmailSender(
                            subjectController.text,
                            bodyController.text,
                            '',
                          );

                          Navigator.of(context).pop();
                          _showThankYouDialog(context);
                        } catch (e) {
                          Navigator.of(context).pop();
                          _showEmailErrorDialog(context, e.toString());
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF2196F3),
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shadowColor: Colors.transparent,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      icon: const Icon(Icons.send_rounded, size: 18),
                      label: const Text(
                        '전송',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          fontFamily: 'Pretendard',
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
  */

  // 카테고리별 의견 전송
  Future<void> _sendFeedbackWithCategory(
    BuildContext context,
    String category,
  ) async {
    try {
      final appInfo = await _getAppInfo();
      final deviceInfo = await _getDeviceInfo();

      // 카테고리별 이메일 내용 생성
      String emailBody = _generateCategoryEmailBody(
        category,
        appInfo,
        deviceInfo,
      );

      final Email email = Email(
        body: emailBody,
        subject: '미루장 앱 $category - ${DateTime.now().toString().split(' ')[0]}',
        recipients: ['gkffhdnls13@gmail.com'],
        isHTML: false,
      );

      await FlutterEmailSender.send(email);
      _showThankYouDialog(context);
    } catch (e) {
      _showEmailErrorDialog(context, e.toString());
    }
  }

  // 카테고리별 이메일 내용 생성
  String _generateCategoryEmailBody(
    String category,
    String appInfo,
    String deviceInfo,
  ) {
    String categoryMessage = '';

    switch (category) {
      case '문의':
        categoryMessage = '문의사항을 말씀해주세요.\n';
        break;
      case '버그':
        categoryMessage = '발견하신 버그에 대해 자세히 설명해주세요.\n';
        break;
      case '제안':
        categoryMessage = '개선사항이나 새로운 기능에 대한 제안을 말씀해주세요.\n';
        break;
      case '칭찬':
        categoryMessage = '미루장 앱에 대한 소중한 칭찬을 들려주세요.\n';
        break;
      default:
        categoryMessage = '의견을 말씀해주세요.\n';
    }

    return '''안녕하세요! 미루장 앱 개발팀입니다.

$categoryMessage
(의견작성):\n\n
──────────────────
──────────────────

🌐 앱 정보
$appInfo

📱 기기 정보  
$deviceInfo

──────────────────
──────────────────

감사합니다! 💙''';
  }

  // 앱 정보 가져오기
  Future<String> _getAppInfo() async {
    try {
      final packageInfo = await PackageInfo.fromPlatform();
      return '앱 버전: ${packageInfo.version} +${packageInfo.buildNumber}';
    } catch (e) {
      return '앱 정보를 가져올 수 없습니다.';
    }
  }

  // 기기 정보 가져오기
  Future<String> _getDeviceInfo() async {
    try {
      final deviceInfo = DeviceInfoPlugin();
      if (Platform.isAndroid) {
        final androidInfo = await deviceInfo.androidInfo;
        return 'Android ${androidInfo.version.release} (API ${androidInfo.version.sdkInt})';
      } else if (Platform.isIOS) {
        final iosInfo = await deviceInfo.iosInfo;
        return 'iOS ${iosInfo.systemVersion}';
      }
      return '기기 정보를 가져올 수 없습니다.';
    } catch (e) {
      return '기기 정보를 가져올 수 없습니다.';
    }
  }

  // 이메일 전송 에러 다이얼로그
  void _showEmailErrorDialog(BuildContext context, String error) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        child: Container(
          width: MediaQuery.of(context).size.width * 0.95,
          decoration: BoxDecoration(
            color: Theme.of(context).brightness == Brightness.dark
                ? const Color(0xFF1C1C1E)
                : Colors.white,
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 20,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // 상단 헤더
              Container(
                width: double.infinity,
                padding: const EdgeInsets.fromLTRB(24, 32, 24, 16),
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Color(0xFFFF5722), Color(0xFFFF8A65)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(24),
                    topRight: Radius.circular(24),
                  ),
                ),
                child: Column(
                  children: [
                    // 에러 아이콘
                    Container(
                      width: 60,
                      height: 60,
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(30),
                      ),
                      child: const Icon(
                        Icons.error_rounded,
                        color: Colors.white,
                        size: 30,
                      ),
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      '이메일 전송 실패 📧',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                        fontFamily: 'Pretendard',
                      ),
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      '이메일을 전송할 수 없습니다',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.white,
                        fontFamily: 'Pretendard',
                      ),
                    ),
                  ],
                ),
              ),

              // 내용 영역
              Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  children: [
                    const Text(
                      '이메일 앱이 설치되어 있지 않거나\n설정이 필요할 수 있습니다.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 16,
                        height: 1.5,
                        fontFamily: 'Pretendard',
                      ),
                    ),
                    const SizedBox(height: 20),

                    // 이메일 주소 복사 섹션
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Theme.of(context).brightness == Brightness.dark
                            ? Colors.grey[800]?.withOpacity(0.3)
                            : Colors.grey[100],
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: Theme.of(context).brightness == Brightness.dark
                              ? Colors.grey[700]!
                              : Colors.grey[300]!,
                        ),
                      ),
                      child: Column(
                        children: [
                          const Text(
                            '직접 이메일을 보내주세요',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              fontFamily: 'Pretendard',
                            ),
                          ),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              Expanded(
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 8,
                                  ),
                                  decoration: BoxDecoration(
                                    color:
                                        Theme.of(context).brightness ==
                                            Brightness.dark
                                        ? Colors.grey[700]
                                        : Colors.white,
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(
                                      color:
                                          Theme.of(context).brightness ==
                                              Brightness.dark
                                          ? Colors.grey[600]!
                                          : Colors.grey[400]!,
                                    ),
                                  ),
                                  child: const Text(
                                    'gkffhdnls13@gmail.com',
                                    style: TextStyle(
                                      fontSize: 14,
                                      fontFamily: 'Pretendard',
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              ElevatedButton.icon(
                                onPressed: () async {
                                  await Clipboard.setData(
                                    const ClipboardData(
                                      text: 'gkffhdnls13@gmail.com',
                                    ),
                                  );
                                  if (context.mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Text('이메일 주소가 복사되었습니다!'),
                                        duration: Duration(seconds: 2),
                                        backgroundColor: Color(0xFF4CAF50),
                                      ),
                                    );
                                  }
                                },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFF4CAF50),
                                  foregroundColor: Colors.white,
                                  elevation: 0,
                                  shadowColor: Colors.transparent,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 8,
                                  ),
                                ),
                                icon: const Icon(Icons.copy_rounded, size: 16),
                                label: const Text(
                                  '복사',
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    fontFamily: 'Pretendard',
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 16),
                    const Text(
                      '다음 방법을 시도해보세요:\n• 이메일 앱 설치\n• 이메일 계정 설정\n• 네트워크 연결 확인',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 14,
                        height: 1.5,
                        color: Colors.grey,
                        fontFamily: 'Pretendard',
                      ),
                    ),
                  ],
                ),
              ),

              // 하단 버튼
              Container(
                padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
                child: SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton(
                    onPressed: () => Navigator.of(context).pop(),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFFF5722),
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shadowColor: Colors.transparent,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text(
                      '확인',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        fontFamily: 'Pretendard',
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // 감사 인사 다이얼로그
  void _showThankYouDialog(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        child: Container(
          width: MediaQuery.of(context).size.width * 0.95, // 화면 가로의 95% 사용
          decoration: BoxDecoration(
            color: Theme.of(context).brightness == Brightness.dark
                ? const Color(0xFF1C1C1E)
                : Colors.white,
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 20,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // 상단 헤더
              Container(
                width: double.infinity,
                padding: const EdgeInsets.fromLTRB(24, 32, 24, 16),
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Color(0xFF4CAF50), Color(0xFF8BC34A)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(24),
                    topRight: Radius.circular(24),
                  ),
                ),
                child: Column(
                  children: [
                    // 성공 아이콘
                    Container(
                      width: 60,
                      height: 60,
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(30),
                      ),
                      child: const Icon(
                        Icons.check_circle_rounded,
                        color: Colors.white,
                        size: 30,
                      ),
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      '감사합니다! 💕',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                        fontFamily: 'Pretendard',
                      ),
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      '소중한 의견이 전달되었어요',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.white,
                        fontFamily: 'Pretendard',
                      ),
                    ),
                  ],
                ),
              ),

              // 내용 영역
              Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  children: [
                    const Text(
                      '미루장을 더 좋게 만들어주셔서\n정말 감사해요!',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 16,
                        height: 1.5,
                        fontFamily: 'Pretendard',
                      ),
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      '여러분의 의견이 미루장을\n더욱 발전시켜 나갈 거예요 ✨',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 14,
                        height: 1.5,
                        color: Colors.grey,
                        fontFamily: 'Pretendard',
                      ),
                    ),
                  ],
                ),
              ),

              // 하단 버튼
              Container(
                padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
                child: SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton(
                    onPressed: () => Navigator.of(context).pop(),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF4CAF50),
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shadowColor: Colors.transparent,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text(
                      '확인',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        fontFamily: 'Pretendard',
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// FAQ 아이템을 위한 별도 StatefulWidget
class _FAQItemWidget extends StatefulWidget {
  final Map<String, String> faq;
  final bool isLast;
  final bool isExpanded;
  final VoidCallback? onTap;

  const _FAQItemWidget({
    required this.faq,
    this.isLast = false,
    this.isExpanded = false,
    this.onTap,
  });

  @override
  State<_FAQItemWidget> createState() => _FAQItemWidgetState();
}

class _FAQItemWidgetState extends State<_FAQItemWidget> {
  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      margin: const EdgeInsets.only(bottom: 1), // 구분선을 위해 마진 최소화
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1C1C1E) : Colors.white,
        border: widget.isLast
            ? null
            : Border(
                bottom: BorderSide(
                  color: isDark ? Colors.grey[800]! : Colors.grey[200]!,
                  width: 1,
                ),
              ),
      ),
      child: Column(
        children: [
          // 질문 부분
          InkWell(
            onTap: widget.onTap,
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 20),
              child: Row(
                children: [
                  // 질문 텍스트
                  Expanded(
                    child: Text(
                      widget.faq['question']!,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        fontFamily: 'Pretendard',
                        height: 1.4,
                        color: isDark ? Colors.white : Colors.black87,
                      ),
                    ),
                  ),

                  const SizedBox(width: 16),
                  // 화살표 아이콘
                  AnimatedRotation(
                    turns: widget.isExpanded ? 0.5 : 0,
                    duration: const Duration(milliseconds: 200),
                    child: Icon(
                      Icons.keyboard_arrow_down_rounded,
                      color: isDark ? Colors.white70 : Colors.black54,
                      size: 24,
                    ),
                  ),
                ],
              ),
            ),
          ),

          // 답변 부분
          AnimatedSize(
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeInOut,
            child: widget.isExpanded
                ? Container(
                    width: double.infinity,
                    padding: const EdgeInsets.fromLTRB(8, 0, 8, 16),
                    child: Text(
                      widget.faq['answer']!,
                      style: TextStyle(
                        fontSize: 15,
                        height: 1.6,
                        color: isDark ? Colors.white70 : Colors.black87,
                        fontFamily: 'Pretendard',
                      ),
                    ),
                  )
                : const SizedBox.shrink(),
          ),
        ],
      ),
    );
  }
}
