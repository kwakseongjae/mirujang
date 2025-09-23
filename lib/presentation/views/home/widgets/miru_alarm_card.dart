import 'package:flutter/material.dart';

class MiruAlarmCard extends StatefulWidget {
  final String content;
  final String deadline;
  final bool isEnabled;
  final VoidCallback? onToggle;
  final VoidCallback? onDelete;

  const MiruAlarmCard({
    super.key,
    required this.content,
    required this.deadline,
    required this.isEnabled,
    this.onToggle,
    this.onDelete,
  });

  @override
  State<MiruAlarmCard> createState() => _MiruAlarmCardState();
}

class _MiruAlarmCardState extends State<MiruAlarmCard>
    with TickerProviderStateMixin {
  late AnimationController _toggleAnimationController;
  late AnimationController _springAnimationController;
  late Animation<double> _toggleAnimation;
  late Animation<double> _springAnimation;
  bool _isToggled = false;

  // 스와이프 관련 변수들
  double _dragOffset = 0.0;
  static const double _deleteButtonWidth = 80.0; // 휴지통 컨테이너 너비
  static const double _threshold = 40.0; // 자동 완료 임계값

  @override
  void initState() {
    super.initState();
    _isToggled = widget.isEnabled;

    // 토글 애니메이션 컨트롤러
    _toggleAnimationController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );
    _toggleAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _toggleAnimationController,
        curve: Curves.easeInOut,
      ),
    );

    // 스프링 애니메이션 컨트롤러
    _springAnimationController = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );
    _springAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _springAnimationController,
        curve: Curves.elasticOut,
      ),
    );

    if (_isToggled) {
      _toggleAnimationController.value = 1.0;
    }
  }

  @override
  void dispose() {
    _toggleAnimationController.dispose();
    _springAnimationController.dispose();
    super.dispose();
  }

  void _handleToggle() {
    setState(() {
      _isToggled = !_isToggled;
    });

    if (_isToggled) {
      _toggleAnimationController.forward();
    } else {
      _toggleAnimationController.reverse();
    }

    widget.onToggle?.call();
  }

  void _handleDragStart(DragStartDetails details) {
    // 드래그 시작 시 애니메이션 정지
  }

  void _handleDragUpdate(DragUpdateDetails details) {
    setState(() {
      // 왼쪽으로 드래그할 때만 음수 값, 오른쪽으로는 0 이상으로 제한
      _dragOffset = (_dragOffset + details.delta.dx).clamp(
        -_deleteButtonWidth,
        0.0,
      );
    });
  }

  void _handleDragEnd(DragEndDetails details) {
    // 드래그 속도와 위치를 고려한 자동 완료 로직
    final velocity = details.velocity.pixelsPerSecond.dx;
    final shouldComplete = _dragOffset.abs() > _threshold || velocity < -500;

    if (shouldComplete) {
      // 완전히 열림 - 스프링 애니메이션 적용
      setState(() {
        _dragOffset = -_deleteButtonWidth;
      });
      _springAnimationController.forward();
    } else {
      // 원래 위치로 복원 - 스프링 애니메이션 적용
      setState(() {
        _dragOffset = 0.0;
      });
      _springAnimationController.reverse();
    }
  }

  void _handleDelete() {
    widget.onDelete?.call();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // 삭제 버튼 (배경) - 화면 우측에 숨겨져 있다가 드래그에 따라 나타남
        Positioned(
          right: 0,
          top: 0,
          bottom: 0,
          child: Transform.translate(
            offset: Offset(_deleteButtonWidth + _dragOffset, 0),
            child: Container(
              width: _deleteButtonWidth,
              decoration: BoxDecoration(
                color: Colors.transparent,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Align(
                alignment: Alignment.centerRight,
                child: Padding(
                  padding: const EdgeInsets.only(right: 16),
                  child: GestureDetector(
                    onTap: _handleDelete,
                    child: Container(
                      width: 40,
                      height: 40,
                      decoration: const BoxDecoration(
                        color: Colors.red,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.delete_outline,
                        color: Colors.white,
                        size: 24,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
        // 메인 카드 - 실시간으로 드래그에 따라 이동 + 스프링 애니메이션
        AnimatedBuilder(
          animation: _springAnimation,
          builder: (context, child) {
            return Transform.translate(
              offset: Offset(_dragOffset, 0),
              child: GestureDetector(
                onHorizontalDragStart: _handleDragStart,
                onHorizontalDragUpdate: _handleDragUpdate,
                onHorizontalDragEnd: _handleDragEnd,
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Theme.of(context).brightness == Brightness.dark
                        ? const Color(0xFF1E1E1E)
                        : Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: Theme.of(context).brightness == Brightness.dark
                          ? const Color(0xFF3A3A3C).withOpacity(0.3)
                          : const Color(0xFFE0E0E0).withOpacity(0.8),
                      width: 0.5,
                    ),
                  ),
                  child: Row(
                    children: [
                      // 좌측: 미루기 내용과 마감일
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // 미루기 내용
                            Text(
                              widget.content,
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: Theme.of(context).colorScheme.onSurface,
                              ),
                            ),
                            const SizedBox(height: 4),
                            // 마감일
                            Text(
                              widget.deadline,
                              style: TextStyle(
                                fontSize: 14,
                                color: Theme.of(
                                  context,
                                ).colorScheme.onSurface.withOpacity(0.6),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 12),
                      // 우측: 커스텀 토글 버튼
                      GestureDetector(
                        onTap: _handleToggle,
                        child: AnimatedBuilder(
                          animation: _toggleAnimation,
                          builder: (context, child) {
                            return Container(
                              width: 50,
                              height: 30,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(15),
                                color: _isToggled
                                    ? const Color(0xFF87CEEB) // 하늘색 배경 (켜짐)
                                    : const Color(
                                        0xFFD0D0D0,
                                      ), // 더 어두운 회색 배경 (꺼짐)
                              ),
                              child: Stack(
                                children: [
                                  // 토글 원
                                  AnimatedPositioned(
                                    duration: const Duration(milliseconds: 200),
                                    curve: Curves.easeInOut,
                                    left: _isToggled ? 22 : 2,
                                    top: 2,
                                    child: Container(
                                      width: 26,
                                      height: 26,
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        color: _isToggled
                                            ? Colors
                                                  .white // 하얀색 원 (켜짐)
                                            : const Color(
                                                0xFFF5F5F5,
                                              ), // 밝은 회색 원 (꺼짐)
                                        boxShadow: [
                                          BoxShadow(
                                            color: Colors.black.withOpacity(
                                              0.1,
                                            ),
                                            blurRadius: 4,
                                            offset: const Offset(0, 2),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ],
    );
  }
}
