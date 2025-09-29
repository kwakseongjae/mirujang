import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import '../../../models/miru_task.dart';
import '../../../services/storage_service.dart';
import '../../../services/notification_service.dart';

class MiruEditView extends StatefulWidget {
  final MiruTask task;

  const MiruEditView({super.key, required this.task});

  @override
  State<MiruEditView> createState() => _MiruEditViewState();
}

class _MiruEditViewState extends State<MiruEditView>
    with TickerProviderStateMixin {
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _memoController = TextEditingController();
  DateTime _selectedTime = DateTime.now();
  bool _enableNotification = false;

  // 수정사항 감지를 위한 원본 값들
  late String _originalTitle;
  late String _originalMemo;
  late DateTime _originalTime;
  late bool _originalNotification;

  // 토스트 메시지 관련
  bool _showToast = false;
  String _toastMessage = '';
  Color _toastColor = Colors.red;
  late AnimationController _toastAnimationController;
  late Animation<double> _toastAnimation;

  @override
  void initState() {
    super.initState();

    // 원본 값 저장
    _originalTitle = widget.task.title;
    _originalMemo = widget.task.memo;
    _originalTime = widget.task.notificationTime ?? DateTime.now();
    _originalNotification = widget.task.hasNotification;

    // 초기 값 설정
    _titleController.text = widget.task.title;
    _memoController.text = widget.task.memo;
    _selectedTime = widget.task.notificationTime ?? DateTime.now();
    _enableNotification = widget.task.hasNotification;

    // 토스트 애니메이션 컨트롤러 초기화
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

  // 수정사항이 있는지 확인
  bool _hasChanges() {
    return _titleController.text.trim() != _originalTitle ||
        _memoController.text.trim() != _originalMemo ||
        _selectedTime != _originalTime ||
        _enableNotification != _originalNotification;
  }

  // 뒤로가기 시 수정사항 확인
  Future<bool> _onWillPop() async {
    if (!_hasChanges()) {
      return true;
    }

    return await showDialog<bool>(
          context: context,
          barrierDismissible: false,
          builder: (context) => Dialog(
            backgroundColor: Colors.transparent,
            child: Container(
              width: double.infinity,
              margin: const EdgeInsets.symmetric(horizontal: 8),
              decoration: BoxDecoration(
                color: Theme.of(context).brightness == Brightness.dark
                    ? const Color(0xFF1C1C1E)
                    : Colors.white,
                borderRadius: BorderRadius.circular(16),
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
                  // 상단 텍스트 영역
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.fromLTRB(24, 32, 24, 16),
                    child: Column(
                      children: [
                        Text(
                          '편집을 중단하시겠어요?',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w700,
                            color:
                                Theme.of(context).brightness == Brightness.dark
                                ? Colors.white
                                : Colors.black,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          '변경사항이 저장되지 않습니다.\n정말 나가시겠어요?',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 16,
                            height: 1.4,
                            color:
                                Theme.of(context).brightness == Brightness.dark
                                ? Colors.white.withOpacity(0.7)
                                : Colors.black.withOpacity(0.7),
                          ),
                        ),
                      ],
                    ),
                  ),

                  // 하단 버튼 영역
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
                    child: Row(
                      children: [
                        // 취소 버튼 (좌측)
                        Expanded(
                          child: Container(
                            height: 44,
                            margin: const EdgeInsets.only(right: 4),
                            child: ElevatedButton(
                              onPressed: () => Navigator.of(context).pop(false),
                              style: ElevatedButton.styleFrom(
                                backgroundColor:
                                    Theme.of(context).brightness ==
                                        Brightness.dark
                                    ? const Color(0xFF2C2C2E)
                                    : const Color(0xFFF2F2F7),
                                foregroundColor:
                                    Theme.of(context).brightness ==
                                        Brightness.dark
                                    ? Colors.white
                                    : Colors.black,
                                elevation: 0,
                                shadowColor: Colors.transparent,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                              ),
                              child: const Text(
                                '취소',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ),
                        ),
                        // 나가기 버튼 (우측)
                        Expanded(
                          child: Container(
                            height: 44,
                            margin: const EdgeInsets.only(left: 4),
                            child: ElevatedButton(
                              onPressed: () => Navigator.of(context).pop(true),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.red,
                                foregroundColor: Colors.white,
                                elevation: 0,
                                shadowColor: Colors.transparent,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                              ),
                              child: const Text(
                                '나가기',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                ),
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
          ),
        ) ??
        false;
  }

  String _getNotificationTimeText() {
    final now = DateTime.now();

    // 현재 시간과 설정한 시간이 같은 분인지 확인 (시, 분만 비교)
    if (now.hour == _selectedTime.hour && now.minute == _selectedTime.minute) {
      return '1분 이내에 알림을 받아요';
    }

    // 시간 차이 계산
    final difference = _selectedTime.difference(now);
    final totalMinutes = difference.inMinutes;

    if (totalMinutes <= 0) {
      // 과거 시간인 경우 다음날로 계산
      final nextDayTime = _selectedTime.add(const Duration(days: 1));
      final nextDayDifference = nextDayTime.difference(now);
      final nextDayMinutes = nextDayDifference.inMinutes;

      final hours = nextDayMinutes ~/ 60;
      final minutes = nextDayMinutes % 60;

      if (hours == 0) {
        return '$minutes분 후에 알림을 받아요';
      }
      return '$hours시간 $minutes분 후에 알림을 받아요';
    }

    final hours = totalMinutes ~/ 60;
    final minutes = totalMinutes % 60;

    if (hours == 0) {
      return '$minutes분 후에 알림을 받아요';
    }

    return '$hours시간 $minutes분 후에 알림을 받아요';
  }

  void _showToastMessage(String message, Color color) {
    if (_showToast) return;

    setState(() {
      _showToast = true;
      _toastMessage = message;
      _toastColor = color;
    });

    _toastAnimationController.forward().then((_) {
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
    if (_titleController.text.trim().isEmpty) {
      _showToastMessage('미룰 일을 입력해주세요.', Colors.red);
      return;
    }

    try {
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
        if (now.hour == _selectedTime.hour &&
            now.minute == _selectedTime.minute) {
          notificationTime = selectedDateTime.add(const Duration(minutes: 1));
        } else {
          notificationTime = selectedDateTime;
        }
      }

      // 기존 알림 취소
      final notificationService = NotificationService();
      await notificationService.cancelNotification(widget.task.id);

      // 태스크 업데이트
      widget.task.title = _titleController.text.trim();
      widget.task.memo = _memoController.text.trim();
      widget.task.notificationTime = notificationTime;
      widget.task.hasNotification = _enableNotification;
      widget.task.isEnabled = _enableNotification;
      widget.task.isCompleted = false;

      // 저장소에 업데이트
      final storageService = await StorageService.getInstance();
      await storageService.updateTask(widget.task);

      // 새 알림 예약
      if (_enableNotification && notificationTime != null) {
        try {
          await notificationService.scheduleNotification(widget.task);
        } catch (e) {
          print('알림 예약 오류: $e');
        }
      }

      // 성공 시 업데이트된 task와 함께 상세 페이지로 이동
      if (mounted) {
        Navigator.of(context).pop(widget.task);
      }
    } catch (e) {
      if (mounted) {
        _showToastMessage('저장 중 오류가 발생했습니다.', Colors.red);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: _onWillPop,
      child: Stack(
        children: [
          Scaffold(
            appBar: AppBar(
              backgroundColor: Colors.transparent,
              elevation: 0,
              leading: IconButton(
                icon: const Icon(Icons.close),
                onPressed: () async {
                  if (await _onWillPop()) {
                    Navigator.of(context).pop();
                  }
                },
                color: Theme.of(context).brightness == Brightness.dark
                    ? Colors.white
                    : Colors.black,
              ),
              centerTitle: true,
              title: Text(
                '미루기 편집',
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
                                  Theme.of(context).brightness ==
                                      Brightness.dark
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
                            : Colors.white,
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
                            color:
                                Theme.of(context).brightness == Brightness.dark
                                ? Colors.white.withOpacity(0.5)
                                : Colors.black.withOpacity(0.5),
                          ),
                          border: InputBorder.none,
                          counterStyle: TextStyle(
                            color:
                                Theme.of(context).brightness == Brightness.dark
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
                            : Colors.white,
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
                            color:
                                Theme.of(context).brightness == Brightness.dark
                                ? Colors.white.withOpacity(0.5)
                                : Colors.black.withOpacity(0.5),
                          ),
                          border: InputBorder.none,
                          counterStyle: TextStyle(
                            color:
                                Theme.of(context).brightness == Brightness.dark
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
                            : const Color(0xFFF2F2F7),
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
                              : const Color(0xFFF2F2F7).withOpacity(0.5),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color:
                                Theme.of(context).brightness == Brightness.dark
                                ? const Color(0xFF3A3A3C).withOpacity(0.2)
                                : const Color(0xFFE0E0E0).withOpacity(0.5),
                            width: 0.5,
                          ),
                        ),
                        child: Text(
                          '알림 없이 간편 미루기를 등록합니다.',
                          style: TextStyle(
                            fontSize: 14,
                            color:
                                Theme.of(context).brightness == Brightness.dark
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
                              : const Color(0xFFF2F2F7),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color:
                                Theme.of(context).brightness == Brightness.dark
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
                                height: 1.2,
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
                            itemExtent: 40,
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
                            color:
                                Theme.of(context).brightness == Brightness.dark
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
      ),
    );
  }
}
