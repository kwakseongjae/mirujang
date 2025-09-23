import 'package:flutter/material.dart';
import 'widgets/miru_alarm_card.dart';

class HomeView extends StatelessWidget {
  const HomeView({super.key});

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    final imageHeight = screenHeight / 3;

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            // 상단 이미지 영역 (화면 높이의 1/3, 너비 full)
            Container(
              height: imageHeight,
              width: double.infinity,
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: Theme.of(context).brightness == Brightness.dark
                    ? null // 다크모드에서는 그라데이션 사용
                    : Colors.white, // 라이트모드에서는 하얀색 배경
                gradient: Theme.of(context).brightness == Brightness.dark
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
                child: Image.asset(
                  'assets/images/miru_lazy.png',
                  fit: BoxFit.contain,
                  errorBuilder: (context, error, stackTrace) {
                    return Container(
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.surface,
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
            ),
            // 나머지 콘텐츠 영역
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // 예정된 미루기 없음 라벨
                    Padding(
                      padding: const EdgeInsets.only(
                        left: 4,
                        top: 20,
                        bottom: 16,
                      ),
                      child: Text(
                        '예정된 미루기 없음',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                          color: Theme.of(context).brightness == Brightness.dark
                              ? Colors.white
                              : Colors.black,
                        ),
                      ),
                    ),
                    // 미루기 알람 카드들
                    Expanded(
                      child: Column(
                        children: [
                          MiruAlarmCard(
                            content: '프로젝트 문서 작성',
                            deadline: '내일까지',
                            isEnabled: true,
                            onToggle: () {
                              // 토글 로직
                            },
                            onDelete: () {
                              // 삭제 로직
                            },
                          ),
                          const SizedBox(height: 12),
                          MiruAlarmCard(
                            content: '운동하기',
                            deadline: '이번 주까지',
                            isEnabled: false,
                            onToggle: () {
                              // 토글 로직
                            },
                            onDelete: () {
                              // 삭제 로직
                            },
                          ),
                          const SizedBox(height: 12),
                          MiruAlarmCard(
                            content: '책 읽기',
                            deadline: '다음 주까지',
                            isEnabled: true,
                            onToggle: () {
                              // 토글 로직
                            },
                            onDelete: () {
                              // 삭제 로직
                            },
                          ),
                        ],
                      ),
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
}
