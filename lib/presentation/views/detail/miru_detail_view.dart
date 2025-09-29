import 'package:flutter/material.dart';
import '../../../models/miru_task.dart';
import '../edit/miru_edit_view.dart';

class MiruDetailView extends StatefulWidget {
  final MiruTask task;

  const MiruDetailView({super.key, required this.task});

  @override
  State<MiruDetailView> createState() => _MiruDetailViewState();
}

class _MiruDetailViewState extends State<MiruDetailView> {
  late MiruTask _currentTask;

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
          onPressed: () => Navigator.of(context).pop(),
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

              // 알림 설정 섹션
              _buildNotificationSection(context),
            ],
          ),
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
                : Colors.white,
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
                : Colors.white,
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

              // 알림 시간 정보
              if (_currentTask.hasNotification &&
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
}
