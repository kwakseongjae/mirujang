import 'package:flutter/material.dart';
import '../../../models/miru_task.dart';
import '../../../services/storage_service.dart';
import '../../../services/notification_service.dart';
import '../../../utils/logger.dart';
import '../edit/miru_edit_view.dart';
import '../../widgets/delete_confirmation_dialog.dart';

class MiruDetailView extends StatefulWidget {
  final MiruTask task;

  const MiruDetailView({super.key, required this.task});

  @override
  State<MiruDetailView> createState() => _MiruDetailViewState();
}

class _MiruDetailViewState extends State<MiruDetailView> {
  late MiruTask _currentTask;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _currentTask = widget.task;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios),
          onPressed: () => Navigator.of(context).pop(_currentTask),
          color: Theme.of(context).brightness == Brightness.dark
              ? Colors.white
              : Colors.black,
        ),
        centerTitle: true,
        title: Text(
          '미루기 일정',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: Theme.of(context).brightness == Brightness.dark
                ? Colors.white
                : Colors.black,
          ),
        ),
        actions: [
          // 완료된 작업이 아닐 때만 편집 버튼 표시
          if (!_currentTask.isCompleted)
            TextButton(
              onPressed: () async {
                final result = await Navigator.of(context).push(
                  PageRouteBuilder(
                    pageBuilder: (context, animation, secondaryAnimation) =>
                        MiruEditView(task: _currentTask),
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

                // 편집 완료 후 현재 페이지 새로고침
                if (result != null) {
                  setState(() {
                    // 편집된 내용을 현재 페이지에 반영
                    _currentTask = result; // 업데이트된 task 사용
                  });
                }
              },
              child: Text(
                '편집',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Theme.of(context).brightness == Brightness.dark
                      ? Colors.white
                      : Colors.black,
                ),
              ),
            ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            // 메인 콘텐츠
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // 제목 섹션
                    _buildSection(
                      context,
                      '제목',
                      _currentTask.title,
                      isRequired: true,
                    ),
                    const SizedBox(height: 24),

                    // 메모 섹션
                    if (_currentTask.memo.isNotEmpty) ...[
                      _buildSection(
                        context,
                        '메모',
                        _currentTask.memo,
                        isRequired: false,
                      ),
                      const SizedBox(height: 24),
                    ],

                    // 알림 설정 섹션 (완료된 작업이 아닐 때만 표시)
                    if (!_currentTask.isCompleted) ...[
                      _buildNotificationSection(context),
                    ],

                    // 하단 여백 (버튼과 겹치지 않도록)
                    const SizedBox(height: 100),
                  ],
                ),
              ),
            ),

            // 하단 액션 버튼들
            _buildActionButtons(context),
          ],
        ),
      ),
    );
  }

  Widget _buildSection(
    BuildContext context,
    String label,
    String content, {
    required bool isRequired,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 라벨
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 8),
          child: Row(
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: Theme.of(context).brightness == Brightness.dark
                      ? Colors.white
                      : Colors.black,
                ),
              ),
              if (isRequired) ...[
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
            ],
          ),
        ),
        // 내용
        Container(
          width: double.infinity,
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
          child: Text(
            content,
            style: TextStyle(
              fontSize: 16,
              color: Theme.of(context).brightness == Brightness.dark
                  ? Colors.white
                  : Colors.black,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildNotificationSection(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 알림 설정 라벨
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 8),
          child: Text(
            '알림 설정',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Theme.of(context).brightness == Brightness.dark
                  ? Colors.white
                  : Colors.black,
            ),
          ),
        ),

        // 알림 설정 내용
        Container(
          width: double.infinity,
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
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 알림 상태
              Row(
                children: [
                  Icon(
                    _currentTask.hasNotification
                        ? Icons.notifications
                        : Icons.notifications_off,
                    size: 20,
                    color: _currentTask.hasNotification
                        ? Colors.green
                        : Colors.grey,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    _currentTask.hasNotification ? '알림 받기' : '알림 안받기',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      color: Theme.of(context).brightness == Brightness.dark
                          ? Colors.white
                          : Colors.black,
                    ),
                  ),
                ],
              ),

              // 알림 시간 정보 (완료된 작업이 아닐 때만 표시)
              if (!_currentTask.isCompleted &&
                  _currentTask.hasNotification &&
                  _currentTask.notificationTime != null) ...[
                const SizedBox(height: 12),
                Text(
                  '알림 시간: ${_formatTime(_currentTask.notificationTime!)}',
                  style: TextStyle(
                    fontSize: 14,
                    color: Theme.of(context).brightness == Brightness.dark
                        ? Colors.white.withOpacity(0.7)
                        : Colors.black.withOpacity(0.7),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  _currentTask.getTimeUntilNotification(),
                  style: TextStyle(
                    fontSize: 14,
                    color: Theme.of(context).brightness == Brightness.dark
                        ? Colors.white.withOpacity(0.7)
                        : Colors.black.withOpacity(0.7),
                  ),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }

  String _formatTime(DateTime dateTime) {
    final hour = dateTime.hour.toString().padLeft(2, '0');
    final minute = dateTime.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }

  // 하단 액션 버튼들
  Widget _buildActionButtons(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(),
      child: SafeArea(
        child: Row(
          children: [
            // 삭제 버튼
            Expanded(child: _buildDeleteButton(context)),
            const SizedBox(width: 12),
            // 완료 버튼 (완료되지 않은 작업일 때만 표시)
            if (!_currentTask.isCompleted)
              Expanded(child: _buildCompleteButton(context)),
          ],
        ),
      ),
    );
  }

  // 삭제 버튼
  Widget _buildDeleteButton(BuildContext context) {
    return OutlinedButton(
      onPressed: _isLoading ? null : _handleDelete,
      style: OutlinedButton.styleFrom(
        foregroundColor: const Color(0xFFFF3B30), // Apple 스타일 빨간색
        side: const BorderSide(color: Color(0xFFFF3B30), width: 2),
        padding: const EdgeInsets.symmetric(vertical: 16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        backgroundColor: Colors.transparent,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.delete_outline, size: 20),
          const SizedBox(width: 8),
          Text(
            '삭제',
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }

  // 완료 버튼
  Widget _buildCompleteButton(BuildContext context) {
    return OutlinedButton(
      onPressed: _isLoading ? null : _handleComplete,
      style: OutlinedButton.styleFrom(
        foregroundColor: const Color(0xFF34C759), // Apple 스타일 초록색
        side: const BorderSide(color: Color(0xFF34C759), width: 2),
        padding: const EdgeInsets.symmetric(vertical: 16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        backgroundColor: Colors.transparent,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.check_circle_outline, size: 20),
          const SizedBox(width: 8),
          Text(
            '완료',
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }

  // 삭제 처리
  Future<void> _handleDelete() async {
    // 삭제 확인 다이얼로그 표시
    final confirmed = await DeleteConfirmationDialog.show(context);
    if (confirmed != true) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final storageService = await StorageService.getInstance();
      final notificationService = NotificationService();

      // 알림 취소
      await notificationService.cancelNotification(_currentTask.id);

      // 저장소에서 삭제
      await storageService.deleteTask(_currentTask.id);

      // 이전 화면으로 돌아가기 (삭제됨을 알림)
      if (mounted) {
        Navigator.of(
          context,
        ).pop('deleted'); // 'deleted'를 반환하여 이전 화면에서 새로고침 및 토스트 표시
      }

      // 사용자 액션 로깅
      Logger.userAction(
        'Task deleted from detail view',
        data: {
          'taskId': _currentTask.id,
          'title': _currentTask.title,
          'deletionTime': DateTime.now().toIso8601String(),
        },
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('삭제 중 오류가 발생했습니다'),
            backgroundColor: const Color(0xFFFF3B30),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  // 완료 처리
  Future<void> _handleComplete() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final storageService = await StorageService.getInstance();
      final notificationService = NotificationService();

      // 작업 완료 처리
      _currentTask.isCompleted = true;
      _currentTask.isEnabled = false;
      _currentTask.completedAt = DateTime.now(); // 완료 처리 시점 기록

      // 알림 취소
      await notificationService.cancelNotification(_currentTask.id);

      // 저장소에 업데이트
      await storageService.updateTask(_currentTask);

      // 홈 화면으로 돌아가기 (토스트는 홈 화면에서 표시)
      if (mounted) {
        Navigator.of(context).pop('completed'); // 완료 상태를 반환하여 홈 화면에서 토스트 표시
      }

      // 사용자 액션 로깅
      Logger.userAction(
        'Task completed from detail view',
        data: {
          'taskId': _currentTask.id,
          'title': _currentTask.title,
          'completionTime': DateTime.now().toIso8601String(),
        },
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('완료 처리 중 오류가 발생했습니다'),
            backgroundColor: const Color(0xFFFF3B30),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }
}
