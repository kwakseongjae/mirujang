import '../models/miru_task.dart';
import 'storage_service.dart';

class DummyDataService {
  // 운동 관련 제목들 (미루면서 작성한 것 같은 느낌)
  static const List<String> exerciseTitles = [
    '오늘은 진짜 운동을 가야한다',
    '오늘은 진짜진짜 운동을 간다',
    '운동장 가기...',
    '헬스장 가기 (하기 싫지만)',
    '오늘은 꼭 운동해야지',
    '운동 루틴 시작하기 (내일부터)',
    '홈트레이닝 하기 (너무 귀찮아)',
    '조깅하기 (날씨가 좋으면)',
    '오늘은 운동의 날 (아마도)',
    '피트니스 센터 가기 (회원권 돈 아까워)',
    '운동복 챙기기 (빨래해야 하는데)',
    '운동 계획 세우기 (계획만)',
    '오늘은 운동을 안 할 수 없다 (정말?)',
    '운동 동기부여 받기 (유튜브로)',
    '운동 전 스트레칭 (이것도 귀찮아)',
    '운동 후 스트레칭 (운동도 안 했는데)',
    '운동 영상 보기 (보기만)',
    '운동 친구와 약속 (친구도 안 갈 것 같은데)',
    '운동 일지 쓰기 (쓸 게 없는데)',
    '운동 목표 달성하기 (목표만 세우고)',
    '헬스장 등록하기 (다음 달에)',
    '운동화 사기 (돈이 없어)',
    '운동 시간 정하기 (시간이 없어)',
    '운동 메이트 찾기 (혼자 하는 게 편해)',
    '운동 앱 다운받기 (앱만 다운)',
    '운동 식단 짜기 (먹는 게 더 중요해)',
    '운동 전후 사진 찍기 (몸매가 안 좋아)',
    '운동 기록하기 (기록할 게 없어)',
    '운동 동기 찾기 (동기가 없어)',
    '운동 장소 정하기 (집이 제일 편해)',
    '운동 시간대 정하기 (아침엔 못 일어나)',
    '운동 강도 정하기 (너무 힘들어)',
    '운동 종류 정하기 (뭘 해야 할지 모르겠어)',
    '운동 효과 확인하기 (효과가 없어)',
    '운동 중단하기 (이미 중단됨)',
    '운동 재시작하기 (다시 시작할까?)',
    '운동 포기하기 (이미 포기함)',
    '운동 고민하기 (고민만 계속)',
    '운동 생각하기 (생각만)',
  ];

  // 운동 관련 더미 데이터 생성
  static Future<int> generateExerciseDummyData() async {
    try {
      final storageService = await StorageService.getInstance();
      final now = DateTime.now();

      // 9월 1일부터 현재까지 역순으로 생성
      final startDate = DateTime(now.year, 9, 1);
      var currentDate = now;
      int titleIndex = 0;
      int createdCount = 0;

      while (currentDate.isAfter(startDate) ||
          currentDate.isAtSameMomentAs(startDate)) {
        // 2-3일 간격으로 간헐적으로 추가
        if (createdCount % 3 != 0) {
          final task = MiruTask(
            id: 'dummy_${currentDate.millisecondsSinceEpoch}',
            title: exerciseTitles[titleIndex % exerciseTitles.length],
            memo: '운동 관련 미루기 더미 데이터',
            createdAt: currentDate,
            isCompleted: true,
            completedAt: currentDate.add(const Duration(hours: 2)), // 2시간 후 완료
            isEnabled: false,
            notificationTime: null,
            hasNotification: false,
          );

          await storageService.addTask(task);
          titleIndex++;
        }

        // 2-3일 전으로 이동
        final daysToSubtract = (createdCount % 2) + 2; // 2-3일 간격
        currentDate = currentDate.subtract(Duration(days: daysToSubtract));
        createdCount++;

        // 최대 30개까지만 생성
        if (createdCount >= 30) break;
      }

      return titleIndex;
    } catch (e) {
      throw Exception('더미 데이터 생성 중 오류가 발생했습니다: $e');
    }
  }
}
