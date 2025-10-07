import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'widgets/miru_alarm_card.dart';
import '../create/create_view.dart';
import '../detail/miru_detail_view.dart';
import '../edit/miru_edit_view.dart';
import '../../../models/miru_task.dart';
import '../../../services/storage_service.dart';
import '../../../services/notification_service.dart';
import '../../../utils/logger.dart';

// 하트 애니메이션 클래스
class HeartAnimation {
  final double startX;
  final double startY;
  final double endX;
  final double endY;
  final AnimationController controller;
  final Animation<double> animation;

  HeartAnimation({
    required this.startX,
    required this.startY,
    required this.endX,
    required this.endY,
    required this.controller,
  }) : animation = Tween<double>(
         begin: 0.0,
         end: 1.0,
       ).animate(CurvedAnimation(parent: controller, curve: Curves.easeOut));

  void dispose() {
    controller.dispose();
  }
}

// Z 아이콘 애니메이션 클래스
class ZzzAnimation {
  final double startX;
  final double startY;
  final double endX;
  final double endY;
  final AnimationController controller;
  final Animation<double> animation;

  ZzzAnimation({
    required this.startX,
    required this.startY,
    required this.endX,
    required this.endY,
    required this.controller,
  }) : animation = Tween<double>(
         begin: 0.0,
         end: 1.0,
       ).animate(CurvedAnimation(parent: controller, curve: Curves.easeOut));

  void dispose() {
    controller.dispose();
  }
}

// 말풍선 꼬리를 그리는 CustomPainter
class SpeechBubblePainter extends CustomPainter {
  final bool isDarkMode;

  SpeechBubblePainter({required this.isDarkMode});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = isDarkMode ? Colors.white : const Color(0xFFF4B41F)
      ..style = PaintingStyle.fill;

    final path = Path();

    // 말풍선 본체 (둥근 사각형)
    final rect = RRect.fromRectAndRadius(
      Rect.fromLTWH(0, 0, size.width, size.height),
      const Radius.circular(16),
    );
    path.addRRect(rect);

    // 꼬리 부분 (역삼각형)
    final tailPath = Path();
    final tailStartX = size.width * 0.2; // 꼬리 시작 위치 (30% 지점)
    final tailEndX = size.width * 0.3; // 꼬리 끝 위치 (40% 지점)
    final tailY = size.height;
    final tailHeight = 6.0;

    tailPath.moveTo(tailStartX, tailY);
    tailPath.lineTo(tailEndX, tailY);
    tailPath.lineTo((tailStartX + tailEndX) / 2, tailY + tailHeight);
    tailPath.close();

    path.addPath(tailPath, Offset.zero);

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class HomeView extends StatefulWidget {
  const HomeView({super.key});

  @override
  State<HomeView> createState() => _HomeViewState();
}

class _HomeViewState extends State<HomeView> with TickerProviderStateMixin {
  List<MiruTask> _tasks = [];
  bool _isLoading = true;
  bool _isInitialLoad = true; // 초기 로드인지 확인하는 플래그
  late GlobalKey<AnimatedListState> _animatedListKey;

  // 하트 애니메이션 관련 변수들
  late AnimationController _heartAnimationController;
  final List<HeartAnimation> _hearts = [];

  // Z 아이콘 애니메이션 관련 변수들
  final List<ZzzAnimation> _zzzIcons = [];

  // 알림 시간 체크를 위한 타이머
  Timer? _notificationTimer;

  // 토스트 메시지 관련
  bool _showToast = false;
  String _toastMessage = '';
  Color _toastColor = Colors.green;
  late AnimationController _toastAnimationController;
  late Animation<double> _toastAnimation;

  @override
  void initState() {
    super.initState();
    _animatedListKey = GlobalKey<AnimatedListState>();

    // 하트 애니메이션 컨트롤러 초기화
    _heartAnimationController = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    );

    // 토스트 애니메이션 컨트롤러 초기화
    _toastAnimationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _toastAnimation = Tween<double>(begin: -1.0, end: 0.0).animate(
      CurvedAnimation(parent: _toastAnimationController, curve: Curves.easeOut),
    );

    _loadTasks();
    _startNotificationTimer();
  }

  @override
  void dispose() {
    // 모든 하트 애니메이션 정리
    for (var heart in _hearts) {
      heart.dispose();
    }
    _hearts.clear();

    // 모든 Z 아이콘 애니메이션 정리
    for (var zzzIcon in _zzzIcons) {
      zzzIcon.dispose();
    }
    _zzzIcons.clear();

    _heartAnimationController.dispose();
    _toastAnimationController.dispose();
    _notificationTimer?.cancel();
    super.dispose();
  }

  // 토스트 메시지 표시 메서드
  void _showToastMessage(String message, Color color) {
    // 이미 토스트가 표시 중이면 중복 표시하지 않음
    if (_showToast) return;

    setState(() {
      _showToast = true;
      _toastMessage = message;
      _toastColor = color;
    });

    _toastAnimationController.forward().then((_) {
      // 3초 후 토스트 숨기기 (성공 메시지는 좀 더 길게)
      Future.delayed(const Duration(seconds: 3), () {
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

  // 미루기 상세 보기 메서드
  void _showTaskDetail(MiruTask task) async {
    final result = await Navigator.of(context).push(
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) =>
            MiruDetailView(task: task),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          const begin = Offset(0.0, 1.0);
          const end = Offset.zero;
          const curve = Curves.easeInOut;

          var tween = Tween(
            begin: begin,
            end: end,
          ).chain(CurveTween(curve: curve));
          var offsetAnimation = animation.drive(tween);

          return SlideTransition(position: offsetAnimation, child: child);
        },
        transitionDuration: const Duration(milliseconds: 300),
      ),
    );

    // 상세 페이지에서 삭제나 완료 작업이 있었거나 편집이 완료되었으면 새로고침
    if (result == true ||
        result is MiruTask ||
        result == 'completed' ||
        result == 'deleted') {
      // AnimatedList를 완전히 새로고침하기 위해 키를 재생성
      _animatedListKey = GlobalKey<AnimatedListState>();
      await _loadTasks();

      // 완료 처리된 경우 토스트 메시지 표시
      if (result == 'completed') {
        _showToastMessage('미루기가 완료되었습니다! 🎉', Colors.green);
      }
      // 삭제 처리된 경우 토스트 메시지 표시
      else if (result == 'deleted') {
        _showToastMessage('미루기가 삭제되었습니다', Colors.red);
      }
    }
  }

  // 미루기 편집 메서드
  void _editTask(MiruTask task) async {
    final result = await Navigator.of(context).push(
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) =>
            MiruEditView(task: task),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          const begin = Offset(0.0, 1.0);
          const end = Offset.zero;
          const curve = Curves.easeInOut;

          var tween = Tween(
            begin: begin,
            end: end,
          ).chain(CurveTween(curve: curve));
          var offsetAnimation = animation.drive(tween);

          return SlideTransition(position: offsetAnimation, child: child);
        },
        transitionDuration: const Duration(milliseconds: 300),
      ),
    );

    // 편집 완료 후 목록 새로고침
    if (result != null) {
      // 편집이 완료된 경우에만 새로고침
      await _loadTasks();
    }
  }

  // 하트 생성 메서드
  void _createHearts() {
    if (_tasks.isNotEmpty) return; // 미루기가 있을 때는 하트 생성 안함

    final random = DateTime.now().millisecondsSinceEpoch;
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    // 3-5개의 하트 생성
    final heartCount = 3 + (random % 3);

    for (int i = 0; i < heartCount; i++) {
      final controller = AnimationController(
        duration: Duration(milliseconds: 1500 + (random % 500)),
        vsync: this,
      );

      final heart = HeartAnimation(
        startX: (screenWidth * 0.3) + (random % (screenWidth * 0.4).toInt()),
        startY: screenHeight * 0.35,
        endX: (screenWidth * 0.2) + (random % (screenWidth * 0.6).toInt()),
        endY: -100,
        controller: controller,
      );

      _hearts.add(heart);

      // 애니메이션 완료 후 하트 제거
      controller.addStatusListener((status) {
        if (status == AnimationStatus.completed) {
          setState(() {
            _hearts.remove(heart);
          });
          heart.dispose();
        }
      });

      controller.forward();
    }

    setState(() {});
  }

  // Z 아이콘 생성 메서드
  void _createZzzIcons() {
    if (_tasks.isEmpty) return; // 미루기가 없을 때는 Z 아이콘 생성 안함

    final random = DateTime.now().millisecondsSinceEpoch;
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    // 2-4개의 Z 아이콘 생성
    final zzzCount = 2 + (random % 3);

    for (int i = 0; i < zzzCount; i++) {
      final controller = AnimationController(
        duration: Duration(milliseconds: 2000 + (random % 1000)),
        vsync: this,
      );

      final zzzIcon = ZzzAnimation(
        startX: (screenWidth * 0.3) + (random % (screenWidth * 0.4).toInt()),
        startY: screenHeight * 0.35,
        endX: (screenWidth * 0.2) + (random % (screenWidth * 0.6).toInt()),
        endY: -100,
        controller: controller,
      );

      _zzzIcons.add(zzzIcon);

      // 애니메이션 완료 후 Z 아이콘 제거
      controller.addStatusListener((status) {
        if (status == AnimationStatus.completed) {
          setState(() {
            _zzzIcons.remove(zzzIcon);
          });
          zzzIcon.dispose();
        }
      });

      controller.forward();
    }

    setState(() {});
  }

  // 알림 시간 체크 타이머 시작
  void _startNotificationTimer() {
    _notificationTimer = Timer.periodic(const Duration(seconds: 10), (timer) {
      _checkNotificationStatus();
    });
  }

  // 알림 시간 상태 체크 및 UI 업데이트
  void _checkNotificationStatus() async {
    // 초기 로드 중에는 상태 체크하지 않음
    if (_isInitialLoad) return;

    bool needsUpdate = false;
    final storageService = await StorageService.getInstance();
    final notificationService = NotificationService();

    for (var task in _tasks) {
      if (task.hasNotification &&
          task.notificationTime != null &&
          !task.isCompleted &&
          task.isEnabled) {
        final now = DateTime.now();
        if (task.notificationTime!.isBefore(now)) {
          // 알림 시간이 지났으면 토글을 Off로 변경 (완료 처리하지 않음)
          task.isEnabled = false;
          await notificationService.cancelNotification(task.id);
          await storageService.updateTask(task);
          needsUpdate = true;
        }
      }
    }

    if (needsUpdate) {
      _sortTasks();
      setState(() {});
    }
  }

  // 작업 정렬 메서드
  void _sortTasks() {
    _tasks.sort((a, b) {
      // 1. 알림 없음 우선
      if (a.status == MiruTaskStatus.noNotification &&
          b.status != MiruTaskStatus.noNotification) {
        return -1;
      }
      if (a.status != MiruTaskStatus.noNotification &&
          b.status == MiruTaskStatus.noNotification) {
        return 1;
      }

      // 2. 알림 완료 우선 (알림 없음 다음)
      if (a.status == MiruTaskStatus.notificationCompleted &&
          b.status != MiruTaskStatus.notificationCompleted) {
        return -1;
      }
      if (a.status != MiruTaskStatus.notificationCompleted &&
          b.status == MiruTaskStatus.notificationCompleted) {
        return 1;
      }

      // 3. 알림 시각이 가까운 순 (알림 예정된 것들과 일시정지된 것들)
      if ((a.status == MiruTaskStatus.notificationScheduled ||
              a.status == MiruTaskStatus.notificationPaused) &&
          (b.status == MiruTaskStatus.notificationScheduled ||
              b.status == MiruTaskStatus.notificationPaused) &&
          a.notificationTime != null &&
          b.notificationTime != null) {
        return a.notificationTime!.compareTo(b.notificationTime!);
      }

      // 4. 생성 시간 순
      return a.createdAt.compareTo(b.createdAt);
    });
  }

  Future<void> _loadTasks() async {
    try {
      final storageService = await StorageService.getInstance();
      final allTasks = await storageService.getTasks();

      // 완료되지 않은 작업만 필터링
      final incompleteTasks = allTasks
          .where((task) => !task.isCompleted)
          .toList();

      // 이전 작업 수 저장
      final previousTaskCount = _tasks.length;

      // 정렬 적용
      _tasks = incompleteTasks;
      _sortTasks();

      // 초기 로드 시에는 애니메이션 없이 바로 설정
      if (_isInitialLoad) {
        // 초기 로드 시에는 데이터 로드 완료 후 한 번에 UI 업데이트
        setState(() {
          _isLoading = false;
          _isInitialLoad = false; // 초기 로드 완료
        });
      } else {
        // 작업 수가 변경된 경우 AnimatedList를 완전히 새로고침
        if (previousTaskCount != _tasks.length) {
          // AnimatedList 키를 재생성하여 완전히 새로고침
          _animatedListKey = GlobalKey<AnimatedListState>();
        } else {
          // 새로 추가된 아이템들에 대해 애니메이션 추가
          for (int i = previousTaskCount; i < _tasks.length; i++) {
            _animatedListKey.currentState?.insertItem(i);
          }
        }

        setState(() {
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _deleteTask(String taskId) async {
    try {
      final storageService = await StorageService.getInstance();
      final notificationService = NotificationService();

      // 삭제할 아이템의 인덱스 찾기
      final index = _tasks.indexWhere((task) => task.id == taskId);
      if (index == -1) return;

      // 알림 취소
      await notificationService.cancelNotification(taskId);

      // 저장소에서 삭제
      await storageService.deleteTask(taskId);

      // 애니메이션과 함께 리스트에서 제거
      final removedTask = _tasks.removeAt(index);
      _animatedListKey.currentState?.removeItem(
        index,
        (context, animation) =>
            _buildAnimatedItem(removedTask, animation, index),
        duration: const Duration(milliseconds: 200),
      );

      // UI 즉시 업데이트 (텍스트, 이미지, 말풍선 반영)
      setState(() {});

      // 삭제 성공 토스트 메시지 표시
      _showToastMessage('미루기가 삭제되었습니다', Colors.red);
    } catch (e) {
      // 작업 삭제 실패 시 사용자에게 알림
      _showToastMessage('작업 삭제 중 오류가 발생했습니다.', Colors.red);
    }
  }

  Future<void> _completeTask(MiruTask task) async {
    try {
      // 완료할 아이템의 인덱스 찾기
      final index = _tasks.indexWhere((t) => t.id == task.id);
      if (index == -1) return;

      // 작업 완료 처리
      task.isCompleted = true;
      task.isEnabled = false;
      task.completedAt = DateTime.now(); // 완료 처리 시점 기록

      // 알림 취소
      final notificationService = NotificationService();
      await notificationService.cancelNotification(task.id);

      // 저장소에 업데이트
      final storageService = await StorageService.getInstance();
      await storageService.updateTask(task);

      // 애니메이션과 함께 리스트에서 제거
      final completedTask = _tasks.removeAt(index);
      _animatedListKey.currentState?.removeItem(
        index,
        (context, animation) =>
            _buildAnimatedItem(completedTask, animation, index),
        duration: const Duration(milliseconds: 300),
      );

      // UI 즉시 업데이트
      setState(() {});

      // 완료 토스트 메시지 표시
      _showToastMessage('미루기가 완료되었습니다! 🎉', Colors.green);

      // 사용자 액션 로깅
      Logger.userAction(
        'Task completed',
        data: {
          'taskId': task.id,
          'title': task.title,
          'completionTime': DateTime.now().toIso8601String(),
        },
      );
    } catch (e) {
      _showToastMessage('작업 완료 중 오류가 발생했습니다.', Colors.red);
    }
  }

  Future<void> _toggleTaskNotification(MiruTask task) async {
    try {
      final storageService = await StorageService.getInstance();
      final notificationService = NotificationService();

      // 상태에 따른 토글 처리
      switch (task.status) {
        case MiruTaskStatus.noNotification:
          // 시간 설정 모달 표시 (토글 상태는 임시로 변경하지 않음)
          _showTimeSettingModal(task);
          return;

        case MiruTaskStatus.notificationScheduled:
          // 토글 off (일시정지)
          task.isEnabled = false;
          await notificationService.cancelNotification(task.id);
          break;

        case MiruTaskStatus.notificationPaused:
          // 토글 on (재개) - 알림 설정이 활성화되어 있을 때만
          task.isEnabled = true;
          if (task.notificationTime != null &&
              notificationService.isNotificationEnabled) {
            await notificationService.scheduleNotification(task);
          }
          break;

        case MiruTaskStatus.notificationCompleted:
          // 알림 완료 상태에서 토글 On 시 시간 설정 모달 표시
          _showTimeSettingModal(task);
          return;
      }

      // 저장소에 업데이트
      await storageService.updateTask(task);

      // 리스트 새로고침으로 정렬 반영
      await _loadTasks();

      // 사용자 액션 로깅
      Logger.userAction(
        'Task notification toggled',
        data: {
          'taskId': task.id,
          'title': task.title,
          'enabled': task.isEnabled,
          'toggleTime': DateTime.now().toIso8601String(),
        },
      );
    } catch (e) {
      // 알림 토글 실패 시 사용자에게 알림
      _showToastMessage('알림 설정 변경 중 오류가 발생했습니다.', Colors.red);
    }
  }

  // 시간 설정 모달 표시
  void _showTimeSettingModal(MiruTask task) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => TimeSettingModal(
        task: task,
        onTimeSet: (DateTime newTime) async {
          // 새로운 시간으로 업데이트 (저장을 눌렀을 때만 토글 On)
          task.notificationTime = newTime;
          task.hasNotification = true; // 알림 설정 활성화
          task.isEnabled = true;
          task.isCompleted = false; // 시간 재설정 시 완료 상태 초기화
          task.completedAt = null; // 완료 시간도 초기화

          final storageService = await StorageService.getInstance();
          await storageService.updateTask(task);

          final notificationService = NotificationService();
          if (notificationService.isNotificationEnabled) {
            await notificationService.scheduleNotification(task);
          }

          await _loadTasks();
        },
      ),
    );
  }

  Widget _buildAnimatedItem(
    MiruTask task,
    Animation<double> animation,
    int index,
  ) {
    return SizeTransition(
      sizeFactor: animation,
      child: FadeTransition(
        opacity: animation,
        child: Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: MiruAlarmCard(
            key: ValueKey(task.id),
            title: task.title,
            content: task.memo,
            deadline: task.getTimeUntilNotification(),
            isEnabled: task.isEnabled,
            needsStrikethrough: task.needsStrikethrough,
            requiresTimeModal: task.status == MiruTaskStatus.noNotification,
            onToggle: () {
              _toggleTaskNotification(task);
            },
            onDelete: () {
              _deleteTask(task.id);
            },
            onComplete: () {
              _completeTask(task);
            },
            onEdit: () {
              _editTask(task);
            },
            onTap: () {
              _showTaskDetail(task);
            },
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    final imageHeight = screenHeight / 3.5;

    return Stack(
      children: [
        Scaffold(
          floatingActionButton: Container(
            margin: const EdgeInsets.only(right: 8),
            width: 48,
            height: 48,
            decoration: const BoxDecoration(
              color: Colors.red,
              shape: BoxShape.circle,
            ),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                borderRadius: BorderRadius.circular(24),
                onTap: () async {
                  final result = await Navigator.of(context).push(
                    PageRouteBuilder(
                      pageBuilder: (context, animation, secondaryAnimation) =>
                          const CreateView(),
                      transitionsBuilder:
                          (context, animation, secondaryAnimation, child) {
                            const begin = Offset(0.0, 1.0);
                            const end = Offset.zero;
                            const curve = Curves.easeInOut;

                            var tween = Tween(
                              begin: begin,
                              end: end,
                            ).chain(CurveTween(curve: curve));

                            return SlideTransition(
                              position: animation.drive(tween),
                              child: child,
                            );
                          },
                      transitionDuration: const Duration(milliseconds: 300),
                    ),
                  );

                  // CreateView에서 돌아온 후 목록 새로고침
                  await _loadTasks();

                  // 등록 성공 시 토스트 메시지 표시
                  if (result == true) {
                    // 화면이 완전히 렌더링된 후 토스트 표시
                    WidgetsBinding.instance.addPostFrameCallback((_) {
                      _showToastMessage('미루기가 등록되었습니다!', Colors.green);
                    });
                  }
                },
                child: const Center(
                  child: Icon(Icons.add, color: Colors.white, size: 32),
                ),
              ),
            ),
          ),
          floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
          body: Stack(
            children: [
              SafeArea(
                child: Column(
                  children: [
                    // 상단 이미지 영역 (화면 높이의 1/3, 너비 full)
                    Container(
                      height: imageHeight,
                      width: double.infinity,
                      margin: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: Theme.of(context).brightness == Brightness.dark
                            ? null // 다크모드에서는 그라데이션 사용
                            : const Color(0xFFF7FAFC), // 라이트모드에서는 pale slate 배경
                        gradient:
                            Theme.of(context).brightness == Brightness.dark
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
                        child: Stack(
                          alignment: Alignment.center,
                          children: [
                            // 미루 이미지
                            GestureDetector(
                              onTap: () {
                                if (_tasks.isEmpty) {
                                  _createHearts();
                                } else {
                                  _createZzzIcons();
                                }
                              },
                              child: Image.asset(
                                (_isLoading || _tasks.isEmpty)
                                    ? 'assets/images/miru_standing.png'
                                    : 'assets/images/miru_lazy.png',
                                fit: BoxFit.contain,
                                errorBuilder: (context, error, stackTrace) {
                                  return Container(
                                    decoration: BoxDecoration(
                                      color: Theme.of(
                                        context,
                                      ).colorScheme.surface,
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
                            // 말풍선
                            Positioned(
                              top: 25,
                              child: CustomPaint(
                                painter: SpeechBubblePainter(
                                  isDarkMode:
                                      Theme.of(context).brightness ==
                                      Brightness.dark,
                                ),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 8,
                                  ),
                                  child: Text(
                                    _tasks.isEmpty
                                        ? '아직 미룬 일이 하나도 없어!'
                                        : '벌써 ${_tasks.length}개나 할 일이 밀렸어...',
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w500,
                                      color:
                                          Theme.of(context).brightness ==
                                              Brightness.dark
                                          ? Colors.black87
                                          : Colors.grey[800],
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    // 나머지 콘텐츠 영역
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // 예정된 미루기 라벨
                            Padding(
                              padding: const EdgeInsets.only(
                                left: 4,
                                top: 20,
                                bottom: 16,
                              ),
                              child: Text(
                                _tasks.isEmpty
                                    ? '예정된 미루기 없음'
                                    : '${_tasks.length}개의 일정을 미루는 중',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w800,
                                  color:
                                      Theme.of(context).brightness ==
                                          Brightness.dark
                                      ? Colors.white
                                      : Colors.black,
                                ),
                              ),
                            ),
                            // 미루기 알람 카드들
                            Expanded(
                              child: _isLoading
                                  ? const Center(
                                      child: CircularProgressIndicator(),
                                    )
                                  : _tasks.isEmpty
                                  ? Center(
                                      child: Text(
                                        '아직 등록된 미루기가 없습니다.\n+ 버튼을 눌러 미루기를 등록해보세요!',
                                        textAlign: TextAlign.center,
                                        style: TextStyle(
                                          fontSize: 16,
                                          color:
                                              Theme.of(context).brightness ==
                                                  Brightness.dark
                                              ? Colors.white.withOpacity(0.6)
                                              : Colors.black.withOpacity(0.6),
                                        ),
                                      ),
                                    )
                                  : AnimatedList(
                                      key: _animatedListKey,
                                      padding: const EdgeInsets.only(
                                        bottom:
                                            132, // 플로팅 버튼을 위한 여백 + 마지막 아이템 여백
                                      ),
                                      initialItemCount: _tasks.length,
                                      itemBuilder: (context, index, animation) {
                                        final task = _tasks[index];
                                        return _buildAnimatedItem(
                                          task,
                                          animation,
                                          index,
                                        );
                                      },
                                    ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              // 하트 애니메이션
              ..._hearts.map(
                (HeartAnimation heart) => AnimatedBuilder(
                  animation: heart.animation,
                  builder: (context, child) {
                    final progress = heart.animation.value;
                    final currentX =
                        heart.startX + (heart.endX - heart.startX) * progress;
                    final currentY =
                        heart.startY + (heart.endY - heart.startY) * progress;
                    final opacity = 1.0 - progress;
                    final scale = 0.5 + (0.5 * progress);

                    return Positioned(
                      left: currentX,
                      top: currentY,
                      child: Opacity(
                        opacity: opacity,
                        child: Transform.scale(
                          scale: scale,
                          child: const Icon(
                            Icons.favorite,
                            color: Colors.red,
                            size: 36,
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
              // Z 아이콘 애니메이션
              ..._zzzIcons.map(
                (ZzzAnimation zzzIcon) => AnimatedBuilder(
                  animation: zzzIcon.animation,
                  builder: (context, child) {
                    final progress = zzzIcon.animation.value;
                    final currentX =
                        zzzIcon.startX +
                        (zzzIcon.endX - zzzIcon.startX) * progress;
                    final currentY =
                        zzzIcon.startY +
                        (zzzIcon.endY - zzzIcon.startY) * progress;
                    final opacity = 1.0 - progress;
                    final scale = 0.3 + (0.7 * progress);

                    return Positioned(
                      left: currentX,
                      top: currentY,
                      child: Opacity(
                        opacity: opacity,
                        child: Transform.scale(
                          scale: scale,
                          child: Transform.rotate(
                            angle: -0.262, // -15도 (라디안)
                            child: const Text(
                              'Z',
                              style: TextStyle(
                                fontSize: 32,
                                fontWeight: FontWeight.bold,
                                color: Colors.blue,
                                shadows: [
                                  Shadow(
                                    offset: Offset(1, 1),
                                    blurRadius: 2,
                                    color: Colors.black26,
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
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

// 시간 설정 모달 위젯
class TimeSettingModal extends StatefulWidget {
  final MiruTask task;
  final Function(DateTime) onTimeSet;

  const TimeSettingModal({
    super.key,
    required this.task,
    required this.onTimeSet,
  });

  @override
  State<TimeSettingModal> createState() => _TimeSettingModalState();
}

class _TimeSettingModalState extends State<TimeSettingModal> {
  late DateTime _selectedTime;

  @override
  void initState() {
    super.initState();
    _selectedTime = widget.task.notificationTime ?? DateTime.now();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.7,
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
          // 상단 바
          Container(
            padding: const EdgeInsets.fromLTRB(8, 8, 8, 0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // 좌측 X 버튼
                IconButton(
                  onPressed: () => Navigator.of(context).pop(),
                  icon: const Icon(Icons.close),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
                // 가운데 제목
                const Text(
                  '알림 시간 설정',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600),
                ),
                // 우측 빈 공간 (균형 맞추기)
                const SizedBox(width: 48, height: 0),
              ],
            ),
          ),
          const Divider(color: Colors.grey, thickness: 0.5),

          // 시간 선택기
          Expanded(
            child: CupertinoTheme(
              data: CupertinoThemeData(
                textTheme: CupertinoTextThemeData(
                  dateTimePickerTextStyle: TextStyle(
                    fontSize: 20,
                    color: Theme.of(context).brightness == Brightness.dark
                        ? Colors.white
                        : Colors.black,
                  ),
                ),
              ),
              child: CupertinoDatePicker(
                mode: CupertinoDatePickerMode.time,
                initialDateTime: _selectedTime,
                onDateTimeChanged: (DateTime newTime) {
                  setState(() {
                    _selectedTime = newTime;
                  });
                },
              ),
            ),
          ),

          // 저장 버튼
          Container(
            width: double.infinity,
            margin: const EdgeInsets.fromLTRB(16, 16, 16, 48),
            child: ElevatedButton(
              onPressed: () {
                // 오늘 날짜와 선택된 시간을 결합하여 정확한 DateTime 생성
                final now = DateTime.now();
                final exactTime = DateTime(
                  now.year,
                  now.month,
                  now.day,
                  _selectedTime.hour,
                  _selectedTime.minute,
                  0, // 초는 0으로 설정 (정각)
                  0, // 밀리초는 0으로 설정
                );

                // 현재 시간과 같거나 이전이면 1분 후로 설정 (편의 기능)
                final nowNormalized = DateTime(
                  now.year,
                  now.month,
                  now.day,
                  now.hour,
                  now.minute,
                  0, // 초는 0으로 정규화
                  0, // 밀리초는 0으로 정규화
                );

                if (exactTime.isAtSameMomentAs(nowNormalized) ||
                    exactTime.isBefore(nowNormalized)) {
                  // 현재 시간과 같거나 과거면 다음날 같은 시각으로 롤오버
                  final nextDayTime = exactTime.add(const Duration(days: 1));
                  widget.onTimeSet(nextDayTime);
                } else {
                  widget.onTimeSet(exactTime);
                }

                Navigator.of(context).pop();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: const Text(
                '저장',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
