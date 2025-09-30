import 'package:flutter/material.dart';

class MiruHistoryCard extends StatelessWidget {
  final String title;
  final String content;
  final String deadline;
  final VoidCallback? onTap;
  final bool isSelectionMode;
  final bool isSelected;
  final VoidCallback? onSelectionChanged;

  const MiruHistoryCard({
    super.key,
    required this.title,
    required this.content,
    required this.deadline,
    this.onTap,
    this.isSelectionMode = false,
    this.isSelected = false,
    this.onSelectionChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      height: 80,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Theme.of(context).brightness == Brightness.dark
            ? const Color(0xFF1E1E1E)
            : const Color(0xFFF7FAFC), // 라이트모드에서는 pale slate 배경
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Theme.of(context).brightness == Brightness.dark
              ? const Color(0xFF3A3A3C).withOpacity(0.3)
              : const Color(0xFFE0E0E0).withOpacity(0.8),
          width: 0.5,
        ),
      ),
      child: InkWell(
        onTap: isSelectionMode ? onSelectionChanged : onTap,
        borderRadius: BorderRadius.circular(12),
        child: Row(
          children: [
            // 좌측: 체크박스 또는 미루기 내용
            if (isSelectionMode) ...[
              // 선택 모드일 때 체크박스
              Container(
                width: 24,
                height: 24,
                decoration: BoxDecoration(
                  color: isSelected ? Colors.red : Colors.transparent,
                  border: Border.all(
                    color: isSelected ? Colors.red : Colors.grey,
                    width: 2,
                  ),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: isSelected
                    ? const Icon(Icons.check, color: Colors.white, size: 16)
                    : null,
              ),
              const SizedBox(width: 12),
            ],
            // 미루기 내용과 마감일
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                mainAxisSize: MainAxisSize.min,
                children: [
                  // 미루기 타이틀 (1줄로 truncate)
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: Theme.of(context).colorScheme.onSurface,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  // 마감일
                  Text(
                    deadline,
                    style: TextStyle(
                      fontSize: 15,
                      color: Theme.of(
                        context,
                      ).colorScheme.onSurface.withOpacity(0.6),
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            // 우측: 완료 아이콘 (선택 모드가 아닐 때만)
            if (!isSelectionMode)
              const Icon(Icons.check_circle, color: Colors.green, size: 24),
          ],
        ),
      ),
    );
  }
}
