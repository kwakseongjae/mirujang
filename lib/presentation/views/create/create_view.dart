import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import '../../../models/miru_task.dart';
import '../../../services/storage_service.dart';
import '../../../services/notification_service.dart';

class CreateView extends StatefulWidget {
  const CreateView({super.key});

  @override
  State<CreateView> createState() => _CreateViewState();
}

class _CreateViewState extends State<CreateView> with TickerProviderStateMixin {
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _memoController = TextEditingController();
  DateTime _selectedTime = DateTime.now();
  bool _enableNotification = false; // false: 알림 안받기, true: 알림 받기

  // 토스트 메시지 관련
  bool _showToast = false;
  String _toastMessage = '';
  Color _toastColor = Colors.red;
  late AnimationController _toastAnimationController;
  late Animation<double> _toastAnimation;

  @override
  void initState() {
    super.initState();
    _toastAnimationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _toastAnimation = Tween<double>(begin: -1.0, end: 0.0).animate(
      CurvedAnimation(parent: _toastAnimationController, curve: Curves.easeOut),
    );
  }

  @override
  void dispose() {
    _titleController.dispose();
    _memoController.dispose();
    _toastAnimationController.dispose();
    super.dispose();
  }

  String _getNotificationTimeText() {
    final now = DateTime.now();

    // 현재 시간과 설정한 시간이 같은 분인지 확인 (시, 분만 비교)
    final isSameTime =
        now.hour == _selectedTime.hour && now.minute == _selectedTime.minute;

    // 현재 시각과 정확히 같을 때만 "1분 이내에 알림을 받아요" 표시
    if (isSameTime) {
      return '1분 이내에 알림을 받아요';
    }

    // 현재 시간을 분 단위로 정규화 (초를 0으로)
    final currentTimeNormalized = DateTime(
      now.year,
      now.month,
      now.day,
      now.hour,
      now.minute,
    );

    // 설정한 시간
    final selectedDateTime = DateTime(
      now.year,
      now.month,
      now.day,
      _selectedTime.hour,
      _selectedTime.minute,
    );

    // 설정한 시간이 현재 시간보다 이전이면 다음날로 설정
    final notificationDateTime =
        selectedDateTime.isBefore(currentTimeNormalized)
        ? selectedDateTime.add(const Duration(days: 1))
        : selectedDateTime;

    final difference = notificationDateTime.difference(currentTimeNormalized);
    final totalMinutes = difference.inMinutes;
    final hours = totalMinutes ~/ 60;
    final minutes = totalMinutes % 60;

    // 0시간일 때는 시간 정보 제외
    if (hours == 0) {
      if (minutes == 0) {
        return '1분 이내에 알림을 받아요';
      }
      return '$minutes분 후에 알림을 받아요';
    }

    return '$hours시간 $minutes분 후에 알림을 받아요';
  }

  void _showToastMessage(String message, Color color) {
    // 이미 토스트가 표시 중이면 중복 표시하지 않음
    if (_showToast) return;

    setState(() {
      _showToast = true;
      _toastMessage = message;
      _toastColor = color;
    });

    _toastAnimationController.forward().then((_) {
      // 2초 후 토스트 숨기기
      Future.delayed(const Duration(seconds: 2), () {
        if (mounted) {
          _toastAnimationController.reverse().then((_) {
            if (mounted) {
              setState(() {
                _showToast = false;
              });
            }
          });
        }
      });
    });
  }

  Future<void> _saveTask() async {
    // 타이틀이 비어있으면 저장하지 않음
    if (_titleController.text.trim().isEmpty) {
      _showToastMessage('미룰 일을 입력해주세요.', Colors.red);
      return;
    }

    // 메모는 선택사항이므로 검증하지 않음

    try {
      // 알림 시간 계산
      DateTime? notificationTime;
      if (_enableNotification) {
        final now = DateTime.now();
        final selectedDateTime = DateTime(
          now.year,
          now.month,
          now.day,
          _selectedTime.hour,
          _selectedTime.minute,
        );

        // 현재 시간과 같으면 1분 후로 설정
        final isSameTime =
            now.hour == _selectedTime.hour &&
            now.minute == _selectedTime.minute;
        if (isSameTime) {
          notificationTime = now.add(const Duration(minutes: 1));
        } else if (selectedDateTime.isBefore(now)) {
          notificationTime = selectedDateTime.add(const Duration(days: 1));
        } else {
          notificationTime = selectedDateTime;
        }
      }

      // MiruTask 생성
      final task = MiruTask(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        title: _titleController.text.trim(),
        memo: _memoController.text.trim(),
        createdAt: DateTime.now(),
        notificationTime: notificationTime,
        hasNotification: _enableNotification,
        isEnabled: _enableNotification, // 알림 받기로 설정했을 때만 활성화
        isCompleted: false, // 새로 생성되는 작업은 완료되지 않음
      );

      // 저장소에 저장
      final storageService = await StorageService.getInstance();
      await storageService.addTask(task);

      // 알림 예약
      if (_enableNotification && notificationTime != null) {
        try {
          final notificationService = NotificationService();
          await notificationService.scheduleNotification(task);
        } catch (e) {
          // 알림 예약 실패해도 작업은 저장됨
        }
      }

      // 성공 시 홈화면으로 이동 (토스트는 홈화면에서 표시)
      if (mounted) {
        Navigator.of(context).pop(true); // true를 반환하여 성공 상태 전달
      }
    } catch (e) {
      // 에러 메시지 표시
      if (mounted) {
        _showToastMessage('저장 중 오류가 발생했습니다.', Colors.red);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Scaffold(
          appBar: AppBar(
            backgroundColor: Colors.transparent,
            elevation: 0,
            leading: IconButton(
              icon: const Icon(Icons.close),
              onPressed: () => Navigator.of(context).pop(),
              color: Theme.of(context).brightness == Brightness.dark
                  ? Colors.white
                  : Colors.black,
            ),
            centerTitle: true,
            title: Text(
              '미루기 등록',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Theme.of(context).brightness == Brightness.dark
                    ? Colors.white
                    : Colors.black,
              ),
            ),
          ),
          body: SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(16.0, 16.0, 16.0, 120.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 제목 라벨
                  Padding(
                    padding: const EdgeInsets.only(left: 4, bottom: 8),
                    child: Row(
                      children: [
                        Text(
                          '제목',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                            color:
                                Theme.of(context).brightness == Brightness.dark
                                ? Colors.white
                                : Colors.black,
                          ),
                        ),
                        const SizedBox(width: 4),
                        const Text(
                          '*',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: Colors.red,
                          ),
                        ),
                      ],
                    ),
                  ),
                  // 제목 입력 필드
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Theme.of(context).brightness == Brightness.dark
                          ? const Color(0xFF2C2C2E)
                          : const Color(0xFFF7FAFC), // 라이트모드에서는 pale slate 배경
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: Theme.of(context).brightness == Brightness.dark
                            ? const Color(0xFF3A3A3C).withOpacity(0.3)
                            : const Color(0xFFE0E0E0).withOpacity(0.8),
                        width: 0.5,
                      ),
                    ),
                    child: TextField(
                      controller: _titleController,
                      maxLength: 30,
                      decoration: InputDecoration(
                        hintText: '미룰 일을 입력해주세요 (30자 이내)',
                        hintStyle: TextStyle(
                          color: Theme.of(context).brightness == Brightness.dark
                              ? Colors.white.withOpacity(0.5)
                              : Colors.black.withOpacity(0.5),
                        ),
                        border: InputBorder.none,
                        counterStyle: TextStyle(
                          color: Theme.of(context).brightness == Brightness.dark
                              ? Colors.white.withOpacity(0.5)
                              : Colors.black.withOpacity(0.5),
                        ),
                      ),
                      style: TextStyle(
                        fontSize: 16,
                        color: Theme.of(context).brightness == Brightness.dark
                            ? Colors.white
                            : Colors.black,
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  // 메모 라벨
                  Padding(
                    padding: const EdgeInsets.only(left: 4, bottom: 8),
                    child: Text(
                      '메모(선택)',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Theme.of(context).brightness == Brightness.dark
                            ? Colors.white
                            : Colors.black,
                      ),
                    ),
                  ),
                  // 메모 입력 필드
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Theme.of(context).brightness == Brightness.dark
                          ? const Color(0xFF2C2C2E)
                          : const Color(0xFFF7FAFC), // 라이트모드에서는 pale slate 배경
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: Theme.of(context).brightness == Brightness.dark
                            ? const Color(0xFF3A3A3C).withOpacity(0.3)
                            : const Color(0xFFE0E0E0).withOpacity(0.8),
                        width: 0.5,
                      ),
                    ),
                    child: TextField(
                      controller: _memoController,
                      maxLength: 300,
                      maxLines: 4,
                      style: TextStyle(
                        fontSize: 16,
                        color: Theme.of(context).brightness == Brightness.dark
                            ? Colors.white
                            : Colors.black,
                      ),
                      decoration: InputDecoration(
                        hintText: '메모를 입력해주세요 (300자 이내)',
                        hintStyle: TextStyle(
                          color: Theme.of(context).brightness == Brightness.dark
                              ? Colors.white.withOpacity(0.5)
                              : Colors.black.withOpacity(0.5),
                        ),
                        border: InputBorder.none,
                        counterStyle: TextStyle(
                          color: Theme.of(context).brightness == Brightness.dark
                              ? Colors.white.withOpacity(0.5)
                              : Colors.black.withOpacity(0.5),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  // 알림 설정 섹션
                  Text(
                    '알림 설정',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: Theme.of(context).brightness == Brightness.dark
                          ? Colors.white
                          : Colors.black,
                    ),
                  ),
                  const SizedBox(height: 16),
                  // iPhone 타이머 스타일 탭 버튼
                  Container(
                    width: double.infinity,
                    height: 44,
                    decoration: BoxDecoration(
                      color: Theme.of(context).brightness == Brightness.dark
                          ? const Color(0xFF2C2C2E)
                          : const Color(0xFFF7FAFC), // 라이트모드에서는 pale slate 배경
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: Theme.of(context).brightness == Brightness.dark
                            ? const Color(0xFF3A3A3C).withOpacity(0.3)
                            : const Color(0xFFE0E0E0).withOpacity(0.8),
                        width: 0.5,
                      ),
                    ),
                    child: Row(
                      children: [
                        // 알림 안받기 버튼
                        Expanded(
                          child: GestureDetector(
                            onTap: () {
                              setState(() {
                                _enableNotification = false;
                              });
                            },
                            child: Container(
                              height: 44,
                              decoration: BoxDecoration(
                                color: !_enableNotification
                                    ? Colors.red
                                    : Colors.transparent,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Center(
                                child: Text(
                                  '알림 안받기',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w500,
                                    color: !_enableNotification
                                        ? Colors.white
                                        : Theme.of(context).brightness ==
                                              Brightness.dark
                                        ? Colors.white.withOpacity(0.6)
                                        : Colors.black.withOpacity(0.6),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                        // 알림 받기 버튼
                        Expanded(
                          child: GestureDetector(
                            onTap: () {
                              setState(() {
                                _enableNotification = true;
                                // 알림 받기 선택 시 현재 시간으로 설정
                                _selectedTime = DateTime.now();
                              });
                            },
                            child: Container(
                              height: 44,
                              decoration: BoxDecoration(
                                color: _enableNotification
                                    ? Colors.red
                                    : Colors.transparent,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Center(
                                child: Text(
                                  '알림 받기',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w500,
                                    color: _enableNotification
                                        ? Colors.white
                                        : Theme.of(context).brightness ==
                                              Brightness.dark
                                        ? Colors.white.withOpacity(0.6)
                                        : Colors.black.withOpacity(0.6),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  // 조건부 UI 표시
                  if (!_enableNotification)
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Theme.of(context).brightness == Brightness.dark
                            ? const Color(0xFF2C2C2E).withOpacity(0.5)
                            : const Color(
                                0xFFF7FAFC,
                              ).withOpacity(0.5), // 라이트모드에서는 pale slate 배경
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: Theme.of(context).brightness == Brightness.dark
                              ? const Color(0xFF3A3A3C).withOpacity(0.2)
                              : const Color(0xFFE0E0E0).withOpacity(0.5),
                          width: 0.5,
                        ),
                      ),
                      child: Text(
                        '알림 없이 간편 미루기를 등록합니다.',
                        style: TextStyle(
                          fontSize: 14,
                          color: Theme.of(context).brightness == Brightness.dark
                              ? Colors.white.withOpacity(0.7)
                              : Colors.black.withOpacity(0.7),
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  if (_enableNotification) ...[
                    Text(
                      '알림 시각 설정',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                        color: Theme.of(context).brightness == Brightness.dark
                            ? Colors.white
                            : Colors.black,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Container(
                      width: double.infinity,
                      height: 200,
                      decoration: BoxDecoration(
                        color: Theme.of(context).brightness == Brightness.dark
                            ? const Color(0xFF2C2C2E)
                            : const Color(0xFFF7FAFC), // 라이트모드에서는 pale slate 배경
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: Theme.of(context).brightness == Brightness.dark
                              ? const Color(0xFF3A3A3C).withOpacity(0.3)
                              : const Color(0xFFE0E0E0).withOpacity(0.8),
                          width: 0.5,
                        ),
                      ),
                      child: CupertinoTheme(
                        data: CupertinoThemeData(
                          brightness: Theme.of(context).brightness,
                          textTheme: CupertinoTextThemeData(
                            dateTimePickerTextStyle: TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.w400,
                              color:
                                  Theme.of(context).brightness ==
                                      Brightness.dark
                                  ? CupertinoColors.white
                                  : CupertinoColors.black,
                              height: 1.2, // 줄 간격 조정으로 중앙 정렬 개선
                            ),
                          ),
                        ),
                        child: CupertinoDatePicker(
                          mode: CupertinoDatePickerMode.time,
                          initialDateTime: _selectedTime,
                          use24hFormat: true,
                          onDateTimeChanged: (DateTime newTime) {
                            setState(() {
                              _selectedTime = newTime;
                            });
                          },
                          backgroundColor: Colors.transparent,
                          itemExtent: 40, // 아이템 높이 증가로 중앙 정렬 개선
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    // 알림 시간 표시
                    Center(
                      child: Text(
                        _getNotificationTimeText(),
                        style: TextStyle(
                          fontSize: 16,
                          color: Theme.of(context).brightness == Brightness.dark
                              ? Colors.white.withOpacity(0.6)
                              : Colors.black.withOpacity(0.6),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
          floatingActionButton: Container(
            width: double.infinity,
            margin: const EdgeInsets.symmetric(horizontal: 16),
            child: FloatingActionButton.extended(
              onPressed: () async {
                await _saveTask();
              },
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              label: const Text(
                '저장',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600),
              ),
            ),
          ),
          floatingActionButtonLocation:
              FloatingActionButtonLocation.centerFloat,
        ),
        // 토스트 메시지
        if (_showToast)
          Positioned(
            top: MediaQuery.of(context).padding.top + 20,
            left: 16,
            right: 16,
            child: AnimatedBuilder(
              animation: _toastAnimation,
              builder: (context, child) {
                return Transform.translate(
                  offset: Offset(0, _toastAnimation.value * 100),
                  child: Material(
                    color: Colors.transparent,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                      decoration: BoxDecoration(
                        color: _toastColor,
                        borderRadius: BorderRadius.circular(8),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.1),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            _toastColor == Colors.green
                                ? Icons.check_circle
                                : Icons.error,
                            color: Colors.white,
                            size: 20,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              _toastMessage,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
      ],
    );
  }
}
