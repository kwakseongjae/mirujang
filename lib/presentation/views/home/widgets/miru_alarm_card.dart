import 'package:flutter/material.dart';

class MiruAlarmCard extends StatefulWidget {
  final String title;
  final String content;
  final String deadline;
  final bool isEnabled;
  final bool needsStrikethrough;
  final bool requiresTimeModal; // 시간 설정 모달이 필요한지 여부
  final VoidCallback? onToggle;
  final VoidCallback? onDelete;
  final VoidCallback? onTap; // 카드 클릭 이벤트

  const MiruAlarmCard({
    super.key,
    required this.title,
    required this.content,
    required this.deadline,
    required this.isEnabled,
    this.needsStrikethrough = false,
    this.requiresTimeModal = false,
    this.onToggle,
    this.onDelete,
    this.onTap,
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
  bool _isDragging = false;
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
  void didUpdateWidget(MiruAlarmCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    // 위젯의 isEnabled 상태가 변경되면 토글 상태 동기화
    if (oldWidget.isEnabled != widget.isEnabled) {
      _isToggled = widget.isEnabled;
      if (_isToggled) {
        _toggleAnimationController.forward();
      } else {
        _toggleAnimationController.reverse();
      }
    }
  }

  @override
  void dispose() {
    _toggleAnimationController.dispose();
    _springAnimationController.dispose();
    super.dispose();
  }

  void _handleToggle() {
    // 시간 설정 모달이 필요한 경우에는 토글 상태를 변경하지 않음
    if (widget.requiresTimeModal) {
      widget.onToggle?.call();
      return;
    }

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
    _isDragging = false;
  }

  void _handleDragUpdate(DragUpdateDetails details) {
    // 드래그가 시작되었는지 확인 (임계값 이상 움직임)
    if (!_isDragging && details.delta.dx.abs() > 5) {
      _isDragging = true;
    }

    if (_isDragging) {
      setState(() {
        // 왼쪽으로 드래그할 때만 음수 값, 오른쪽으로는 0 이상으로 제한
        _dragOffset = (_dragOffset + details.delta.dx).clamp(
          -_deleteButtonWidth,
          0.0,
        );
      });
    }
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

    // 드래그 상태 초기화
    _isDragging = false;
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
                onTap: () {
                  // 토글 버튼이 아닌 영역에서만 클릭 처리
                  widget.onTap?.call();
                },
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
                            // 미루기 타이틀 (1줄로 truncate)
                            Text(
                              widget.title,
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: Theme.of(context).colorScheme.onSurface,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 4),
                            // 마감일 (가운데선 적용)
                            Text(
                              widget.deadline,
                              style: TextStyle(
                                fontSize: 14,
                                color: Theme.of(
                                  context,
                                ).colorScheme.onSurface.withOpacity(0.6),
                                decoration: widget.needsStrikethrough
                                    ? TextDecoration.lineThrough
                                    : TextDecoration.none,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 12),
                      // 우측: 커스텀 토글 버튼
                      GestureDetector(
                        behavior: HitTestBehavior.opaque,
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
                                    ? const Color(0xFFEAD49B) // 말풍선 색상 (켜짐)
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
