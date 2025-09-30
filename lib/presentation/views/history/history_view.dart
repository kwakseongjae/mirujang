import 'package:flutter/material.dart';
import '../../../models/miru_task.dart';
import '../../../services/storage_service.dart';
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
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _loadCompletedTasks() async {
    try {
      final storageService = await StorageService.getInstance();
      final allTasks = await storageService.getTasks();

      // 완료된 작업만 필터링
      _completedTasks = allTasks.where((task) => task.isCompleted).toList();

      // 완료 시간 순으로 정렬 (최신순)
      _completedTasks.sort((a, b) => b.createdAt.compareTo(a.createdAt));

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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
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
                  TextButton(
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
              ]
            : [
                // 일반 모드일 때 기존 버튼들
                // 개발용: 더미 히스토리 추가
                IconButton(
                  onPressed: () async {
                    await _addDummyHistory();
                    _loadCompletedTasks(); // UI 새로고침
                  },
                  icon: const Icon(Icons.add),
                  tooltip: '더미 히스토리 추가',
                ),
                // 선택 삭제 모드 진입
                IconButton(
                  onPressed: _enterSelectionMode,
                  icon: const Icon(Icons.delete_outline, color: Colors.red),
                  tooltip: '선택 삭제',
                ),
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
    );
  }

  void _showTaskDetail(MiruTask task) {
    Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (context) => MiruDetailView(task: task)));
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
      } catch (e) {
        // 선택된 작업 삭제 실패 시 사용자에게 알림
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('작업 삭제 중 오류가 발생했습니다.'),
            backgroundColor: Colors.red,
          ),
        );
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

  // 개발용 더미 히스토리 추가
  Future<void> _addDummyHistory() async {
    final storageService = await StorageService.getInstance();
    final now = DateTime.now();

    // 다양한 날짜의 더미 데이터 생성
    final dummyTasks = [
      // 오늘
      MiruTask(
        id: 'dummy_${now.millisecondsSinceEpoch}_1',
        title: '오늘의 운동하기',
        memo: '헬스장에서 1시간 운동 완료!',
        createdAt: now.subtract(const Duration(hours: 2)),
        isCompleted: true,
        isEnabled: false,
        hasNotification: false,
      ),
      MiruTask(
        id: 'dummy_${now.millisecondsSinceEpoch}_2',
        title: '프로젝트 문서 작성',
        memo: 'API 문서 정리 완료',
        createdAt: now.subtract(const Duration(hours: 5)),
        isCompleted: true,
        isEnabled: false,
        hasNotification: false,
      ),

      // 어제
      MiruTask(
        id: 'dummy_${now.millisecondsSinceEpoch}_3',
        title: '장보기',
        memo: '마트에서 필요한 것들 구매 완료',
        createdAt: now.subtract(const Duration(days: 1, hours: 3)),
        isCompleted: true,
        isEnabled: false,
        hasNotification: false,
      ),
      MiruTask(
        id: 'dummy_${now.millisecondsSinceEpoch}_4',
        title: '친구와 저녁 식사',
        memo: '맛있는 파스타 먹고 왔어요',
        createdAt: now.subtract(const Duration(days: 1, hours: 8)),
        isCompleted: true,
        isEnabled: false,
        hasNotification: false,
      ),

      // 2일 전
      MiruTask(
        id: 'dummy_${now.millisecondsSinceEpoch}_5',
        title: '책 읽기',
        memo: '자기계발서 한 권 완독',
        createdAt: now.subtract(const Duration(days: 2, hours: 2)),
        isCompleted: true,
        isEnabled: false,
        hasNotification: false,
      ),
      MiruTask(
        id: 'dummy_${now.millisecondsSinceEpoch}_6',
        title: '방 정리하기',
        memo: '책상과 옷장 정리 완료',
        createdAt: now.subtract(const Duration(days: 2, hours: 6)),
        isCompleted: true,
        isEnabled: false,
        hasNotification: false,
      ),
      MiruTask(
        id: 'dummy_${now.millisecondsSinceEpoch}_7',
        title: '영화 보기',
        memo: '넷플릭스에서 좋은 영화 봤어요',
        createdAt: now.subtract(const Duration(days: 2, hours: 10)),
        isCompleted: true,
        isEnabled: false,
        hasNotification: false,
      ),

      // 3일 전
      MiruTask(
        id: 'dummy_${now.millisecondsSinceEpoch}_8',
        title: '산책하기',
        memo: '공원에서 30분 산책 완료',
        createdAt: now.subtract(const Duration(days: 3, hours: 1)),
        isCompleted: true,
        isEnabled: false,
        hasNotification: false,
      ),
      MiruTask(
        id: 'dummy_${now.millisecondsSinceEpoch}_9',
        title: '요리하기',
        memo: '새로운 레시피로 파스타 만들기',
        createdAt: now.subtract(const Duration(days: 3, hours: 4)),
        isCompleted: true,
        isEnabled: false,
        hasNotification: false,
      ),

      // 4일 전
      MiruTask(
        id: 'dummy_${now.millisecondsSinceEpoch}_10',
        title: '게임하기',
        memo: '친구들과 온라인 게임',
        createdAt: now.subtract(const Duration(days: 4, hours: 3)),
        isCompleted: true,
        isEnabled: false,
        hasNotification: false,
      ),
      MiruTask(
        id: 'dummy_${now.millisecondsSinceEpoch}_11',
        title: '음악 듣기',
        memo: '새로 나온 앨범 감상',
        createdAt: now.subtract(const Duration(days: 4, hours: 7)),
        isCompleted: true,
        isEnabled: false,
        hasNotification: false,
      ),

      // 5일 전
      MiruTask(
        id: 'dummy_${now.millisecondsSinceEpoch}_12',
        title: '독서하기',
        memo: '소설책 한 권 읽기',
        createdAt: now.subtract(const Duration(days: 5, hours: 2)),
        isCompleted: true,
        isEnabled: false,
        hasNotification: false,
      ),

      // 1주일 전
      MiruTask(
        id: 'dummy_${now.millisecondsSinceEpoch}_13',
        title: '주말 정리',
        memo: '일주일치 정리 완료',
        createdAt: now.subtract(const Duration(days: 7, hours: 1)),
        isCompleted: true,
        isEnabled: false,
        hasNotification: false,
      ),
      MiruTask(
        id: 'dummy_${now.millisecondsSinceEpoch}_14',
        title: '가족과 시간 보내기',
        memo: '가족과 함께 저녁 식사',
        createdAt: now.subtract(const Duration(days: 7, hours: 5)),
        isCompleted: true,
        isEnabled: false,
        hasNotification: false,
      ),
    ];

    // 기존 작업들 가져오기
    final existingTasks = await storageService.getTasks();

    // 더미 작업들 추가
    for (final task in dummyTasks) {
      existingTasks.add(task);
    }

    // 저장
    await storageService.saveTasks(existingTasks);
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
              deadline: _formatRelativeTime(task.createdAt),
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
      final dateKey = _getDateKey(task.createdAt);
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
