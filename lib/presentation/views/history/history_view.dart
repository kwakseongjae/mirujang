import 'package:flutter/material.dart';
import '../../../models/miru_task.dart';
import '../../../services/storage_service.dart';
// import '../../../services/dummy_data_service.dart'; // 개발용 - 필요시 주석 해제
import '../detail/miru_detail_view.dart';
import 'widgets/miru_history_card.dart';

class HistoryView extends StatefulWidget {
  const HistoryView({super.key});

  @override
  State<HistoryView> createState() => _HistoryViewState();
}

class _HistoryViewState extends State<HistoryView>
    with TickerProviderStateMixin {
  List<MiruTask> _completedTasks = [];
  Map<String, List<MiruTask>> _groupedTasks = {};
  bool _isLoading = true;

  // 검색바 관련 변수들
  final TextEditingController _searchController = TextEditingController();
  bool _isSearchVisible = true;
  bool _isSearching = false;
  late AnimationController _searchAnimationController;
  late Animation<double> _searchAnimation;
  final ScrollController _scrollController = ScrollController();
  double _lastScrollOffset = 0.0;

  // 다중 선택 관련 변수들
  bool _isSelectionMode = false;
  final Set<String> _selectedTaskIds = {};

  // 토스트 메시지 관련
  bool _showToast = false;
  String _toastMessage = '';
  Color _toastColor = Colors.green;
  late AnimationController _toastAnimationController;
  late Animation<Offset> _toastAnimation;

  @override
  void initState() {
    super.initState();
    _loadCompletedTasks();

    // 검색바 애니메이션 컨트롤러 초기화
    _searchAnimationController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );
    _searchAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _searchAnimationController,
        curve: Curves.easeInOut,
      ),
    );

    // 토스트 애니메이션 컨트롤러 초기화
    _toastAnimationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _toastAnimation =
        Tween<Offset>(begin: const Offset(0, -1), end: Offset.zero).animate(
          CurvedAnimation(
            parent: _toastAnimationController,
            curve: Curves.easeOut,
          ),
        );

    // 초기 상태를 표시로 설정
    _searchAnimationController.value = 1.0;

    // 스크롤 리스너 추가
    _scrollController.addListener(_onScroll);

    // 검색 컨트롤러 리스너 추가
    _searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _searchController.dispose();
    _searchAnimationController.dispose();
    _toastAnimationController.dispose();
    _scrollController.dispose();
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
      // 3초 후 토스트 숨기기
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

  Future<void> _loadCompletedTasks() async {
    try {
      final storageService = await StorageService.getInstance();
      final allTasks = await storageService.getTasks();

      // 완료된 작업만 필터링
      _completedTasks = allTasks.where((task) => task.isCompleted).toList();

      // 완료 시간 순으로 정렬 (최신순) - completedAt이 있으면 그것을, 없으면 createdAt을 사용
      _completedTasks.sort((a, b) {
        final aTime = a.completedAt ?? a.createdAt;
        final bTime = b.completedAt ?? b.createdAt;
        return bTime.compareTo(aTime);
      });

      // 날짜별로 그룹화
      _groupedTasks = _groupTasksByDate(_completedTasks);

      setState(() {
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  // 운동 관련 더미 데이터 생성 (개발용 - 필요시 주석 해제)
  // Future<void> _generateExerciseDummyData() async {
  //   try {
  //     final count = await DummyDataService.generateExerciseDummyData();

  //     // 성공 메시지 표시
  //     if (mounted) {
  //       ScaffoldMessenger.of(context).showSnackBar(
  //         SnackBar(
  //           content: Text('$count개의 운동 더미 데이터가 생성되었습니다!'),
  //           backgroundColor: const Color(0xFF34C759),
  //           behavior: SnackBarBehavior.floating,
  //           shape: RoundedRectangleBorder(
  //             borderRadius: BorderRadius.circular(8),
  //           ),
  //         ),
  //       );
  //     }

  //     // 히스토리 목록 새로고침
  //     await _loadCompletedTasks();
  //   } catch (e) {
  //     if (mounted) {
  //       ScaffoldMessenger.of(context).showSnackBar(
  //         SnackBar(
  //           content: Text('더미 데이터 생성 중 오류가 발생했습니다: $e'),
  //           backgroundColor: const Color(0xFFFF3B30),
  //           behavior: SnackBarBehavior.floating,
  //           shape: RoundedRectangleBorder(
  //             borderRadius: BorderRadius.circular(8),
  //           ),
  //         ),
  //       );
  //     }
  //   }
  // }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Scaffold(
          appBar: AppBar(
            title: _isSelectionMode
                ? Text(
                    '${_selectedTaskIds.length}개 선택됨',
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                    ),
                  )
                : const Text(
                    '히스토리',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
                  ),
            backgroundColor: Colors.transparent,
            elevation: 0,
            centerTitle: true,
            leading: _isSelectionMode
                ? IconButton(
                    onPressed: _exitSelectionMode,
                    icon: const Icon(Icons.close),
                  )
                : null,
            actions: _isSelectionMode
                ? [
                    // 선택 모드일 때 삭제 버튼
                    if (_selectedTaskIds.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(right: 12),
                        child: TextButton(
                          onPressed: _deleteSelectedTasks,
                          child: const Text(
                            '삭제',
                            style: TextStyle(
                              color: Colors.red,
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                  ]
                : [
                    // 편집 모드 진입
                    Padding(
                      padding: const EdgeInsets.only(right: 12),
                      child: TextButton(
                        onPressed: _enterSelectionMode,
                        child: Text(
                          '편집',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color:
                                Theme.of(context).brightness == Brightness.dark
                                ? Colors.white
                                : Colors.black,
                          ),
                        ),
                      ),
                    ),
                    // 개발용: 더미 데이터 생성 버튼 (주석 처리)
                    // IconButton(
                    //   onPressed: _generateExerciseDummyData,
                    //   icon: const Icon(Icons.add),
                    //   tooltip: '운동 더미 데이터 생성',
                    // ),
                  ],
          ),
          body: _isLoading
              ? const Center(child: CircularProgressIndicator())
              : _completedTasks.isEmpty
              ? const Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.history_rounded, size: 80, color: Colors.grey),
                      SizedBox(height: 16),
                      Text(
                        '아직 완료된 일정이 없어요',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w500,
                          color: Colors.grey,
                        ),
                      ),
                      SizedBox(height: 8),
                      Text(
                        '미루기를 완료하면 여기에 기록됩니다',
                        style: TextStyle(fontSize: 14, color: Colors.grey),
                      ),
                    ],
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _loadCompletedTasks,
                  child: Column(
                    children: [
                      // iOS 스타일 검색바
                      AnimatedBuilder(
                        animation: _searchAnimation,
                        builder: (context, child) {
                          return SizeTransition(
                            sizeFactor: _searchAnimation,
                            child: Container(
                              padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                              child: _buildSearchBar(),
                            ),
                          );
                        },
                      ),
                      // 히스토리 목록
                      Expanded(
                        child: ListView.builder(
                          controller: _scrollController,
                          padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                          itemCount: _groupedTasks.length,
                          itemBuilder: (context, index) {
                            final sortedKeys = _groupedTasks.keys.toList()
                              ..sort((a, b) => b.compareTo(a)); // 최신 날짜부터
                            final dateKey = sortedKeys[index];
                            final tasks = _groupedTasks[dateKey]!;
                            final dateTime = DateTime.parse(dateKey);

                            return _buildDateSection(dateTime, tasks);
                          },
                        ),
                      ),
                    ],
                  ),
                ),
        ),
        // 토스트 메시지
        if (_showToast)
          Positioned(
            top: MediaQuery.of(context).padding.top + 16,
            left: 16,
            right: 16,
            child: SlideTransition(
              position: _toastAnimation,
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
          ),
      ],
    );
  }

  void _showTaskDetail(MiruTask task) async {
    final result = await Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (context) => MiruDetailView(task: task)));

    // 상세페이지에서 돌아왔을 때 결과 처리
    if (result == true ||
        result is MiruTask ||
        result == 'completed' ||
        result == 'deleted') {
      // 히스토리 목록 새로고침
      await _loadCompletedTasks();

      // 삭제 처리된 경우 토스트 메시지 표시
      if (result == 'deleted') {
        _showToastMessage('미루기 기록이 삭제되었습니다', Colors.red);
      }
    }
  }

  // 선택 모드 진입
  void _enterSelectionMode() {
    setState(() {
      _isSelectionMode = true;
      _selectedTaskIds.clear();
    });
  }

  // 선택 모드 종료
  void _exitSelectionMode() {
    setState(() {
      _isSelectionMode = false;
      _selectedTaskIds.clear();
    });
  }

  // 작업 선택 토글
  void _toggleTaskSelection(String taskId) {
    setState(() {
      if (_selectedTaskIds.contains(taskId)) {
        _selectedTaskIds.remove(taskId);
      } else {
        _selectedTaskIds.add(taskId);
      }
    });
  }

  // 선택된 작업들 삭제
  void _deleteSelectedTasks() async {
    if (_selectedTaskIds.isEmpty) return;

    // 삭제 확인 다이얼로그 표시
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('선택한 히스토리를 삭제하시겠어요?', style: TextStyle(fontSize: 24)),
        content: Text('${_selectedTaskIds.length}개의 히스토리가 삭제됩니다.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('취소'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('삭제'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      // 삭제할 개수를 미리 저장
      final deleteCount = _selectedTaskIds.length;

      try {
        final storageService = await StorageService.getInstance();
        final allTasks = await storageService.getTasks();

        // 선택된 작업들 제거
        allTasks.removeWhere((task) => _selectedTaskIds.contains(task.id));

        // 저장
        await storageService.saveTasks(allTasks);

        // UI 업데이트
        _exitSelectionMode();
        _loadCompletedTasks();

        // 삭제 성공 토스트 메시지 표시
        _showToastMessage(
          deleteCount == 1
              ? '미루기 기록이 삭제되었습니다'
              : '$deleteCount개의 미루기 기록이 삭제되었습니다',
          Colors.red,
        );
      } catch (e) {
        // 선택된 작업 삭제 실패 시 사용자에게 알림
        _showToastMessage('작업 삭제 중 오류가 발생했습니다.', Colors.red);
      }
    }
  }

  // 스크롤 이벤트 처리
  void _onScroll() {
    if (_scrollController.hasClients) {
      final offset = _scrollController.offset;
      const threshold = 80.0; // 80px 이상 스크롤하면 검색바 숨김

      // 스크롤 방향에 따른 처리
      final isScrollingDown = offset > _lastScrollOffset;
      _lastScrollOffset = offset;

      if (offset > threshold && isScrollingDown && _isSearchVisible) {
        setState(() {
          _isSearchVisible = false;
        });
        _searchAnimationController.reverse();
      } else if (offset <= threshold && !_isSearchVisible) {
        setState(() {
          _isSearchVisible = true;
        });
        _searchAnimationController.forward();
      }
    }
  }

  // 검색 텍스트 변경 처리
  void _onSearchChanged() {
    setState(() {
      _isSearching = _searchController.text.isNotEmpty;
    });
    _filterTasks();
  }

  // 검색어로 작업 필터링
  void _filterTasks() {
    if (_searchController.text.isEmpty) {
      _groupedTasks = _groupTasksByDate(_completedTasks);
    } else {
      final filteredTasks = _completedTasks.where((task) {
        return task.title.toLowerCase().contains(
              _searchController.text.toLowerCase(),
            ) ||
            task.memo.toLowerCase().contains(
              _searchController.text.toLowerCase(),
            );
      }).toList();
      _groupedTasks = _groupTasksByDate(filteredTasks);
    }
  }

  // iOS 스타일 검색바 위젯
  Widget _buildSearchBar() {
    return Container(
      height: 40,
      margin: const EdgeInsets.symmetric(horizontal: 4),
      decoration: BoxDecoration(
        color: Theme.of(context).brightness == Brightness.dark
            ? const Color(0xFF2C2C2E)
            : const Color(0xFFF2F2F7),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Theme.of(context).brightness == Brightness.dark
              ? const Color(0xFF3A3A3C).withOpacity(0.5)
              : const Color(0xFFD1D1D6).withOpacity(0.8),
          width: 0.5,
        ),
      ),
      child: Row(
        children: [
          const SizedBox(width: 12),
          Icon(
            Icons.search,
            size: 20,
            color: Theme.of(context).brightness == Brightness.dark
                ? Colors.white.withOpacity(0.6)
                : Colors.black.withOpacity(0.6),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: TextField(
              controller: _searchController,
              style: TextStyle(
                fontSize: 17,
                height: 1.2,
                color: Theme.of(context).brightness == Brightness.dark
                    ? Colors.white
                    : Colors.black,
              ),
              decoration: InputDecoration(
                hintText: '검색',
                hintStyle: TextStyle(
                  fontSize: 17,
                  height: 1.2,
                  color: Theme.of(context).brightness == Brightness.dark
                      ? Colors.white.withOpacity(0.6)
                      : Colors.black.withOpacity(0.6),
                ),
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(vertical: 8),
                isDense: true,
              ),
            ),
          ),
          if (_isSearching)
            GestureDetector(
              onTap: () {
                _searchController.clear();
              },
              child: Container(
                margin: const EdgeInsets.only(right: 8),
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: Theme.of(context).brightness == Brightness.dark
                      ? Colors.white.withOpacity(0.2)
                      : Colors.black.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.clear,
                  size: 16,
                  color: Theme.of(context).brightness == Brightness.dark
                      ? Colors.white.withOpacity(0.8)
                      : Colors.black.withOpacity(0.6),
                ),
              ),
            ),
        ],
      ),
    );
  }

  // 날짜 섹션 위젯 생성
  Widget _buildDateSection(DateTime dateTime, List<MiruTask> tasks) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 날짜 라벨
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 12, top: 8),
          child: Text(
            _formatDateLabel(dateTime),
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Theme.of(context).brightness == Brightness.dark
                  ? Colors.white.withOpacity(0.8)
                  : Colors.black.withOpacity(0.8),
            ),
          ),
        ),
        // 해당 날짜의 작업들
        ...tasks.asMap().entries.map((entry) {
          final taskIndex = entry.key;
          final task = entry.value;
          return Padding(
            padding: EdgeInsets.only(
              bottom: taskIndex < tasks.length - 1 ? 12 : 0,
            ),
            child: MiruHistoryCard(
              title: task.title,
              content: task.memo,
              deadline: _formatRelativeTime(task.completedAt ?? task.createdAt),
              isSelectionMode: _isSelectionMode,
              isSelected: _selectedTaskIds.contains(task.id),
              onTap: () {
                _showTaskDetail(task);
              },
              onSelectionChanged: () {
                _toggleTaskSelection(task.id);
              },
            ),
          );
        }),
        const SizedBox(height: 24), // 날짜 섹션 간 간격
      ],
    );
  }

  // 날짜별로 작업을 그룹화
  Map<String, List<MiruTask>> _groupTasksByDate(List<MiruTask> tasks) {
    final Map<String, List<MiruTask>> grouped = {};

    for (final task in tasks) {
      // completedAt이 있으면 그것을, 없으면 createdAt을 사용
      final dateTime = task.completedAt ?? task.createdAt;
      final dateKey = _getDateKey(dateTime);
      if (!grouped.containsKey(dateKey)) {
        grouped[dateKey] = [];
      }
      grouped[dateKey]!.add(task);
    }

    return grouped;
  }

  // 날짜 키 생성 (YYYY-MM-DD 형식)
  String _getDateKey(DateTime dateTime) {
    return '${dateTime.year}-${dateTime.month.toString().padLeft(2, '0')}-${dateTime.day.toString().padLeft(2, '0')}';
  }

  // 날짜 라벨 포맷팅 (예: 2025년 9월 30일 (화))
  String _formatDateLabel(DateTime dateTime) {
    final weekdays = ['일', '월', '화', '수', '목', '금', '토'];
    final weekday = weekdays[dateTime.weekday % 7];

    return '${dateTime.year}년 ${dateTime.month}월 ${dateTime.day}일 ($weekday)';
  }

  // 상대적 시간 포맷팅 (예: 2시간 전)
  String _formatRelativeTime(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inDays > 0) {
      return '${difference.inDays}일 전';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}시간 전';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes}분 전';
    } else {
      return '방금 전';
    }
  }
}
